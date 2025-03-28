//
//  PoseProcessor.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import Vision

struct PoseProcessor {
    static func checkPosture(observations: [VNHumanBodyPoseObservation]) -> Bool {
        guard let observation = observations.first else { return false }
        
        do {
            let points = try observation.recognizedPoints(.all)
            guard let neck = points[.neck],
                  let leftShoulder = points[.leftShoulder],
                  let rightShoulder = points[.rightShoulder] else { return false }
            
            // Calculate angles
            let neckAngle = AngleCalculator.neckAngle(neck: neck.location)
            let shoulderAngle = AngleCalculator.shoulderAngle(left: leftShoulder.location,
                                                             right: rightShoulder.location)
            
            // Thresholds
            return neckAngle > 25 || shoulderAngle > 15
        } catch {
            return false
        }
    }
}
