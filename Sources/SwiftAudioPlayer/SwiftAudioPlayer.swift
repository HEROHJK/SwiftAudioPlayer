import Foundation
import AVFoundation
import MediaPlayer
import HeLogger

let timeScale: Int32 = 60_000

public class SwiftAudioPlayer {
    var player: AVPlayer?
    var state: PlayerState = .unload
    var rate: Float = 1.0
    var duration: Int = 0
    var subjects = AudioPlayerSubject()
    var playerTimeObserver: Any?
    
    func initItem(isLocal: Bool, urlString: String, metaData: AudioMetaData? = nil, seek: Int = 0, duration: Int? = nil) {
        unload()
        
        guard let item = makeAVPlayerItem(isLocal, urlString) else {
            changeState(state: .unload)
            return
        }
        
        self.player = AVPlayer(playerItem: item)
        guard self.player?.status == .readyToPlay else {
            hlog(l: .warn, t: .player, "플레이어 아이템 적재 오류 - \(urlString)")
            changeState(state: .unload)
            return
        }
        
        let cmTime = CMTimeMake(value: Int64(seek), timescale: timeScale)
        self.player?.seek(to: cmTime)
        
        if let duration = duration {
            self.duration = duration
        } else {
            self.duration = Int(item.duration.seconds)
        }
        
        changeState(state: .load)
        
        self.playerTimeObserver = self.player?.addProgressObserver { time in
            self.subjects.progressUpdate.onNext((Int(time), 0))
        }
    }
    
    func play() {
        if state == .load || state == .pause || state == .stop {
            self.player?.play()
            changeState(state: .play)
        }
    }
    
    func pause() {
        if state == .play {
            self.player?.pause()
            changeState(state: .pause)
        }
    }
    
    func stop() {
        if state == .load || state == .pause || state == .stop {
            self.player?.pause()
            self.player?.seek(to: CMTimeMake(value: 0, timescale: timeScale))
            changeState(state: .stop)
        }
    }
    
    func unload() {
        if state != .unload {
            self.player?.replaceCurrentItem(with: nil)
            
            if let observer = self.playerTimeObserver {
                self.player?.removeTimeObserver(observer)
                self.playerTimeObserver = nil
            }
            
            changeState(state: .unload)
        }
    }
    
    func setRate(rate: Float) {
        if state != .unload {
            self.player?.rate = rate
        }
    }
    
    private func makeAVPlayerItem(_ isLocal: Bool, _ urlString: String) -> AVPlayerItem? {
        guard let url = isLocal ? URL(fileURLWithPath: urlString) : URL(string: urlString) else {
            hlog(
                l: .warn,
                t: .player,
                "플레이어 url 오류 - \(urlString)(\(isLocal ? "local" : "streaming"))"
            )
            return nil
        }
        let item = AVPlayerItem(asset: AVAsset(url: url))
        
        return item
    }
    
    func changeState(state: PlayerState) {
        if self.state != state {
            self.state = state
            subjects.stateChange.onNext(state)
        }
    }
}
