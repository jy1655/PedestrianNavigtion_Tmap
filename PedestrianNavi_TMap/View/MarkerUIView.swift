//
//  MarkerUIView.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/21/23.
//

import UIKit
import TMapSDK

class MarkerUIView: UIView {

    weak var delegate: ModalDelegate?
    var labelField = UILabel()
    var deleteButton = UIButton()
    var viewDownButton = UIButton()
    var navigationButton = UIButton()
    var associatedMarker: TMapMarker? // 연관된 마커에 대한 참조
    var markerLocation: CLLocationCoordinate2D?


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

        viewDownButton.frame = CGRect(x: 0, y: 0 , width: 15, height: 15) // 적절한 위치 및 크기 설정
        viewDownButton.setTitle("X", for: .normal) //  창 없에는 버튼을 임시?로 만듬 더 좋은방식으로 만들수 있다면 수정예저
        viewDownButton.backgroundColor = .black
        viewDownButton.addTarget(self, action: #selector(shutdownView), for: .touchUpInside)
        self.addSubview(viewDownButton)

        navigationButton.frame = CGRect(x: 120, y: 470, width: 100, height: 30) // 적절한 위치 및 크기 설정
        navigationButton.setTitle("목적지로 설정", for: .normal)
        navigationButton.backgroundColor = .black
        navigationButton.addTarget(self, action: #selector(searchLocationModal), for: .touchUpInside)
        self.addSubview(navigationButton)
    }

    func configure(with data: [String: Any], marker: TMapMarker) {
//         데이터를 사용하여 뷰의 내용을 업데이트합니다.

        labelField.text = data.description as String
        // 마커와 UIView를 연동시키기
        self.associatedMarker = marker
        self.markerLocation = marker.position
    }


    @objc func shutdownView() { // 창만 종료하기(마커유지)
        self.removeFromSuperview()
    }

    @objc func deleteMarkerAndView() { // 자폭시퀸스
        associatedMarker?.map = nil // 마커 제거
        self.removeFromSuperview() // 뷰 제거
    }

//    @objc func navigationStart() { // 마커좌표를 도착지점으로 하여
//
//        self.removeFromSuperview() // 뷰 제거
//        print(delegate?.currentLocation ?? "값이 없음")
//        print(markerLocation ?? "알수 없음")
//        delegate?.requestRoute()
//    }

    @objc func searchLocationModal() {
        self.removeFromSuperview() // 뷰 제거
        print((delegate?.selectLocation)!)
        delegate?.searchLocationModal() // 모달 열기
    }


}
