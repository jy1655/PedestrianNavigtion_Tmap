//
//  CallRestAPI.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/8/23.
//

import Foundation


struct CallRestAPI {

    let startX: String
    let startY: String
    let endX: String
    let endY: String
    let session = URLSession.shared
    let callAppKey = CallAppKey()

        // API 호출 메소드
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


