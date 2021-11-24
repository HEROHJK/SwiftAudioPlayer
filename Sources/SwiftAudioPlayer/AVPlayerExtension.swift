import Foundation
import AVFoundation

extension AVPlayer {
    func addProgressObserver(action:@escaping ((Double) -> Void)) -> Any {
        let interval = CMTime(seconds:1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        return self.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { time in
            action(CMTimeGetSeconds(time))
        })
    }
}
