import Flutter
import UIKit
import Firebase
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurer Firebase
    FirebaseApp.configure()
    
    // Permettre aux plugins Flutter de s'enregistrer
    GeneratedPluginRegistrant.register(with: self)
    
    // Laisser flutter_local_notifications et firebase_messaging gérer l'enregistrement
    // de UNUserNotificationCenter. FlutterAppDelegate s'occupe de router les événements.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Gérer le token APNs
  override func application(_ application: UIApplication,
                            didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
    print("📱 APNs token enregistré")
    
    // CRITIQUE : Il faut impérativement appeler super pour que firebase_messaging 
    // côté Flutter reçoive le token APNs. Sinon les notifs échouent sur iOS 15/16.
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }
  
  // Gérer les erreurs d'enregistrement
  override func application(_ application: UIApplication,
                            didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print("❌ Erreur enregistrement APNs: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
