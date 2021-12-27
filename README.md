# SwiftAudioPlayer

## English


Simple streaming/local audio player.
The following features are supported.

* Simple Audio Control
* Simple MPRemoteCommandCenter control (EasyRemoteCenter)
* Rate setting (0.5 ~ 2.0)
* Seeking
* State control observer with RxSwift
    * `stateChange` -> control the player state
        * `unload`, `load`, `play`, `pause`, `stop`, `finish`
    * `currentTimeUpdate` -> Check the current section (for Progress)
    * `durationChange` -> Duration Check
    * `rateChange` -> Notification of Rate change
* Playlist under development..

### Installation:
* Added using Swift Package Manager.
* `https://github.com/herohjk/swiftaudioplayer`
* The library [RxSwift (6.2.0)](https://github.com/ReactiveX/RxSwift) and [HeLogger](https://github.com/herohjk/HeLogger) libraries are set as dependency packages.

### Usage:

```Swift
import SwiftAudioPlayer

let player = SwiftAudioPlayer()

player.observers.stateChange
    .subscribe(
        with: self,
        onNext: { owner, state in
            switch state {
            case .load:
                owner.player.play()
            default:
                break
            }
        }
    )
    .disposed(by: self.disposeBag)

player.initItem(urlString: "audio url path")

```

## Korean

간단한 스트리밍/로컬 오디오 플레이어.
다음과 같은 기능들을 지원합니다.

* 간단한 Audio 제어
* 간단한 MPRemoteCommandCenter 제어 (EasyRemoteCenter)
* 배속 설정 (0.5 ~ 2.0)
* 구간 이동
* RxSwift를 이용한 상태 제어 옵저버
    * `stateChange` -> 플레이어의 상태 제어
        * `unload`, `load`, `play`, `pause`, `stop`, `finish`
    * `currentTimeUpdate` -> 현재 구간 확인 (Progress용)
    * `durationChange` -> 오디오 전체 길이 체크
    * `rateChange` -> 배속 변경 알림
* playlist 개발중..

### 설치:
* Swift Package Manager를 사용하여 추가.
* `https://github.com/herohjk/swiftaudioplayer`
* 해당 라이브러리는 [RxSwift (6.2.0)](https://github.com/ReactiveX/RxSwift)와 [HeLogger](https://github.com/herohjk/HeLogger) 라이브러리가 의존성 패키지로 설정되어 있습니다.

### 사용법:

```Swift
import SwiftAudioPlayer

let player = SwiftAudioPlayer()

player.observers.stateChange
    .subscribe(
        with: self,
        onNext: { owner, state in
            switch state {
            case .load:
                owner.player.play()
            default:
                break
            }
        }
    )
    .disposed(by: self.disposeBag)

player.initItem(urlString: "audio url path")

```
