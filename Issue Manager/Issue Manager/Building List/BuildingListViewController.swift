// Created by Julian Dunskus

import UIKit

fileprivate let refreshingCellAlpha: CGFloat = 0.25

class BuildingListViewController: UITableViewController, LoadedViewController {
	fileprivate typealias Localization = L10n.BuildingList
	
	static let storyboardID = "Building List"
	
	@IBOutlet var welcomeLabel: UILabel!
	@IBOutlet var clientModeSwitch: UISwitch!
	@IBOutlet var clientModeCell: UITableViewCell!
	@IBOutlet var buildingListView: UICollectionView!
	
	@IBAction func clientModeSwitched() {
		Client.shared.isInClientMode = clientModeSwitch.isOn
		Client.shared.saveShared()
		updateClientModeAppearance()
	}
	
	@objc func refresh(_ refresher: UIRefreshControl) {
		isRefreshing = true
		buildingListView.visibleCells.forEach { ($0 as! BuildingCell).isRefreshing = true }
		
		let result = Client.shared.read().on(.main)
		
		result.then {
			self.buildings = Array(Client.shared.storage.buildings.values)
		}
		result.always {
			refresher.endRefreshing()
			self.isRefreshing = false
			self.buildingListView.reloadData()
		}
		result.catch { error in
			switch error {
			case RequestError.communicationError:
				self.showAlert(titled: L10n.Alert.ConnectionIssues.title,
							   message: L10n.Alert.ConnectionIssues.message)
			default:
				self.showAlert(titled: L10n.Alert.UnknownSyncError.title,
							   message: L10n.Alert.UnknownSyncError.message)
			}
		}
	}
	
	var isRefreshing = false
	var buildings: [Building] = [] {
		didSet {
			buildings += buildings // TODO remove after testing
			buildings.sort {
				$0.name < $1.name // TODO use last opened date instead
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let user = Client.shared.user!
		welcomeLabel.text = Localization.welcome(user.givenName)
		
		clientModeSwitch.isOn = Client.shared.isInClientMode
		updateClientModeAppearance()
		
		buildings = Array(Client.shared.storage.buildings.values)
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		tableView.refreshControl = refreshControl
	}
	
	func updateClientModeAppearance() {
		clientModeCell.backgroundColor = Client.shared.backgroundColor
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return UITableViewAutomaticDimension
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
		return 100
	}
}

extension BuildingListViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return buildings.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeue(BuildingCell.self, for: indexPath)!
		
		let building = buildings[indexPath.item]
		cell.building = building
		cell.isRefreshing = isRefreshing
		
		return cell
	}
}

extension BuildingListViewController: UICollectionViewDelegateFlowLayout {}

extension Client {
	var backgroundColor: UIColor {
		return isInClientMode ? #colorLiteral(red: 1, green: 0.945, blue: 0.9, alpha: 1) : #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
	}
}
