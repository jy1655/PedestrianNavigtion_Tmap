//
//  ViewController.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/10/23.
//

//
//  ViewController.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/10/23.
//

import UIKit
import TMapSDK
import CoreLocation
import SideMenu
import MapKit


class ViewController: UIViewController, TMapTapiDelegate, TMapViewDelegate, CLLocationManagerDelegate, ModalDelegate {

    let callAppkey = CallAppKey()
    let pathData = TMapPathData() // 경로 탐색을 위한 지정
    var mapView: TMapView! // TMapView의 인스턴스를 저장할 변수를 선언합니다
    //    var installed: Bool = TMapApi.isTmapApplicationInstalled() // 티맵 App 설치 여부를 판단한다
    var path = Array<CLLocationCoordinate2D>()
    var locationManager: CLLocationManager!
    var currentLocation: CLLocationCoordinate2D!
    var selectLocation: CLLocationCoordinate2D?
    var gpsStatus: String = "UNKNOWN" { didSet { detectStatus() } } // GPS 상태변화 확인용
    var markers:Array<TMapMarker> = [] // 마커를 관리하기 위한 배열
    var polylines:Array<TMapPolyline> = [] // 폴리라인을 관리하기 위한배열
    let addressTextField = UITextField()
    var searchButton = UIButton()
    var menuButton = UIButton()
    var routeButton = UIButton()
    var routeButtonBottomConstraint: NSLayoutConstraint? // 하단부 버튼이 키보드에 가리지 않도록 조정하기 위함
    var menu: SideMenuNavigationController?
    var isTableViewVisible = false
    let imuCheck = IMUCheck()
    var menuTableViewController: MenuTableViewController?
    let userLocation: MKMapView? = nil // 사용자 위치표시용
    var modalData = [Route]()
    var modalLineData: Route?
    var currentCustomView: MarkerUIView?
    var isNavigationActive = false



    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setUpUI()
//        imuCheck.startMotionUpdates() // 콘솔창이 너무 어지러워서 임시 차단

        setupSideMenu()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationCheck(on: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        // 중단된 뷰 컨트롤러의 뷰 해제
        for viewController in self.children {
            if !viewController.isViewLoaded || (viewController.view.window == nil) {
                viewController.view = nil
            }
        }
    }

    @objc func requestRoute() {
        userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시

        clearMarkers()
        clearPolylines()

        addressTextField.resignFirstResponder() // 키보드가 보이는 경우 숨깁니다

        mapView.trackingMode = .followWithHeading // 트래킹 모드 활성화

        let startPoint = currentLocation!

        let endPoint = selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)

        pedestrianAPICall(startPoint: startPoint, endPoint: endPoint) { result in
            switch result {
            case .success(let pedestrianData):
                // 성공적으로 데이터를 받았을 때의 처리
                print(pedestrianData)
            case .failure(let error):
                // 오류가 발생했을 때의 처리
                print(error.localizedDescription)
            }
        }// API 호출

        path.append(startPoint)
        path.append(endPoint)

//        _ = TMapPolyline(coordinates: path)

        let pathType = TMapPathType.PEDESTRIAN_PATH

        print("경로탐색")
        pathData.findPathDataWithType(pathType, startPoint: startPoint, endPoint: endPoint) { (result, error)->Void in
            // 결과
            if let error = error {
                // 에러 처리
                print("Error: \(error.localizedDescription)")
            } else if let polyline = result {

                // 경로 데이터 사용
                print("Path data received")
                DispatchQueue.main.async { // UI 업데이트는 메인 스레드에서 수행합니다.
                    let marker1 = TMapMarker(position: startPoint) // `pathData` 폴리라인을 지도에 추가합니다.
                    marker1.map = self.mapView
                    marker1.title = "출발지"
                    self.markers.append(marker1)

                    let marker2 = TMapMarker(position: endPoint)
                    marker2.map = self.mapView
                    marker2.title = "목적지"
                    self.markers.append(marker2)

                    polyline.map = self.mapView
                    polyline.strokeColor = MakingUI.colorWithHexString(hexString: "000000") // 네비용 폴리선을 검은색으로
                    self.mapView.fitMapBoundsWithPolylines([polyline])
                    self.polylines.append(polyline)
                }
            }
        }
    }

    @objc func searchLocationModal() {

        let modalView = SearchView()
        modalView.delegate = self // 자신을 delegate로 지정
        modalView.routes = modalData // 이전데이터 전달
        modalView.onDataUpdate = { [weak self] updatedData in
            self?.modalLineData = updatedData // 업데이트된 데이터 저장
        }
        present(modalView, animated: true)
    }

    func setupMapView() {
        // TMapView 객체를 생성합니다.
        mapView = TMapView()

        mapView.delegate = self // 지도 상호작용을 위해 추가
        mapView.isUserInteractionEnabled = true // 지도 상호작용을 위해 추가

        //        mapView?.setApiKey(getValue(forKey: "appKey")!)
        mapView?.setApiKey(callAppkey.appKey()!)

        // 필요한 경우, 여기에 추가적인 mapView 설정을 추가할 수 있습니다.
        // 예: mapView.setCenter(...)

        // mapView를 self.view에 추가합니다.
        self.view.addSubview(mapView)

        // 오토레이아웃을 사용하여 mapView의 제약 조건을 설정합니다.
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
            mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            mapView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        mapView.trackingMode = .follow// 트래킹 모드 활성화
    }

    private func mapViewDidFinishLoadingMap() async { // showsUserLocation 점이 나오지 않는 버그상황 방지를 위해 async 사용
        userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시
    } // 지도가 생성된 이후에 실행할 메소드

    func setUpUI() {

        // 검색 버튼 설정
        searchButton = setButton(title: "검색", selector: #selector(searchLocationModal))
        self.view.addSubview(searchButton)

        // 메뉴 버튼 설정
        menuButton = setButton(title: "Menu", selector: #selector(presentSideMenu))
        self.view.addSubview(menuButton)
        // 경로 탐색 버튼 설정
        routeButton = setButton(title: "경로 탐색", selector: #selector(requestRoute))
        view.addSubview(routeButton)
//        self.view.addSubview(routeButton)

        // 오토 레이아웃 설정
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        routeButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        // NSLayoutConstraint를 사용하여 오토 레이아웃 설정
        NSLayoutConstraint.activate([
            // 검색 버튼은 주소 입력창의 오른쪽에 위치
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),

            // 메뉴 버튼은 주소 입력창 왼쪽에 위치
            menuButton.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            menuButton.centerYAnchor.constraint(equalTo: searchButton.centerYAnchor),

            // 경로 탐색 버튼은 하단 중앙에 위치
            routeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            routeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            routeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        // 초기 상수를 가지고 경로 버튼 하단 제약 설정
        routeButtonBottomConstraint = routeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        routeButtonBottomConstraint?.isActive = true

        // 키보드 알림 등록
        registerForKeyboardNotifications { [weak self] (keyboardHeight, isKeyboardShowing) in
            self?.routeButtonBottomConstraint?.constant = isKeyboardShowing ? -keyboardHeight - 20 : -20
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        }
        hideKeyboardWhenTappedAround() // 키보드 내려가는 탭제스쳐 인식기
    }

    func setupSideMenu() {

        let menuTableVC = MenuTableViewController()
        self.menuTableViewController = menuTableVC
        initTableViewData()

        menu = SideMenuNavigationController(rootViewController: menuTableViewController!)
        //        menu = SideMenuNavigationController(rootViewController: menuTableViewController)
        // 메뉴가 나타날 방향 설정
        SideMenuManager.default.leftMenuNavigationController = menu
        // 메뉴를 나타나게 하는 제스처 활성화
        SideMenuManager.default.addPanGestureToPresent(toView: self.view)
    }

    func modalViewDidDisappear() { // SearchView 모달이 닫히면서 조건을 충족하면 작동하는 메소드
        print("전송받은 전체 데이터: \(modalData)")
        print("경로를 표시해야할 데이터: \(String(describing: modalLineData))")

        if modalLineData != nil {

            clearMarkers()
            clearPolylines()

            startNavigation()

            let startPointLat = modalLineData?.itinerary.legs.first?.start.lat
            let startPointLon = modalLineData?.itinerary.legs.first?.start.lon
            let endPointLat = modalLineData?.itinerary.legs.last?.end.lat
            let endPointLon = modalLineData?.itinerary.legs.last?.end.lon

            setMarker(position: CLLocationCoordinate2D(latitude: startPointLat!, longitude: startPointLon!))
            setMarker(position: CLLocationCoordinate2D(latitude: endPointLat!, longitude: endPointLon!))

            polylines = createPolylines(from: modalLineData!) // TMapView에 polyline들을 추가

            transitMarker() // 대중교통 타고 내리는 위치에 마크 추가

            for polyline in polylines {
                polyline.map = self.mapView
                self.polylines.append(polyline)
            }
            mapView.trackingMode = .followWithHeading // 트래킹 모드 활성화
        } // 선택했던 경로를 지도에 표시(polyline)
    } // 모달창이 경로를 선택하면서 닫힐떄 호출되는 메소드

    func takeData(data: [Route]) {
        modalData = data
    } // 모달에서 검색한 대중교통경로 정보(10개치) 저장

    func createPolylines(from route: Route) -> [TMapPolyline] {
        var previousStepEndCoordinate: CLLocationCoordinate2D?

        for leg in route.itinerary.legs {

            if leg.passShape != nil {

                let transitcoordinates = MakingUI.createCoordinates(from: leg.passShape!.linestring) // 좌표들 생성

                if let endCoordinate = previousStepEndCoordinate, let startCoordinate = transitcoordinates.first {
                    let bridgeCoordinates = [endCoordinate, startCoordinate]
                    let bridgePolyline = TMapPolyline(coordinates: bridgeCoordinates)
                    bridgePolyline.strokeColor = MakingUI.colorWithHexString(hexString: leg.routeColor ?? "000000") // 환승 지역 이동은 검은색으로 표현
                    bridgePolyline.lineStyle = .dot
                    polylines.append(bridgePolyline)
                } // 이전에 생성된 좌표가 존재했을 경우 이어주는 메소드

                let transitpolyline = TMapPolyline(coordinates: transitcoordinates)
                transitpolyline.strokeColor = MakingUI.colorWithHexString(hexString: leg.routeColor ?? "000000") // routeColor에 맞게 경로 색 설정
                if !(leg.routeColor != nil) {
                    transitpolyline.lineStyle = .dash
                } // 환승지역으로 걸어가는 거리가 있기도 함
                polylines.append(transitpolyline)
                previousStepEndCoordinate = transitcoordinates.last
            }

            guard let steps = leg.steps else { continue }

            for step in steps {
                let coordinates = MakingUI.createCoordinates(from: step.linestring)

                if let endCoordinate = previousStepEndCoordinate, let startCoordinate = coordinates.first {
                    let stepCoordinates = [endCoordinate, startCoordinate]
                    let stepPolyline = TMapPolyline(coordinates: stepCoordinates)
                    stepPolyline.strokeColor = MakingUI.colorWithHexString(hexString: "000000") // 도보 이동은 검은색으로 표현
                    stepPolyline.lineStyle = .dot
                    polylines.append(stepPolyline)
                } // 이전에 생성된 좌표가 존재했을 경우 이어주는 메소드

                let polyline = TMapPolyline(coordinates: coordinates)
                polyline.strokeColor = MakingUI.colorWithHexString(hexString: "000000") // 도보 이동은 검은색으로 표현
                polyline.lineStyle = .dot
                polylines.append(polyline)
                previousStepEndCoordinate = coordinates.last
            }
        }
        print("폴리라인들: \(polylines)")
        return polylines
    }


    func detectStatus() {

        let action1 = UIAlertAction(title: "확인", style: .default, handler: { _ in print("버튼 눌림") } )

        if gpsStatus == "NO_SIGNAL" {
            print("GPS 신호 없음")
            setAlert(title: "GPS 오류!", message: "GPS 신호가 없습니다!", actions: [action1], on: self)
        } else if gpsStatus == "BAD" {
            print("GPS 신호가 약합니다")
        } else if gpsStatus == "TUNNEL" {
            print("터널진입")
        } else if gpsStatus == "UNDERPASS" {
            print("Underpass")
        } else {
            print("상태양호")
        }
    }

    func checkAuthorization() {
        let status = locationManager.authorizationStatus

        let logOkAction = UIAlertAction(title: "네", style: UIAlertAction.Style.default) {
            (action: UIAlertAction) in
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(NSURL(string:UIApplication.openSettingsURLString)! as URL)
            } else {
                UIApplication.shared.openURL(NSURL(string: UIApplication.openSettingsURLString)! as URL)
            }
        }
        let logNoAction = UIAlertAction(title: "아니오", style: UIAlertAction.Style.destructive) {
            (action: UIAlertAction) in
            exit(0)
        }

        if status == .denied || status == .restricted {
            setAlert(title: "권한 필요", message: "위치 서비스 권한이 필요합니다. 위치 서비스 권한 제한시 앱이 종료됩니다.", actions: [logOkAction, logNoAction], on: self)

        }
    }

    func locationCheck(on viewController: UIViewController) {

        print("location check")

        locationManager = CLLocationManager()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 최상의 정확도
        locationManager.distanceFilter = 30 // 30미터마다 위치업데이트를 받음
//                locationManager.distanceFilter = kCLDistanceFilterNone // 미세한 움직임에 대한 피드백도 받음

//        locationManager.requestWhenInUseAuthorization() // 위치 서비스 권한 요청(앱을 사용하고 있을떄만)
        locationManager.requestAlwaysAuthorization() // 백그라운드에서도 위치정보에 접근가능 권한 요청
        locationManager.startUpdatingLocation() // 위치 업데이트 시작

        checkAuthorization()

    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // 위치 정보가 업데이트 되었을 때 호출되는 델리게이트 메소드
        if let location = locations.last { // 최신 위치 정보를 가져옵니다.
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude

            if isNavigationActive {
                // 네비게이션 활성화 상태일 때만 실행
                let distance = distanceFromPolyline()
                print("떨어진 거리\(distance)")
                //                circle.map = nil
                mapView.animateTo(zoom: 18)

                let alert1 = UIAlertAction(title: "확인", style: .default)
                if distance > 10 { // 10m 이상 경로를 벗어난다면
                    setAlert(title: "경로 이탈", message: "경로를 벗어났습니다. 약 \(ceil(distance))m", actions: [alert1], on: self)
                    print("경고문")
                }
                // 여기에 경로 계산 및 업데이트 로직 추가
                // 예: calculateRoute(from: location.coordinate, to: destinationCoordinate)
            }

            currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) // CLLocationCoordinate2D로 변환
            updateLocation(newLocation: currentLocation)

            mapView.animateTo(location: currentLocation) // 현재 위치로 지도의 위치를 옮긴다.

            print("Current coordinates: \(String(describing: currentLocation))") // 여기서 coordinate를 사용할 수 있습니다.


        }
    }

    // 위치 접근이 실패했을 때 호출되는 메소드
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) { // 위치정보 권한 설정이 변경될 때마다 콜백
        print("위치권한 설정 변경")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            // 권한이 승인되었을때
            print("권한 설정 완료")
            userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시
        case .notDetermined:
            print("권한 결정 안함")
            checkAuthorization()
        case .restricted:
            print("권한 제한")
            checkAuthorization()
        case .denied:
            print("권한 거부")
            checkAuthorization()
        @unknown default:
            print("알 수 없는 권한")
            checkAuthorization()
        }
    }


    func mapView(_ mapView: TMapView, singleTapOnMap location: CLLocationCoordinate2D) {
        print("싱글탭")

        currentCustomView?.removeFromSuperview()
        view.endEditing(true) // 키보드가 올라와 있었다면 내린다.
    }

    func mapView(_ mapView: TMapView, longTapOnMap position: CLLocationCoordinate2D) {
        print("롱탭")
        //        self.logLabel.text = "지도 롱탭"
        let lat: Double = position.latitude
        let lon: Double = position.longitude
        print("lat:\(lat) \n lon:\(lon)")
    }

    func mapView(_ mapView: TMapView, doubleTapOnMap position: CLLocationCoordinate2D) {
        print("지도 더블 탭")

        _ = TMapMarker(position: position)

        setMarker(position: position)

        //        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 50))
        //        label.text = "좌측"
        //        marker.leftCalloutView = label
        //        let label2 = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 50))
        //        label2.text = "우측"
        //        marker.rightCalloutView = label2
    }

    func mapView(_ mapView: TMapView, tapOnMarker marker: TMapMarker) {
        print("마커 탭")
        selectLocation = marker.position
        print("selectLocation latitude: \(String(describing: selectLocation?.latitude)), longitude: \(String(describing: selectLocation?.longitude))")
    }

//    func mapView(_ mapView: TMapView, shouldChangeFrom oldPosition: CLLocationCoordinate2D, to newPosition: CLLocationCoordinate2D) -> Bool {
//        let oldPosition = CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)
//        var newPosition = currentLocation
//        return true
//    }

    func setMarker(position: CLLocationCoordinate2D) { // 마커 생성시 리버스지오코딩으로 주소 가져오기
        pathData.reverseGeocoding(position, addressType: "A02") {(result, error) in
            if let result = result {
                DispatchQueue.main.async {
                    let marker = TMapMarker(position: position)
                    marker.map = self.mapView
                    marker.draggable = false
                    marker.title = result["fullAddress"] as? String
                    marker.subTitle = result["legalDong"] as? String
                    marker.setTapCallback { [weak self] _ in
                        guard let self = self else { return }

                        let customView = MarkerUIView()
                        customView.delegate = self

                        // 기존 뷰 제거
                        currentCustomView?.removeFromSuperview()

                        // 새로운 뷰 생성 및 구성
                        customView.createCalloutView()
                        customView.configure(with: result, marker: marker)

                        mapView.addSubview(customView)
                        currentCustomView = customView
                    }
                    print(result)

                    self.markers.append(marker)
                }
            }
        }
    }

    func transitMarker() { // 대중교통 이용시 승차, 환승, 하차지역 정보 마커표시 메소드
        if modalLineData?.itinerary != nil {
            let legs = modalLineData!.itinerary.legs
            for leg in legs {
                if leg.passStopList != nil {
                    let latStart: String = (leg.passStopList?.stationList.first!.lat)!
                    let lonStart: String = (leg.passStopList?.stationList.first!.lon)!
                    let latEnd: String = (leg.passStopList?.stationList.last!.lat)!
                    let lonEnd: String = (leg.passStopList?.stationList.last!.lon)!

                    let latStartValue = Double(latStart)
                    let lonStartValue = Double(lonStart)
                    let latEndValue = Double(latEnd)
                    let lonEndValue = Double(lonEnd)

                    let startPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latStartValue!, longitude: lonStartValue!)
                    let endPostion = CLLocationCoordinate2D(latitude: latEndValue!, longitude: lonEndValue!)

                    DispatchQueue.main.async {
                        let startMarker = TMapMarker(position: startPosition) // 승차지역
                        let endMarker = TMapMarker(position: endPostion) // 하차지역
                        startMarker.map = self.mapView
                        endMarker.map = self.mapView
                        startMarker.draggable = true
                        endMarker.draggable = false
                        startMarker.title = leg.mode ?? "알수없는 교통수단" // 교통수단 :버스 지하철등
                        endMarker.title = "\((leg.passStopList?.stationList.last?.stationName)!) 하차" // 하차 역 정보

                        switch leg.Lane {
                        case nil:
                            startMarker.subTitle = leg.route // 노선정보 간선641등
                        case let lane? where lane.endIndex == 1: // 요소가 하나만 있을때
                            startMarker.subTitle = leg.route
                        case let lane? where lane.endIndex == 2: // 요소가 두개만 있을때
                            startMarker.subTitle = "\(leg.Lane!.first!.route), \(leg.Lane!.last!.route)"
                        default:
                            if let lane = leg.Lane {
                                startMarker.subTitle = "\(lane.first!.route), \(lane.last!.route)외 \(lane.endIndex-2)노선"
                            }
                        }

                        endMarker.subTitle = "\((leg.passStopList?.stationList.last?.index)!+1) 정거장" // 지나야 하는 정류장 수

                        self.markers.append(startMarker)
                        self.markers.append(endMarker)
                    }
                }
            }
        }
    }

    func pedestrianAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<PedestrianData, Error>) -> Void) {
        let routeRequest = CallRestAPI(
            startX: String(describing: startPoint.longitude),
            startY: String(describing: startPoint.latitude),
            endX: String(describing: endPoint.longitude),
            endY: String(describing: endPoint.latitude)
        )

        routeRequest.fetchRoute { result in
            switch result {
            case .success(let data):
                do {
                    // JSON 데이터를 PedestrianData으로 디코딩
                    let pedestrianData = try JSONDecoder().decode(PedestrianData.self, from: data)
                    // featureCollection 처리
                    print(pedestrianData)
                    completion(.success(pedestrianData))
                } catch {
                    print("JSON 디코딩 에러: \(error)")
                    completion(.failure(error))
                }

            case .failure(let error):
                print("API 호출 오류: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

//        routeRequest.fetchRoute { result in
//            switch result {
//            case .success(let data):
//                // 성공적으로 데이터를 받았을 때 처리
//                do {
//                    // JSON 데이터를 딕셔너리로 변환
//                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                        // JSON 데이터를 이쁘게 출력하기 위해 JSONSerialization을 사용
//                        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
//                        // 이쁘게 만든 JSON 데이터를 문자열로 변환
//                        if let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
//                            // 이쁘게 만든 문자열을 콘솔에 출력
//                            print(prettyPrintedString)
//                        }
//                    }
//                } catch {
//                    print("JSON 파싱 에러: \(error)")
//                }
//            case .failure(let error):
//                // 오류가 발생했을 때 처리
//                print(error.localizedDescription)
//            }
//        }
    }

    func transitAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<TransitData, Error>) -> Void) {
        let transitRequest = CallRestAPI(
            startX: String(describing: startPoint.longitude),
            startY: String(describing: startPoint.latitude),
            endX: String(describing: endPoint.longitude),
            endY: String(describing: endPoint.latitude)
        )

        transitRequest.transitRoute { result in
            switch result {
            case .success(let data):
                do {
                    // JSON 데이터를 PedestrianData으로 디코딩
                    let transitData = try JSONDecoder().decode(TransitData.self, from: data)
                    // featureCollection 처리
                    print(transitData)
                    completion(.success(transitData))
                } catch {
                    print("JSON 디코딩 에러: \(error)")
                    completion(.failure(error))
                }

            case .failure(let error):
                print("API 호출 오류: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }

//        transitRequest.transitRoute { result in
//            switch result {
//            case .success(let data):
//                // 성공적으로 데이터를 받았을 때 처리
//                do {
//                    // JSON 데이터를 딕셔너리로 변환
//                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                        // JSON 데이터를 이쁘게 출력하기 위해 JSONSerialization을 사용
//                        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
//                        // 이쁘게 만든 JSON 데이터를 문자열로 변환
//                        if let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
//                            // 이쁘게 만든 문자열을 콘솔에 출력
//                            print(prettyPrintedString)
//                        }
//                    }
//                } catch {
//                    print("JSON 파싱 에러: \(error)")
//                }
//            case .failure(let error):
//                // 오류가 발생했을 때 처리
//                print(error.localizedDescription)
//            }
//        }
    }

    func clearMarkers() { // 마커 지우기
        print("마커 지우기")
        for marker in markers {
            marker.map = nil
        }
        self.markers.removeAll()
    }

    func clearPolylines() {
        print("폴리라인 지우기")
        for polyline in polylines {
            polyline.map = nil
        }
        self.polylines.removeAll()
    }

    func SKTMapApikeySucceed() { // TMapTapiDelegate를 통해 callback을 받음.
        print("APIKEY 인증 성공")
    }

    func SKTMapApikeyFailed(error: NSError?) {
        print("APIKEY 인증 실패")
    }

    func startNavigation() {
        isNavigationActive = true
    }

    func stopNavigation() {
        isNavigationActive = false
    }

    @objc func presentSideMenu() {
        // 메뉴 표시
        present(menu!, animated: true, completion: nil)
    }

    @objc func dismissSideMenu() {
        // Dismiss the currently presented view controller, which is the side menu.
        dismiss(animated: true, completion: nil)
    }

    func initTableViewData() {
        print("확인")

        guard let menuTableVC = menuTableViewController else { return }

        menuTableVC.menuItems.append(LeftMenuData(title: "초기화", onClick: {[weak self] in self?.initMapView()}))

        // 기본 기능
        menuTableVC.menuItems.append(LeftMenuData(title: "현재위치", onClick: {[weak self] in self?.basicFunc001()}))
        menuTableVC.menuItems.append(LeftMenuData(title: "대중교통 경로", onClick: {[weak self] in self?.transit(startPoint: self!.currentLocation!, endPoint: self?.selectLocation!)}))


        // api
        //            self.leftArray?.append(LeftMenuData(title: "자동완성", onClick: objFunc51))
        //            self.leftArray?.append(LeftMenuData(title: "BizCategory", onClick: objFunc52))
        menuTableVC.menuItems.append(LeftMenuData(title: "POI 검색", onClick: {[weak self] in self?.objFunc53()}))
        menuTableVC.menuItems.append(LeftMenuData(title: "POI 주변검색", onClick: {[weak self] in self?.objFunc54()}))
        menuTableVC.menuItems.append(LeftMenuData(title: "리버스 지오코딩", onClick: {[weak self] in self?.objFunc56()}))
        menuTableVC.menuItems.append(LeftMenuData(title: "경로탐색", onClick: {[weak self] in self?.objFunc57()}))
        //            self.leftArray?.append(LeftMenuData(title: "타임머신", onClick: objFunc59))
        menuTableVC.menuItems.append(LeftMenuData(title: "경유지 최적화", onClick: {[weak self] in self?.objFunc60()}))
        print("메뉴 항목 수: \(menuTableVC.menuItems.count)")

        menuTableVC.tableView.reloadData()
    }


    deinit {
        unregisterForKeyboardNotifications() // 뷰 컨트롤러가 해제될 때 또는 더 이상 키보드 알림을 받을 필요가 없을 때 알림 관찰자를 제거
    }

}


extension ViewController {
    //맵 초기화
        public func initMapView(){
            clearMarkers()
            clearPolylines()
            mapView.removeFromSuperview() // 지도 삭제
            addressTextField.removeFromSuperview() // 입력창 삭제
            searchButton.removeFromSuperview() // 검색 버튼 삭제
            menuButton.removeFromSuperview() // 메뉴 버튼 삭제
            routeButton.removeFromSuperview() // 경로탐색 버튼 삭제
            print("지도 삭제")
            mapView.delegate = nil

            mapView.delegate = self

            mapView.trackingMode = .none

            // mapView를 self.view에 추가합니다.
            self.view.addSubview(mapView) // 지도 다시 추가

            // 오토레이아웃을 사용하여 mapView의 제약 조건을 설정합니다.
            mapView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                mapView.topAnchor.constraint(equalTo: self.view.topAnchor),
                mapView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
                mapView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
                mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])


            setUpUI() // 지도 위에 다시 UI 생성
            dismissSideMenu()
        }

    //화면이동
    public func basicFunc001(){
        self.mapView?.setCenter(currentLocation) // 현재 사용자 위치를 중심으로
        mapView.animateTo(zoom: 17) // 줌레벨 조정
        mapView.trackingMode = .followWithHeading
        dismissSideMenu()
    }

    public func objFunc53() {
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        pathData.requestFindAllPOI(addressTextField.text ?? "SK", count: 20) { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        let marker = TMapMarker(position: poi.coordinate!)
                        marker.map = self.mapView
                        marker.title = poi.name
                        self.markers.append(marker)
                        self.mapView?.fitMapBoundsWithMarkers(self.markers)

                    }
                }
            }
        }
        dismissSideMenu()
    }

    public func objFunc54() {
        guard let center = self.mapView?.getCenter() else { return }
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()

        pathData.requestFindAroundKeywordPOI(center, keywordName: addressTextField.text ?? "SK", radius: 500, count: 20, completion: { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    for poi in result {
                        let marker = TMapMarker(position: poi.coordinate!)
                        marker.map = self.mapView
                        marker.title = poi.name
                        self.markers.append(marker)
                        //                        self.mapView?.fitMapBoundsWithMarkers(self.markers)

                    }
                }
            }
        })
        dismissSideMenu()
    }

    public func objFunc56() {
        guard let center = self.mapView?.getCenter() else { return }
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()

        pathData.reverseGeocoding(center, addressType: "A02") { (result, error)->Void in
            if let result = result {
                DispatchQueue.main.async {
                    let marker = TMapMarker(position: center)
                    marker.map = self.mapView
                    marker.title = result["fullAddress"] as? String
                    self.markers.append(marker)
                }
            }
        }
        dismissSideMenu()
    }

    // 경로탐색
    public func objFunc57() {
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        let startPoint = currentLocation ?? CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038)
        let endPoint = selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)

        pathData.findPathData(startPoint: startPoint, endPoint: endPoint) { (result, error)->Void in
            if let polyline = result {
                DispatchQueue.main.async {
                    let marker1 = TMapMarker(position: startPoint)
                    marker1.map = self.mapView
                    marker1.title = "출발지"
                    self.markers.append(marker1)

                    let marker2 = TMapMarker(position: endPoint)
                    marker2.map = self.mapView
                    marker2.title = "목적지"
                    self.markers.append(marker2)

                    polyline.map = self.mapView
                    self.polylines.append(polyline)
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
        }
        dismissSideMenu()
    }

    // 경유지 최적화
    public func objFunc60() {
        self.clearMarkers()
        self.clearPolylines()

        let pathData = TMapPathData()
        let startPoint = currentLocation ?? CLLocationCoordinate2D(latitude: 37.566567, longitude: 126.985038)
        let endPoint = selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)
        let via1Point = CLLocationCoordinate2D(latitude: 37.557822, longitude: 126.925119)
        let via2Point = CLLocationCoordinate2D(latitude: 37.510537, longitude: 127.062002)

        pathData.findMultiPathData(startPoint: startPoint, endPoint: endPoint, passPoints: [via1Point, via2Point], searchOption: 1) { (result, error)->Void in
            if let polyline = result {
                DispatchQueue.main.async {
                    let marker1 = TMapMarker(position: startPoint)
                    marker1.map = self.mapView
                    marker1.title = "출발지"
                    self.markers.append(marker1)

                    let marker2 = TMapMarker(position: endPoint)
                    marker2.map = self.mapView
                    marker2.title = "목적지"
                    self.markers.append(marker2)

                    let marker3 = TMapMarker(position: via1Point)
                    marker3.map = self.mapView
                    marker3.title = "경유지1"
                    self.markers.append(marker3)

                    let marker4 = TMapMarker(position: via2Point)
                    marker4.map = self.mapView
                    marker4.title = "경유지2"
                    self.markers.append(marker4)

                    polyline.map = self.mapView
                    self.polylines.append(polyline)
                    self.mapView?.fitMapBoundsWithPolylines(self.polylines)
                }
            }
        }
        dismissSideMenu()
    }

    public func transit(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D?) {
        clearMarkers()
        clearPolylines()

        addressTextField.resignFirstResponder() // 키보드가 보이는 경우 숨깁니다

        mapView.trackingMode = .follow // 트래킹 모드 활성화

        transitAPICall(startPoint: startPoint, endPoint: endPoint ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)) { result in
            switch result {
            case .success(let transitData):
                // 성공적으로 데이터를 받았을 때의 처리
                print(transitData)
            case .failure(let error):
                // 오류가 발생했을 때의 처리
                print(error.localizedDescription)
            }
        } // API 호출

        path.append(startPoint)
        path.append(endPoint ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318))

        _ = TMapPolyline(coordinates: path)
    }

    func distanceFromPolyline() -> CLLocationDistance {
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude

        for polyline in polylines {
            for i in 0..<(polyline.path.count - 1) {
                let startPoint = polyline.path[i]
                let endPoint = polyline.path[i + 1]

                let distance = calculateDistanceFromPointToLineSegment(point: currentLocation, lineStart: startPoint, lineEnd: endPoint)
                minDistance = min(minDistance, distance)
            }
        }

        return minDistance
    }

    func distanceFromLineSegment(point: CLLocationCoordinate2D, start: [CLLocationCoordinate2D], end: [CLLocationCoordinate2D]) -> CLLocationDistance {
        // 여기에 선분과 점 사이의 최소 거리를 계산하는 로직을 구현합니다.
        // 이는 수학적인 계산이 필요하며, 선형 대수학을 사용하여 구현할 수 있습니다.
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude

        for (startPoint, endPoint) in zip(start, end) {
            let distance = calculateDistanceFromPointToLineSegment(point: point, lineStart: startPoint, lineEnd: endPoint)
            minDistance = min(minDistance, distance)
        }

        return minDistance
    }


    private func calculateDistanceFromPointToLineSegment(point: CLLocationCoordinate2D, lineStart: CLLocationCoordinate2D, lineEnd: CLLocationCoordinate2D) -> CLLocationDistance {
        let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
        let startLocation = CLLocation(latitude: lineStart.latitude, longitude: lineStart.longitude)
        let endLocation = CLLocation(latitude: lineEnd.latitude, longitude: lineEnd.longitude)

        // 선분 위의 점에 대한 투영을 계산합니다
        let dx = endLocation.coordinate.longitude - startLocation.coordinate.longitude
        let dy = endLocation.coordinate.latitude - startLocation.coordinate.latitude

        let lengthSquared = dx * dx + dy * dy
        var t = ((point.longitude - lineStart.longitude) * dx + (point.latitude - lineStart.latitude) * dy) / lengthSquared

        t = max(0, min(1, t))

        let closestPoint = CLLocationCoordinate2D(
            latitude: lineStart.latitude + t * dy,
            longitude: lineStart.longitude + t * dx
        )

        let closestLocation = CLLocation(latitude: closestPoint.latitude, longitude: closestPoint.longitude)

        return pointLocation.distance(from: closestLocation)
    }

    func updateLocation(newLocation: CLLocationCoordinate2D) {
        self.currentLocation = newLocation
    }


}


protocol ModalDelegate: AnyObject { // 모달창에서 메소드를 공유하기 위한 Delegate
    var currentLocation: CLLocationCoordinate2D! { get set }
    var selectLocation: CLLocationCoordinate2D? { get set }
    //    func transit(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D?)
    func modalViewDidDisappear()
    func takeData(data: [Route])
    func pedestrianAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<PedestrianData, Error>) -> Void)
    func transitAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<TransitData, Error>) -> Void)
    func updateLocation(newLocation: CLLocationCoordinate2D)
    func requestRoute()
    func searchLocationModal()
}

