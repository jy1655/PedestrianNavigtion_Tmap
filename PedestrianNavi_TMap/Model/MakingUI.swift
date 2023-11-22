//
//  MakingUI.swift
//  PedestrianNavi_TMap
//
//  Created by 황재영 on 11/16/23.
//

import UIKit
import CoreLocation

struct MakingUI {

    static func colorWithHexString(hexString: String) -> UIColor { // 16진수 색상 코드를 UIColor로 변환하는 함수
        var cString: String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.removeFirst()
        }

        if cString.count != 6 {
            return UIColor.gray // 기본 색상 반환, 혹은 에러 처리
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }


    static func createCoordinates(from linestring: String) -> [CLLocationCoordinate2D] {
        var coordinates = Array<CLLocationCoordinate2D>()

        let pairs = linestring.split(separator: " ")
        for pair in pairs {
            let values = pair.split(separator: ",").compactMap { Double($0) }
            if values.count == 2 {
                let coordinate = CLLocationCoordinate2D(latitude: values[1], longitude: values[0])
                coordinates.append(coordinate)
            }
        }
        print("좌표정보: \(coordinates)")
        return coordinates
    }

}

extension UIViewController {
    var bottomConstraint: NSLayoutConstraint! {
        get { return nil }
        set { /* do nothing */ }
    }

    /** 키보드 알림 관련 확장 메소드 **/
    typealias KeyboardUIUpdate = (_ keyboardHeight: CGFloat, _ isKeyboardShowing: Bool) -> Void

    func registerForKeyboardNotifications(updateUI: @escaping KeyboardUIUpdate) {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    let keyboardRectangle = keyboardFrame.cgRectValue
                    let keyboardHeight = keyboardRectangle.height
                    updateUI(keyboardHeight, true)
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { notification in
                updateUI(0, false)
            }
        }

    func unregisterForKeyboardNotifications() { // 뷰 컨트롤러가 해제될 때 unregisterForKeyboardNotifications()를 호출하여 알림을 제거
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    } // 일반적으로 deinit{unregisterForKeyboardNotifications()} 으로 사용

    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            updateBottomLayoutConstraint(with: -keyboardHeight - 20)
            // 여기에 키보드가 나타날 때 필요한 UI 업데이트를 추가합니다.(전역적으로)
            // 예를 들어, 특정 제약 조건을 업데이트할 수 있습니다.
            // 예: self.someConstraint.constant = -(keyboardHeight + 20)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        // 여기에 키보드가 사라질 때 필요한 UI 업데이트를 추가합니다.
        // 예를 들어, 특정 제약 조건을 원래대로 되돌릴 수 있습니다.
        // 예: self.someConstraint.constant = originalConstraintValue
        updateBottomLayoutConstraint(with: -20)
    }

    func updateBottomLayoutConstraint(with constant: CGFloat) {
        // 여기에 뷰의 하단 제약을 업데이트하는 로직을 구현합니다.
        // 예: self.routeButtonBottomConstraint?.constant = constant
        // 이 부분은 각 뷰 컨트롤러의 구현에 따라 달라질 수 있습니다.
        bottomConstraint.constant = constant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    } //키보드 관련 함수들을 UIViewController의 extension으로 추가

    func hideKeyboardWhenTappedAround() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    } // 키보드가 아닌 화면을 클릭하면 키보드가 내려가도록 하는 탭제스쳐 인식기 생성


    /** 버튼, 알림관련 메소드 **/
    func setButton(title: String, selector: Selector) -> UIButton { // 버튼 만들기
        // iOS 14 미만에서 사용하는 기존의 UIButton 초기화 방식
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside) // selector로 버튼 클릭시 구현될 메소드 작성

        button.addAction(UIAction { _ in self.touchDownAction(button) }, for: .touchDown) // 버튼을 눌렀을때
        button.addAction(UIAction { _ in self.touchUpAction(button) }, for: [.touchUpInside, .touchUpOutside]) // 버튼이 눌렸다가 올라갔을때
        // 손가락이 버튼 밖으로 이동한 후 떼지는 경우
        button.addAction(UIAction { _ in self.touchUpAction(button) }, for: .touchUpOutside)
        button.addAction(UIAction { _ in self.touchUpAction(button) }, for: .touchCancel)

        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 5
        button.clipsToBounds = true

        return button
    }

    func touchDownAction(_ sender: UIButton) {
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } // 크기를 95%로 줄이는 메서드
        } // 버튼이 눌렸을 때 호출되는 메서드

    func touchUpAction(_ sender: UIButton) {
            UIView.animate(withDuration: 0.2) {
                sender.transform = CGAffineTransform.identity
            } // 크기를 원래대로 되돌리는 메서드
        } // 버튼에서 손을 떼었을 때 호출되는 메서드

    func setAlert(title: String, message: String, actions: [UIAlertAction], on viewController: UIViewController) { // 알람기능 만들어두기
        print("버튼생성 : \(title)")
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertController.Style.alert
        )
        for action in actions {
            alert.addAction(action)
        }
        viewController.present(alert, animated: true)
    }

}



protocol KeyboardHandling {
    var bottomConstraint: NSLayoutConstraint! { get set }
    func updateBottomLayoutConstraint(height: CGFloat)
}
