import Foundation
import AVFoundation
import MediaPlayer
import HeLogger

let timeScale: Int32 = 60_000

public class SwiftAudioPlayer {
    public var player: AVPlayer?
    public var state: PlayerState = .unload
    public var rate: Float = 1.0
    public var duration: Int = 0
    public var subjects = AudioPlayerSubject()
    public var playerTimeObserver: Any?
    public var currentTime: Int {
        if self.state != .unload,
           let timeDouble = self.player?.currentItem?.currentTime().seconds {
            return Int(timeDouble)
        }
        return 0
    }
    
    public init() { }
    
    public func initItem(isLocal: Bool, urlString: String, metaData: AudioMetaData? = nil, seek: Int = 0, duration: Int? = nil) {
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
            self.subjects.currentTimeUpdate.onNext((Int(time)))
        }
        
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(playFinished(note:)),
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
    }
    
    public func play() {
        if state != .unload, state != .play {
            self.player?.play()
            changeState(state: .play)
        }
    }
    
    public func pause() {
        if state == .play {
            self.player?.pause()
            changeState(state: .pause)
        }
    }
    
    public func stop() {
        if state != .unload, state != .stop {
            self.player?.pause()
            self.player?.seek(to: CMTimeMake(value: 0, timescale: timeScale))
            changeState(state: .stop)
        }
    }
    
    public func unload() {
        if state != .unload {
            self.player?.replaceCurrentItem(with: nil)
            
            if let observer = self.playerTimeObserver {
                self.player?.removeTimeObserver(observer)
                self.playerTimeObserver = nil
            }
            
            NotificationCenter.default.removeObserver(self)
            
            changeState(state: .unload)
        }
    }
    
    @objc
    private func playFinished(note: NSNotification) {
        changeState(state: .finish)
    }
    
    public func setRate(rate: Float) {
        if state != .unload {
            self.player?.rate = rate
        }
    }
    
    public func setSeek(_ seekTime: Double) {
        self.player?.seek(to: CMTimeMake(value: CMTimeValue(seekTime), timescale: timeScale))
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
    
    private func changeState(state: PlayerState) {
        if self.state != state {
            self.state = state
            subjects.stateChange.onNext(state)
        }
    }
}
