import Flutter
import UIKit
import FirebaseAuth
import FirebaseCore

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      let url = context.url
      let scheme = url.scheme ?? "nil"
      let host = url.host ?? "nil"
      if FirebaseApp.allApps?.isEmpty == false, Auth.auth().canHandle(url) {
        PhoneAuthDiagnostics.shared.recordUrlOpen(scheme: scheme, host: host, handledByAuth: true)
        return
      }
      PhoneAuthDiagnostics.shared.recordUrlOpen(scheme: scheme, host: host, handledByAuth: false)
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
