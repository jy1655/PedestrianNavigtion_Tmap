//
//  SearchView.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/14/23.
//

import Foundation
import UIKit
import CoreLocation


class SearchView: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: ModalDelegate?
    let departureTextField = UITextField()
    let destinationTextField = UITextField()
    var searchButton = UIButton()
    let routesTableView = UITableView()
    var routes = [Route]() // Route 모델 배열
    var walks: PedestrianData? = nil // PedestrianData 모델 배열
    var selectedData: Route? = nil // 유저가 선택한 길찾기 정보 전달용
    var onDataUpdate: ((Route?) -> Void)?
    var isDataUpdated = false // 모달 페이지가 닫혔을떄 경로정보를 표시할지 여부 판단용
    var routeButtonBottomConstraint: NSLayoutConstraint?

    let decoder = JSONDecoder()




    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        routesTableView.dataSource = self
        routesTableView.delegate = self
        routesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "walkCell")
        routesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        registerForKeyboardNotifications { [weak self] (keyboardHeight, isKeyboardShowing) in
            self?.routesTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0) // 테이블 뷰가 키보드 높이 만큼 하단이 올라와서 하단 선택지를 선택할 수 있도록 함
            UIView.animate(withDuration: 0.3) {
                self?.view.layoutIfNeeded()
            }
        } // 키보드 알림 설정
        hideKeyboardWhenTappedAround() // 키보드 내려가는 탭제스쳐 인식기
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isDataUpdated {
            delegate?.modalViewDidDisappear() // 데이터가 변경되었을 경우에만 modalViewDidDisappear() 를 호출한다.
        }
    }

    func setupUI() {
        // 출발지 텍스트 필드 설정
        departureTextField.placeholder = "출발지 입력(현재 위치: \(String(describing: (delegate?.currentLocation)!))" // 나중에 리버스 지오코딩으로 지명 가져오는 걸로 변경하기
        departureTextField.borderStyle = .roundedRect

        // 목적지 텍스트 필드 설정
        destinationTextField.placeholder = "목적지" //\(String(describing:(delegate?.selectLocation)!))" // 나중에 리버스 지오코딩으로 지명 가져오는 걸로 변경하기
        destinationTextField.borderStyle = .roundedRect

        // 검색 버튼 설정
        searchButton = setButton(title: "검색", selector: #selector(searchButtonTapped))

        // 테이블 뷰 설정
        routesTableView.tableFooterView = UIView() // 빈 셀 제거

        // 뷰에 추가
        view.addSubview(departureTextField)
        view.addSubview(destinationTextField)
        view.addSubview(searchButton)
        view.addSubview(routesTableView)
    }

    func setupConstraints() {
        // Auto Layout 설정
        departureTextField.translatesAutoresizingMaskIntoConstraints = false
        destinationTextField.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        routesTableView.translatesAutoresizingMaskIntoConstraints = false

        // NSLayoutConstraint를 사용하여 오토 레이아웃 설정
        NSLayoutConstraint.activate([
            departureTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            departureTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            departureTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            destinationTextField.topAnchor.constraint(equalTo: departureTextField.bottomAnchor, constant: 10),
            destinationTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            destinationTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            searchButton.topAnchor.constraint(equalTo: destinationTextField.bottomAnchor, constant: 10),
            searchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            routesTableView.topAnchor.constraint(equalTo: searchButton.bottomAnchor, constant: 20),
            routesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            routesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            routesTableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @objc func searchButtonTapped() {
        transData() // 데이터 전송 (modalData), 테이블 뷰 보이기
//        search()
        print("전송된 데이터: \(routes)")
    }

    func transData() { // json 데이터 디코딩 + 데이터 저장및 부모뷰에도 데이터 전송
        let startPoint = delegate?.currentLocation
        let endPoint = delegate?.selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318) // 임시 작성
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        if let jsonData = loadJsonDataFromFile() {
            if let transitData = decodeTransitData(from: jsonData) {
                routes = transitData.metaData.plan.itineraries.map { Route(itinerary: $0) }
                delegate?.takeData(data: routes) // ViewController의 modalData에 정보 저장
            }
        }

        delegate?.pedestrianAPICall(startPoint: startPoint!, endPoint: endPoint) { result in
            switch result {
            case .success(let walkData):
                // 성공적으로 데이터를 받았을 때의 처리
                print(walkData)
                self.walks = walkData
//                self.delegate?.takeData(data: self.walks) // ViewController의 modalData에 정보 저장
            case .failure(let error):
                // 오류가 발생했을 때의 처리
                print(error.localizedDescription)
            }
        }
        dispatchGroup.leave()

        dispatchGroup.notify(queue: .main) {
            self.routesTableView.reloadData() // 모든작업 완료 후 실행될 코드
        }
    }

    func search() {
        let startPoint = delegate?.currentLocation
        let endPoint = delegate?.selectLocation ?? CLLocationCoordinate2D(latitude: 37.403049, longitude: 127.103318) // 임시 작성
        let dispatchGroup = DispatchGroup()

        dispatchGroup.enter()
        delegate?.transitAPICall(startPoint: startPoint!, endPoint: endPoint) { result in
            switch result {
            case .success(let transitData):
                // 성공적으로 데이터를 받았을 때의 처리
                print(transitData)
                self.routes = transitData.metaData.plan.itineraries.map { Route(itinerary: $0) }
                self.delegate?.takeData(data: self.routes) // ViewController의 modalData에 정보 저장
//                dispatchGroup.leave()
//                DispatchQueue.main.async {
//                    self.routesTableView.reloadData()
//                }
            case .failure(let error):
                // 오류가 발생했을 때의 처리
                print(error.localizedDescription)
//                dispatchGroup.leave()
            }
        } // API 호출

//        dispatchGroup.enter()
        delegate?.pedestrianAPICall(startPoint: startPoint!, endPoint: endPoint) { result in
            switch result {
            case .success(let walkData):
                // 성공적으로 데이터를 받았을 때의 처리
                print(walkData)
                self.walks = walkData
//                self.delegate?.takeData(data: self.walks) // ViewController의 modalData에 정보 저장
//                dispatchGroup.leave()
            case .failure(let error):
                // 오류가 발생했을 때의 처리
                print(error.localizedDescription)
//                dispatchGroup.leave()
            }
        }
        dispatchGroup.leave()

        dispatchGroup.notify(queue: .main) {
            self.routesTableView.reloadData() // 모든작업 완료 후 실행될 코드
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(routes.count)
        if routes.count == 0 { // routes 데이터가 없으면 테이블 생성 안함
            return 0
        } else {
            return routes.count + 1 // 도보이동을 추가하기 위해서 숫자를 1 증가 시킴
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "walkCell", for: indexPath) //
            if walks != nil {
                let walk = walks
                // 셀에 walk 데이터를 설정
                cell.textLabel?.text = "도보이동 약 \(walk!.features!.first!.properties!.totalTime!/60)분 소요, 총 거리: \(walk!.features!.first!.properties!.totalDistance!)M"
                return cell
            } else {
                return UITableViewCell()
            }
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) // "RouteCell"을 "cell"로 수정
            let route = routes[indexPath.row - 1]
            // 셀의 내용을 설정할 때 실제 경로 데이터를 반영
            cell.textLabel?.text = "약 \(route.itinerary.totalTime/60)분 소요, Transfers: \(route.itinerary.transferCount)회, 요금 \(route.itinerary.fare.regular.totalFare))원"
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < 1 {
            _ = walks
            print("걷기")
            close()
        } else {
            let selectedRoute = routes[indexPath.row - 1]
            selectedData = selectedRoute // 자료형의 변경
            for leg in selectedRoute.itinerary.legs {
                if let steps = leg.steps {
                    for step in steps {
                        let linestring = step.linestring
                        let description = step.description
                        print(linestring)
                        print(description)
                    }
                }
                if let pass = leg.passStopList {
                    let passShape = leg.passShape?.linestring
                    let passName = leg.route
                    print(passShape ?? "")
                    print(passName ?? "")
                    let stationLists = pass.stationList
                    for stationList in stationLists {
                        let stationName = stationList.stationName
                        print(stationName)
                    }
                }
                close() // 선택시 모달창 닫기
            }// 선택된 경로를 지도에 표시
        }
    }

    func close() {
        print("보내질 예정 선택된 경로 데이터: \(String(describing: selectedData))")
        onDataUpdate?(selectedData ?? nil)
        updateData() // isDataUpdated = true 로 변경
        dismiss(animated: true)
    }

    func updateData() {
        isDataUpdated = true
    }

    func loadJsonDataFromFile() -> Data? {
        guard let url = Bundle.main.url(forResource: "transit", withExtension: "json") else {
            print("transit.json file not found")
            return nil
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            print("Error reading transit.json file: \(error)")
            return nil
        }
    }
    // JSON 데이터를 TransitData 타입으로 디코딩하는 함수
    func decodeTransitData(from data: Data) -> TransitData? {
        let decoder = JSONDecoder()
        do {
            let transitData = try decoder.decode(TransitData.self, from: data)
            return transitData
        } catch {
            print("Error decoding transit.json: \(error)")
            return nil
        }
    }

    deinit {
        unregisterForKeyboardNotifications() //키보드 알림 해제
    }
}


