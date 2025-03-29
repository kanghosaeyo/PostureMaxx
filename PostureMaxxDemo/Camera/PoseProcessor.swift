// PoseProcessor.swift
import Vision

struct PoseProcessor {
    // Updated to return PostureStatus
    static func checkPosture(observations: [VNHumanBodyPoseObservation]) -> PostureStatus {
        guard let observation = observations.first else {
            print("PoseProcessor: No observations found.")
            return .notFound // No person detected
        }

        do {
            let points = try observation.recognizedPoints(.all)

            // Check if essential points are present and have sufficient confidence
            guard let neck = points[.neck], neck.confidence > 0.1,
                  let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.1,
                  let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.1,
                  let leftEar = points[.leftEar], leftEar.confidence > 0.1
            
            else {
                print("PoseProcessor: Required points not found or confidence too low.")
                return .notFound // Required body parts not detected confidently
            }

            // Calculate angles (ensure AngleCalculator exists and works)
            let neckAngle = AngleCalculator.neckAngle(neck: neck.location, leftEar: leftEar.location)
            let badNeckAngle = neckAngle > 100 || neckAngle < 70

            // Thresholds for bad posture
            let isBad = badNeckAngle
            print("PoseProcessor: Neck Angle: \(neckAngle), Is Bad: \(isBad)")

            return isBad ? .bad : .good // Return .bad or .good based on calculation

        } catch {
            print("PoseProcessor: Error getting recognized points: \(error)")
            return .notFound // Error during point processing
        }
    }
}
