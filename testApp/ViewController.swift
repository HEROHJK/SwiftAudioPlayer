import UIKit
import SwiftAudioPlayer
import RxSwift

class ViewController: UIViewController {
    @IBOutlet private weak var thumb: UIImageView!
    @IBOutlet private weak var slider: UISlider!
    @IBOutlet private weak var currentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var rateButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var artistLabel: UILabel!
    var sliding = false
    let player = SwiftAudioPlayer()
    var remote: EasyRemoteCenter?
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observe()
        
        self.remote = EasyRemoteCenter(player: self.player)
        
        slider.value = 0
        
    }
    
    @IBAction private func streamingPlay(_ sender: Any) {
        player.initItem(
            // swiftlint:disable line_length
            urlString: "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/m3u8s/f08e80da-bf1d-4e3d-8899-f0f6155f6efa-audio-only.m3u8"
            // swiftlint:enable line_length
        )
        
        
        
        if let image = UIImage(named: "cover")?.pngData() {
            let metaData = AudioMetaData(
                imageData: image,
                title: "StreamingM3U8",
                subTitle: "None",
                artist: "None Artist"
            )
            remote?.setMetaData(metaData: metaData)
            
            thumb.image = UIImage(data: image)
            titleLabel.text = metaData.title
            subTitleLabel.text = metaData.subTitle
            artistLabel.text = metaData.artist
        }
    }
    
    @IBAction private func localPlay(_ sender: Any) {
        guard let url = Bundle.main.url(forResource: "sample", withExtension: "mp3") else { return }
        player.initItem(urlString: url.path)
        
        if let image = UIImage(named: "cover")?.pngData() {
            let metaData = AudioMetaData(
                imageData: image,
                title: "LocalMP3",
                subTitle: "Sample",
                artist: "None Artist"
            )
            
            remote?.setMetaData(metaData: metaData)
            
            thumb.image = UIImage(data: image)
            titleLabel.text = metaData.title
            subTitleLabel.text = metaData.subTitle
            artistLabel.text = metaData.artist
        }
    }
    
    @IBAction private func playAction(_ sender: Any) {
        if player.state == .play {
            player.pause()
        } else if player.state == .pause {
            player.play()
        } else if player.state == .finish {
            player.setSeek(0)
            player.play()
        }
    }
    @IBAction private func sliderChanged(_ sender: UISlider, forEvent event: UIEvent) {
        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began: sliderTouchDown()
            case .ended: sliderTouchUp()
            default: break
            }
        }
    }
    
    private func sliderTouchDown() {
        sliding = true
    }
    
    private func sliderTouchUp() {
        let value = slider.value
        player.setSeek(Double(value))
        
        let time = DispatchTime.now() + .milliseconds(10)
        DispatchQueue.main.asyncAfter(deadline: time) {
            self.sliding = false // 이걸 해주지 않으면, 손가락을 떼는 순간 슬라이더가 잠깐 움직임.
        }
    }
    
    @IBAction private func rateButtonAction(_ sender: Any) {
        var rate: Float = 1.0
        if player.rate == 0.5 {
            rate = 0.75
        } else if player.rate == 0.75 {
            rate = 1.0
        } else if player.rate == 1.0 {
            rate = 1.25
        } else if player.rate == 1.25 {
            rate = 1.5
        } else if player.rate == 1.5 {
            rate = 1.75
        } else if player.rate == 1.75 {
            rate = 2.0
        } else if player.rate == 2.0 {
            rate = 0.5
        }
        
        player.setRate(rate: rate)
    }
    
    private func timeString(time: Int) -> String {
        let hour = Int(time) / 3_600
        let minute = Int(time) / 60 % 60
        let second = Int(time) % 60
        
        return String(format: "%02i:%02i:%02i", hour, minute, second)
    }
    
    private func observe() {
        player.observers.currentTimeUpdate.subscribe(
            with: self,
            onNext: { owner, time in
                owner.currentLabel.text = owner.timeString(time: time)
                if !owner.sliding { owner.slider.value = Float(time) }
            }
        )
            .disposed(by: self.disposeBag)
        
        player.observers.durationChange.subscribe(
            with: self,
            onNext: { owner, time in
                owner.durationLabel.text = owner.timeString(time: time)
                owner.slider.maximumValue = Float(time)
            }
        )
            .disposed(by: self.disposeBag)
        
        player.observers.stateChange
            .delay(.milliseconds(10), scheduler: MainScheduler.instance)
            .subscribe(
                with: self,
                onNext: { owner, state in
                    switch state {
                    case .load:
                        owner.player.play()
                    case .play:
                        owner.playButton.setTitle("pause", for: .normal)
                    case .pause:
                        owner.playButton.setTitle("play", for: .normal)
                    case .finish:
                        owner.playButton.setTitle("play", for: .normal)
                    default:
                        break
                    }
                }
            )
            .disposed(by: self.disposeBag)
        
        player.observers.rateChange
            .subscribe(with: self, onNext: { owner, rate in
                owner.rateButton.setTitle("\(String(format: "%0.2f", rate))", for: .normal)
            }
            )
            .disposed(by: self.disposeBag)
    }
}
