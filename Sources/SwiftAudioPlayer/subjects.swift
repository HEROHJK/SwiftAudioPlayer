import Foundation
import RxSwift

class AudioPlayerSubject {
    var stateChange = PublishSubject<PlayerState>()
    var currentTimeUpdate = PublishSubject<(Int)>()
}
