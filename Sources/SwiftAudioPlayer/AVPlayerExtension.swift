// swiftlint:disable:this file_name

import Foundation
import AVFoundation

extension AVPlayer {
    /// 단순하게 현재 시간을 항상 기록하기 위한 함수
    /// - Parameter action: 시간을 전달할 클로저
    /// - Returns: 옵저버를 보관하기 위한 반환 객체
    func addProgressObserver(action:@escaping ((Double) -> Void)) -> Any {
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        return self.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { time in
            action(CMTimeGetSeconds(time))
        })
    }
}
