import Foundation
import RxSwift

public class AudioPlayerSubject {
    public var stateChange = PublishSubject<PlayerState>()
    public var currentTimeUpdate = PublishSubject<(Int)>()
}
