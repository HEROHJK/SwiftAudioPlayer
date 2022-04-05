import UIKit
import MediaPlayer

public struct AudioPlayerData {
    public var imageData: Data?
    public let title: String
    public let subTitle: String
    public let artist: String
    
    public init(imageData: Data, title: String, subTitle: String, artist: String) {
        self.imageData = imageData
        self.title = title
        self.subTitle = subTitle
        self.artist = artist
    }
    
    public init(title: String, subTitle: String, artist: String, imageURL: String) {
        self.title = title
        self.subTitle = subTitle
        self.artist = artist
        
        self.imageData = try? Data.init(contentsOf: URL.init(string:imageURL)!)
    }
}
