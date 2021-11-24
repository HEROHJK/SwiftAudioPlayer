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
    private var player: SwiftAudioPlayer?
    private var disposeBag = DisposeBag()
    
    public enum SetRemove {
        case setup
        case remove
    }
    
    public init(player: SwiftAudioPlayer) {
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
            playCommand = rcc.playCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                self.player?.play()
                return .success
            }
            pauseCommand = rcc.pauseCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                self.player?.pause()
                return .success
            }
            skipFowardCommand =
            rcc.skipForwardCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                guard let currentTime = self.player?.currentTime else { return .commandFailed }
                self.player?.setSeek(Double(currentTime + 10))
                return .success
            }
            skipBackwardCommand =
            rcc.skipBackwardCommand.addTarget { _ -> MPRemoteCommandHandlerStatus in
                guard let currentTime = self.player?.currentTime else { return .commandFailed }
                self.player?.setSeek(Double(currentTime - 10))
                return .success
            }
            changePlaybackPositionCommand =
            rcc.changePlaybackPositionCommand.addTarget { event -> MPRemoteCommandHandlerStatus in
                guard let changeEvent = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
                
                self.player?.setSeek(Double(changeEvent.positionTime))
                
                return .success
            }
            setSkipInterval()
        } else {
            rcc.playCommand.removeTarget(playCommand)
            rcc.pauseCommand.removeTarget(pauseCommand)
            rcc.skipForwardCommand.removeTarget(skipFowardCommand)
            rcc.skipBackwardCommand.removeTarget(skipBackwardCommand)
            rcc.changePlaybackPositionCommand.removeTarget(changePlaybackPositionCommand)
        }
        
        rcc.playCommand.isEnabled = setUp == .setup ? true : false
        rcc.pauseCommand.isEnabled = setUp == .setup ? true : false
        rcc.skipForwardCommand.isEnabled = setUp == .setup ? true : false
        rcc.skipBackwardCommand.isEnabled = setUp == .setup ? true : false
        rcc.changePlaybackPositionCommand.isEnabled = setUp == .setup ? true : false
    }
    
    public func setMetaData(metaData: AudioMetaData) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = metaData.title as AnyObject
        nowPlayingInfo[MPMediaItemPropertyMediaType] = MPMediaType.anyAudio.rawValue as AnyObject
        nowPlayingInfo[MPMediaItemPropertyArtist] = metaData.artist as AnyObject
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = metaData.subTitle as AnyObject
        
        if let image = UIImage(data: metaData.imageData) {
            let artwork: MPMediaItemArtwork
            if #available(iOS 10.0, *) {
                artwork = MPMediaItemArtwork(boundsSize: image.size) { _ -> UIImage in
                    return image
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
