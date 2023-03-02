//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Mindy Barrs on 2023-02-19.
//

import SwiftUI

struct PaletteChooser: View {
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font{.system(size: emojiFontSize)}
    
    @EnvironmentObject var store: PaletteStore
    
    @SceneStorage("PaletteChooser.choosenPaletteIndex")
    private var choosenPaletteIndex =  0
    
    var body: some View {
        HStack {
            paletteControlBtn
            body(for: store.palette(at: choosenPaletteIndex))
        }.clipped()
    }
    
    @ViewBuilder
    var contextMenu: some View {
        AnimatedActionButton(title: "New", systemImage: "plus.diamond") {
            store.insertPalette(named: "New", emojis: "", at: choosenPaletteIndex)
            paletteToEdit = store.palette(at: choosenPaletteIndex)
        }
        AnimatedActionButton(title: "Delete", systemImage: "minus.diamond") {
            store.insertPalette(named: "New", emojis: "", at: choosenPaletteIndex)
        }
        AnimatedActionButton(title: "Edit", systemImage: "square.and.pencil") {
            paletteToEdit = store.palette(at: choosenPaletteIndex)
        }
        AnimatedActionButton(title: "Manage", systemImage: "gearshape.2") {
            managing = true
        }
        goToMenu
    }
    
    var goToMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButton(title: palette.name) {
                    if let index = store.palettes.index(matching: palette) {
                        choosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "arrowshape.zigzag.forward")
        }
    }
    
    var paletteControlBtn: some View {
        Button {
            withAnimation {
                choosenPaletteIndex = (choosenPaletteIndex + 1) % store.palettes.count
            }
            
        } label: {
            Image(systemName: "swatchpalette")
        }
        .font(emojiFont)
        .foregroundColor(Color("PurpleColor"))
        .contextMenu { contextMenu }
    }
    
    func body(for palette: Palette) -> some View {
        HStack {
            Text(palette.name)
            ScrollingEmojiView(emojis: palette.emojis)
                .font(emojiFont)
        }
        .id(palette.id)
        .transition(rollTransition)
        //  .sheet(isPresented: $editing) {
        //      PaletteEditor(palette: $store.palettes[choosenPaletteIndex])
        //  }
        .popover(item: $paletteToEdit) { palette in
            PaletteEditor(palette: $store.palettes[palette])
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
    }
    
    //  @State private var editing =  false
    @State private var managing =  false
    @State private var paletteToEdit: Palette?
    
    var rollTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .offset(x: 0, y: emojiFontSize),
            removal: .offset(x: 0, y: -emojiFontSize)
        )
    }
}

struct ScrollingEmojiView: View {
    let emojis: String
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.removingDuplicateCharacters .map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag{ NSItemProvider(object: emoji as NSString) }
                }
            }.foregroundColor(Color.white)
        }
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
    }
}
