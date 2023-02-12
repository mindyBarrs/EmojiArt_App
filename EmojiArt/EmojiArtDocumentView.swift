//
//  ContentView.swift
//  EmojiArt
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    let defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            header
            documentBody
            palette
        }
    }
    
    var header: some View  {
        ZStack {
            Text("Emoji Art App")
                .foregroundColor(Color("PurpleColor"))
                .font(.system(size: defaultEmojiFontSize))
                .multilineTextAlignment(.leading)
                .bold()
                .padding()
        }
    }
    
    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .overlay(OptionalImage(uiImage: document.backgroundImage))
                    .position(convertFromEmojiCoordinates((0,0), in: geometry))
                
                ForEach(document.emojis) { emoji in
                    Text(emoji.text)
                        .font(.system(size: fontSize(for: emoji)))
                        .position(position(for: emoji, in: geometry))
                }
            }
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return dropEmoji(providers: providers, at: location, in: geometry)
            }
        }
    }
    
    // MARK - Drag & Drop
    private func dropEmoji (providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            document.setBackground(EmojiArtModel.Background.url(url.imageURL))
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data =  image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(EmojiArtModel.Background.imageData(data))
                }
            }
        }
        
        if !found {
            found =  providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: converToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize
                    )
                }
            }
        }
        
        return found
    }
    
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func converToEmojiCoordinates(_ location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        
        let location = CGPoint(
            x: location.x - center.x,
            y: location.y - center.y
        )
        
        return (Int(location.x), (Int(location.y)))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x),
            y: center.y + CGFloat(location.y)
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    //MARK: - Pallete
    var palette: some View {
        ScrollingEmojiView(emojis: testEmoji)
            .font(.system(size: defaultEmojiFontSize))
    }
    
    let testEmoji = "🚕😇🐱🦄🥨🏹🚞📸❤️‍🔥🇨🇦😜🦊🦖🌮🏵🎡⛩⚖️🎁🔱🐻‍❄️🥶🤖💋👑🦚🎄🌸☃️🌊🥮"
}


struct ScrollingEmojiView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag{ NSItemProvider(object: emoji as NSString) }
                }
            }
        }
    }
}























struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
