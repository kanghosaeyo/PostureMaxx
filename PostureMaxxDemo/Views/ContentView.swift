// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        ZStack {
            // Camera Preview takes up the background
            // Pass the whole manager instance now
            CameraPreview(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)

            // Overlay the status view
            VStack {
                Spacer() // Push status view towards the bottom
                PostureStatusView(status: cameraManager.postureStatus) // Pass the status enum
                    .padding(.bottom, 50) // Add some padding from the bottom edge
            }
        }
        .onAppear {
             // Session is started internally by CameraManager after setup
             print("ContentView appeared.")
        }
        .onDisappear {
            // Stop the session when the view disappears to save resources
            cameraManager.stopSession()
            print("ContentView disappeared.")
        }
    }
}


struct PostureStatusView: View {
    let status: PostureStatus // Accept the enum

    var body: some View {
        VStack { // Use VStack for potential future expansion
            RoundedRectangle(cornerRadius: 20)
                .fill(statusColor) // Use computed property for color
                .frame(width: 100, height: 100)
                .overlay(
                    Text(statusText) // Use computed property for text
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(5) // Add padding to text
                )
        }
    }

    // Computed property for the circle color based on status
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .bad:
            return .red
        case .notFound:
            return .gray // Use gray for the 'not found' state
        }
    }

    // Computed property for the display text based on status
    private var statusText: String {
        switch status {
        case .good:
            return "Good Posture"
        case .bad:
            return "Adjust Posture!"
        case .notFound:
            return "Body Not Found"
        }
    }
}



