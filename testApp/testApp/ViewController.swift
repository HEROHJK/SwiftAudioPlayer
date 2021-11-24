//
//  ViewController.swift
//  testApp
//
//  Created by 오디언 on 2021/11/24.
//

import UIKit
import SwiftAudioPlayer
import RxSwift

class ViewController: UIViewController {
    @IBOutlet weak var thumb: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    let player = SwiftAudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        player.subjects.currentTimeUpdate
    }

    @IBAction func streamingPlay(_ sender: Any) {
        
    }
    
    @IBAction func localPlay(_ sender: Any) {
        
    }
    
    @IBAction func playAction(_ sender: Any) {
        
    }
}

