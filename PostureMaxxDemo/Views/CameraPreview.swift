// CameraPreview.swift
import SwiftUI
import AVFoundation
import Vision
import UIKit

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraManager: CameraManager

    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.previewLayer.session = cameraManager.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.poseOverlayLayer.frame = view.bounds
        view.layer.addSublayer(view.poseOverlayLayer)
        return view
    }

    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        uiView.updatePoseOverlay(using: cameraManager.smoothedPoints)

        if uiView.previewLayer.session != cameraManager.session {
             uiView.previewLayer.session = cameraManager.session
        }
    }

    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

        let poseOverlayLayer: CAShapeLayer = {
            // Layer setup (same as before)
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.systemGreen.cgColor
            layer.lineWidth = 3.0
            layer.fillColor = UIColor.clear.cgColor
            layer.shadowColor = UIColor.black.cgColor
            layer.shadowOpacity = 0.7
            layer.shadowRadius = 3.0
            layer.shadowOffset = CGSize(width: 1, height: 1)
            return layer
        }()

        override func layoutSubviews() {
            super.layoutSubviews()
            poseOverlayLayer.frame = bounds
        }

        func updatePoseOverlay(using points: [VNHumanBodyPoseObservation.JointName: CGPoint]?) {

             guard Thread.isMainThread else {
                 DispatchQueue.main.async { self.updatePoseOverlay(using: points) }
                 return
             }

            guard let smoothedPoints = points else {
                poseOverlayLayer.path = nil
                return
            }

            let path = UIBezierPath()

             let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
                (.neck, .leftShoulder)
             ]

            for (startKey, endKey) in connections {
                guard let startPointLocation = smoothedPoints[startKey],
                      let endPointLocation = smoothedPoints[endKey] else {
                    continue
                }

                let viewStartPoint = pointInView(startPointLocation)
                let viewEndPoint = pointInView(endPointLocation)

                // Don't draw if points are effectively zero
                guard viewStartPoint != .zero && viewEndPoint != .zero else { continue }

                path.move(to: viewStartPoint)
                path.addLine(to: viewEndPoint)
            }


             CATransaction.begin()
             CATransaction.setDisableActions(true)
             poseOverlayLayer.path = path.cgPath
             CATransaction.commit()
        }

        private func pointInView(_ normalizedPoint: CGPoint) -> CGPoint {
            let viewWidth = bounds.width
            let viewHeight = bounds.height
            guard viewWidth > 0, viewHeight > 0 else { return .zero }
            let viewX = normalizedPoint.x * viewWidth
            let viewY = (1.0 - normalizedPoint.y) * viewHeight
            return CGPoint(x: viewX, y: viewY)
        }
    }
}


