//
//  CameraManager.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import AVFoundation
import Vision
import Combine
import UIKit

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var lastProcessedTime = Date(timeIntervalSince1970: 0)
    private let processingInterval: TimeInterval = 0.1 // Process every 0.1 seconds (adjust as needed)

    @Published var postureStatus: PostureStatus = .notFound
    @Published var latestObservation: VNHumanBodyPoseObservation? = nil // Publish the observation

    // Keep init, requestCameraAccess, setupCamera methods as before...
    override init() {
        super.init()
        requestCameraAccess()
    }

    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
             DispatchQueue.main.async { // Ensure UI updates and setup happen on main thread
                 if granted {
                     self.setupCamera()
                 } else {
                     print("Camera access denied.")
                     self.postureStatus = .notFound // Or some error state
                 }
             }
        }
    }

    private func setupCamera() {
         guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
               let input = try? AVCaptureDeviceInput(device: device) else {
             print("Failed to get camera device or input.")
             return
         }

         session.beginConfiguration()
         session.sessionPreset = .hd1280x720 // Lower preset might improve performance if needed
         if session.canAddInput(input) {
             session.addInput(input)
         } else {
             print("Could not add camera input.")
             session.commitConfiguration()
             return
         }

         let videoOutput = AVCaptureVideoDataOutput()
         // Ensure pixel format is suitable for Vision and drawing
         videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
         videoOutput.alwaysDiscardsLateVideoFrames = true // Important for real-time processing
         videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue", qos: .userInitiated))
         if session.canAddOutput(videoOutput) {
             session.addOutput(videoOutput)
         } else {
             print("Could not add video output.")
             session.commitConfiguration()
             return
         }

         session.commitConfiguration()

         // Start session in the background
         DispatchQueue.global(qos: .userInitiated).async {
             print("Camera session starting.")
             self.session.startRunning()
         }
     }

     func stopSession() {
         DispatchQueue.global(qos: .userInitiated).async {
             if self.session.isRunning {
                 print("Camera session stopping.")
                 self.session.stopRunning()
                 DispatchQueue.main.async {
                    self.latestObservation = nil // Clear observation when stopping
                    self.postureStatus = .notFound
                 }
             }
         }
     }
}

    extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            let currentTime = Date()
            guard currentTime.timeIntervalSince(self.lastProcessedTime) >= processingInterval else {
                return // Skip frame if too soon
            }
            self.lastProcessedTime = currentTime

            // --- Orientation Handling ---
            // This is crucial. Get current device orientation.
            // You might need to manage this using NotificationCenter observing UIDevice.orientationDidChangeNotification
            // For now, assuming portrait. Adjust based on actual orientation.
            let currentOrientation = UIDevice.current.orientation
            let visionOrientation = visionOrientation(from: currentOrientation) // Defaulting to .up for now


            let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: visionOrientation) // Use dynamic orientation
            let request = VNDetectHumanBodyPoseRequest()

            var newObservation: VNHumanBodyPoseObservation? = nil // Temp var for the observation
            var newStatus: PostureStatus = .notFound // Temp var for status

            do {
                try requestHandler.perform([request])
                if let observation = request.results?.first {
                    newObservation = observation // Store observation if found
                    newStatus = PoseProcessor.checkPosture(observations: [observation]) // Calculate status
                } else {
                    newStatus = .notFound // No observation means notFound
                }
            } catch {
                print("Error performing pose detection request: \(error)")
                newStatus = .notFound // Error means notFound
            }

            // Update published properties on the main thread
            DispatchQueue.main.async {
                // Update observation regardless of status change
                self.latestObservation = newObservation

                // Update status only if it changed
                if self.postureStatus != newStatus {
                    self.postureStatus = newStatus
                }
            }
        }

         // Helper to convert UIDeviceOrientation to CGImagePropertyOrientation
        func visionOrientation(from deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
            switch deviceOrientation {
            case .portrait: return .up
            case .portraitUpsideDown: return .down
            case .landscapeLeft: return .left // Check if this needs swapping depending on camera sensor
            case .landscapeRight: return .right // Check if this needs swapping
            case .faceUp, .faceDown, .unknown: return .up // Default to portrait
            @unknown default: return .up
            }
        }
    }
