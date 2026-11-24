import Flutter
import UIKit
import UserNotifications
import FirebaseAuth
import FirebaseCore

/// Thread-safe in-memory diagnostic recorder for iOS Phone Auth & APNs events.
final class PhoneAuthDiagnostics {
  static let shared = PhoneAuthDiagnostics()

  private let lock = NSLock()
  private let isoFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
  }()

  private var events: [String] = []
  private var apnsTokenData: Data?
  private var apnsTokenHexPrefix: String?
  private var apnsRegistrationError: String?
  private var apnsTokenTypeApplied: String = "none"
  private var remoteNotificationsReceivedCount: Int = 0
  private var authHandledNotificationCount: Int = 0
  private var urlsReceivedCount: Int = 0
  private var authHandledUrlCount: Int = 0
  private var firebaseConfiguredInAppDelegate: Bool = false

  private init() {}

  func record(_ message: String) {
    let line = "\(isoFormatter.string(from: Date())) | \(message)"
    lock.lock()
    events.append(line)
    if events.count > 100 {
      events.removeFirst(events.count - 100)
    }
    lock.unlock()
    print("[OpenFood-PhoneDiag] \(message)")
  }

  func setFirebaseConfiguredInAppDelegate(_ configured: Bool) {
    lock.lock()
    firebaseConfiguredInAppDelegate = configured
    lock.unlock()
  }

  func setApnsToken(_ data: Data, typeLabel: String) {
    let prefix = data.prefix(8).map { String(format: "%02x", $0) }.joined()
    lock.lock()
    apnsTokenData = data
    apnsTokenHexPrefix = prefix
    apnsTokenTypeApplied = typeLabel
    apnsRegistrationError = nil
    lock.unlock()
    record("APNs deviceToken received (len=\(data.count), prefix=\(prefix)..., type=\(typeLabel))")
  }

  func getApnsTokenData() -> Data? {
    lock.lock()
    let data = apnsTokenData
    lock.unlock()
    return data
  }

  func setApnsTokenTypeApplied(_ typeLabel: String) {
    lock.lock()
    apnsTokenTypeApplied = typeLabel
    lock.unlock()
  }

  func setApnsRegistrationError(_ errorText: String) {
    lock.lock()
    apnsRegistrationError = errorText
    lock.unlock()
    record("APNs registration failed: \(errorText)")
  }

  func recordRemoteNotification(handledByAuth: Bool) {
    lock.lock()
    remoteNotificationsReceivedCount += 1
    if handledByAuth {
      authHandledNotificationCount += 1
    }
    let total = remoteNotificationsReceivedCount
    let handled = authHandledNotificationCount
    lock.unlock()
    record("didReceiveRemoteNotification (total=\(total), authHandled=\(handled), thisHandled=\(handledByAuth))")
  }

  func recordUrlOpen(scheme: String, host: String, handledByAuth: Bool) {
    lock.lock()
    urlsReceivedCount += 1
    if handledByAuth {
      authHandledUrlCount += 1
    }
    let total = urlsReceivedCount
    let handled = authHandledUrlCount
    lock.unlock()
    record("openURL (scheme=\(scheme), host=\(host), total=\(total), authHandled=\(handled), thisHandled=\(handledByAuth))")
  }

  func snapshot(notificationAuthStatus: Int = -1) -> [String: Any] {
    let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] ?? []
    var urlSchemes: [String] = []
    for item in urlTypes {
      if let schemes = item["CFBundleURLSchemes"] as? [String] {
        urlSchemes.append(contentsOf: schemes)
      }
    }
    let backgroundModes = Bundle.main.infoDictionary?["UIBackgroundModes"] as? [String] ?? []
    let hasPlist = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil

    #if DEBUG
    let isDebugBuild = true
    #else
    let isDebugBuild = false
    #endif

    lock.lock()
    let snapshotEvents = events
    let tokenLength = apnsTokenData?.count ?? 0
    let hasToken = apnsTokenData != nil
    let tokenPrefix = apnsTokenHexPrefix ?? "nil"
    let regError = apnsRegistrationError ?? "none"
    let typeApplied = apnsTokenTypeApplied
    let notifTotal = remoteNotificationsReceivedCount
    let notifAuth = authHandledNotificationCount
    let urlTotal = urlsReceivedCount
    let urlAuth = authHandledUrlCount
    let configuredHere = firebaseConfiguredInAppDelegate
    lock.unlock()

    return [
      "platform": "iOS",
      "iosVersion": UIDevice.current.systemVersion,
      "deviceModel": UIDevice.current.model,
      "bundleId": Bundle.main.bundleIdentifier ?? "nil",
      "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "nil",
      "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "nil",
      "isDebugBuild": isDebugBuild,
      "hasGoogleServicePlistInBundle": hasPlist,
      "urlSchemes": urlSchemes,
      "backgroundModes": backgroundModes,
      "firebaseConfiguredInAppDelegate": configuredHere,
      "firebaseAppCount": FirebaseApp.allApps?.count ?? 0,
      "firebaseGoogleAppID": FirebaseApp.app()?.options.googleAppID ?? "nil",
      "firebaseProjectID": FirebaseApp.app()?.options.projectID ?? "nil",
      "isRegisteredForRemoteNotifications": UIApplication.shared.isRegisteredForRemoteNotifications,
      "notificationAuthStatus": notificationAuthStatus,
      "hasApnsToken": hasToken,
      "apnsTokenLength": tokenLength,
      "apnsTokenPrefix": tokenPrefix,
      "apnsTokenTypeApplied": typeApplied,
      "apnsRegistrationError": regError,
      "remoteNotificationsReceivedCount": notifTotal,
      "authHandledNotificationCount": notifAuth,
      "urlsReceivedCount": urlTotal,
      "authHandledUrlCount": urlAuth,
      "events": snapshotEvents,
    ]
  }
}

/// Scene-aware UI delegate for presenting reCAPTCHA SFSafariViewController on UIScene lifecycle apps.
final class OpenFoodAuthUIDelegate: NSObject, AuthUIDelegate {
  static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
    let keyWindow = activeScene?.windows.first(where: { $0.isKeyWindow }) ?? activeScene?.windows.first
    var current = keyWindow?.rootViewController
    while let presented = current?.presentedViewController {
      current = presented
    }
    if let nav = current as? UINavigationController {
      return nav.visibleViewController ?? nav
    }
    if let tab = current as? UITabBarController {
      return tab.selectedViewController ?? tab
    }
    return current
  }

  @objc(presentViewController:animated:completion:)
  func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
    DispatchQueue.main.async {
      guard let presenter = OpenFoodAuthUIDelegate.topViewController() else {
        PhoneAuthDiagnostics.shared.record("AuthUIDelegate.present: NO topViewController found")
        completion?()
        return
      }
      PhoneAuthDiagnostics.shared.record("AuthUIDelegate.present: presenting \(type(of: viewControllerToPresent)) from \(type(of: presenter))")
      presenter.present(viewControllerToPresent, animated: flag, completion: completion)
    }
  }

  @objc(dismissViewControllerAnimated:completion:)
  func dismiss(animated flag: Bool, completion: (() -> Void)?) {
    DispatchQueue.main.async {
      guard let top = OpenFoodAuthUIDelegate.topViewController() else {
        PhoneAuthDiagnostics.shared.record("AuthUIDelegate.dismiss: NO topViewController found")
        completion?()
        return
      }
      if top.presentingViewController != nil {
        PhoneAuthDiagnostics.shared.record("AuthUIDelegate.dismiss: dismissing \(type(of: top))")
        top.dismiss(animated: flag, completion: completion)
      } else {
        PhoneAuthDiagnostics.shared.record("AuthUIDelegate.dismiss: nothing presented to dismiss")
        completion?()
      }
    }
  }
}

private final class OnceReplyGuard {
  private let lock = NSLock()
  private var replied = false
  private let result: FlutterResult

  init(_ result: @escaping FlutterResult) {
    self.result = result
  }

  func send(_ payload: Any?) {
    DispatchQueue.main.async {
      self.lock.lock()
      let alreadyReplied = self.replied
      self.replied = true
      self.lock.unlock()
      if !alreadyReplied {
        self.result(payload)
      }
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // Retain strongly because PhoneAuthProvider holds uiDelegate weakly.
  private var activeAuthUIDelegate: OpenFoodAuthUIDelegate?
  private var diagChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let plistExists = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    PhoneAuthDiagnostics.shared.record("didFinishLaunchingWithOptions: GoogleService-Info.plist in bundle = \(plistExists)")

    if plistExists, (FirebaseApp.allApps?.isEmpty ?? true) {
      FirebaseApp.configure()
      PhoneAuthDiagnostics.shared.setFirebaseConfiguredInAppDelegate(true)
      PhoneAuthDiagnostics.shared.record("FirebaseApp.configure() succeeded in AppDelegate")
    } else if !plistExists {
      PhoneAuthDiagnostics.shared.record("WARNING: GoogleService-Info.plist missing from bundle in AppDelegate")
    } else {
      PhoneAuthDiagnostics.shared.record("FirebaseApp already initialized (count=\(FirebaseApp.allApps?.count ?? 0))")
    }

    application.registerForRemoteNotifications()
    PhoneAuthDiagnostics.shared.record("Called registerForRemoteNotifications()")
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    PhoneAuthDiagnostics.shared.setApnsToken(deviceToken, typeLabel: "unknown")
    if FirebaseApp.allApps?.isEmpty == false {
      Auth.auth().setAPNSToken(deviceToken, type: .unknown)
    } else {
      PhoneAuthDiagnostics.shared.record("WARNING: FirebaseApp.allApps empty during didRegisterForRemoteNotifications")
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let nsErr = error as NSError
    let formatted = "domain=\(nsErr.domain), code=\(nsErr.code), desc=\(nsErr.localizedDescription)"
    PhoneAuthDiagnostics.shared.setApnsRegistrationError(formatted)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    let scheme = url.scheme ?? "nil"
    let host = url.host ?? "nil"
    if FirebaseApp.allApps?.isEmpty == false, Auth.auth().canHandle(url) {
      PhoneAuthDiagnostics.shared.recordUrlOpen(scheme: scheme, host: host, handledByAuth: true)
      return true
    }
    PhoneAuthDiagnostics.shared.recordUrlOpen(scheme: scheme, host: host, handledByAuth: false)
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification notification: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if FirebaseApp.allApps?.isEmpty == false, Auth.auth().canHandleNotification(notification) {
      PhoneAuthDiagnostics.shared.recordRemoteNotification(handledByAuth: true)
      completionHandler(.noData)
      return
    }
    PhoneAuthDiagnostics.shared.recordRemoteNotification(handledByAuth: false)
    super.application(application, didReceiveRemoteNotification: notification, fetchCompletionHandler: completionHandler)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "openfood/phone_auth_diag",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    self.diagChannel = channel

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      let replyGuard = OnceReplyGuard(result)

      switch call.method {
      case "getNativeDiagnostics":
        UNUserNotificationCenter.current().getNotificationSettings { settings in
          let authRaw = settings.authorizationStatus.rawValue
          DispatchQueue.main.async {
            replyGuard.send(PhoneAuthDiagnostics.shared.snapshot(notificationAuthStatus: authRaw))
          }
        }

      case "reregisterAPNs":
        let args = call.arguments as? [String: Any]
        let requestedType = (args?["tokenType"] as? String) ?? "unknown"
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          if let token = PhoneAuthDiagnostics.shared.getApnsTokenData(),
             FirebaseApp.allApps?.isEmpty == false {
            let apnsType = AppDelegate.mapApnsTokenType(requestedType)
            Auth.auth().setAPNSToken(token, type: apnsType)
            PhoneAuthDiagnostics.shared.setApnsTokenTypeApplied(requestedType)
            PhoneAuthDiagnostics.shared.record("reregisterAPNs: re-applied cached token with type=\(requestedType)")
          } else {
            PhoneAuthDiagnostics.shared.record("reregisterAPNs: triggered registerForRemoteNotifications (cachedToken=\(PhoneAuthDiagnostics.shared.getApnsTokenData() != nil))")
          }
          UNUserNotificationCenter.current().getNotificationSettings { settings in
            let authRaw = settings.authorizationStatus.rawValue
            DispatchQueue.main.async {
              replyGuard.send(PhoneAuthDiagnostics.shared.snapshot(notificationAuthStatus: authRaw))
            }
          }
        }

      case "nativeVerifyPhoneNumber":
        guard let args = call.arguments as? [String: Any],
              let phoneNumber = args["phoneNumber"] as? String,
              !phoneNumber.isEmpty else {
          replyGuard.send([
            "success": false,
            "domain": "OpenFoodDiag",
            "code": -1,
            "message": "Missing phoneNumber argument for nativeVerifyPhoneNumber",
            "userInfo": "{}",
            "underlying": "none",
          ])
          return
        }

        let useSceneUIDelegate = (args["useSceneUIDelegate"] as? Bool) ?? true
        let requestedType = args["apnsTokenType"] as? String

        DispatchQueue.main.async {
          guard let strongSelf = self else {
            replyGuard.send(["success": false, "domain": "OpenFoodDiag", "code": -2, "message": "AppDelegate deallocated"])
            return
          }

          if FirebaseApp.allApps?.isEmpty ?? true {
            let plistExists = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
            if plistExists {
              FirebaseApp.configure()
              PhoneAuthDiagnostics.shared.record("nativeVerifyPhoneNumber: late FirebaseApp.configure() executed")
            } else {
              replyGuard.send([
                "success": false,
                "domain": "OpenFoodDiag",
                "code": -3,
                "message": "GoogleService-Info.plist missing from app bundle and FirebaseApp not initialized",
                "userInfo": "{}",
                "underlying": "none",
              ])
              return
            }
          }

          if let typeStr = requestedType,
             let token = PhoneAuthDiagnostics.shared.getApnsTokenData() {
            Auth.auth().setAPNSToken(token, type: AppDelegate.mapApnsTokenType(typeStr))
            PhoneAuthDiagnostics.shared.setApnsTokenTypeApplied(typeStr)
            PhoneAuthDiagnostics.shared.record("nativeVerifyPhoneNumber: applied APNs token type=\(typeStr)")
          }

          strongSelf.activeAuthUIDelegate = useSceneUIDelegate ? OpenFoodAuthUIDelegate() : nil
          PhoneAuthDiagnostics.shared.record("nativeVerifyPhoneNumber: invoking PhoneAuthProvider (useSceneUIDelegate=\(useSceneUIDelegate), apnsType=\(requestedType ?? "keep"))")

          PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: strongSelf.activeAuthUIDelegate) { verificationID, error in
            DispatchQueue.main.async {
              strongSelf.activeAuthUIDelegate = nil
              if let error = error {
                let nsErr = error as NSError
                var underlyingStr = "none"
                if let underlying = nsErr.userInfo[NSUnderlyingErrorKey] as? NSError {
                  underlyingStr = "domain=\(underlying.domain), code=\(underlying.code), desc=\(underlying.localizedDescription)"
                }
                var safeUserInfo: [String: String] = [:]
                for (k, v) in nsErr.userInfo {
                  let keyStr = String(describing: k)
                  safeUserInfo[keyStr] = String(describing: v)
                }
                PhoneAuthDiagnostics.shared.record("nativeVerifyPhoneNumber FAILED: domain=\(nsErr.domain) code=\(nsErr.code) msg=\(nsErr.localizedDescription) underlying=\(underlyingStr)")
                replyGuard.send([
                  "success": false,
                  "domain": nsErr.domain,
                  "code": nsErr.code,
                  "message": nsErr.localizedDescription,
                  "userInfo": String(describing: safeUserInfo),
                  "underlying": underlyingStr,
                ])
              } else {
                PhoneAuthDiagnostics.shared.record("nativeVerifyPhoneNumber SUCCEEDED (verificationId length=\(verificationID?.count ?? 0))")
                replyGuard.send([
                  "success": true,
                  "verificationId": verificationID ?? "",
                ])
              }
            }
          }
        }

      default:
        replyGuard.send(FlutterMethodNotImplemented)
      }
    }
  }

  private static func mapApnsTokenType(_ label: String) -> AuthAPNSTokenType {
    switch label.lowercased() {
    case "prod", "production":
      return .prod
    case "sandbox", "dev", "development":
      return .sandbox
    default:
      return .unknown
    }
  }
}
