//
//  CallRestAPI.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/8/23.
//

import Foundation


struct CallRestAPI { // 보행자 네비게이션과 대중교통 네비게이션

    let startX: String
    let startY: String
    let endX: String
    let endY: String
    let session = URLSession.shared
//    let timemachine: String
    let callAppKey = CallAppKey()

        // 보행자 API 호출 메소드
    func fetchRoute(completion: @escaping (Result<Data, Error>) -> Void) {
        let urlString = "https://apis.openapi.sk.com/tmap/routes/pedestrian?version=1&format=json&callback=result" // 보행자 경로요청 API URL

        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 인증이 필요한 경우 헤더에 추가
        request.addValue(callAppKey.appKey()!, forHTTPHeaderField: "appKey")

        // 데이터 작업 요청
        let parameters: [String: String] = [
            "startX": startX,
            "startY": startY,
            "endX": endX,
            "endY": endY,
            "reqCoordType": "WGS84GEO",
            "resCoordType": "WGS84GEO",
            "startName": "출발지",
            "endName": "도착지",
            "searchOption": "0",
        ]

        request.httpBody = parameters.percentEncoded()

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            completion(.success(data))
        }

        task.resume()
    }


    // 대중교통 API
    func transitRoute(completion: @escaping (Result<Data, Error>) -> Void) {
        let urlStringT = "https://apis.openapi.sk.com/transit/routes" // 대중교통 경로요청 API URL

        guard let url = URL(string: urlStringT) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 인증이 필요한 경우 헤더에 추가
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(callAppKey.appKey()!, forHTTPHeaderField: "appKey")


        // 데이터 작업 요청
        let parametersT: [String: String] = [
            "startX": startX,
            "startY": startY,
            "endX": endX,
            "endY": endY,
            "format": "json",
            "count": "10"
//            "searcgDttm": timemachine,
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parametersT, options: []) else {
                completion(.failure(NSError(domain: "InvalidParameters", code: 0, userInfo: nil)))
                return
            }

//        request.httpBody = parametersT.percentEncoded()
        request.httpBody = httpBody

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

    func transitSubRoute(completion: @escaping (Result<Data, Error>) -> Void) { // transit중에서 간략한 정보만 보내주는 API
        let urlStringTS = "https://apis.openapi.sk.com/transit/routes/sub" // 대중교통 경로요청 API URL

        guard let url = URL(string: urlStringTS) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // 인증이 필요한 경우 헤더에 추가
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(callAppKey.appKey()!, forHTTPHeaderField: "appKey")



        // 데이터 작업 요청
        let parametersT: [String: String] = [
            "startX": startX,
            "startY": startY,
            "endX": endX,
            "endY": endY,
            "format": "json",
            "count": "1",
//            "searchDttm": timemachine,
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parametersT, options: []) else {
                completion(.failure(NSError(domain: "InvalidParameters", code: 0, userInfo: nil)))
                return
            }

//        request.httpBody = parametersT.percentEncoded()
        request.httpBody = httpBody

        let session = URLSession.shared
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }
            completion(.success(data))
        }
        task.resume()
    }

}

extension Dictionary {
    func percentEncoded() -> Data? {
        return self.map { key, value in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return escapedKey + "=" + escapedValue
        }
        .joined(separator: "&")
        .data(using: .utf8)
    }
}
//
//// 사용 예
//let routeRequest = CallRestAPI(
//    startX: "126.983937",
//    startY: "37.564991",
//    endX: "126.988940",
//    endY: "37.566158"
//)
//
//routeRequest.fetchRoute { result in
//    switch result {
//    case .success(let data):
//        // 성공적으로 데이터를 받았을 때 처리
//        if let dataString = String(data: data, encoding: .utf8) {
//            print(dataString)
//        }
//    case .failure(let error):
//        // 오류가 발생했을 때 처리
//        print(error.localizedDescription)
//    }
//}

//routeRequest.fetchRoute { result in
//    switch result {
//    case .success(let data):
//        // 성공적으로 데이터를 받았을 때 처리
//        do {
//            // JSON 데이터를 딕셔너리로 변환
//            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//                // JSON 데이터를 이쁘게 출력하기 위해 JSONSerialization을 사용
//                let prettyJsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
//                // 이쁘게 만든 JSON 데이터를 문자열로 변환
//                if let prettyPrintedString = String(data: prettyJsonData, encoding: .utf8) {
//                    // 이쁘게 만든 문자열을 콘솔에 출력
//                    print(prettyPrintedString)
//                }
//            }
//        } catch {
//            print("JSON 파싱 에러: \(error)")
//        }
//    case .failure(let error):
//        // 오류가 발생했을 때 처리
//        print(error.localizedDescription)
//    }
//}



