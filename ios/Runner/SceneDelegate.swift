import Flutter
import UIKit
import FirebaseAuth
import FirebaseCore

class SceneDelegate: FlutterSceneDelegate {
  override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    for context in URLContexts {
      let url = context.url
      if FirebaseApp.allApps?.isEmpty == false, Auth.auth().canHandle(url) {
        return
      }
    }
    super.scene(scene, openURLContexts: URLContexts)
  }
}
