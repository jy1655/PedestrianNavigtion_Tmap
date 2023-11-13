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


class ViewController: UIViewController, TMapTapiDelegate, TMapViewDelegate, CLLocationManagerDelegate {

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



    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setUpUI()
        imuCheck.startMotionUpdates()

        setupSideMenu()

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationCheck(on: self)
        userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
    }

    @objc func requestRoute() {
        userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시

        clearMarkers()
        clearPolylines()

        addressTextField.resignFirstResponder() // 키보드가 보이는 경우 숨깁니다

        mapView.trackingMode = .follow // 트래킹 모드 활성화

        let startPoint = currentLocation!

        let endPoint = selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)

        let routeRequest = CallRestAPI(
            startX: String(describing: startPoint.longitude),
            startY: String(describing: startPoint.latitude),
            endX: String(describing: endPoint.longitude),
            endY: String(describing: endPoint.latitude)

        )

        routeRequest.fetchRoute { result in
            switch result {
            case .success(let data):
                // 성공적으로 데이터를 받았을 때 처리
                do {
                    // JSON 데이터를 딕셔너리로 변환
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // JSON 데이터를 이쁘게 출력하기 위해 JSONSerialization을 사용
                        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        // 이쁘게 만든 JSON 데이터를 문자열로 변환
                        if let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
                            // 이쁘게 만든 문자열을 콘솔에 출력
                            print(prettyPrintedString)
                        }
                    }
                } catch {
                    print("JSON 파싱 에러: \(error)")
                }
            case .failure(let error):
                // 오류가 발생했을 때 처리
                print(error.localizedDescription)
            }
        }

        path.append(startPoint)
        path.append(endPoint)

        _ = TMapPolyline(coordinates: path)

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
                    self.mapView.fitMapBoundsWithPolylines([polyline])
                    self.polylines.append(polyline)
                }
            }
        }
    }

    @objc func searchLocation() {
        userLocation?.showsUserLocation = true // 사용자의 위치정보를 파란색 점으로 표시

        clearMarkers()
        clearPolylines()

        guard let address = addressTextField.text, !address.isEmpty else {
            print("Address is empty")
            return
        }

        print("address: \(address)")

        pathData.requestFindAllPOI(address, count: 30) { (results, error) in
            guard error == nil else {
                print("Error finding POIs: \(error!.localizedDescription)")
                return
            }

            if let results = results {
                for result in results {
                    self.setMarker(position: result.coordinate!)
                }
            }
        }
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
            // 하단을 비우기 위해 'mapView'의 하단을 뷰의 중간에 맞춥니다.
            mapView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        mapView.trackingMode = .follow// 트래킹 모드 활성화
    }

    func setUpUI() {

        // 주소 검색 텍스트 입력창 설정
        addressTextField.placeholder = "주소 검색"
        addressTextField.borderStyle = .none
        addressTextField.backgroundColor = UIColor.white
        addressTextField.layer.cornerRadius = 8
        addressTextField.layer.masksToBounds = true
        addressTextField.layer.sublayerTransform = CATransform3DMakeTranslation(10, 0, 0) // Padding left
        view.addSubview(addressTextField)

        // 검색 버튼 설정
        searchButton = setButton(title: "검색", selector: #selector(searchLocation))

        //        // 메뉴 버튼 설정
        menuButton = setButton(title: "Menu", selector: #selector(presentSideMenu))

        // 경로 탐색 버튼 설정
        routeButton = setButton(title: "경로 탐색", selector: #selector(requestRoute))
        //        view.addSubview(routeButton)

        // 오토 레이아웃 설정
        addressTextField.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        routeButton.translatesAutoresizingMaskIntoConstraints = false
        menuButton.translatesAutoresizingMaskIntoConstraints = false

        // NSLayoutConstraint를 사용하여 오토 레이아웃 설정
        NSLayoutConstraint.activate([
            // 주소 입력창은 상단에 위치
            addressTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 5),
            addressTextField.leadingAnchor.constraint(equalTo: menuButton.trailingAnchor, constant: 20),
            addressTextField.trailingAnchor.constraint(equalTo: searchButton.leadingAnchor, constant: -10),

            // 검색 버튼은 주소 입력창의 오른쪽에 위치
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.centerYAnchor.constraint(equalTo: addressTextField.centerYAnchor),

            // 메뉴 버튼은 주소 입력창 왼쪽에 위치
            menuButton.trailingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            menuButton.centerYAnchor.constraint(equalTo: addressTextField.centerYAnchor),

            // 경로 탐색 버튼은 하단 중앙에 위치
            routeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            routeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            routeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
        // 초기 상수를 가지고 경로 버튼 하단 제약 설정
        routeButtonBottomConstraint = routeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        routeButtonBottomConstraint?.isActive = true

        // 키보드 알림 등록
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
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

    func locationCheck(on viewController: UIViewController) {

        print("location check")

        locationManager = CLLocationManager()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 최상의 정확도
        locationManager.distanceFilter = 30 // 30미터마다 위치업데이트를 받음
        //        locationManager.distanceFilter = kCLDistanceFilterNone // 미세한 움직임에 대한 피드백도 받음

        locationManager.requestWhenInUseAuthorization() // 위치 서비스 권한 요청
        locationManager.requestAlwaysAuthorization() // 언제나?
        locationManager.startUpdatingLocation() // 위치 업데이트 시작


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
            setAlert(title: "권한 필요", message: "위치 서비스 권한이 필요합니다", actions: [logOkAction, logNoAction], on: self)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { // 위치 정보가 업데이트 되었을 때 호출되는 델리게이트 메소드
        if let location = locations.last { // 최신 위치 정보를 가져옵니다.
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude

            currentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude) // CLLocationCoordinate2D로 변환

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
        case .restricted:
            print("권한 제한")
        case .denied:
            print("권한 거부")
        @unknown default:
            print("알 수 없는 권한")
        }
    }


    func mapView(_ mapView: TMapView, singleTapOnMap location: CLLocationCoordinate2D) {
        print("싱글탭")
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
                    print(result)

                    self.markers.append(marker)
                }
            }
        }
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

    func setButton(title: String, selector: Selector) -> UIButton { // 버튼 만들기
        // iOS 14 미만에서 사용하는 기존의 UIButton 초기화 방식
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside) // selector로 버튼 클릭시 구현될 메소드 작성
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 5
        button.clipsToBounds = true

        self.view.addSubview(button)

        return button
    }

    func SKTMapApikeySucceed() { // TMapTapiDelegate를 통해 callback을 받음.
        print("APIKEY 인증 성공")
    }

    func SKTMapApikeyFailed(error: NSError?) {
        print("APIKEY 인증 실패")
    }


    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            // 경로 버튼의 하단 제약을 업데이트합니다
            routeButtonBottomConstraint?.constant = -keyboardHeight - 20 // 필요에 따라 값을 조정
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // 경로 버튼의 하단 제약을 초기 상수 값으로 리셋합니다
        routeButtonBottomConstraint?.constant = -20
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
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
        menuTableVC.menuItems.append(LeftMenuData(title: "화면이동", onClick: {[weak self] in self?.basicFunc001()}))
        menuTableVC.menuItems.append(LeftMenuData(title: "대중교통 경로", onClick: {[weak self] in self?.transit()}))


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

    func setAlert(title: String, message: String, actions: [UIAlertAction], on viewController: UIViewController) { // 알람기능 만들어두기
        print("버튼생성 : \(title)")
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        for action in actions {
            alert.addAction(action)
        }
        viewController.present(alert, animated:  true)
    }

    deinit { // 뷰 컨트롤러가 해제될 때 또는 더 이상 키보드 알림을 받을 필요가 없을 때 알림 관찰자를 제거
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

}


extension ViewController {
    //맵 초기화
        public func initMapView(){
            mapView.removeFromSuperview() // 지도 삭제
            addressTextField.removeFromSuperview() // 입력창 삭제
            searchButton.removeFromSuperview() // 검색 버튼 삭제
            menuButton.removeFromSuperview() // 메뉴 버튼 삭제
            routeButton.removeFromSuperview() // 경로탐색 버튼 삭제
            print("지도 삭제")
            mapView.delegate = nil

            mapView.delegate = self

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
        self.mapView?.setCenter(currentLocation)
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

    // 대중교통1
    public func objFunc71() {
//                if self.mapView.isPublicTrasit {
//                    for marker in self.ptMarkers {
//                        marker.map = nil
//                    }
//                    self.ptMarkers.removeAll()
//                    self.ptCircle?.map = nil
//                }
//                self.isPublicTrasit = !self.isPublicTrasit
    }

    public func transit() {
        clearMarkers()
        clearPolylines()

        addressTextField.resignFirstResponder() // 키보드가 보이는 경우 숨깁니다

        mapView.trackingMode = .follow // 트래킹 모드 활성화

        let startPoint = currentLocation!

        let endPoint = selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)

        let routeRequest = CallRestAPI(
            startX: String(describing: startPoint.longitude),
            startY: String(describing: startPoint.latitude),
            endX: String(describing: endPoint.longitude),
            endY: String(describing: endPoint.latitude)

        )

        routeRequest.transitRoute { result in
            switch result {
            case .success(let data):
                // 성공적으로 데이터를 받았을 때 처리
                do {
                    // JSON 데이터를 딕셔너리로 변환
                    if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        // JSON 데이터를 이쁘게 출력하기 위해 JSONSerialization을 사용
                        let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                        // 이쁘게 만든 JSON 데이터를 문자열로 변환
                        if let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
                            // 이쁘게 만든 문자열을 콘솔에 출력
                            print(prettyPrintedString)
                        }
                    }
                } catch {
                    print("JSON 파싱 에러: \(error)")
                }
            case .failure(let error):
                // 오류가 발생했을 때 처리
                print(error.localizedDescription)
            }
        }

        path.append(startPoint)
        path.append(endPoint)

        _ = TMapPolyline(coordinates: path)
    }
}

