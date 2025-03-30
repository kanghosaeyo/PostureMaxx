# PostureMaxx

An iOS application developed during a 24-hour hackathon (Mar 2025) aimed at combating poor posture during prolonged periods of sitting by providing real-time feedback using the device's front camera. Poor posture can lead to various health issues, and this app serves as a tool to encourage healthier habits.

## Features

* **Real-Time Pose Estimation:** Utilizes the device's front camera (via AVFoundation) and Apple's Vision framework to detect human body pose in real-time.
* **Posture Analysis:** Analyzes key joint positions to determine posture status (Good / Bad / Body Not Found) based on calculated metrics like:
    * Neck Angle Deviation
    * Shoulder Slump (using normalization relative to shoulder span - experimental)
* **Visual Feedback:** Overlays the detected skeleton lines on the camera preview for visual understanding.
* **Status Indicator:** Displays the current posture status clearly on screen.
* **Temporal Smoothing:** Implements smoothing algorithms on detected joint data to reduce jitter and improve detection stability.
* **Configurable Alerts:** Provides immediate feedback via visual and audio alerts when poor posture is detected (haptic feedback can be added).

## Technology Stack

* **Language:** Swift
* **UI Framework:** SwiftUI
* **Core Technologies:**
    * **Vision Framework:** For Human Body Pose Estimation.
    * **AVFoundation:** For camera input stream management.
* **Algorithms:** Temporal smoothing for jitter reduction, angle calculations, ratio-based slump detection.

## Getting Started

### Prerequisites

* Xcode (latest version recommended)
* An iOS device with a front-facing camera (required for pose detection)
* Apple Developer Account (if running on a physical device)

### Installation & Running

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/your-github-username/PostureMaxx.git](https://www.google.com/search?q=https://github.com/your-github-username/PostureMaxx.git)
    cd PostureMaxx
    ```
    *(Replace with your actual repository URL)*
2.  **Open the project:** Open the `.xcodeproj` or `.xcworkspace` file in Xcode.
3.  **Configure Signing:** Select your developer account in the "Signing & Capabilities" tab for the project target.
4.  **Build & Run:** Select your connected iOS device or a simulator (camera feed will be simulated) and run the project (Cmd+R).
5.  **Permissions:** Grant camera permission when prompted by the app upon first launch. Notification permissions may also be requested for alerts.

## Usage

1.  Launch the PostureMaxx app.
2.  Grant necessary permissions (Camera is essential).
3.  Position your iOS device upright on a stable surface (e.g., leaning against your monitor or on a stand) so the front camera has a clear view of your upper body while seated.
4.  Observe the skeleton overlay and the posture status indicator.
5.  The app will provide alerts if it detects poor posture based on the implemented checks (neck angle, shoulder slump).
6.  (If implemented) Use the calibration feature to set your personal "good posture" baseline.

## Technical Details & Challenges

* **Real-time Performance:** Balancing the frame processing rate (`CameraManager` processing interval) with device performance was crucial.
* **Detection Stability:** Raw Vision pose data can be jittery. Temporal smoothing was implemented to average joint positions over recent frames, providing a more stable visual output and basis for analysis.
* **Normalization for Slump Detection:** Detecting shoulder slump reliably required normalization. Initial attempts using `.root` or `.leftHip`/`.rightHip` joints proved difficult due to inconsistent detection in seated positions. The current implementation uses the distance between shoulders as a normalization factor, which is an approximation and may require further tuning or alternative approaches for robustness across different body types and distances.

## Future Improvements

* More robust normalization techniques for posture metrics.
* Background operation mode.
* Additional posture checks (e.g., forward head posture).
* User-adjustable thresholds and alert settings.
* Posture history tracking and statistics.
* Refined calibration process.
* Haptic feedback implementation.
