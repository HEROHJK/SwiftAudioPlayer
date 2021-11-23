import Foundation
import RxSwift

class AudioPlayerSubject {
    var stateChange = PublishSubject<PlayerState>()
    var progressUpdate = PublishSubject<(Int, Int)>()
}
