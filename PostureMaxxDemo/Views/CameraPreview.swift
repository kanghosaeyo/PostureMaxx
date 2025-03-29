//
//  CameraPreview.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import SwiftUI
import AVFoundation
import UIKit

struct CameraPreview: UIViewRepresentable {
    let captureSession: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = VideoPreviewView()
                view.previewLayer.session = captureSession
                view.previewLayer.videoGravity = .resizeAspectFill
                return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {

    }
    
    // Custom UIView subclass to host the preview layer
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }

        var previewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
