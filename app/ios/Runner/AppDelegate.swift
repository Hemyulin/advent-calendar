import Flutter
import UIKit
import CoreMotion

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let tilt = TiltStreamHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterEventChannel(name: "advent_calendar/tilt", binaryMessenger: controller.binaryMessenger)
        .setStreamHandler(tilt)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Gravity from Core Motion fuses accelerometer/gyro data on device. No recording.
private final class TiltStreamHandler: NSObject, FlutterStreamHandler {
  private let motion = CMMotionManager()

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    guard motion.isDeviceMotionAvailable else {
      events(FlutterError(code: "NO_SENSOR", message: "Kein Bewegungssensor verfügbar", details: nil))
      return nil
    }
    motion.deviceMotionUpdateInterval = 1.0 / 50.0
    motion.startDeviceMotionUpdates(to: .main) { [weak self] sample, error in
      if error != nil {
        self?.motion.stopDeviceMotionUpdates()
        events(FlutterError(code: "SENSOR_UNAVAILABLE", message: "Bewegungssensor nicht verfügbar", details: nil))
        return
      }
      guard let g = sample?.gravity else { return }
      let orientation = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }.first(where: { $0.activationState == .foregroundActive })?.interfaceOrientation
      let values: [Double]
      switch orientation {
      case .landscapeLeft: values = [-g.y, -g.x]
      case .landscapeRight: values = [g.y, g.x]
      case .portraitUpsideDown: values = [-g.x, g.y]
      default: values = [g.x, -g.y]
      }
      events(values)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    motion.stopDeviceMotionUpdates()
    return nil
  }

  deinit { motion.stopDeviceMotionUpdates() }
}
