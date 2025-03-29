// CameraManager.swift
import AVFoundation
import Vision
import Combine
import UIKit
import AudioToolbox

enum Vibration {
    case error
    case success
    case warning
    case light
    case medium
    case heavy
    @available(iOS 13.0, *)
    case soft
    @available(iOS 13.0, *)
    case rigid
    case selection
    case oldSchool
    
    public func vibrate() {
        switch self {
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .soft:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        case .rigid:
            if #available(iOS 13.0, *) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .oldSchool:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
}

let jointsToSmooth: [VNHumanBodyPoseObservation.JointName] = [
    .neck, .leftShoulder
]

class CameraManager: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private var lastProcessedTime = Date(timeIntervalSince1970: 0)
    private let processingInterval: TimeInterval = 0.25
    private let smoothingFrameCount = 5
    private var poseHistory: [[VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]] = []
    private let smoothingConfidenceThreshold: VNConfidence = 0.1
    
    @Published var postureStatus: PostureStatus = .notFound
    @Published var smoothedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint]? = nil
    
    
    override init() {
        super.init()
        requestCameraAccess()
    }
    
    private func requestCameraAccess() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.setupCamera()
                } else {
                    print("Camera access denied.")
                    self.postureStatus = .notFound
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
        session.sessionPreset = .hd1280x720
        if session.canAddInput(input) { session.addInput(input) }
        else { print("Could not add camera input."); session.commitConfiguration(); return }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.queue", qos: .userInitiated))
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        else { print("Could not add video output."); session.commitConfiguration(); return }
        
        session.commitConfiguration()
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
                self.poseHistory.removeAll()
                DispatchQueue.main.async {
                    self.smoothedPoints = nil
                    self.postureStatus = .notFound
                }
            }
        }
    }
    
    private func calculateSmoothedPoints() -> [VNHumanBodyPoseObservation.JointName: CGPoint]? {
        guard !poseHistory.isEmpty else { return nil }
        
        var currentSmoothedPoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        for jointName in jointsToSmooth {
            var pointSum = CGPoint.zero
            var confidentCount: Int = 0
            
            for framePoints in poseHistory {
                if let point = framePoints[jointName], point.confidence >= smoothingConfidenceThreshold {
                    pointSum.x += point.location.x
                    pointSum.y += point.location.y
                    confidentCount += 1
                }
            }
            
            if confidentCount > 0 {
                let averagePoint = CGPoint(x: pointSum.x / CGFloat(confidentCount),
                                           y: pointSum.y / CGFloat(confidentCount))
                currentSmoothedPoints[jointName] = averagePoint
            }
        }
        return currentSmoothedPoints.isEmpty ? nil : currentSmoothedPoints
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let currentTime = Date()
        guard currentTime.timeIntervalSince(self.lastProcessedTime) >= processingInterval else {
            return
        }
        self.lastProcessedTime = currentTime
        
        let currentOrientation = UIDevice.current.orientation
        let visionOrientation = visionOrientation(from: currentOrientation)
        
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: visionOrientation)
        let request = VNDetectHumanBodyPoseRequest()
        
        var framePoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint]? = nil
        var currentStatus: PostureStatus = .notFound
        
        do {
            try requestHandler.perform([request])
            if let observation = request.results?.first {
                framePoints = try? observation.recognizedPoints(.all)
                currentStatus = PoseProcessor.checkPosture(observations: [observation])
                if currentStatus == .bad {
                    Vibration.success.vibrate()
                    AudioServicesPlaySystemSound(1007)
                }
            } else {
                currentStatus = .notFound
            }
        } catch {
            print("Error performing pose detection request: \(error)")
            currentStatus = .notFound
        }
        
        poseHistory.append(framePoints ?? [:])
        while poseHistory.count > smoothingFrameCount {
            poseHistory.removeFirst()
        }
        
        let newSmoothedPoints = calculateSmoothedPoints()
        
        DispatchQueue.main.async {
            self.smoothedPoints = newSmoothedPoints
            
            if self.postureStatus != currentStatus {
                self.postureStatus = currentStatus
            }
        }
    }
    
    func visionOrientation(from deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        switch deviceOrientation {
        case .portrait: return .up
        case .portraitUpsideDown: return .down
        case .landscapeLeft: return .left
        case .landscapeRight: return .right
        default: return .up
        }
    }
}

