// ContentView.swift
import SwiftUI

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()

    var body: some View {
        VStack {
            Text("PostureMaxx")
                .padding(.top, 25)
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            ZStack {
                CameraPreview(cameraManager: cameraManager)
                    .cornerRadius(20)
                    .frame(width: 300, height: 500)
                    .padding(.bottom, 150)
                    
                

                VStack {

                    Spacer()
                    PostureStatusView(status: cameraManager.postureStatus)
                        .padding(.bottom, 50)
                }
            }

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .onAppear {
             print("ContentView appeared.")
        }
        .onDisappear {
            cameraManager.stopSession()
            print("ContentView disappeared.")
        }
    }
}


struct PostureStatusView: View {
    let status: PostureStatus

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(statusColor)
                .frame(width: 100, height: 100)
                .overlay(
                    Text(statusText)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(5)
                )
        }
    }

    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .bad:
            return .red
        case .notFound:
            return .gray
        }
    }

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





