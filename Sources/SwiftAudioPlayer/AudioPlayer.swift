import Foundation
import AVFoundation
import MediaPlayer
import HeLogger
import RxSwift

let timeScale: Int32 = 60_000

/// SwiftAudioPlayer
///
/// AVPlayer의 기본적인 스트리밍파일, 오디오파일을 지원
///
/// 0.5~2.0 까지의 배속 조절
///
/// 구간 이동 기능
public class AudioPlayer {
    /// 플레이어의 현재 상태
    public var state: PlayerState { _state }
    /// 플레이어의 현재 배속
    public var rate: Float { _rate }
    /// 플레이어에 현재 적재되어 있는 오디오의 길이
    public var duration: Int { _duration }
    /// 플레이어에서 지원하는 Observables
    public let observers = AudioPlayerObserver()
    /// 플레이어에 적재되어 있는 오디오의 현재 구간
    public var currentTime: Int {
        if self._state != .unload,
           let timeDouble = self.player?.currentItem?.currentTime().seconds {
            return Int(timeDouble)
        }
        return 0
    }
    /// 자동 재생 지연
    public var automaticallyWaitsToMinimizeStalling: Bool? {
        get {
            return player?.automaticallyWaitsToMinimizeStalling
        }
        set(value) {
            if let value = value {
                player?.automaticallyWaitsToMinimizeStalling = value
            }
        }
    }
    
    private var player: AVPlayer?
    private var playerTimeObserver: Any?
    private var _state: PlayerState = .unload
    private var _rate: Float = 1.0
    private var _duration: Int = 0
    private var setup = false
    private var interrupt = false
    
    /// 기본 생성자
    public init() {
        observers.stateChangeSubject.onNext(.unload)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func firstSetup() {
        if setup { return }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        try? audioSession.setActive(false)
        
        try? audioSession.setCategory(.playback, mode: .default)
        try? audioSession.setActive(true)
        
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(handleAudioSessionInterruption),
                name: AVAudioSession.interruptionNotification,
                object: audioSession
            )
        
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(routeChange),
                name: AVAudioSession.routeChangeNotification,
                object: audioSession
            )
    }
    
    @objc
    private func playFinished(note: NSNotification) {
        changeState(state: .finish)
    }
    
    private func changeState(state: PlayerState) {
        if self._state != state {
            self._state = state
            observers.stateChangeSubject.onNext(state)
        }
    }
}

// MARK: - Control
extension AudioPlayer {
    /// 오디오 재생
    /// 오디오가 로드되어 있을 때만 동작.
    public func play() {
        if _state != .unload, _state != .play {
            if _state == .finish { self.setSeek(0) } // 완료상태에서 플레이를 누르면, 처음부터 재생
            self.player?.playImmediately(atRate: self.rate)
            changeState(state: .play)
        }
    }
    
    /// 오디오 일시중지
    /// 재생중에만 동작
    public func pause() {
        if _state == .play {
            self.player?.pause()
            changeState(state: .pause)
        }
    }
    
    /// 오디오 중지
    /// 일시중지 + 시간 0으로 초기화
    public func stop() {
        if _state != .unload, _state != .stop {
            self.player?.pause()
            self.player?.seek(to: CMTimeMake(value: 0, timescale: timeScale))
            changeState(state: .stop)
        }
    }
    
    /// 오디오 초기화
    /// AVPleyer의 데이터들을 초기화.
    public func unload() {
        if _state != .unload {
            self.player?.replaceCurrentItem(with: nil)
            
            if let observer = self.playerTimeObserver {
                self.player?.removeTimeObserver(observer)
                self.playerTimeObserver = nil
            }
            
            NotificationCenter.default.removeObserver(self)
            
            changeState(state: .unload)
        }
    }
    
    /// 배속 설정
    /// - Parameter rate: 배속 값. (0.5 ~ 2.0 사이)
    public func setRate(rate: Float) {
        // 0.5 ~ 2.0 배속 범위에서만 동작.
        let rate: Float = rate < 0.5 ? 0.5 : rate > 2.0 ? 2.0 : rate
        
        if _state != .unload, self.rate != rate {
            self._rate = rate
            self.player?.rate = rate
            observers.rateChangeSubject.onNext(rate)
        }
    }
    
    /// 이동 설정
    /// 설정한 구간으로 이동
    /// - Parameter seekTime: 이동할 시간
    public func setSeek(_ seekTime: Double) {
        if _state != .unload {
            let seekTime: Double =
            seekTime < 0 ? 0 : seekTime > Double(duration) ? Double(duration - 1) : seekTime
            
            let cmtime = CMTimeValue(seekTime * Double(timeScale))
            self.player?.seek(to: CMTimeMake(value: cmtime, timescale: timeScale))
        }
    }
}

// MARK: - initial
extension AudioPlayer {
    /// 오디오 적재
    /// - Parameters:
    ///   - urlString: 오디오 경로 (스트리밍 url 주소 or 로컬 주소)
    ///   - seek: 0부터 시작하지 않을 때 설정
    ///   - duration: 전체 구간 강제 설정(미리듣기용)
    public func initItem(
        urlString: String,
        seek: Int = 0,
        duration: Int? = nil
    ) {
        unload()
        
        guard let url = makePlayerItemURL(urlString) else {
            changeState(state: .unload)
            return
        }
        
        let asset = AVAsset(url: url)
        
        self.player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        
        let cmTime = CMTimeMake(value: Int64(seek), timescale: timeScale)
        self.player?.seek(to: cmTime)
        
        if let duration = duration {
            self._duration = duration
            self.observers.durationChangeSubject.onNext(Int(duration))
        } else {
            self._duration = Int(Float(asset.duration.value) / Float(asset.duration.timescale))
            if self.duration < 1 {
                changeState(state: .unload)
                return
            }
            observers.durationChangeSubject.onNext(self.duration)
        }
        
        firstSetup()
        
        changeState(state: .load)
        
        self.playerTimeObserver = self.player?.addProgressObserver { [weak self] time in
            self?.observers.currentTimeUpdateSubject.onNext(Int(time))
        }
        
        NotificationCenter
            .default
            .addObserver(
                self,
                selector: #selector(playFinished),
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
    }
    
    private func makePlayerItemURL(_ urlString: String) -> URL? {
        let url: URL?
        if urlString.contains("file://") || Array(urlString)[0] == "/" {
            url = URL(fileURLWithPath: urlString)
        } else {
            url = URL(string: urlString)
        }
        
        guard let url = url else {
            hlog(
                l: .warn,
                t: .player,
                "플레이어 url 오류 - \(urlString)"
            )
            return nil
        }
        
        return url
    }
}

extension AudioPlayer {
    @objc
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard state == .play || self.interrupt else { return }
        
        guard let userInfo = notification.userInfo as? [String: AnyObject] else { return }
        
        guard let rawInterruptionType =
                userInfo[AVAudioSessionInterruptionTypeKey] as? NSNumber else { return }
        
        guard let interruptionType =
                AVAudioSession.InterruptionType(rawValue: rawInterruptionType.uintValue) else {
                    return
                }
        switch interruptionType {
        case .began: // interruption started
            pause()
            self.interrupt = true
        case .ended: // interruption ended
            if let rawInterruptionOption =
                userInfo[AVAudioSessionInterruptionOptionKey] as? NSNumber {
                let interruptionOption =
                AVAudioSession.InterruptionOptions(rawValue: rawInterruptionOption.uintValue)
                if interruptionOption == .shouldResume {
                    play()
                    self.interrupt = false
                }
            }
        default: break
        }
    }
    
    @objc
    private func routeChange(_ notification: Notification) {
        // 스피커 -> 블루투스 전환 시 재생 유지: O
        // 블루투스 -> 스피커 전환 시 재생 유지 : X
        // oldDeviceUnavailable <- 이전 오디오를 더이상 찾을 수 없을 때.
        let oldDeviceUnavailable = AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue
        if let userInfo = notification.userInfo,
           let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? Int,
           reason == oldDeviceUnavailable {
            self.pause()
        }
    }
}
