# AudioPlayer

## 플레이어의 기능과 범위

### 기능
* 오디오 재생(play) / 일시정지(pause) / 정지(stop)
* 스트리밍(streaming) / 로컬파일(local) 지원
* 메타데이터 설정 (iOS remoteCenter)
* 상태변화에 따른 델리게이트
  * RxSwift를 이용.
  * 로드 / 언로드
  * 재생
  * 일시정지
  * 정지
  * 완료
* 배속조절 (0.5 ~ 2)
* Seeking
