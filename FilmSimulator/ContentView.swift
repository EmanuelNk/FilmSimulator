import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var exposureBias: Double = 0.0
    @State private var selectedControl: ControlType = .ev
    @State private var isFilmSelectorVisible: Bool = false
    
    enum ControlType: Hashable {
        case ev
        case temp
    }
    
    private var activeControlLabel: String {
        switch selectedControl {
        case .ev: return "EV"
        case .temp: return "Temp"
        }
    }
    
    private var activeControlRange: ClosedRange<Double> {
        switch selectedControl {
        case .ev: return -2.0...2.0
        case .temp: return 2000...10000
        }
    }
    
    private var activeControlStep: Double {
        switch selectedControl {
        case .ev: return 0.5
        case .temp: return 250
        }
    }
    
    private var activeControlFormat: String {
        switch selectedControl {
        case .ev: return "%.1f"
        case .temp: return "%.0f"
        }
    }
    
    private var activeControlValue: Binding<Double> {
        Binding(
            get: {
                switch selectedControl {
                case .ev:
                    return exposureBias
                case .temp:
                    return cameraManager.currentProfile.temperature
                }
            },
            set: { newValue in
                switch selectedControl {
                case .ev:
                    exposureBias = newValue
                    cameraManager.setExposureBias(Float(newValue))
                case .temp:
                    cameraManager.currentProfile.temperature = newValue
                }
            }
        )
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top padding to mimic system indicators area
                Spacer()
                    .frame(height: 16)
                
                // Framed camera preview with rounded corners
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                    
                    ZStack {
                        CameraPreviewView(cameraManager: cameraManager)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        
                        ThirdsGridOverlay()
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .allowsHitTesting(false)
                    }
                }
                .padding(.horizontal, 16)
                .shadow(color: Color.black.opacity(0.9), radius: 12, x: 0, y: 8)
                .aspectRatio(9.0/16.0, contentMode: .fit)
                
                Spacer()
                
                // Bottom controls panel
                VStack(spacing: 16) {
                    // Manual Controls
                    VStack(spacing: 8) {
                        Picker("Control", selection: $selectedControl) {
                            Text("EV").tag(ControlType.ev)
                            Text("TEMP").tag(ControlType.temp)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 24)
                        
                        ControlDial(
                            label: activeControlLabel,
                            value: activeControlValue,
                            range: activeControlRange,
                            step: activeControlStep,
                            format: activeControlFormat
                        )
                    }
                    
                    // Shutter + Film selector toggle row
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                                isFilmSelectorVisible.toggle()
                            }
                        }) {
                            Image(systemName: "film")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(isFilmSelectorVisible ? .black : .white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(isFilmSelectorVisible ? Color.yellow : Color.white.opacity(0.18))
                                )
                        }
                        
                        Spacer()
                        
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
                        
                        Spacer()
                        
                        // Placeholder lock button to mirror reference UI
                        Button(action: {}) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.yellow)
                                )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 4)
                }
                .padding(.bottom, 24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.9)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
                
                // Film selector panel (shown on demand)
                if isFilmSelectorVisible {
                    FilmSelectorView(currentProfile: $cameraManager.currentProfile)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }
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

// Simple thirds grid overlay like a camera viewfinder
struct ThirdsGridOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let v1 = width / 3
            let v2 = 2 * width / 3
            let h1 = height / 3
            let h2 = 2 * height / 3
            
            Path { path in
                // Vertical lines
                path.move(to: CGPoint(x: v1, y: 0))
                path.addLine(to: CGPoint(x: v1, y: height))
                
                path.move(to: CGPoint(x: v2, y: 0))
                path.addLine(to: CGPoint(x: v2, y: height))
                
                // Horizontal lines
                path.move(to: CGPoint(x: 0, y: h1))
                path.addLine(to: CGPoint(x: width, y: h1))
                
                path.move(to: CGPoint(x: 0, y: h2))
                path.addLine(to: CGPoint(x: width, y: h2))
            }
            .stroke(Color.white.opacity(0.35), lineWidth: 1)
        }
    }
}
