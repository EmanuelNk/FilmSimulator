import SwiftUI

struct CameraPreviewView: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        GeometryReader { geometry in
            if let image = cameraManager.currentFrame {
                Image(decorative: image, scale: 1.0, orientation: .up)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Color.black
                    .overlay(
                        Text("Loading Camera...")
                            .foregroundColor(.white)
                    )
            }
        }
    }
}
