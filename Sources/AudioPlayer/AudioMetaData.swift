import UIKit
import MediaPlayer

public struct AudioMetaData {
    public let imageData: Data
    public let title: String
    public let subTitle: String
    public let artist: String
    
    public init(imageData: Data, title: String, subTitle: String, artist: String) {
        self.imageData = imageData
        self.title = title
        self.subTitle = subTitle
        self.artist = artist
    }
}
