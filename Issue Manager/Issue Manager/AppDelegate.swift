// Created by Julian Dunskus

import UIKit
import UserDefault

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
	static var shared: AppDelegate {
		UIApplication.shared.delegate as! Self
	}
	
	var window: UIWindow?
	
	let reachability = Reachability() <- {
		$0?.whenReachable = { _ in
			print("Reachable again! Trying to push any changes that weren't pushed earlier...")
			try? Client.shared.pushLocalChanges().await()
		}
	}
	
	func application(
		_ app: UIApplication,
		willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		window!.tintColor = .main
		
		// disables state restoration animations
		window!.isHidden = false
		
		wipeIfNecessary()
		
		Issue.moveLegacyFiles()
		
		return true
	}
	
	func application(
		_ app: UIApplication,
		open url: URL,
		options: [UIApplication.OpenURLOptionsKey: Any] = [:]
	) -> Bool {
		guard let link = DeepLink(from: url) else { return false }
		
		switch link {
		case .login(let loginInfo):
			let loginController = window!.rootViewController as! LoginViewController
			loginController.logIn(with: loginInfo)
		case .wipe:
			wipeAllDataThenExit()
		}
		
		return true
	}
	
	func wipeAllDataThenExit() {
		wipeAllData()
		
		dismissThenPerform {
			$0.showAlert(
				titled: L10n.Alert.Wiped.title,
				message: L10n.Alert.Wiped.message,
				okMessage: L10n.Alert.Wiped.quit
			) { exit(0) }
		}
	}
	
	func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool { true }
	
	func application(_ app: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
		Client.shared.localUser != nil && !Issue.isInClientMode
	}
	
	// MARK: - Wiping
	
	private static let wipeVersion = 2
	@UserDefault("lastWipeVersion")
	private static var lastWipeVersion: Int?
	
	private func wipeIfNecessary() {
		if Self.lastWipeVersion == nil, DatabaseDataStore.databaseFileExists() {
			print("setting missing last wipe version to 1 because a database was present")
			Self.lastWipeVersion = 1
		}
		
		if let lastWipe = Self.lastWipeVersion, lastWipe < Self.wipeVersion {
			print("last wipe version (\(lastWipe)) is older than current wipe version (\(Self.wipeVersion)).")
			wipeAllData()
			Self.lastWipeVersion = Self.wipeVersion
			
			dismissThenPerform {
				$0.showAlert(
					titled: L10n.Alert.UpgradeWiped.title,
					message: L10n.Alert.UpgradeWiped.message
				)
			}
		}
	}
	
	private func dismissThenPerform(_ block: @escaping (UIViewController) -> Void) {
		let loginController = window!.rootViewController!
		loginController.dismiss(animated: true) {
			block(loginController)
		}
	}
	
	private func wipeAllData() {
		print("wiping all data!")
		
		wipeDownloadedFiles()
		DatabaseDataStore.wipeData()
		Client.shared.wipeAllData()
	}
}
