//
//  CameraManager.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import AVFoundation
import Vision

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession() // Change from private to internal/public

    @Published var isBadPosture = false

    override init() {
        super.init()
        setupCamera()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device) else { return }

        session.sessionPreset = .hd1280x720
        if session.canAddInput(input) {
            session.addInput(input)
        }

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up)
        let request = VNDetectHumanBodyPoseRequest()
        
        do {
            try requestHandler.perform([request])
            guard let observations = request.results else { return }
            
            // Use PoseProcessor to check posture
            DispatchQueue.main.async {
                self.isBadPosture = PoseProcessor.checkPosture(observations: observations)
            }
        } catch {
            print("Error processing pose detection: \(error)")
        }
    }
}

