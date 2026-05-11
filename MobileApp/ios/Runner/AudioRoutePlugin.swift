import AVFoundation
import Flutter
import UIKit

/// Native bridge that forces the iOS audio session output to the built-in
/// speaker for the voice-mode flow.
///
/// Why this is needed: `flutter_tts`'s `defaultToSpeaker` category option is
/// not honored on its own — `SFSpeechRecognizer` flips the route to the
/// receiver while listening, and AVSpeechSynthesizer's internal category
/// activation can reset the override right before audio starts. The only
/// reliable iOS API is `AVAudioSession.overrideOutputAudioPort(.speaker)`,
/// and it must be re-applied on every route change because changing the
/// category implicitly clears it.
///
/// Two-pronged approach:
///   1. `routeToSpeaker` method — Dart calls this before each speak() to
///      configure category + activate + override.
///   2. `routeChangeNotification` observer — auto-re-overrides whenever iOS
///      tries to drop us back to the receiver (e.g. after flutter_tts
///      internally re-applies its category during speak()).
class AudioRoutePlugin: NSObject, FlutterPlugin {
  static let channelName = "com.claimai/audio_route"

  private var forceSpeaker = false

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())
    let instance = AudioRoutePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    instance.installRouteChangeObserver()
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "routeToSpeaker":
      forceSpeaker = true
      routeToSpeaker(result: result)
    case "releaseSpeakerRoute":
      forceSpeaker = false
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func routeToSpeaker(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(
        .playAndRecord,
        mode: .default,
        options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP])
      try session.setActive(true, options: [])
      try session.overrideOutputAudioPort(.speaker)
      result(true)
    } catch {
      result(
        FlutterError(
          code: "audio_route_failed",
          message: error.localizedDescription,
          details: nil))
    }
  }

  private func installRouteChangeObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleRouteChange(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: nil)
  }

  @objc private func handleRouteChange(_ notification: Notification) {
    guard forceSpeaker else { return }
    let session = AVAudioSession.sharedInstance()
    let isOnReceiver = session.currentRoute.outputs.contains { output in
      output.portType == .builtInReceiver
    }
    if isOnReceiver {
      try? session.overrideOutputAudioPort(.speaker)
    }
  }
}
