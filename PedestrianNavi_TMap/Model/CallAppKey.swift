//
//  CallAppKey.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/8/23.
//

import Foundation

struct CallAppKey {


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
