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
            Spacer()
            documentBody
            Spacer()
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
                Color("YellowColor")
                    .overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .position(convertFromEmojiCoordinates((0,0), in: geometry))
                    )
                    .gesture(doubleTapToZoom(in: geometry.size))
                    
                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView().scaleEffect(2)
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale)
                            .position(position(for: emoji, in: geometry))
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                return dropEmoji(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: pinchToZoom()))
        }
    }
    
    //MARK: - Drag & Drop
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
                        size: defaultEmojiFontSize / zoomScale
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
            x: (location.x  - panOffSet.width - center.x) / zoomScale,
            y: (location.y - panOffSet.height - center.y) / zoomScale
        )
        
        return (Int(location.x), (Int(location.y)))
    }
    
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffSet.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffSet.height
        )
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }
    
    //MARK: - Gestures
    
    @State private var steadyStatePanOffSet: CGSize = CGSize.zero
    @GestureState private var gesturePanOffSet: CGSize = CGSize.zero
    
    private var panOffSet: CGSize {
        (steadyStatePanOffSet + gesturePanOffSet) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffSet) { latestDragGestureVale, gesturePanOffSet, _ in
                gesturePanOffSet = latestDragGestureVale.translation / zoomScale
            }
            .onEnded{ finalDragGestureValue in
                steadyStatePanOffSet = steadyStatePanOffSet + (finalDragGestureValue.translation / zoomScale)
            }
    }

    @State private var steadyStateZoomScale: CGFloat = 1
    @GestureState private var gestureZoomScale: CGFloat = 1
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func pinchToZoom() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transition in
                gestureZoomScale = latestGestureScale
            }
            .onEnded{ gestureScaleAtEnd in
                steadyStateZoomScale *= gestureScaleAtEnd
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded{
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            steadyStatePanOffSet = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
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
            }.foregroundColor(Color.white)
        }
    }
}























struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
