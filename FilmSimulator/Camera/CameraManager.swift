import AVFoundation
import Foundation
import UIKit
import CoreImage
import Combine

enum PhotoCodecPreference: String, CaseIterable {
    case automatic
    case heif
    case jpeg
}

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isSessionRunning = false
    @Published var isAuthorized = false
    @Published var currentFrame: CGImage?
    
    private let sessionQueue = DispatchQueue(label: "com.filmsimulator.sessionQueue")
    private let videoOutputQueue = DispatchQueue(label: "com.filmsimulator.videoOutputQueue")
    
    let photoOutput = AVCapturePhotoOutput()
    let videoOutput = AVCaptureVideoDataOutput()
    
    private let filterRenderer = FilterRenderer()
    @Published var currentProfile: FilmProfile = FilmProfile.allProfiles[0]
    
    /// User preference for photo container/codec. `.automatic` will prefer HEIF when supported, otherwise JPEG.
    #if targetEnvironment(simulator)
    @Published var preferredPhotoCodec: PhotoCodecPreference = .jpeg
    #else
    @Published var preferredPhotoCodec: PhotoCodecPreference = .automatic
    #endif
    
    override init() {
        super.init()
        // Check permissions first, then configure
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isAuthorized = true
            self.configureAndStartSession()
        case .notDetermined:
            sessionQueue.suspend() // Pause queue until we know
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                }
                self.sessionQueue.resume()
                if granted {
                    self.configureAndStartSession()
                }
            }
        default:
            self.isAuthorized = false
        }
    }
    
    private func configureAndStartSession() {
        sessionQueue.async {
            self.configureSession()
            self.startSession()
        }
    }
    
    func start() {
        // Public start method called from UI
        sessionQueue.async {
            self.startSession()
        }
    }
    
    private func startSession() {
        print("CameraManager: Attempting to start session (Authorized: \(isAuthorized), Running: \(session.isRunning))")
        if self.isAuthorized && !self.session.isRunning {
            self.session.startRunning()
            print("CameraManager: Session startRunning() called")
            DispatchQueue.main.async {
                self.isSessionRunning = true
            }
        }
    }
    
    func stop() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
            }
        }
    }
    
    private func configureSession() {
        print("CameraManager: Configuring session...")
        session.beginConfiguration()
        // session.sessionPreset = .photo // .photo might be causing -12710 on some devices with VideoDataOutput
        session.sessionPreset = .high // Try .high for better compatibility
        
        // Add Video Input
        do {
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("CameraManager: No back camera found")
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                print("CameraManager: Video input added")
            } else {
                print("CameraManager: Could not add video device input")
            }
        } catch {
            print("CameraManager: Error creating video device input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // Add Photo Output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            // We rely on sessionPreset = .photo for high res capture for now
            // Explicitly setting maxPhotoDimensions can cause configuration errors on some devices
            photoOutput.isHighResolutionCaptureEnabled = true
            print("CameraManager: Photo output added")
        } else {
            print("CameraManager: Could not add photo output")
        }
        
        // Add Video Data Output for Live Preview
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // IMPORTANT: Set pixel format to BGRA for CoreImage compatibility
            // videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            // FIX: Removing forced BGRA format. The .photo preset might not support it on all devices.
            // CIImage handles YUV (default) fine.
            print("CameraManager: Video output added")
        } else {
            print("CameraManager: Could not add video output")
        }
        
        session.commitConfiguration()
        print("CameraManager: Session configuration committed")
    }
    
    private func resolvedPhotoSettings() -> AVCapturePhotoSettings {
        // Simulator often lacks full HEIF/HEVC support; force JPEG/default
        #if targetEnvironment(simulator)
        // Simulator often lacks full HEIF/HEVC support; force JPEG/default
        let simAvailable = photoOutput.availablePhotoCodecTypes
        if simAvailable.contains(.jpeg) {
            return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        } else {
            return AVCapturePhotoSettings()
        }
        #endif
        
        // Determine desired codec based on preference and availability
        let available = photoOutput.availablePhotoCodecTypes
        func makeSettings(with codec: AVVideoCodecType?) -> AVCapturePhotoSettings {
            if let codec, available.contains(codec) {
                return AVCapturePhotoSettings(format: [AVVideoCodecKey: codec])
            } else {
                return AVCapturePhotoSettings()
            }
        }
        switch preferredPhotoCodec {
        case .jpeg:
            return makeSettings(with: .jpeg)
        case .heif:
            // HEIF typically uses HEVC codec; fall back to default if unavailable
            return makeSettings(with: .hevc)
        case .automatic:
            // Prefer HEVC when available, else JPEG, else default
            if available.contains(.hevc) {
                return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else if available.contains(.jpeg) {
                return AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
            } else {
                return AVCapturePhotoSettings()
            }
        }
    }
    
    func capturePhoto() {
        sessionQueue.async {
            guard self.session.isRunning else {
                print("Cannot capture photo: Session is not running")
                return
            }
            
            let photoSettings = self.resolvedPhotoSettings()
            print("CameraManager: capturing photo (highResEnabled=\(self.photoOutput.isHighResolutionCaptureEnabled))")
            // Enable high-resolution per-capture if supported
            if self.photoOutput.isHighResolutionCaptureEnabled {
                photoSettings.isHighResolutionPhotoEnabled = true
            }
            
            self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("CameraManager: Frame received") // Uncommented for debugging
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Fix orientation: The image comes in landscape. We need to rotate it for portrait display.
        // For a robust app, we should check UIDevice.current.orientation.
        // Here we hardcode a rotation for portrait mode.
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(.right)
        
        // Apply Filter
        let filteredImage = filterRenderer.process(image: ciImage, with: currentProfile, isPreview: true)
        
        // Render to CGImage for display
        // Note: Creating a CGImage every frame can be expensive.
        // In a production app, we might render directly to a Metal view (MTKView).
        // But for this prototype, we optimize by using a shared context.
        if let cgImage = filterRenderer.createCGImage(from: filteredImage) {
            // print("CameraManager: CGImage created successfully")
            DispatchQueue.main.async {
                // print("CameraManager: Updating UI with new frame")
                self.currentFrame = cgImage
            }
        } else {
            print("CameraManager: Failed to create CGImage")
        }
    }
    
    // Manual Controls
    func setExposureBias(_ bias: Float) {
        sessionQueue.async {
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(bias, completionHandler: nil)
                device.unlockForConfiguration()
            } catch {
                print("Error setting exposure: \(error)")
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        // Process the captured photo with the SAME filter
        guard let data = photo.fileDataRepresentation(),
              let ciImage = CIImage(data: data) else {
            print("Error: No photo data found")
            return
        }
        
        // Apply filter
        // Note: The photo might have different orientation metadata.
        // We should respect it. For now, we assume the same orientation fix as preview for simplicity,
        // but ideally we read the orientation from metadata.
        let orientedImage = ciImage.oriented(.right)
        let filteredImage = filterRenderer.process(image: orientedImage, with: currentProfile, isPreview: false)
        
        // Convert to UIImage for saving
        if let cgImage = filterRenderer.createCGImage(from: filteredImage) {
            let uiImage = UIImage(cgImage: cgImage)
            
            PhotoLibraryManager.shared.savePhoto(image: uiImage) { success, error in
                if success {
                    print("Photo saved successfully!")
                } else {
                    print("Error saving photo: \(String(describing: error))")
                }
            }
        }
        
        print("Photo captured and processed!")
    }
}

