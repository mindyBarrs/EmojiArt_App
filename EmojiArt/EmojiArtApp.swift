//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let document = EmojiArtDocument()
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
