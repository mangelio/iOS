// Created by Julian Dunskus

import UIKit
import Promise

final class SiteListViewController: RefreshingTableViewController, InstantiableViewController {
	fileprivate typealias Localization = L10n.SiteList
	
	static let storyboardName = "Site List"
	
	@IBOutlet private var welcomeLabel: UILabel!
	
	@IBOutlet private var siteListView: UICollectionView!
	@IBOutlet private var refreshHintLabel: UILabel!
	
	@IBOutlet private var clientModeCell: UITableViewCell!
	@IBOutlet private var clientModeSwitch: UISwitch!
	
	@IBOutlet private var fileProgressBar: UIProgressView!
	@IBOutlet private var fileProgressLabel: UILabel!
	
	@IBAction func clientModeSwitched() {
		Issue.isInClientMode = clientModeSwitch.isOn
		updateClientModeAppearance()
		siteListView.reloadData()
	}
	
	@IBAction func backToSiteList(_ segue: UIStoryboardSegue) {
		updateContent()
	}
	
	private var fileDownloadProgress = FileDownloadProgress.done {
		didSet {
			switch fileDownloadProgress {
			case .undetermined:
				fileProgressBar.progress = 0
				fileProgressLabel.text = Localization.FileProgress.indeterminate
			case .determined(let current, let total):
				fileProgressBar.progress = Float(current) / Float(total)
				fileProgressLabel.text = Localization.FileProgress.determinate(current, total)
			case .done:
				break
			}
			
			if (fileDownloadProgress == .done) != (oldValue == .done) {
				tableView.reloadData()
			}
		}
	}
	
	override var isRefreshing: Bool {
		didSet {
			siteListView.visibleCells
				.forEach { ($0 as! SiteCell).isRefreshing = isRefreshing }
		}
	}
	
	private var sites: [ConstructionSite] = [] {
		didSet {
			sites.sort {
				$0.name < $1.name // TODO: use last opened date instead
			}
			refreshHintLabel.isHidden = !sites.isEmpty
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = Client.shared.localUser!
		welcomeLabel.text = Localization.welcome(user.givenName ?? "")
		
		clientModeSwitch.isOn = Issue.isInClientMode
		updateClientModeAppearance()
		
		updateContent()
	}
	
	var needsRefresh = false
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		needsRefresh = true
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// have to wait because we're not presenting anything yet
		DispatchQueue.main.async {
			if self.needsRefresh, self.presentedViewController == nil {
				self.needsRefresh = false
				self.refreshManually()
			}
		}
	}
	
	override func doRefresh() -> Future<Void> {
		Client.shared.pullRemoteChanges { progress in
			DispatchQueue.main.async {
				self.syncProgress = progress
			}
		} onIssueImageProgress: { imageProgress in
			DispatchQueue.main.async {
				self.fileDownloadProgress = imageProgress
			}
		}
	}
	
	override func refreshCompleted() {
		super.refreshCompleted()
		
		updateContent()
	}
	
	private func updateContent() {
		sites = Repository.read(ConstructionSite.all().withoutDeleted.fetchAll) // TODO: order?
		siteListView.reloadData()
	}
	
	func updateClientModeAppearance() {
		let color = Issue.isInClientMode ? UIColor.clientMode : nil
		UIView.animate(withDuration: 0.1) {
			self.clientModeCell.backgroundColor = color
		}
		UINavigationBar.appearance().barTintColor = color
	}
	
	func showMapList(for site: ConstructionSite, animated: Bool = true) {
		let main = MainViewController.instantiate()!
		main.site = site
		
		if #available(iOS 13, *) {} else { // can't negate #available
			// iOS pre-13 is more strict about this, while on iOS 13+ it looks best as .currentContext
			main.modalPresentationStyle = .fullScreen
		}
		
		present(main, animated: animated)
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		UITableView.automaticDimension
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		3 + (fileDownloadProgress == .done ? 0 : 1)
	}
}

extension SiteListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		sites.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(SiteCell.self, for: indexPath)!
		
		cell.site = sites[indexPath.item]
		cell.isRefreshing = isRefreshing
		
		return cell
	}
}

extension SiteListViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let site = sites[indexPath.item]
		showMapList(for: site)
	}
}
