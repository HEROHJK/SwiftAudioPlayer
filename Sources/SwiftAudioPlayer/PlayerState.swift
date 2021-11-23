import Foundation

/// 플레이어 상태 열거형
/// - unload: 플레이어에 아이템이 적재되지 않은 상태.
/// - load: 플레이어에 아이템이 적재되어 있는 상태.
/// - play: 재생중인 상태
/// - pause: 일시중지 되어 있는 상태
/// - stop: 멈춰있는 상태, 시간은 0으로 초기화되어있다.
public enum PlayerState {
    case unload
    case load
    case play
    case pause
    case stop
}
