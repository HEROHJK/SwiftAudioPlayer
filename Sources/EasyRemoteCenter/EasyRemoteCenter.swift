import UIKit
import MediaPlayer
import SwiftAudioPlayer
import RxSwift

public class EasyRemoteCenter {
    public var skipSeconds: Int {
        get { _skipSeconds }
        
        set(value) {
            _skipSeconds = value
            setSkipInterval()
        }
    }
    
    private var _skipSeconds = 10
    private var playCommand: Any?
    private var pauseCommand: Any?
    private var skipFowardCommand: Any?
    private var skipBackwardCommand: Any?
    private var changePlaybackPositionCommand: Any?
    private var player: AudioPlayer?
    private var disposeBag = DisposeBag()
    
    public enum SetRemove {
        case setup
        case remove
    }
    
    public init(player: AudioPlayer) {
        self.player = player
        self.player?.observers.durationChange.subscribe(with: self, onNext: { owner, duration  in
            owner.updateDuration(duration)
        })
            .disposed(by: self.disposeBag)
        
        self.player?.observers.currentTimeUpdate.subscribe(with: self, onNext: { owner, time in
            owner.updateAudioTime(time)
        })
            .disposed(by: self.disposeBag)
        
        self.player?.observers.stateChange.subscribe(with: self, onNext: { owner, state in
            if state == .load {
                owner.setRemoteCommandCenter(.setup)
            } else if state == .unload {
                owner.setRemoteCommandCenter(.remove)
            }
        })
            .disposed(by: self.disposeBag)
    }
    
    private func setRemoteCommandCenter(_ setUp: SetRemove) {
        
        let rcc = MPRemoteCommandCenter.shared()
        if setUp == .setup {
            UIApplication.shared.beginReceivingRemoteControlEvents()
            rcc.playCommand.addTarget { _ in
                self.player?.play()
                return .success
            }
            rcc.pauseCommand.addTarget { _ in
                self.player?.pause()
                return .success
            }
            rcc.skipForwardCommand.addTarget { _ in
                guard let currentTime = self.player?.currentTime else { return .commandFailed }
                self.player?.setSeek(Double(currentTime + self.skipSeconds))
                return .success
            }
            rcc.skipBackwardCommand.addTarget { _ in
                guard let currentTime = self.player?.currentTime else { return .commandFailed }
                self.player?.setSeek(Double(currentTime - self.skipSeconds))
                return .success
            }
            rcc.changePlaybackPositionCommand.addTarget { event in
                guard let changeEvent = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
                
                self.player?.setSeek(Double(changeEvent.positionTime))
                
                return .success
            }
            setSkipInterval()
        } else {
            UIApplication.shared.endReceivingRemoteControlEvents()
        }
        
        rcc.playCommand.isEnabled = setUp == .setup ? true : false
        rcc.pauseCommand.isEnabled = setUp == .setup ? true : false
        rcc.skipForwardCommand.isEnabled = setUp == .setup ? true : false
        rcc.skipBackwardCommand.isEnabled = setUp == .setup ? true : false
        rcc.changePlaybackPositionCommand.isEnabled = setUp == .setup ? true : false
    }
    
    public func setMetaData(metaData: AudioPlayerData) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = metaData.title as AnyObject
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue as AnyObject
        nowPlayingInfo[MPMediaItemPropertyArtist] = metaData.artist as AnyObject
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = metaData.subTitle as AnyObject
        
        if let data = metaData.imageData, let image = UIImage(data: data) {
            let artwork: MPMediaItemArtwork
            if #available(iOS 10.0, *) {
                artwork = MPMediaItemArtwork(boundsSize: image.size) { _ -> UIImage in
                    image
                }
            } else {
                artwork = MPMediaItemArtwork(image: image)
            }
            
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateDuration(_ duration: Int) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration as AnyObject
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateAudioTime(_ time: Int) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time as AnyObject
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func setSkipInterval() {
        let rcc = MPRemoteCommandCenter.shared()
        
        rcc.skipForwardCommand.preferredIntervals = [NSNumber(value: skipSeconds)]
        rcc.skipBackwardCommand.preferredIntervals = [NSNumber(value: skipSeconds)]
    }
}
