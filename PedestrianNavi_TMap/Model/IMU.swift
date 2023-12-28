//
//  IMU.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/9/23.
//

import CoreMotion // IMU 데이터 확인

class IMUCheck {

    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()  // 별도의 OperationQueue 생성

    var lastStateIsMoving = false  // 마지막 가속도 상태를 저장하는 변수(임시)
    var lastGyroData: CMGyroData?
    var lastMagnetometerData: CMMagnetometerData?

    func startMotionUpdates() {
        // 가속도계 업데이트를 시작하려면
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1  // 초당 10번의 데이터를 받음
            motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] (accelerometerData, error) in
                guard let self = self, error == nil else {
                    print(error!)
                    return
                }
                if let data = accelerometerData {
                    // 여기에서 data.acceleration.x, data.acceleration.y, data.acceleration.z를 사용

                    // 가속도 데이터 사용
                    let accelerationX = data.acceleration.x
                    let accelerationY = data.acceleration.y
                    let accelerationZ = data.acceleration.z

                    // 단순한 움직임 감지를 위한 임계값 설정 - 실제 사용기준으로 적합한 값으로 변경필요
                    let movementThreshold: Double = 0.2
                    // X, Y, Z 축에 대한 가속도의 변화량을 계산
                    let totalAcceleration = sqrt(pow(accelerationX, 2) + pow(accelerationY, 2) + pow(accelerationZ, 2))
                    // 설정한 임계값보다 큰 경우, 움직임으로 간주

                    let isMoving = totalAcceleration > movementThreshold

                    if isMoving != self.lastStateIsMoving {
                        if isMoving {
                            print("움직임 감지")
                        } else {
                            print("정지 상태")
                        }
                        self.lastStateIsMoving = isMoving
                    }
                }
            }
        }

        // 자이로스코프 업데이트를 시작하려면
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: operationQueue) { [weak self] (gyroData, error) in
                guard let self = self, error == nil else {
                    print(error!)
                    return
                }
                if let data = gyroData {
                    // 여기에서 data.rotationRate.x, data.rotationRate.y, data.rotationRate.z를 사용
//                    print(data.rotationRate)
                    self.lastGyroData = data
                    self.detectDirectionChange()
                }
            }
        }

        // 자력계 업데이트를 시작하려면
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: operationQueue) { [weak self] (magnetometerData, error) in
                guard let self = self, error == nil else {
                    print(error!)
                    return
                }
                if let data = magnetometerData {
                    // 여기에서 data.magneticField.x, data.magneticField.y, data.magneticField.z를 사용
                    //                    print(data.magneticField)
                    self.lastMagnetometerData = data
                    self.detectDirectionChange()
                }
            }
        }
    }

    func detectDirectionChange() { // 방향전환을 감시하는 메소드 - 미완성
        guard let gyroData = lastGyroData, let magnetometerData = lastMagnetometerData else {
            return
        }

        // 각 센서 데이터에서 필요한 값을 추출합니다.
        let rotationRate = gyroData.rotationRate
        let magneticField = magnetometerData.magneticField

        // 여기에서 lastGyroData와 lastMagnetometerData를 사용하여 방향 변경 감지
        // 예: 현재 방향과 이전 방향을 비교하여 45도 이상 변경되었는지 확인
        // 이 부분에 방향 결정 로직 구현
        // 간단한 예로, x축 회전율이 특정 임계값을 넘는지 확인합니다.
        let rotationThreshold: Double = 0.5 // 임계값 설정

        if abs(rotationRate.x) > rotationThreshold {
            // x축을 중심으로 특정 임계값 이상 회전했을 때
            print("X축 회전 감지")
        }
    }

}
