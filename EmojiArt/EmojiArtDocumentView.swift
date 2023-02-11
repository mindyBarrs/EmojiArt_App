//
//  ContentView.swift
//  EmojiArt
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }
    
    var documentBody: some View {
        ZStack {
            Color("YellowColor")
            ForEach(document.emojis) { emoji in
                Text(emoji.text)
            }
        }
        
    }
    
    var palette: some View {
        ScrollingEmojiView(emojis: testEmoji)
    }
    
    let testEmoji = "🚕😇🐱🦄🥨🏹🚞📸❤️‍🔥🇨🇦😜🦊🦖🌮🏵🎡⛩⚖️🎁🔱"
}


struct ScrollingEmojiView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
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
