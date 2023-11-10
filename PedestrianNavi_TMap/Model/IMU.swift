//
//  IMU.swift
//  TmapSDK_pod
//
//  Created by 황재영 on 11/9/23.
//

import CoreMotion // IMU 데이터 확인

struct IMUCheck {

    private let motionManager = CMMotionManager()

    func startMotionUpdates() {
        // 가속도계 업데이트를 시작하려면
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1  // 초당 10번의 데이터를 받음
            motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (accelerometerData, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                if let data = accelerometerData {
                    // 여기에서 data.acceleration.x, data.acceleration.y, data.acceleration.z를 사용
                    print(data.acceleration)
                }
            }
        }

        // 자이로스코프 업데이트를 시작하려면
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 1
            motionManager.startGyroUpdates(to: OperationQueue.current!) { (gyroData, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                if let data = gyroData {
                    // 여기에서 data.rotationRate.x, data.rotationRate.y, data.rotationRate.z를 사용
                    print(data.rotationRate)
                }
            }
        }

        // 자력계 업데이트를 시작하려면
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 1
            motionManager.startMagnetometerUpdates(to: OperationQueue.current!) { (magnetometerData, error) in
                guard error == nil else {
                    print(error!)
                    return
                }
                if let data = magnetometerData {
                    // 여기에서 data.magneticField.x, data.magneticField.y, data.magneticField.z를 사용
                    print(data.magneticField)
                }
            }
        }
    }
}
