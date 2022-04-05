import Foundation
import RxSwift

/// 오디오 플레이어용 옵저버들
///
/// 외부에서 발송(onNext)을 방지하고, 순수한 읽기전용 구독만을 지원하기 위해,
/// 내부에서는 subject를 외부에서는 observable을 이용함.
public class AudioPlayerObserver {
    /// 상태변화를 전달해주는 PublishSubject
    internal var stateChangeSubject = PublishSubject<PlayerState>()
    /// 현재 재생 시각을 전달해주는 PublishSubject
    internal var currentTimeUpdateSubject = PublishSubject<Int>()
    /// 오디오 길이를 전달해주는 BehaviorSubject
    /// 오디오값이 없다면, 0으로 초기화를 하기 위해 0으로 설정함.
    internal var durationChangeSubject = BehaviorSubject<Int>(value: 0)
    /// 배속을 전달해주는 BehaviorSubject
    /// 배속은 기본값이 0이므로 0으로 설정.
    internal var rateChangeSubject = BehaviorSubject<Float>(value: 1.0)
    
    /// 외부에 상태변화를 전달해주는 Observable
    public var stateChange: Observable<PlayerState> {
        stateChangeSubject
            .asObservable()
            .distinctUntilChanged()
            .delay(.milliseconds(10), scheduler: MainScheduler.instance)
    }
    
    /// 외부에 Progress용으로 현재 재생 시각을 전달해주는 Observable
    public var currentTimeUpdate: Observable<Int> {
        currentTimeUpdateSubject
            .asObservable()
            .distinctUntilChanged()
    }
    
    /// 외부에 오디오 길이를 전달해주는 Observable
    /// 스트리밍 파일의 경우, 적재한 직후에 길이를 알수가 없기 때문에 이용
    public var durationChange: Observable<Int> { durationChangeSubject.asObservable() }
    
    /// 외부에 배속이 바뀌었을 때, 바뀐 배속을 전달해주는 Observable
    public var rateChange: Observable<Float> { rateChangeSubject.asObservable() }
}
