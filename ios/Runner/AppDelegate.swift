import BackgroundTasks
import Flutter
import Photos
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let storyShareChannel = "com.fittrace.app/story_share"
  private let backgroundSyncChannel = "com.fittrace.app/background_sync"
  private let notificationsChannel = "com.fittrace.app/notifications"
  private let bgSyncTaskIdentifier = "com.fittrace.app.garminSync"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(
        forTaskWithIdentifier: bgSyncTaskIdentifier,
        using: nil
      ) { [weak self] task in
        self?.handleAppRefresh(task: task as! BGAppRefreshTask)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: storyShareChannel,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleStoryShareCall(call: call, result: result)
    }

    let bgChannel = FlutterMethodChannel(
      name: backgroundSyncChannel,
      binaryMessenger: messenger
    )
    bgChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleBackgroundSyncCall(call: call, result: result)
    }

    let notifChannel = FlutterMethodChannel(
      name: notificationsChannel,
      binaryMessenger: messenger
    )
    notifChannel.setMethodCallHandler { [weak self] call, result in
      self?.handleNotificationCall(call: call, result: result)
    }
  }

  private func handleStoryShareCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isInstagramInstalled":
      guard let url = URL(string: "instagram-stories://share") else {
        result(false)
        return
      }
      result(UIApplication.shared.canOpenURL(url))

    case "shareToInstagramStory":
      guard let args = call.arguments as? [String: Any] else {
        result("failed")
        return
      }
      let appId = (args["appId"] as? String) ?? "com.fittrace.app"
      guard let url = URL(string: "instagram-stories://share?source_application=\(appId)"),
            UIApplication.shared.canOpenURL(url) else {
        result("not_installed")
        return
      }

      var pasteboardItems: [String: Any] = [:]
      if let bgPath = args["backgroundPath"] as? String,
         let bgData = try? Data(contentsOf: URL(fileURLWithPath: bgPath)) {
        pasteboardItems["com.instagram.sharedSticker.backgroundImage"] = bgData
      }
      if let stickerPath = args["stickerPath"] as? String,
         let stickerData = try? Data(contentsOf: URL(fileURLWithPath: stickerPath)) {
        pasteboardItems["com.instagram.sharedSticker.stickerImage"] = stickerData
      }
      if let topColor = args["topColorHex"] as? String {
        pasteboardItems["com.instagram.sharedSticker.backgroundTopColor"] = topColor
      }
      if let bottomColor = args["bottomColorHex"] as? String {
        pasteboardItems["com.instagram.sharedSticker.backgroundBottomColor"] = bottomColor
      }

      if pasteboardItems.isEmpty {
        result("failed")
        return
      }

      let options: [UIPasteboard.OptionsKey: Any] = [
        .expirationDate: Date().addingTimeInterval(300)
      ]
      UIPasteboard.general.setItems([pasteboardItems], options: options)
      UIApplication.shared.open(url, options: [:]) { opened in
        result(opened ? "launched" : "failed")
      }

    case "saveToGallery":
      guard let args = call.arguments as? [String: Any],
            let filePath = args["filePath"] as? String,
            let image = UIImage(contentsOfFile: filePath) else {
        result(FlutterError(code: "INVALID_ARGS", message: "File PNG tidak valid.", details: nil))
        return
      }

      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else {
          DispatchQueue.main.async {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Izin galeri ditolak.", details: nil))
          }
          return
        }
        PHPhotoLibrary.shared().performChanges({
          PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { success, error in
          DispatchQueue.main.async {
            if success {
              result("photos://saved")
            } else {
              result(FlutterError(code: "SAVE_FAILED", message: error?.localizedDescription ?? "Gagal simpan.", details: nil))
            }
          }
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleBackgroundSyncCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "schedulePeriodicSync",
          let args = call.arguments as? [String: Any] else {
      result(FlutterMethodNotImplemented)
      return
    }

    let enabled = (args["enabled"] as? Bool) ?? false
    let intervalMinutes = max(15, (args["intervalMinutes"] as? Int) ?? 15)
    scheduleIosAppRefresh(enabled: enabled, intervalMinutes: intervalMinutes)
    result(true)
  }

  private func scheduleIosAppRefresh(enabled: Bool, intervalMinutes: Int) {
    guard #available(iOS 13.0, *) else { return }
    BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: bgSyncTaskIdentifier)
    guard enabled else { return }

    let request = BGAppRefreshTaskRequest(identifier: bgSyncTaskIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: TimeInterval(intervalMinutes * 60))
    try? BGTaskScheduler.shared.submit(request)
  }

  @available(iOS 13.0, *)
  private func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleIosAppRefresh(enabled: true, intervalMinutes: 15)
    let workerEngine = FlutterEngine(name: "fittrace_bg_sync", project: nil, allowHeadlessExecution: true)
    workerEngine.run(withEntrypoint: "backgroundSyncMain")

    let channel = FlutterMethodChannel(
      name: "com.fittrace.app/background_sync_worker",
      binaryMessenger: workerEngine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "complete" {
        let ok = ((call.arguments as? [String: Any])?["success"] as? Bool) ?? true
        result(true)
        workerEngine.destroyContext()
        task.setTaskCompleted(success: ok)
      }
    }

    task.expirationHandler = {
      workerEngine.destroyContext()
      task.setTaskCompleted(success: false)
    }
  }

  private func handleNotificationCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "showBackupReminder",
          let args = call.arguments as? [String: Any] else {
      result(FlutterMethodNotImplemented)
      return
    }
    let title = (args["title"] as? String) ?? "Backup FitTrace"
    let body = (args["body"] as? String) ?? "Sudah > 30 hari sejak backup terakhir."

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let request = UNNotificationRequest(
      identifier: "fittrace_monthly_backup_reminder",
      content: content,
      trigger: trigger
    )
    UNUserNotificationCenter.current().add(request) { error in
      DispatchQueue.main.async {
        result(error == nil)
      }
    }
  }
}
