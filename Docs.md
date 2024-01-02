기본적인 TMapAPI 기능은 [TMapAPI](https://tmapapi.sktelecom.com/) 문서를 참고


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
    
- Example

    ```swift
    let transitpolyline = TMapPolyline(coordinates: transitcoordinates)
    transitpolyline.strokeColor = MakingUI.colorWithHexString(hexString: leg.routeColor ?? "000000") // routeColor에 맞게 경로 색 설정 지정색 없을시 검은색
    polylines.append(transitpolyline)
    ```



## static func createCoordinates(from linestring: String) -> [CLLocationCoordinate2D]

- Description

    `MakingUI` 파일에 있는 메소드로 API로 불러진 데이터셋에서 linestring 좌표들을 실제 CLLocationCoordinate2D 값으로 return 해주는 메소드

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



## func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int

- Description

    tableView에 대중교통 index수 + 1 (index > 0) 테이블이 공백으로 하나만 생성되는것을 방지하기 위한 조건으로 만들기는 했는데 너무 가까운 거리여서 routes 데이터가 존재하지 않는경우에 오류가 발생할 수 있을거 같긴함



## func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell

- Description

    최상위 검색결과에는 도보경로 결과를 보이고 나머지 밑에는 대중교통 정보를 보이게 cell 설정



## func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)

- Description

    사용자가 table의 특정 index를 선택했을경우 close() 메소드를 실행함.



## func close()

- Description

    검색완료 이후 창이 닫히면서 실행되는 메소드
    onTransitDataUpdate?(selectedData ?? nil)로 대중교통 데이터를 
    onWalkDataUpdate?(walks ?? nil)로 도보이동 데이터를 메인 View 에 보내주는 역활을 하고
    SearchView를 종료한다.




# ViewController 기능 정리

- Description

    main View, 초기화면 
    - var mapView: TMapView의 인스턴스를 저장할 변수를 선언. 사용자 위치 표시을 위한 MKMapView와 구별됨
    - var menu: SideMenu를 제작하기 위한 Dependency 변수 지정, 후에 삭제하거나 변경예정
    - let mkView: 사용자의 위치를 표시하기 위한 MKMapView
    - var modalTransitData: SearchView 페이지에서 가져온 대중교통 데이터를 저장할 변수 선언
    - var modalWalkData: SearchView 페이지에서 가져온 도보 데이터를 저장할 변수 선언
    - var modalLineData: SearchView 페이지에서 가져온 대중교통 데이터중에서 사용자가 선택한 데이터가 있을경우 저장할 변수 선언
    - var isInitialLocationSet: 첫 실행시 위치설정 여부를 추적하기 위한 변수 선언
