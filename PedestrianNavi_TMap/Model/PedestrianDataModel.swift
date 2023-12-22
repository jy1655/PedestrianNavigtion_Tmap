//
//  PedestrianDataModel.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/27/23.
//

import Foundation
import CoreLocation

/** 보행자 네비게이션 Json 데이터 형식 **/

struct Walk {
    let feature: Features
}

struct PedestrianData: Codable { // 제일 외곽부
    let type: String
    let features: [Features]
}

struct Features: Codable {
    let type: String
    let geometry: Geometry
    let properties: Properties?
}

struct Geometry: Codable {
    let type: String?
    var coordinates: [Coordinate]?

    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
    init(from decoder: Decoder) throws { // coordinates: [Coordinate] 가 [Double]와 [[Double]]두가지 경우의 수로 값이 나오기 때문에 디코딩 메소드 제작
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)

        var tempCoordinates = [Coordinate]()
        if var coordContainer = try? container.nestedUnkeyedContainer(forKey: .coordinates) {
            while !coordContainer.isAtEnd {
                if var coordinatePairContainer = try? coordContainer.nestedUnkeyedContainer() {
                    let lon = try coordinatePairContainer.decode(Double.self)
                    let lat = try coordinatePairContainer.decode(Double.self)
                    tempCoordinates.append(Coordinate(longitude: lon, latitude: lat))
                } else {
                    let lon = try coordContainer.decode(Double.self)
                    let lat = try coordContainer.decode(Double.self)
                    tempCoordinates.append(Coordinate(longitude: lon, latitude: lat))
                    break
                }
            }
        }
        coordinates = tempCoordinates.isEmpty ? nil : tempCoordinates
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(coordinates, forKey: .coordinates)
    }
}

struct Properties: Codable {
    let description: String
    let index: Int
    let nearPoiName: String?
    let intersectionName: String?
    let facilityName: String?
    let pointIndex: Int?
    let turnType: Int?
    let totalTime: Int?
    let pointType: String?
    let totalDistance: Int?
    let nearPoiX: String?
    let facilityType: String?
    let nearPoiY: String?
    let name: String?
    let direction: String?
    let categoryRoadType: Int?
    let distance: Int?
    let time: Int?
    let roadType: Int?
    let lineIndex: Int?
}

struct Coordinate: Codable {
    let longitude: Double
    let latitude: Double
}
