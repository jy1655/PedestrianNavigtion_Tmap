# **`PedestrianNavi_Tmap` Docs v0.1**
** 2024.01.03 기준**
** 기본적인 TMapAPI 기능은 [TMapAPI](https://tmapapi.sktelecom.com/) 문서를 참고 **





# Model 폴더에 존재하는 기능 정리 


## func appKey() -> String?
 
- Description

    `CallAppKey` 파일에 존재하는 `Config.plist` 에 저장된 appKey의 value 값(Tmap API 사이트에서 발급받은 appKey)을 불러오는 메소드. 현재 방식대로는 소스코드 내부에 appKey를 저장해야되는 보안문제가 존재하여 후에 정식 서비스 전에 변경해야하는 메소드임

- Example

    ```swift
    CallAppKey().appKey()!
    ```





## func fetchRoute(completion: @escaping (Result<Data, Error>) -> Void)

- Description

    `CallRestAPI` 파일에서 보행자 경로요청 API를 불러오는 메소드. 

    데이터를 제공받기 위해서는 TMap API 사이트에서 발급받은 appKey가 필요하다. 
    메소드 내부에 request.addValue(`발급받은 appKey`, forHTTPHeaderField: "appKey")부분에 키값 입력
    
    정상적으로 데이터를 받아올 경우 json 형식의 데이터를 받아옴
    
- Example

    ```swift
    CallRestAPI().fetchRoute { result in
        switch result {
        case .success(let data):
            do {
                // JSON 데이터를 PedestrianData으로 디코딩
                let pedestrianData = try JSONDecoder().decode(PedestrianData.self, from: data)
                completion(.success(pedestrianData))
            } catch {
                completion(.failure(error))
            }

        case .failure(let error):
            completion(.failure(error))
        }
    }
    ```





## func transitRoute(completion: @escaping (Result<Data, Error>) -> Void)

- Description

    `CallRestAPI` 파일에서 대중교통 경로요청 API를 불러오는 메소드.

    데이터를 제공받기 위해서는 TMap API 사이트에서 발급받은 appKey가 필요하다. 
    메소드 내부에 request.addValue(`발급받은 appKey`, forHTTPHeaderField: "appKey")부분에 키값 입력
    
    정상적으로 데이터를 받아올 경우 json 형식의 데이터를 받아옴
    
- Example

    ```swift
    CallRestAPI().transitRoute { result in
        switch result {
        case .success(let data):
            do {
                // JSON 데이터를 TransitData으로 디코딩
                let transitData = try JSONDecoder().decode(TransitData.self, from: data)
                completion(.success(transitData))
            } catch {
                completion(.failure(error))
            }

        case .failure(let error):
            completion(.failure(error))
        }
    }
    ```





## func transitSubRoute(completion: @escaping (Result<Data, Error>) -> Void)

- Description

    `CallRestAPI` 파일에서 대중교통 경로요청 API를 불러오는 메소드.

    데이터를 제공받기 위해서는 TMap API 사이트에서 발급받은 appKey가 필요하다. 
    메소드 내부에 request.addValue(`발급받은 appKey`, forHTTPHeaderField: "appKey")부분에 키값 입력
    
    정상적으로 데이터를 받아올 경우 json 형식의 데이터를 받아옴
    
    transitRoute 메소드와 다르게 간략화된 데이터를 가져옴.(URL이 다름) 현재는 사용되지 않는 메소드이나 API 호출제한과 관련된 문제로 사용해야하는 경우가 생길수 있어서 유지중. 사용방식은 동일하나 데이터 형식의 차이점이 존재함.





## func startMotionUpdates()

- Description

    `IMU` 파일에서 기기의 IMU 기능을 활성화하기 위해서 만들어진 메소드.
    
    현재 하나의 메소드에 가속도계, 자이로스코프와 자력계 3개의 기능을 모두 활성화하고 있는데 추후에 나누게 될지 어떨지는 아직 정해진바가 없고 지금 이 기능을 활성화 하느냐 마냐에 따른 기능성 변화가 없다. 오히려 활성화시 전력소모가 커지는 단점만 있으나 추후에 이것을 가지고 기능개발에 들어갈 수도 있음
    
- Example

    ```swift
    IMUCheck().startMotionUpdates()
    ```





## func detectDirectionChange()

- Description

    `IMU` 파일에서 기기의 IMU 기능을 활용하여 방향전환을 인식할 수 있도록 만들어진 메소드. 미완성





## static func colorWithHexString(hexString: String) -> UIColor

- Description

    `MakingUI` 파일에 존재하는 메소드로 지도에 표시된 경로(Polyline)을 API호출로 불려진 데이터셋 중 경로 색상에 맞게 변경해주기 위해 만든 메소드. 도보이동은 경로 색상이 지정되어있지 않으나 대중교통 경로에는 이동 방식(버스나 지하철)에 따른 경로의 색상이 지정되어서 데이터를 전송해주기에 그에 맞게 지도에 표시하기 위함.
    
- Parameters

    hexString: `XXXXXX` 형식으로 구성된 16진수 숫자, 대중교통 API 데이터셋에서 `routeColor` 부분을 사용

- Example

    ```swift
    let transitpolyline = TMapPolyline(coordinates: transitcoordinates)
    transitpolyline.strokeColor = MakingUI.colorWithHexString(hexString: leg.routeColor ?? "000000") // routeColor에 맞게 경로 색 설정 지정색 없을시 검은색
    polylines.append(transitpolyline)
    ```





## static func createCoordinates(from linestring: String) -> [CLLocationCoordinate2D]

- Description

    `MakingUI` 파일에 있는 메소드로 API로 불러진 데이터셋에서 linestring 좌표들을 실제 CLLocationCoordinate2D 값으로 return 해주는 메소드

- Parameters

    linestring: `longitude,latitude` 형식의 연속으로 이루어진 문자열. 문자열간의 구분은 띄어쓰기. 도보나 대중교통이나 똑같은 형식으로 정보를 제공받는다.
    
    - Example
        linestring = "126.994222,37.480300 126.996675,37.481094 126.997442,37.481344 126.997619,37.481403 126.997792,37.481453 126.997958,37.481494 126.998186,37.481519 126.999553,37.481653 127.000000,37.481719"

- Example

    ```swift
    let transitcoordinates = MakingUI.createCoordinates(from: `TransitData`.leg.passShape!.linestring) // 좌표들 저장
    ```






# extension UIViewController


## 키보드 관련 확장 메소드

- Description
    
    `MakingUI` 파일에서 extension UIViewController 내부에 있는 타입 정의
    
    - typealias KeyboardUIUpdate = (_ keyboardHeight: CGFloat, _ isKeyboardShowing: Bool) -> Void 
    - func registerForKeyboardNotifications(updateUI: @escaping KeyboardUIUpdate)
    - func unregisterForKeyboardNotifications()
    - @objc func keyboardWillShow(notification: NSNotification)
    - @objc func keyboardWillHide(notification: NSNotification)
    - func updateBottomLayoutConstraint(with constant: CGFloat)
    - func hideKeyboardWhenTappedAround()
    - @objc private func dismissKeyboard()
    
    로 연관 메소드들이 구성되어 있다.
    
    
    protocol KeyboardHandling 으로 키보드의 등장과 사라짐에 따라 화면 레이아웃을 조정하는 데 필요한 메서드와 속성을 정의
    
    - bottomConstraint: NSLayoutConstraint 타입의 속성으로, 화면 하단에 위치한 뷰의 오토레이아웃 제약 조건을 참조합니다. 이 속성은 키보드가 화면에 표시될 때 뷰의 위치를 조정하는 데 사용
    - updateBottomLayoutConstraint(height: CGFloat): 키보드의 높이에 따라 하단 제약 조건을 업데이트하는 메서드입니다. 키보드가 등장하거나 사라질 때 호출되어, 관련 뷰의 레이아웃을 적절히 조정


- Example

    ```swift
    func keyboardMethod() {
    // 키보드 알림 등록
        registerForKeyboardNotifications { [weak self] (keyboardHeight, isKeyboardShowing) in
            self?.routeButtonBottomConstraint?.constant = isKeyboardShowing ? -keyboardHeight - 20 : -20
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        }
        hideKeyboardWhenTappedAround() // 키보드 내려가는 탭제스쳐 인식기
    }
    
    deinit {
        unregisterForKeyboardNotifications() // 뷰 컨트롤러가 해제될 때 또는 더 이상 키보드 알림을 받을 필요가 없을 때 알림 관찰자를 제거
    }
    ```





## 버튼, 알림관련 확장 메소드

- Description

    - func setButton(title: String, selector: Selector) -> UIButton: 버튼제작 용이성을 위해 임의로 만든 확장 메소드 후에 필요에 따라 변경하거나 제거하여도 무방함. title과 selector만 따로 구현하면 여러 버튼을 쉽게 구성 가능하다. 필요에 따라 버튼크기를 지정하는 파라미터를 추가하는 방식으로 변경하는것도 좋을거라 생각함
    
    - func touchDownAction(_ sender: UIButton): 버튼을 눌렀을떄 눌렸다는 UI적 표시를 위해서 임의로 만든 확장 메소드 간단하게 touchDown 되었을때 버튼 크기를 95%로 줄이는 메소드. 기본적으로 setButton내부에 포함되어 있음
    - func touchUpAction(_ sender: UIButton): 위의 메소드와 세트로 버튼에서 떼어지면 크기를 원래대로 되돌리는 메소드. 기본적으로 setButton내부에 포함되어 있음
    
    - func setAlert(title: String, message: String, actions: [UIAlertAction]?, on viewController: UIViewController): 알람기능 제작 편의성을 위해 임의로 만든 확장 메소드. title, message, actions만 지정하면 알람기능을 만들고 actions를 따로 제작하지 않으면 Default로 확인버튼이 나오는 메소드 *주의사항* actions의 경우 여러 action을 넣을수 있도록 UIAlertAction? 이 아닌 [UIAlertAction]? 파라미터를 받도록 되어있음

- Example

    ```swift
    func setting() {
        searchButton = setButton(title: "경로 찾기", selector: #selector(searchLocationModal))
        self.view.addSubview(searchButton)
    
        let action1 = UIAlertAction(title: "확인", style: .default, handler: { _ in print("버튼 눌림") } )
        setAlert(title: "GPS 오류!", message: "GPS 신호가 없습니다!", actions: [action1], on: self)
    }        
    
    @objc func searchLocationModal() {
        present(modalView, animated: true)
    }
    ```






# MarkerUIView 기능정리


- Description

    메인 View(ViewController)에서 마커를 클릭했을때 해당 마커에 저장된 데이터를 Modal페이지로 화면에 보이는 기능을 정리한 파일



## func createCalloutView()

- Description

    메인 View(ViewController)에서 마커를 클릭했을때의 콜백 메소드로 사용이 되도록 제작하였고 지정된 위치의 버튼과 내부설정을 작성해놓았으나 기능구현을 위주로 임시로 제작하여 변경이 필요함.
    
- Example

    ```swift
    // ViewController의 setMarker 메소드 내부에서 사용됨 
    marker.setTapCallback { [weak self] _ in guard let self = self else { return }

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
    ```





## func configure(with data: [String: Any], marker: TMapMarker)

- Description 

    func createCalloutView()와 같이 메인 View에서 마커를 구현시킬때 새로운 뷰의 구성을 맡는 메소드
    
- Parameters

    data: 마커의 구성내용을 저장하기 위한 Dictionary 형식 정보
    marker: TMapMarker(position: ) 형식의 정보로 각 마커마다의 구별성을 위해 필요한 정보

- Example

    func createCalloutView()와 동일





## @objc func shutdownView(), @objc func deleteMarkerAndView()

- Description

    두 메소드 모두 창을 닫는 기능이지만 shutdownView()의 경우 창만을 닫지만 deleteMarkerAndView()의 경우 창을 닫으면서 marker를 삭제한다.
    두 메소드 모두 func createCalloutView() 내부에 포함되어 있다.





## @objc func searchLocationModal()

- Description

    해당 마커의 위치를 `selectLocation` 으로 삼고 `SearchView` 파일의 searchLocationModal()을 실행시키는 메소드
    func createCalloutView() 내부에 포함되어 있다.






# SearchView 기능정리


- Description

    출발지와 목적지를 토대로 네비게이션 검색을 하기위해 만든 Modal 페이지 
    - var routes: TransitDataModel 파일에서 정의한 Routes 모델 배열을 저장하기 위한 변수
    - var walks: PedestrianDataModel 파일에서 정의한 도보 이동 모델 배열을 저장하기 위한 변수
    - var onTransitDataUpdate: 대중교통 데이터를 메인 View로 전달하기 위한 변수
    - var onWalkDataUpdate: 도보 데이터를 메인 View로 전달하기 위한 변수



## override func viewDidLoad()

- Description

    routesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "walkCell")
    routesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    로 테이블 뷰의 셀 재사용을 위해 셀을 등록합니다. "walkCell"과 "cell"이라는 식별자를 가진 기본 UITableViewCell을 등록합니다.
    
    registerForKeyboardNotifications와 hideKeyboardWhenTappedAround 로 키보드 처리를 관리
    
    activityIndicator로 로딩 애니메이션을 설정합니다.    





## override func viewDidDisappear(_ animated: Bool)

- Description

    if isDataUpdated {} 를 통해서 데이터의 변동사항이 존재하는 경우에만 메인 View의 func modalViewDidDisappear()를 호출할 수 있도록 한다.





## func setupUI(), func setupConstraints()

- Description

    Modal 페이지 UI 설정





## @objc func searchButtonTapped()

- Description

    setButton 메소드에 들어갈 action
    조건 충족시 데이터 전송 메소드을 실행





## func testTransData()

- Description

    searchButtonTapped()에서 조건 충족시 사용되는 임시 메소드로 예시및 참고자료용으로 만들어진 transit.json 파일의 정보를 API 호출로 불러온 대중교통데이터로 간주하고 실행되는 메소드로 transit.json파일의 내용을 실제 한 위치의 API 호출 데이터 이므로 실제 지정한 위치가 아닌 하드 코딩된 위치의 결과값을 보인다는 것을 뺴면 차이점이 없다. 도보이동 API의 경우 호출 제한 횟수가 상대적으로 널널하여 정상적으로 호출을 진행한다.
    dispatchGroup 으로 비동기 처리를 진행한다.
    정식서비스 전에 삭제 요망
    
- Example

    ```swift
    if delegate?.selectLocation != nil {
        testTransData()
    } else {
        setAlert(title: "목적지 없음!", message: "목적지를 설정해 주세요", actions: nil, on: self)
    }
    ```





## func decodeTransitData(from data: Data) -> TransitData?, func loadTestJsonDataFromFile() -> Data?

- Description

    testTransData()를 사용하기 위해 transit.json 파일의 정보를 가져오는 메소드. 나중에 정식서비스 전에 삭제 요망





## func search()

- Description

    미리 입력받은 출발지와 목적지 좌표를 가지고 API 호출을 대중교통과 도보 2개를 모두 받아온다. 지연상황에서의 오류 방지를 위한 showLoadingScreen()으로 로딩 애니메이션을 보이고 dispatchGroup stack을 2개 쌓아서 두 API 모두 결과값을 가져왔을 때에만 로딩 애니메이션을 감춘다.
    로딩 완료 이후 self.routesTableView.reloadData() 로 테이블뷰를 새로고침 한다.

- Example

    ```swift
    if delegate?.selectLocation != nil {
        search()
    } else {
        setAlert(title: "목적지 없음!", message: "목적지를 설정해 주세요", actions: nil, on: self)
    }
    ```





## func close()

- Description

    검색완료 이후 창이 닫히면서 실행되는 메소드
    onTransitDataUpdate?(selectedData ?? nil)로 대중교통 데이터를 
    onWalkDataUpdate?(walks ?? nil)로 도보이동 데이터를 메인 View 에 보내주는 역활을 하고
    SearchView를 종료한다.





## func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int

- Description

    tableView에 대중교통 index수 + 1 (index > 0) 테이블이 공백으로 하나만 생성되는것을 방지하기 위한 조건으로 만들기는 했는데 너무 가까운 거리여서 routes 데이터가 존재하지 않는경우에 오류가 발생할 수 있을거 같긴함





## func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell

- Description

    최상위 검색결과에는 도보경로 결과를 보이고 나머지 밑에는 대중교통 정보를 보이게 cell 설정





## func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)

- Description

    사용자가 table의 특정 index를 선택했을경우 close() 메소드를 실행함.






# ViewController 기능 정리

- Description

    **main View, 초기화면** 
    - var currentLocation: 현재 위치를 저장하기 위한 변수 선언. protocol ModalDelegate { get set }로 변수 공유
    - var selectLocation: 목적지를 저장하기 위한 변수 선언. protocol ModalDelegate { get set }로 변수 공유
    - var mapView: TMapView의 인스턴스를 저장할 변수를 선언. 사용자 위치 표시을 위한 MKMapView와 구별됨
    - var menu: SideMenu를 제작하기 위한 Dependency 변수 지정, 후에 삭제하거나 변경예정
    - let mkView: 사용자의 위치를 표시하기 위한 MKMapView
    - var modalTransitData: SearchView 페이지에서 가져온 대중교통 데이터를 저장할 변수 선언
    - var modalWalkData: SearchView 페이지에서 가져온 도보 데이터를 저장할 변수 선언
    - var modalLineData: SearchView 페이지에서 가져온 대중교통 데이터중에서 사용자가 선택한 데이터가 있을경우 저장할 변수 선언
    - var isNavigationActive: 후에 네비게이션 기능을 완성하여 활성화시 locationManager(didUpdateLocations)부분에서 조건적으로 실행될 메소드를 미리 제작해둠
    - var isInitialLocationSet: 첫 실행시 위치설정 여부를 추적하기 위한 변수 선언
    - var gpsStatus: { didSet { detectStatus() } } 으로 GPS 상태변화 확인용으로 제작하였으나 딱히 실용성을 없는 듯하여 후에 삭제예정
    - var markers: 지도상에 만들어질 여러개의 마커들을 관리하기 위한 배열 선언
    - var polylines: 지도상에 만들어질 여러개의 PolyLine들을 관리하기 위한 배열 선언



## func clearMarkers()

- Description

    지도상에 존재하는 마커들을 전부 지우고 markers의 정보도 모두 비운다.





## func clearPolylines()

- Description

    지도상의 존재하는 모든 PolyLine을 지우고 polylines의 정보도 모두 비운다.




## func SKTMapApikeySucceed(), SKTMapApikeyFailed(error: NSError?)

- Description

    Tmap appKey 인증여부 관련 메소드, 현재는 print문만 존재하기에 후에 변경 혹은 삭제 예정




## func startNavigation(), stopNavigation()

- Description

    `isNavigationActive: Bool` 의 값을 변경하기 위해 만든 메소드





## @objc func presentSideMenu(), dismissSideMenu()

- Description

    Package Dependency에 추가되어 있는 SideMenu의 표시 여부관련 메소드




## func initTableViewData()

- Description

    extension ViewController에 제작된 여러 메소드들을 Side메뉴에 추가하기 위한 메소드. 현재 SideMenu 기능의 존속여부가 불투명하기에 사라질 가능성 높음





## func pedestrianAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<PedestrianData, Error>) -> Void)

- Description

    도보이동 API를 불러오기 위한 메소드. 성공적으로 정보를 가져올 경우 json 데이터를 `PedestrianDataModel`파일에 정의되어 있는 PedestrianData 형식의 정보로 return 한다.
    protocol ModalDelegate 로 공유되고 있다.

- Parameters

    startPoint: CLLocationCoordinate2D 좌표로 이루어진 출발지 정보
    endPoint: CLLocationCoordinate2D 좌표로 이루어진 도착지 정보

- Example

    ```swift
    pedestrianAPICall(startPoint: `CLLocationCoordinate2D`, endPoint: `CLLocationCoordinate2D`) { result in
        switch result {
        case .success(let pedestrianData):
            print(pedestrianData)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    ```





## func transitAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<TransitData, Error>) -> Void)

- Description

    대중교통 API를 불러오기 위한 메소드. 성공적으로 정보를 가져올 경우 json 데이터를 `TransitDataModel`파일에 정의되어 있는 TransitData 형식의 정보로 return 한다.
    protocol ModalDelegate 로 공유되고 있다.

- Parameters

    startPoint: CLLocationCoordinate2D 좌표로 이루어진 출발지 정보
    endPoint: CLLocationCoordinate2D 좌표로 이루어진 도착지 정보

- Example

    ```swift
    transitAPICall(startPoint: `CLLocationCoordinate2D`, endPoint: CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318)) { result in
        switch result {
        case .success(let transitData):
            print(transitData)
        case .failure(let error):
            print(error.localizedDescription)
        }
    }
    ```






## func setMarker(position: CLLocationCoordinate2D)

- Description

    `func mapView(_ mapView: TMapView, doubleTapOnMap position: CLLocationCoordinate2D)` 에서 사용되고 있는 메소드
    해당 위치에 마커를 생성한다. 마커 생성시 리버스지오코딩 API 호출로 해당 위치의 정보를 바탕으로 마커 내부에 자료를 저장한다.
    `MarkerUIView` 파일의 `func createCalloutView()` 와 `func configure(with:, marker:)` 매소드를 사용한다.

- Parameters

    position: 마커가 생성될 위치의 CLLocationCoordinate2D 좌표정보





## func mapView(_ mapView: TMapView, singleTapOnMap location: CLLocationCoordinate2D)

- Description

    지도를 한번 클릭했을때 실행되는 콜백 메소드. 현재는 상위에 떠있는 SubView와 키보드를 감추는 용도로 사용.    



## func mapView(_ mapView: TMapView, longTapOnMap position: CLLocationCoordinate2D)

- Description

    지도를 길게 클릭했을때 실행되는 콜백 메소드. 현재는 콘솔에서 해당 위치의 좌표를 확인하기 위한 용도로 사용중.



## func mapView(_ mapView: TMapView, doubleTapOnMap position: CLLocationCoordinate2D)

- Description

    지도를 더블 클릭했을때 실행되는 콜백 메소드. 현재는 `func setMarker(position: CLLocationCoordinate2D)` 실행시키는 용도로 사용중




## func mapView(_ mapView: TMapView, tapOnMarker marker: TMapMarker)

- Description

    특정 마커를 선택했을떄 실행되는 콜백 메소드. 현재는 메커니즘상 마커를 클릭한 순간 마커의 위치가 `selectLocation`으로 처리되어 MarkerUI modal 페이지에서 목적지로 설정하는 방식으로 코드가 짜여져 있음
    마커를 클릭했을때 modal이 생성되는것은 `setMarker(position: CLLocationCoordinate2D)` 에서 이미 생성되어 있으므로 여기서는 `selectLocation` 값을 지정하는 용도로만 사용중





## func locationCheck(on viewController: UIViewController)

- Description

    `override func viewDidAppear(_ animated: Bool)` 에서 사용되고 있는 위치정보 업데이트 관련 설정 메소드





## @objc func requestRoute()

- Description

    도보이동 경로 불러오기. 미리 선언해둔 변수 `currentLocation`, `selectLocation`을 출발지와 목적지로 하고 `func pedestrianAPICall()` 로 불러온 경로 정보를 화면에 마커와 polyline으로 표시한다.
    현재는 따로 parameter 없이 미리 지정된 변수들로 메소드가 실행되고 있으나 후에 필요 시 출발지와 목적지의 Parameter 추가 예정도 있음.
    





## @objc func searchLocationModal()

- Description

    mainView에서 `SearchView` 의 modal을 생성하는 메소드. 생성시 이전 `SearchView`에서 전달받은 대중교통과 도보이동 데이터가 존재하는 경우 데이터를 전달하여 modal에 tableView를 생성하도록 한다. `SearchView`에서 `func close()`로 창이 닫히는 경우에 데이터를 전송받는다.





## func setupMapView()

- Description

    TmapView 객체 생성. appkey 인증을 이 메소드에서 처리한다.





## internal func mapViewDidFinishLoadingMap()

- Description

    사용자의 위치정보를 표시하기 위해서 만들어진 메소드. 가끔 오류로 사용자의 위치정보 표시(파란색 점)이 보이지 않는 버그가 발생함. 현재 방식이 그나마 버그발생률이 거의 없는 편이나 오류가 없는것은 아니니 해결방안이 생길경우 메소드는 얼마든지 변경될 수 있음
    mkView 가 사용됨.





## func setUpUI()

- Description

    버튼, 키보드알림 등록 관련 메소드. `override func viewDidLoad()` 에서 사용





## func setupSideMenu()

- Description

    `SideMenu` dependency 셋업 메서드. SideMenu사용 안하게 될 경우 없어질 예정





## func modalViewDidDisappear()

- Description

    `SearchView` 모달이 닫히면서 조건을 충족하면 작동하는 메소드. `modalLineData`(1~10개 사이의 대중교통 경로중 하나를 선택했을때) 데이터가 존재하면 그 데이터를 바탕으로 지도에 경로 정보를 표시하고 `modalLineData` 데이터가 비어있을 경우 `func requestRoute()` 를 호출하여 도보이동 데이터를 불러온다. 
    현재는 도보이동시 `func requestRoute()`로 API를 다시 불러와서 경로를 지도에 표시하지만 `SearchView` 모달이 닫힐때 도보경로에 대한 정보도 가져오기 때문에 그 자료를 가지고 지도에 경로를 표시하도록 수정도 가능하다.





## func takeData(_ transitData: [Route], _ walkData: PedestrianData?)

- Description

    `SearchView` 모달에서 경로 정보 데이터 (도보, 대중교통)를 받아와서 저장하는 메소드 `protocol ModalDelegate`로 `SearchView`에서 사용된다.

- Parameters

    transitData: 1~10개의 대중교통경로 리스트 데이터
    walkData: 도보이동경로 데이터





## func createPolylines(from route: Route) -> [TMapPolyline]

 - Description
 
    `TransitDataModel` 에서 정의한 Route 데이터셋을 polyline으로 지도상에 표시하기 위한 메소드.




## func detectStatus()

- Description

    var gpsStatus: { didSet { detectStatus() } } 에서 사용되는 메소드. 딱이 실용성이 없기에 삭제될 예정





## func checkAuthorization() 

- Description

    위치서비스 권한 요청관련 메소드





## func locationCheck(on viewController: UIViewController)

- Description

    `override func viewDidAppear(_ animated: Bool)` 에서 사용되는 메소드.
    `CLLocationManager()` 설정값 조정 가능





## func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])

- Description

    위치 정보가 업데이트 되었을 때 호출되는 델리게이트 콜백 메소드. `isNavigationActive` 조건으로 실행되는 메소드는 아직 미완성.





## func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)

- Description

    위치 접근이 실패했을 때 호출되는 콜백 메소드. 콘솔에 에러메시지 표시








# extension ViewController

- Description

    `ViewController`에서 추가적인 메소드 (TMapApi 에서 제공하는 예제 코드) 를 따로 정리하기 위해 만든 extension
    임시제작



## public func initMapView()

- Description

    맵 초기화 기능
    마커, polyline 삭제등등 간단한 화면적 오류를 제거할수 있도록 만들어둠



## public func basicFunc001()

- Description

    화면을 사용자 위치를 중심으로 이동하고 줌레벨을 고정한다.(줌레벨은 0레벨이 가장 축소된 레벨이며 19레벨이 가장 확대된 레벨이다.)





## public func objFunc53()

- Description

    `TMapPathData().requestFindAllPOI(_ keyword)`를 사용하기 위한 메소드.
    통합 POI(Point of Interest) 검색 `addressTextField`에 입력된 텍스트값을 기준으로  API 호출을 진행하지만, 현재는 입력할 `addressTextField`가 없어서 기본값인 "SK" 검색어를 기준으로 20개의 위치를 찾아 마커를 찍는다.
    통합검색 외에 requestFindTitlePOI, requestFindAddressPOI, requestFindNameAroundPOI 로 내부 메소드를 변경하여 다른 검색방식을 사용할수 있다.

- Parameters

    keyword: 검색할 키워드




## public func objFunc54()

- Description

    TMapPathData().requestFindAroundKeywordPOI(point, keyword, radius, count)를 사용하기 위한 메소드
    POI(Point of Interest) 검색 `addressTextField`에 입력된 텍스트값을 기준으로 API 호출을 진행하지만, 현재는 입력할 `addressTextField`가 없어서 기본값인 "SK" 검색어를 기준으로 근방(radius기준 안쪽에서) 20개의 위치를 찾아 마커를 찍는다.

- Parameters

    point: 검색할 좌표 
    keyword: 검색할 키워드
    radius: 검색 반경 지정(1 = 1KM)
    count: 검색 위치 최대 개수 설정





## public func objFunc56()

- Description

    `TMapPathData().reverseGeocoding(point, addressType)` 을 사용하기 위한 메소드

- Parameters

    point: 좌표값
    adressType: 주소타입
        - A00: 선택한 좌표계에 해당하는 행정동,법정동 주소 입니다.
        - A01: 선택한 좌표게에 해당하는 행정동 입니다.     예) 망원2동, 일산1동
        - A02: 선택한 좌표계에 해당하는 법정동 주소입니다.  예) 방화동, 목동
        - A03: 선택한 좌표계에 해당하는 새주소 길입니다.
        - A04: 선택한 좌표계에 해당하는 새주소 건물번호입니다.    예) 양천로 14길 95-11





## public func objFunc57()

- Description

    경로탐색 메소드 API 호출로 데이터를 불러오지 않고 TMapSDK 내부의 메소드로 도보경로를 불러옴.
    `TMapPathData().findMultiPathData(startPoint:, endPoint:, searchOption:)`을 사용

- Parameters

    startPoint: 출발지 설정 (CLLocationCoordinate2D)
    endPoint: 도착지 설정 (CLLocationCoordinate2D)





## public func objFunc60()

- Description

    출발지, 목적지, 경유지 좌표를 설정하여 탐색을 요청하는 `TMapPathData().findMultiPathData(startPoint:,  endPoint:, passPoints:, searchOption:, completion:)` 메소드를 사용하는데 이거는 차량 네비게이션 기능이라 실제로는 사용될 일이 없으므로 삭제해도 무방

- Parameters

    startPoint: 출발지 설정 (CLLocationCoordinate2D)
    endPoint: 도착지 설정 (CLLocationCoordinate2D)
    passPoint: 경유지에 대한 좌표(Array<CLLocationCoordinate2D>)
    searchOption: 경로 탐색 옵션
        - 00 : 교통최적+추천
        - 01 : 교통최적+무료우선
        - 02 : 교통최적+최소시간
        - 03 : 교통최적+초보
        - 04 : 교통최적+고속도로우선
        - 10 : 최단거리+유/무료





##  public func transit(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D?)

- Description

    `transitAPICall(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D, completion: @escaping (Result<TransitData, Error>)`를 사용한 대중교통 경로 표시 메소드

- Parameters

    startPoint: 출발지 설정 (CLLocationCoordinate2D)
    endPoint: 도착지 설정 (CLLocationCoordinate2D)





## func distanceFromPolyline() -> CLLocationDistance

- Description

    사용자가 경로 polyline에서 벗어나는것을 확인하기 위해 만들어진 메소드. 시각장애인용 네비이기 때문에 앱 자체적으로도 경로에 대한 조정및 보정기능이 필요할 거라 생각되어 만들어 두었지만 아직까지 구체적으로 사용되는 기능은 아님.
    `calculateDistanceFromPointToLineSegment`과 같이 사용





## private func calculateDistanceFromPointToLineSegment(point: CLLocationCoordinate2D, lineStart: CLLocationCoordinate2D, lineEnd: CLLocationCoordinate2D) -> CLLocationDistance

- Description

    라인과 점의 최소거리 구하는 메소드. 다만 이 네비에서 경로를 표시하는 방법이 여러 직선 직선을 여러번 사용하는 방식으로 경로를 표시하기 때문에 한 직선의 끝점과 직선의 시작점에서 이 메소드의 처리에 대한 개선이 필요해보임.
    
- Parameters 

    point: 점(CLLocationCoordinate2D), 여기에서는 사용자의 위치정보를 사용할 것으로 보임.
    lineStart: 선의 시작점(CLLocationCoordinate2D)
    lineEnd: 선이 끝점(CLLocationCoordinate2D)
