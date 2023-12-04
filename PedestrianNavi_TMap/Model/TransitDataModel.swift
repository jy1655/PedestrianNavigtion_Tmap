//
//  TransitDataModel.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/15/23.
//

import Foundation

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
    let distance: Int // 거리
    let start: Location
    let end: Location
    let steps: [Step]? // 경로 정보롸 안내문
    let passStopList: PassStopList? //
    let routeId: String?
    let passShape: PassShape?
    let type: Int?
    let Lane: [Lane]?
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
    let startX: String?
    let reqDttm: String?
    let ferryCount: Int?
    let trainCount: Int?
    let locale: String
    let endY: String
    let subwayBusCount: Int?
    let endX: String?
    let airplaneCount: Int?
    let startY: String?
    let subwayCount: Int?
    let wideareaRouteCount: Int?
    let busCount: Int?
    let expressbusCount: Int?

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

struct Lane: Codable {
    let type: Int
    let routeColor: String
    let route: String
    let routeID: String?
    let service: Int
}
