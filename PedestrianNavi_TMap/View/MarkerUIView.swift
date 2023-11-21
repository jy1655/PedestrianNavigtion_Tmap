//
//  MarkerUIView.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/21/23.
//

import Foundation
import UIKit

class MarkerUIView: UIView {
    var labelField = UILabel()

    func createCalloutView() {
        print("콜아웃 뷰 만들기")
        // 여기에서 커스텀 뷰를 생성하고 설정합니다.

        // 예를 들어, 레이블 추가
        labelField = UILabel(frame: self.bounds)
        labelField.textAlignment = .center
        self.addSubview(labelField)

    }

    func configure(with data: [String: Any]) {
        // 데이터를 사용하여 뷰를 업데이트합니다.
        labelField.text = data["fullAddress"] as? String
    }

    func configureView() {
        self.frame = CGRect(x: 100, y: 300, width: 500, height: 500)
        self.backgroundColor = .white
        self.labelField.textColor = .black
//        self.bounds.width = 100
//        self.bounds.height = 300
    }
}
