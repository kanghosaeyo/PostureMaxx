//
//  AngleCalculator.swift
//  PostureMaxxDemo
//
//  Created by Kangho Ji on 3/28/25.
//

import CoreGraphics

struct AngleCalculator {
    static func neckAngle(neck: CGPoint, leftEar: CGPoint) -> CGFloat {
        let vertical = CGPoint(x: neck.x, y: neck.y - 100)
        return angleBetweenThreePoints(a: vertical, b: neck, c: leftEar)
    }
    
    private static func angleBetweenThreePoints(a: CGPoint, b: CGPoint, c: CGPoint) -> CGFloat {
        let vectorBA = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let vectorBC = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        
        let dotProduct = vectorBA.dx * vectorBC.dx + vectorBA.dy * vectorBC.dy
        let magnitudeBA = sqrt(pow(vectorBA.dx, 2) + pow(vectorBA.dy, 2))
        let magnitudeBC = sqrt(pow(vectorBC.dx, 2) + pow(vectorBC.dy, 2))
        
        return acos(dotProduct / (magnitudeBA * magnitudeBC)).degrees
    }
}

extension CGFloat {
    var degrees: CGFloat {
        self * 180 / .pi
    }
}
