//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageIfNecessary()
            }
        }
    }
    
    init() {
        emojiArt = EmojiArtModel()
        emojiArt.addEmoji("🦖", at: (-200, -100), size: 80)
        emojiArt.addEmoji("🦕", at: (50, 100), size: 40)
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    
    private func fetchBackgroundImageIfNecessary() {
         backgroundImage = nil
        
        switch emojiArt.background {
            case .url(let url):
                // fetch URL
                DispatchQueue.global(qos: .userInitiated).async {
                    let imageData = try? Data(contentsOf: url )
                    if imageData != nil {
                        self.backgroundImage = UIImage(data: imageData!)
                    }
                }
            case .imageData(let data):
                backgroundImage = UIImage(data: data)
        case .blank:
                break
        }
    }
    
    // MARK : - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background is se to \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(of: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(of: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
