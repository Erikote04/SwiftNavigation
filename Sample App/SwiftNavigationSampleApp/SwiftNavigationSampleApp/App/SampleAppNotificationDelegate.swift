import Foundation
import UIKit
import UserNotifications

// MARK: - 5.3 Bridge UIKit (notificaciones): entrada externa hacia SwiftUI/AppCoordinator

final class SampleAppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // MARK: - 5.3.1 Registrar `UNUserNotificationCenterDelegate` al lanzar la app

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: - 5.3.2 Publicar evento interno para que `AppRootView` delegue en `AppCoordinator`

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        NotificationCenter.default.post(
            name: .sampleAppNotificationDeepLinkReceived,
            object: nil,
            userInfo: response.notification.request.content.userInfo
        )
        completionHandler()
    }
}
