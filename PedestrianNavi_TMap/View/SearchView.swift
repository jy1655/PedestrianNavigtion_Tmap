//
//  SearchView.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/14/23.
//

import Foundation
import UIKit


class SearchView: UIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: ModalDelegate?
    let departureTextField = UITextField()
    let destinationTextField = UITextField()
    let searchButton = UIButton()
    let routesTableView = UITableView()
    var routes = [Route]() // Route 모델 배열
    var data: [Any] = []
    var selectedData: [Any] = []
    var onDataUpdate: (([Any]) -> Void)?
    var isDataUpdated = false

    let decoder = JSONDecoder()




    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        routesTableView.dataSource = self
        routesTableView.delegate = self
        routesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isDataUpdated {
            delegate?.modalViewDidDisappear() // 데이터가 변경되었을 경우에만 modalViewDidDisappear() 를 호출한다.
        }
    }

    func setupUI() {
        // 출발지 텍스트 필드 설정
        departureTextField.placeholder = "출발지 입력"
        departureTextField.borderStyle = .roundedRect

        // 목적지 텍스트 필드 설정
        destinationTextField.placeholder = "목적지 입력"
        destinationTextField.borderStyle = .roundedRect

        // 검색 버튼 설정
        searchButton.setTitle("검색", for: .normal)
        searchButton.backgroundColor = .blue
        searchButton.setTitleColor(.white, for: .normal)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)

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
        transdata()
        print(routes)
    }

    func transdata() {
        if let jsonData = loadJsonDataFromFile() {
            if let transitData = decodeTransitData(from: jsonData) {
                routes = transitData.metaData.plan.itineraries.map { Route(itinerary: $0) }
                data.append(routes)
                delegate?.takeData(data: data)
                DispatchQueue.main.async {
                    self.routesTableView.reloadData()
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print(routes.count)
        return routes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) // "RouteCell"을 "cell"로 수정
        let route = routes[indexPath.row]
        // 셀의 내용을 설정할 때 실제 경로 데이터를 반영
        cell.textLabel?.text = "약 \(route.itinerary.totalTime/60)분 소요, Transfers: \(route.itinerary.transferCount)회, 요금 \(route.itinerary.fare.regular.totalFare)원"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRoute = routes[indexPath.row]
//        selectedData = selectedRoute
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
        }

        // 선택된 경로를 지도에 표시
    }

    func close() {
        print(selectedData)
        onDataUpdate?(selectedData)
        updateData()
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
}


struct Route {
    // 'Plan' 구조체의 데이터를 저장할 속성들을 여기에 정의합니다.
    // 예시로, 'Itinerary' 객체들의 배열을 저장할 수 있습니다.
    var itinerary: Itinerary
}

struct TransitData: Codable {
    let metaData: MetaData
}

struct MetaData: Codable {
    let plan: Plan
    let requestParameters: RequestParameters?
}

struct Plan: Codable {
    let itineraries: [Itinerary]
}

struct Itinerary: Codable {
    let transferCount: Int
    let pathType: Int
    let totalWalkDistance: Int
    let legs: [Leg]
    let totalDistance: Int
    let totalWalkTime: Int
    let fare: Fare
    let totalTime: Int
}

struct Leg: Codable {
    let distance: Int
    let start: Location
    let end: Location
    let steps: [Step]?
    let passStopList: PassStopList?
    let routeId: String?
    let passShape: PassShape?
    let type: Int?
    let mode: String?
    let routeColor: String?
    let sectionTime: Int?
    let route: String?
    let service: Int?
}

struct Step: Codable {
    let linestring: String
    let description: String
    let streetName: String?
    let distance: Int?
}

struct Location: Codable {
    let name: String
    let lon: Double
    let lat: Double
}

struct Fare: Codable {
    let regular: RegularFare
}

struct RegularFare: Codable {
    let currency: Currency
    let totalFare: Int
}

struct Currency: Codable {
    let currency: String
    let currencyCode: String
    let symbol: String
}

struct RequestParameters: Codable {
    let startX, reqDttm, locale, endY,  endX, startY: String?
    let busCount, expressbusCount: Int?
    let trainCount, ferryCount, subwayCount, wideareaRouteCount, subwayBusCount, airplaneCount: Int?
}

struct PassStopList: Codable {
    let stationList: [StationList]
}

struct StationList: Codable {
    let stationName : String
    let stationID : String
    let lat : String
    let lon : String
    let index : Int
}

struct PassShape: Codable {
    let linestring: String
}
