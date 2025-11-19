import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var exposureBias: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Live Camera Preview
            CameraPreviewView(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top Controls (Placeholder)
                HStack {
                    Button(action: {}) {
                        Image(systemName: "bolt.slash.fill")
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [.black.opacity(0.7), .clear]), startPoint: .top, endPoint: .bottom))
                
                Spacer()
                
                // Film Selector
                FilmSelectorView(currentProfile: $cameraManager.currentProfile)
                    .padding(.bottom, 10)
                
                // Manual Controls
                HStack(spacing: 20) {
                    ControlDial(label: "EV", value: $exposureBias, range: -2.0...2.0, step: 0.5)
                        .onChange(of: exposureBias) { newValue in
                            cameraManager.setExposureBias(Float(newValue))
                        }
                    
                    ControlDial(label: "Temp", value: $cameraManager.currentProfile.temperature, range: 2000...10000, step: 250, format: "%.0f")
                }
                .padding(.bottom, 10)
                
                // Shutter Button
                Button(action: {
                    cameraManager.capturePhoto()
                }) {
                    Circle()
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            cameraManager.start()
        }
        .onDisappear {
            cameraManager.stop()
        }
    }
}
