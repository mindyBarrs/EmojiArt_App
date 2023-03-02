//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by Mindy Barrs on 2023-02-19.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
     
    var body: some View {
        Form {
            nameSection
            addEmojiSection
            deleteEmojiSection
        }
        .navigationTitle("\(palette.name) Editor")
        .toolbarBackground(Color("OrangeColor"), for: .automatic)
        .toolbarBackground(.visible, for: .navigationBar)
        .frame(minWidth: 300, minHeight: 350)
    }
    
    var nameSection: some View {
        Section(header: Text("Name:")) {
            TextField("Name", text: $palette.name)
        }
    }
    
    @State private var emojisToAdd = ""
    
    var addEmojiSection: some View {
        Section(header: Text("Add Emoji(s):")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    addEmojis(emojis)
                }
        }
    }
    
    func addEmojis(_  emojis: String) {
        withAnimation{
            palette.emojis = (emojis + palette.emojis)
                .filter{ $0.isEmoji }
                .removingDuplicateCharacters
        }
    }
    
    var deleteEmojiSection: some View {
        Section(header: Text("Delete Emoji(s):")) {
            let emojis = palette.emojis.removingDuplicateCharacters.map{String($0)}
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))]) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation{
                                palette.emojis.removeAll(where: { String($0) == emoji })
                            }
                        }
                }
            }
        }
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(named: "Preview").palette(at: 4)))
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/300.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/350.0/*@END_MENU_TOKEN@*/))
    }
}
 
