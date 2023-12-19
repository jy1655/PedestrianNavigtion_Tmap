//
//  CallAppKey.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/8/23.
//

import Foundation

struct CallAppKey { // Config.plist 파일에 저장된 API 키값을 불러오는 메소드(외부유출X) 정식서비스 전 임시로 만들어둔 파일이고 정식 서비스시에는 더 안전한 방식으로 진행하는것을 권장함(소스코드 내부에 API 키값이 존재하는 문제점)


    func appKey() -> String? {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            return nil
        }
        return dict["appKey"] as? String
    }

//    func getValue(forKey key: String) -> String? {
//        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
//              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
//            return nil
//        }
//        return dict[key] as? String
//    } // appKey 값을 불러오기 위한 메소드

}
