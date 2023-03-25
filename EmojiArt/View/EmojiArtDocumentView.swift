//
//  ContentView.swift
//  EmojiArt
//
//  Created by Barrs, Mindy on 2023-02-10.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @Environment(\.undoManager) var undoManager
    
    @ScaledMetric var defaultEmojiFontSize: CGFloat = 40
    
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            Spacer()
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color("YellowColor")
                OptionalImage(uiImage: document.backgroundImage)
                    .scaleEffect(zoomScale)
                    .position(convertFromEmojiCoordinates((0,0), in: geometry))
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
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                    case .failed(let url):
                        showBackgroundImageFetchFailedAlert(url)
                    default :
                        break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                if autoZoom {
                    zoomToFit(image, in: geometry.size )
                }
            }
            .navigationTitle("Emoji Art App")
                .foregroundColor(Color("PurpleColor"))
                .font(.system(size: 25))
                .bold()
                .padding()
            .compactableToolbar {
                    AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                        pasteBackground()
                    }
                
                    if Camera.isAvailable {
                        AnimatedActionButton(title: "Snap a Photo", systemImage: "camera.circle") {
                            backgroundPicker = .camera
                        }
                    }
                
                    if PhotoLibrary.isAvailable {
                        AnimatedActionButton(title: "Search Photo", systemImage: "photo.circle") {
                            backgroundPicker = .library
                        }
                    }
                   
                    if let undoManager = undoManager {
                        if undoManager.canUndo {
                            AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                                undoManager.undo()
                            }
                        }
                        
                        if undoManager.canRedo {
                            AnimatedActionButton(title: undoManager.redoActionName, systemImage: "arrow.uturn.forward") {
                                undoManager.redo()
                            }
                        }
                    }
            }
            .sheet(item: $backgroundPicker) { pickerType in
                switch pickerType {
                case .camera: Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library: PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                }
            }
        }
    }
    
    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autoZoom = true
        
        if let imageData = image?.jpegData(compressionQuality: 1.0) {
            document.setBackground(.imageData(imageData ), undoManager: undoManager)
        }
        
        backgroundPicker = nil
    }
    
    @State private var backgroundPicker: BackgroundPickerType?
    
    enum BackgroundPickerType: Identifiable {
        case camera
        case library
        var id: BackgroundPickerType { self }
    }
    
    private func pasteBackground() {
        autoZoom = true
        
        if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
            document.setBackground(.imageData(imageData), undoManager: undoManager)
        } else if let url = UIPasteboard.general.url?.imageURL {
            document.setBackground(.url(url), undoManager: undoManager)
        } else {
            alertToShow = IdentifiableAlert(
                title: "Paste Background",
                message: "There currently isn't a image on the pasteboard."
            )
        }
    }
    
    @State private var autoZoom = false
    @State private var alertToShow: IdentifiableAlert?

    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "Fetch Failed" + url.absoluteString, alert: {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image \(url)."),
                dismissButton: .default(Text("OK"))
            )
        })
    }
    
    //MARK: - Drag & Drop
    
    private func dropEmoji (providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadObjects(ofType: URL.self) { url in
            autoZoom = true
            document.setBackground(EmojiArtModel.Background.url(url.imageURL), undoManager: undoManager)
        }
        
        if !found {
            found = providers.loadObjects(ofType: UIImage.self) { image in
                if let data =  image.jpegData(compressionQuality: 1.0) {
                    autoZoom = true
                    document.setBackground(EmojiArtModel.Background.imageData(data), undoManager: undoManager)
                }
            }
        }
        
        if !found {
            found =  providers.loadObjects(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: converToEmojiCoordinates(location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
                        undoManager: undoManager
                    )
                }
            }
        }
        
        return found
    }
    
    // MARK: - Emoji Placement
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry)
    }
    
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
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

    // MARK: - Gestures
    
    // MARK: - Zoomming
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1
    
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
        if let image = image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0  {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            
            steadyStatePanOffSet = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    
    // MARK: - Panning
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffSet")
    private var steadyStatePanOffSet: CGSize = CGSize.zero
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
}























struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
