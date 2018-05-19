// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import UIKit
import WebRTC
import UserNotifications

class AppDelegate: UIResponder, UIApplicationDelegate {

    let ChatSertificateName = "token"
    let toshiChatServiceBaseURL = "TokenChatServiceBaseURL"

    var window: UIWindow?

    private var screenProtectionActivated = false

    private lazy var screenProtectionWindow: UIWindow = {
        let window = UIWindow()
        window.isHidden = true
        window.backgroundColor = .clear

        window.isUserInteractionEnabled = false
        window.windowLevel = CGFloat.greatestFiniteMagnitude
        window.alpha = 0

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        window.addSubview(effectView)

        effectView.edgesToSuperview()

        return window
    }()

    var token = "" {
        didSet {
            updateRemoteNotificationsCredentials()
        }
    }

    var isFirstLaunch: Bool {
        return !UserDefaultsWrapper.launchedBefore
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if let toshiChatServiceBaseURL = Bundle.main.object(forInfoDictionaryKey: toshiChatServiceBaseURL) as? String {

            OWSSignalService.setBaseURLPath(toshiChatServiceBaseURL)
            OWSHTTPSecurityPolicy.setCertificateServiceName(ChatSertificateName)

        } else {
            assertionFailure("Can't load token chat service base url from main bundle")
        }

        APIKeysManager.setup()

        Theme.setupBasicAppearance()

        UIApplication.shared.applicationIconBadgeNumber = 0

        if !Yap.isUserDatabaseFileAccessible && !Yap.isUserDatabasePasswordAccessible {
            configureAndPresentWindow()
            return true
        }

        guard UIApplication.shared.applicationState != .background else { return true }

        if tryToOpenDB() {
            configureForCurrentSession()
        } else {
            // There might be a case when filesystem state is weird and it doesn't return true results, saying file is not present even if it is.
            // to determine this we might check keychain for database password being there
            // in this case we want to wait a bit and try to open file again
            // if it still fails - both password and database file, whatever is present in Yap, is deleted and splash is presented

            DispatchQueue.main.asyncAfter(seconds: 3, execute: {

                if self.tryToOpenDB() {
                    self.configureForCurrentSession()
                } else {
                    Yap.sharedInstance.processInconsistencyError()
                    self.configureAndPresentWindow()
                }
            })
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Send screen protection deactivation to the main queue
        // to avoid some weird UIKit issue where due to the queue difference, some racing conditions may apply
        // leaving the app with a protection screen when it shouldn't have any.
        DispatchQueue.main.async {
            self.activateScreenProtection()
        }

        guard TSAccountManager.isRegistered() else { return }

        // We need to close open socket while in background to not run expensive process
        // since we need the app to awake in background when PN received
        TSSocketManager.requestSocketClosed()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Send screen protection activation to the main queue
        // to avoid some weird UIKit issue where app is going inactive during the launch process
        // and back to active again. Due to the queue difference, some racing conditions may apply
        // leaving the app with a protection screen when it shouldn't have any.
        DispatchQueue.main.async {
            self.deactivateScreenProtection()
        }

        if TSAccountManager.isRegistered() {
            TSSocketManager.requestSocketOpen()
        }

        TSPreKeyManager.checkPreKeysIfNecessary()
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any] = [:]) -> Bool {

        guard url.scheme == "toshi" else { return false }

        Navigator.tabbarController?.openDeepLinkURL(url)

        return true
    }

    func didSignInUser() {
        setupDB()
        Navigator.tabbarController?.setupControllers()
    }

    private func configureAndPresentWindow() {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = Theme.viewBackgroundColor

        let tabbarController = TabBarController()
        window?.rootViewController = tabbarController
        window?.makeKeyAndVisible()

        if !Yap.isUserDatabaseFileAccessible || !Yap.isUserDatabasePasswordAccessible {
            presentSplash()
        } else {
            tabbarController.setupControllers()
        }
    }

    private func presentSplash() {
        let imageView = UIImageView(image: ImageAsset.launch_screen)
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        window?.addSubview(imageView)

        let splashNavigationController = SplashNavigationController()
        window?.rootViewController?.present(splashNavigationController, animated: false, completion: {
            imageView.removeFromSuperview()
        })
    }

    private func configureForCurrentSession() {
        configureAndPresentWindow()
        SignalNotificationManager.updateUnreadMessagesNumber()

        PrekeyHandler.tryRetrievingPrekeys()
    }

    private func tryToOpenDB() -> Bool {
        if Yap.isUserDatabaseFileAccessible && Yap.isUserDatabasePasswordAccessible {
            Profile.retrieveCurrentUser()
            setupDB()

            return true
        }

        CrashlyticsLogger.log(Yap.inconsistentStateDescription)

        return false
    }

    func setupDB() {
        setupTSKitEnvironment()
        setupSignalService()

        NotificationCenter.default.post(name: .ChatDatabaseCreated, object: nil)
    }

    private func setupTSKitEnvironment() {
        ALog("Setting up Signal KIT environment")

        // ensure this is called from main queue for the first time
        // otherwise app crashes, because of some code path differences between
        // us and Signal app.
        OWSSignalService.sharedInstance()

        let storageManager = TSStorageManager.shared()
        storageManager.setup(forAccountName: Cereal.shared.address, isFirstLaunch: isFirstLaunch)

        if storageManager.database() == nil {
            CrashlyticsLogger.log("Failed to create chat databse for the user")
        }

        SessionManager.shared.setupSecureEnvironment()
        UserDefaultsWrapper.launchedBefore = true
    }

    private func setupSignalService() {
        // Encryption/Decryption mutates session state and must be synchronized on a serial queue.

        SessionCipher.setSessionCipherDispatchQueue(OWSDispatch.sessionStoreQueue())

        CrashlyticsClient.setupForUser(with: Cereal.shared.address)
        
        let hashedUserID = CryptoTools.hash(withSha256: Cereal.shared.address)
        Amplitude.instance().setUserId(hashedUserID)

        TSSocketManager.requestSocketOpen()
        RTCInitializeSSL()

        registerForRemoteNotifications()
    }

    private func registerForRemoteNotifications() {
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: authOptions) { _, error in

            guard error == nil else {
                let message = "Failed to request user notifications authorization"
                assertionFailure(message)
                CrashlyticsLogger.log(message)
                return
            }

            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        // We need to make sure completion handler is called within 30 seconds after notification is received
        DispatchQueue.main.asyncAfter(seconds: 20, execute: {
            completionHandler(.newData)
        })

        SessionManager.shared.messageFetcherJob?.run()
    }

    private func updateRemoteNotificationsCredentials() {

        ALog("\n||--------------------\n||\n|| --- Account is registered:\(TSAccountManager.isRegistered()) \n||\n||--------------------\n\n")

        TSAccountManager.sharedInstance().registerForPushNotifications(pushToken: token, voipToken: nil, success: { [weak self] in

            guard let strongSelf = self else { return }

            ALog("\n\n||------- \n||\n|| - TOKEN: chat PN register - SUCCESS: token: \(strongSelf.token) \n")

            EthereumAPIClient.shared.registerForMainNetworkPushNotifications()
            EthereumAPIClient.shared.registerForSwitchedNetworkPushNotificationsIfNeeded()

            }, failure: { error in

                ALog("\n\n||------- \n|| - TOKEN: chat PN register - FAILURE: \(error.localizedDescription) \n||------- \n")

                CrashlyticsLogger.log("Failed to register for PNs", attributes: ["error": error.localizedDescription])
        })
    }

    // Screen protection

    private func activateScreenProtection() {

        guard screenProtectionActivated == false else { return }

        screenProtectionActivated = true

        UIView.animate(withDuration: 0.3, animations: {
            self.screenProtectionWindow.alpha = 1
        }, completion: { _ in
            self.screenProtectionWindow.isHidden = false
        })
    }

    private func deactivateScreenProtection() {
        guard screenProtectionActivated else { return }

        screenProtectionActivated = false

        UIView.animate(withDuration: 0.3, animations: {
            self.screenProtectionWindow.alpha = 0
        }, completion: { _ in
            self.screenProtectionWindow.isHidden = true
        })
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

        BackgroundNotificationHandler.handle(notification) { options in
            completionHandler(options)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.content.threadIdentifier
        Navigator.navigate(to: identifier, animated: true)

        completionHandler()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        token = deviceToken.hexadecimalString
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        ALog("Failed to register for remote notifications. \(error)")
    }
}
