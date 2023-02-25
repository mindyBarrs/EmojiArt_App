//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  View Model
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
             scheduleAutoSave()
            
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageIfNecessary()
            }
        }
    }
    
    // MARK: - Intent(s)
    
    // AutoSave Contants
    private struct AutoSave {
        static let filename = "AutoSave.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coelescingIterval = 5.0
    }
    
    private var autoSaveTimer: Timer?
    
    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: AutoSave.coelescingIterval, repeats: false) { _ in
            self.autoSave()
        }
    }
    
    private func autoSave() {
        if let url = AutoSave.url {
            save(to: url)
        }
    }
    
    private func save(to url: URL) {
        let thisFucntion = "\(String(describing: self)).\(#function)"
        do{
            let data: Data = try emojiArt.json()
            
            try data.write(to: url)
            
            print("\(thisFucntion) Success, Yay!")
        } catch let encodingError where encodingError is EncodingError {
            print("\(thisFucntion) couldn't encode EmojiArt as JSON becasue \(encodingError.localizedDescription)")
        }
        catch {
            print("\(thisFucntion) error = \(error)")
        }
        
    }
    
    init() {
        if let url = AutoSave.url, let autoSaveEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autoSaveEmojiArt
            fetchBackgroundImageIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
        
    }
    
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }
    
    //MARK: - Background
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private var backgroundImageFetchCanellable: AnyCancellable?
    
    private func fetchBackgroundImageIfNecessary() {
         backgroundImage = nil
        
        switch emojiArt.background {
            case .url(let url):
                // fetch URL
                backgroundImageFetchStatus = .fetching
                backgroundImageFetchCanellable?.cancel()
                
                let session = URLSession.shared
                let publisher = session.dataTaskPublisher(for: url)
                    .map{ (data, urlResponse) in UIImage(data: data) }
                    .replaceError(with: nil)
                    .receive(on: DispatchQueue.main)
                
                backgroundImageFetchCanellable = publisher
                    .sink { [weak self] image in
                        self?.backgroundImage = image
                        self?.backgroundImageFetchStatus = (image != nil) ? .idle : .failed(url)
                    }
            case .imageData(let data):
                backgroundImage = UIImage(data: data)
        case .blank:
                break
        }
    }
    
    // MARK: - Intent(s)
    
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
        print("background is set to \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(of: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(of: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
