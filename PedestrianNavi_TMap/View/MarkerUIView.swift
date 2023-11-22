//
//  MarkerUIView.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/21/23.
//

import UIKit
import TMapSDK

class MarkerUIView: UIView {
    var labelField = UILabel()
    var deleteButton = UIButton()
    var associatedMarker: TMapMarker? // 연관된 마커에 대한 참조

    func createCalloutView() {
        print("콜아웃 뷰 만들기")
        // 여기에서 커스텀 뷰를 생성하고 설정합니다.
        self.frame = CGRect(x: 20, y: 130, width: 300, height: 500)
        self.backgroundColor = .white

        // 예를 들어, 레이블 추가
        labelField = UILabel(frame: self.bounds)
        labelField.textColor = .black
        labelField.textAlignment = .center
        labelField.lineBreakMode = .byWordWrapping // 글자가 화면을 넘어가면 줄바꿈
        labelField.numberOfLines = 0 // 무제한
        self.addSubview(labelField)

        // 버튼 추가 및 구성
        deleteButton.frame = CGRect(x: 20, y: 470, width: 100, height: 30) // 적절한 위치 및 크기 설정
        deleteButton.setTitle("Delete", for: .normal)
        deleteButton.backgroundColor = .red
        deleteButton.addTarget(self, action: #selector(deleteMarkerAndView), for: .touchUpInside)
        self.addSubview(deleteButton)

    }

    func configure(with data: [String: Any], marker: TMapMarker) {
//         데이터를 사용하여 뷰의 내용을 업데이트합니다.
        let text = data.map { (key, value) -> String in
            return "\(key): \(value)"
        }.joined(separator: "\n") // 각 쌍을 줄바꿈 문자로 구분

        labelField.text = data.description as String
        // 마커와 UIView를 연동시키기
        self.associatedMarker = marker
    }

    @objc func deleteMarkerAndView() { // 자폭시퀸스
        associatedMarker?.map = nil // 마커 제거
        self.removeFromSuperview() // 뷰 제거
    }

}
