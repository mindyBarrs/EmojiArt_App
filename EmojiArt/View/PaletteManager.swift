//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by Mindy Barrs on 2023-02-20.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore
    // How to check if in dark mode
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(store.palettes){ palette in
                    NavigationLink(destination: PaletteEditor(palette: $store.palettes[palette])) {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                            Text(palette.emojis)
                        }
                    }
                    .gesture(editMode == .active ? tap : nil)
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Palette Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("GreenColor"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .dismissable {
                presentationMode.wrappedValue.dismiss()
            }
            .toolbar {
                ToolbarItem { EditButton() }
            }
            .environment(\.editMode, $editMode)
        }
    }
    
    var tap: some Gesture {
        TapGesture().onEnded{ }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .previewDevice("iPhone 14")
            .previewLayout(.device)
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
