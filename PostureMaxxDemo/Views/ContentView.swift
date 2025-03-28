import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @StateObject private var notificationManager = NotificationManager()

    var body: some View {
        ZStack {
            CameraPreview(captureSession: cameraManager.session) // Pass session directly
                .edgesIgnoringSafeArea(.all)

            VStack {
                PostureStatusView(isBadPosture: cameraManager.isBadPosture)
            }
        }
        .onChange(of: cameraManager.isBadPosture) { oldValue, newValue in
            if oldValue == false && newValue == true { // Trigger only on transition
                notificationManager.scheduleNotification()
            }
        }
    }
}

struct PostureStatusView: View {
    let isBadPosture: Bool
    
    var body: some View {
        Circle()
            .fill(isBadPosture ? Color.red : Color.green)
            .frame(width: 100, height: 100)
            .overlay(
                Text(isBadPosture ? "Adjust Posture!" : "Good Posture")
                    .foregroundColor(.white)
            )
    }
}

