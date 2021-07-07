// Created by Julian Dunskus

import UIKit
import Promise
import ArrayBuilder

class RefreshingTableViewController: UITableViewController {
	var isRefreshing = false
	
	var syncProgress: SyncProgress? {
		didSet {
			refreshControl!.attributedTitle = (syncProgress?.localizedDescription)
				.map(NSAttributedString.init(string:))
		}
	}
	
	@objc final func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		
		let result = doRefresh().on(.main)
		
		result.always {
			refresher.endRefreshing()
			self.isRefreshing = false
		}
		result.then {
			self.refreshCompleted()
		}
		result.catch(showAlert)
	}
	
	func doRefresh() -> Future<Void> {
		Client.shared.pullRemoteChanges()
	}
	
	private func showAlert(for error: Error) {
		typealias Alert = L10n.Alert
		switch error {
		case RequestError.communicationError:
			self.showAlert(
				titled: Alert.ConnectionIssues.title,
				message: Alert.ConnectionIssues.message
			)
		case RequestError.notAuthenticated:
			self.showAlert(
				titled: Alert.InvalidSession.title,
				message: Alert.InvalidSession.message
			) { self.performSegue(withIdentifier: "log out", sender: self) }
		case RequestError.pushFailed(let errors):
			showAlertWithDetails(
				for: error,
				title: Alert.PushFailed.title,
				message: Alert.PushFailed.message(
					errors
						.map(\.quickIssueIdentifier)
						.map { "• \($0)" }
						.joined(separator: "\n")
				)
			)
		default:
			print("refresh error!")
			dump(error)
			showAlertWithDetails(
				for: error,
				title: Alert.UnknownSyncError.title,
				message: Alert.UnknownSyncError.message
			)
		}
	}
	
	private func showAlertWithDetails(for error: Error, title: String, message: String? = nil) {
		self.presentOnTop(UIAlertController(
			title: title,
			message: message,
			preferredStyle: .alert
		) <- {
			$0.addAction(UIAlertAction(title: L10n.Alert.moreInfo, style: .default) { _ in
				let navController = ErrorViewerNavigationController.instantiate()!
				navController.errorViewerController.error = error
				self.presentOnTop(navController)
			})
			$0.addAction(UIAlertAction(title: L10n.Alert.okay, style: .cancel))
		})
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.refreshControl = UIRefreshControl() <- {
			$0.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		}
	}
	
	func refreshCompleted() {}
	
	func refreshManually() {
		let refresher = self.tableView.refreshControl!
		refresher.beginRefreshing()
		self.refresh(refresher)
		self.tableView.scrollRectToVisible(refresher.bounds, animated: true)
	}
}

private extension SyncProgress {
	private typealias L = L10n.Sync.Progress
	
	var localizedDescription: String {
		switch self {
		case .pushingLocalChanges:
			return L.pushingLocalChanges
		case .fetchingTopLevelObjects:
			return L.fetchingTopLevelObjects
		case .pullingSiteData(let site):
			return L.pullingSiteData(site.name)
		case .downloadingConstructionSiteFiles(let progress):
			return L.downloadingConstructionSiteFiles(progress.localizedDescription)
		case .downloadingMapFiles(let progress):
			return L.downloadingMapFiles(progress.localizedDescription)
		}
	}
}

private extension FileDownloadProgress {
	private typealias L = L10n.Sync.Progress.FileProgress
	
	var localizedDescription: String {
		switch self {
		case .undetermined:
			return L.indeterminate
		case .determined(let current, let total):
			return L.determinate(current, total)
		case .done:
			return L.done
		}
	}
}
