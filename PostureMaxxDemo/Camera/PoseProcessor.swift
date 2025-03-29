// PoseProcessor.swift
import Vision

struct PoseProcessor {
    static func checkPosture(observations: [VNHumanBodyPoseObservation]) -> PostureStatus {
        guard let observation = observations.first else {
            print("PoseProcessor: No observations found.")
            return .notFound
        }

        do {
            let points = try observation.recognizedPoints(.all)

            guard let neck = points[.neck], neck.confidence > 0.1,
                  let leftShoulder = points[.leftShoulder], leftShoulder.confidence > 0.1,
                  let rightShoulder = points[.rightShoulder], rightShoulder.confidence > 0.1,
                  let leftEar = points[.leftEar], leftEar.confidence > 0.1
            
            else {
                print("PoseProcessor: Required points not found or confidence too low.")
                return .notFound
            }

            let neckAngle = AngleCalculator.neckAngle(neck: neck.location, leftEar: leftEar.location)
            let badNeckAngle = (neckAngle > 100 && neckAngle < 115) || neckAngle < 68

            let isBad = badNeckAngle
            print("PoseProcessor: Neck Angle: \(neckAngle), Is Bad: \(isBad)")

            return isBad ? .bad : .good

        } catch {
            print("PoseProcessor: Error getting recognized points: \(error)")
            return .notFound
        }
    }
}

