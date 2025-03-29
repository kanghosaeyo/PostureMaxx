// CameraPreview.swift

import SwiftUI
import AVFoundation
import Vision // Import Vision
import UIKit

struct CameraPreview: UIViewRepresentable {
    // Observe the CameraManager to get observations
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> VideoPreviewView { // Return specific type
        let view = VideoPreviewView()
        // Ensure the session is assigned. If CameraManager sets it up asynchronously,
        // this might need to be done in updateUIView or via a coordinator initially.
        view.previewLayer.session = cameraManager.session
        view.previewLayer.videoGravity = .resizeAspectFill

        // Set the initial frame for the overlay layer
        // Note: Bounds might be zero here initially. layoutSubviews is more reliable.
        view.poseOverlayLayer.frame = view.bounds
        // Add the overlay layer
        view.layer.addSublayer(view.poseOverlayLayer)

        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) { // Use specific type
        // Update the pose overlay when the observation changes
        uiView.updatePoseOverlay(for: cameraManager.latestObservation)

        // Ensure the preview layer's session is up-to-date
        // This handles cases where the session might be reset or assigned later
        if uiView.previewLayer.session != cameraManager.session {
             uiView.previewLayer.session = cameraManager.session
        }
    }

    // Custom UIView subclass to host the preview layer AND the pose overlay
    class VideoPreviewView: UIView {
        // The layer displaying the camera feed
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // Force unwrap is generally safe here because we override layerClass
            layer as! AVCaptureVideoPreviewLayer
        }

        // The layer for drawing pose lines
        let poseOverlayLayer: CAShapeLayer = {
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.systemGreen.cgColor // Line color
            layer.lineWidth = 5.0 // Line width
            layer.fillColor = UIColor.clear.cgColor // No fill
            // Optional: Add shadow for better visibility
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.7
            layer.shadowRadius = 3.0
            layer.shadowOffset = CGSize(width: 1, height: 1)
            return layer
        }()

        // Called when the view's bounds change (e.g., rotation, initial layout)
        override func layoutSubviews() {
            super.layoutSubviews()
            // Keep the overlay layer sized to the view bounds reliably
            poseOverlayLayer.frame = bounds
        }

        // Function to draw lines based on pose observation
        func updatePoseOverlay(for observation: VNHumanBodyPoseObservation?) {
            // Ensure we are on the main thread for UI updates
             guard Thread.isMainThread else {
                 DispatchQueue.main.async { self.updatePoseOverlay(for: observation) }
                 return
             }

            guard let observation = observation else {
                // No observation, clear the path
                poseOverlayLayer.path = nil
                return
            }

            let path = UIBezierPath()

            do {
                // The dictionary uses JointName as its key type
                 let recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]
                 recognizedPoints = try observation.recognizedPoints(.all)

                // --- Define Connections ---
                // List pairs of joints you want to connect
                let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                    // Head
                    (.neck, .leftEar),
                //    (.neck, .rightEar),
                    // Torso
                    (.neck, .leftShoulder),
                //    (.neck, .rightShoulder),
                //    (.leftShoulder, .rightShoulder), // Across shoulders
                    (.leftShoulder, .leftHip),
                 //   (.rightShoulder, .rightHip),
                 //   (.leftHip, .rightHip), // Across hips
                    // Left Arm
                   // (.leftShoulder, .leftElbow),
                  //  (.leftElbow, .leftWrist),
                    // Right Arm
                  //  (.rightShoulder, .rightElbow),
                  //  (.rightElbow, .rightWrist)
                    // Add legs if needed: e.g., (.leftHip, .leftKnee), (.leftKnee, .leftAnkle)
                ]

                // --- Draw Connections ---
                for (startKey, endKey) in connections {
                    // Check confidence level for both points
                    guard let startPoint = recognizedPoints[startKey], startPoint.confidence > 0.1,
                          let endPoint = recognizedPoints[endKey], endPoint.confidence > 0.1 else {
                        continue // Skip if points are missing or low confidence
                    }

                    // Convert normalized points to view coordinates
                    let viewStartPoint = pointInView(startPoint.location)
                    let viewEndPoint = pointInView(endPoint.location)

                    // Don't draw if points are effectively zero (can happen if conversion fails)
                    guard viewStartPoint != .zero && viewEndPoint != .zero else { continue }

                    path.move(to: viewStartPoint)
                    path.addLine(to: viewEndPoint)
                }

            } catch {
                print("Error getting recognized points for drawing: \(error)")
                // Clear path on error
                poseOverlayLayer.path = nil
                return
            }

            // Update the layer's path atomically
             CATransaction.begin()
             CATransaction.setDisableActions(true) // Avoid implicit animation
             poseOverlayLayer.path = path.cgPath
             CATransaction.commit()
        }

        // Helper function to convert normalized point to view coordinates
        private func pointInView(_ normalizedPoint: CGPoint) -> CGPoint {
            // --- Manual Conversion ---
            // Assumes Vision normalized coordinates (0,0) at bottom-left.
            // View/Layer coordinates (0,0) at top-left.
            let viewWidth = bounds.width
            let viewHeight = bounds.height

            // Check for valid bounds to prevent division by zero or NaN results
            guard viewWidth > 0, viewHeight > 0 else {
                return .zero // Return zero point if bounds are not valid yet
            }

            let viewX = normalizedPoint.x * viewWidth
            let viewY = (1.0 - normalizedPoint.y) * viewHeight // Flip Y-axis

            return CGPoint(x: viewX, y: viewY)
        }
    }
}

