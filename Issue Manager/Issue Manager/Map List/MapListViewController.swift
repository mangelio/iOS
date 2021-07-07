// Created by Julian Dunskus

import UIKit
import Promise

final class MapListViewController: RefreshingTableViewController, InstantiableViewController {
	typealias Localization = L10n.MapList
	
	static let storyboardName = "Map List"
	
	@IBOutlet private var backToSiteListButton: UIBarButtonItem!
	
	var holder: MapHolder! {
		didSet { update() }
	}
	
	private var maps: [Map]! {
		didSet { tableView.reloadData() }
	}
	
	/// - note: only safe to unwrap when currently part of the controller hierarchy
	private var mainController: MainViewController? {
		splitViewController.map { $0 as! MainViewController } // if non-nil, always that type
	}
	
	override var isRefreshing: Bool {
		didSet {
			tableView.visibleCells.forEach { ($0 as! MapCell).isRefreshing = isRefreshing }
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		clearsSelectionOnViewWillAppear = false
		
		update()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		let mainController = self.mainController!
		if mainController.isCollapsed {
			if let selected = tableView.indexPathForSelectedRow {
				// coming back from selected map's sublist
				tableView.deselectRow(at: selected, animated: true)
			}
		} else if let selected = tableView.indexPathForSelectedRow {
			// not appearing for the first time
			if Repository.read(map(for: selected).hasChildren) {
				// coming back from selected map's sublist
				showOwnMap(in: mainController)
			} else {
				// appearing because split view was expanded to show list
			}
		} else {
			// appearing for the first time
			showOwnMap(in: mainController)
		}
		
		navigationItem.leftBarButtonItem = holder is ConstructionSite ? backToSiteListButton : nil
		
		super.viewWillAppear(animated)
	}
	
	/// set to true when encountering a site we've been removed from during refresh to avoid multiple alerts
	private var isAlreadyReturning = false
	override func doRefresh() -> Future<Void> {
		Client.shared.pullRemoteChanges(for: holder.constructionSiteID) { progress in
			DispatchQueue.main.async {
				self.syncProgress = progress
			}
		}
		.flatMapError { error in
			if case SyncError.siteAccessRemoved = error {
				self.isAlreadyReturning = true
				self.showAlert(
					titled: Localization.RemovedFromMap.title,
					message: Localization.RemovedFromMap.message,
					okMessage: Localization.RemovedFromMap.dismiss,
					okHandler: self.returnToSiteList
				)
				return .fulfilled
			} else {
				return .rejected(with: error)
			}
		}
	}
	
	override func refreshCompleted() {
		guard let mainController = mainController else { return } // dismissed in the meantime
		
		super.refreshCompleted()
		
		let isValid = handleRefresh()
		if isValid {
			if mainController.isExtended {
				mainController.detailNav.mapController.holder = holder
			}
		} else {
			if !isAlreadyReturning {
				showAlert(
					titled: Localization.MapRemoved.title,
					message: Localization.MapRemoved.message,
					okMessage: Localization.MapRemoved.dismiss,
					okHandler: returnToSiteList
				)
			}
		}
		
		for viewController in navigationController!.viewControllers where viewController !== self {
			(viewController as? MapListViewController)?.handleRefresh()
		}
	}
	
	private func returnToSiteList() {
		self.performSegue(withIdentifier: "back to site list", sender: self)
	}
	
	/// - returns: whether or not the holder is still valid
	@discardableResult private func handleRefresh() -> Bool {
		if
			let oldSite = holder as? ConstructionSite,
			let site = Repository.object(oldSite.id),
			!site.isDeleted
		{
			holder = site
			return true
		} else if
			let oldMap = holder as? Map,
			let map = Repository.object(oldMap.id),
			!map.isDeleted
		{
			holder = map
			return true
		} else {
			maps = []
			return false
		}
	}
	
	func update() {
		guard isViewLoaded, let holder = holder else { return }
		
		navigationItem.title = holder.name
		
		maps = Repository.read(
			holder.children
				.withoutDeleted
				.order(Map.Columns.name.asc)
				.fetchAll
		)
	}
	
	private func showOwnMap(in mainController: MainViewController) {
		// update shown map
		if mainController.isExtended {
			let mapController = mainController.detailNav.mapController
			if holder is Map {
				tableView.selectRow(at: [0, 0], animated: false, scrollPosition: .none)
			} else if let selected = tableView.indexPathForSelectedRow {
				tableView.deselectRow(at: selected, animated: true)
			}
			
			if holder.rawID != mapController.holder?.rawID {
				mapController.holder = holder
			}
		} else {
			showMapController(for: holder)
		}
	}
	
	func showMapController(for holder: MapHolder) {
		let mapController = MapViewController.instantiate()!
		mapController.holder = holder
		show(mapController, sender: self)
	}
	
	func showListController(for holder: MapHolder) {
		let listController = MapListViewController.instantiate()!
		listController.holder = holder
		show(listController, sender: self)
	}
	
	func map(for indexPath: IndexPath) -> Map {
		if indexPath.section == 0, let map = holder as? Map {
			return map
		} else {
			return maps[indexPath.row]
		}
	}
	
	/// reloads the cell for the given map, if currently visible
	func reload(_ map: Map) {
		for cell in tableView.visibleCells {
			let mapCell = cell as! MapCell
			if mapCell.map.id == map.id {
				mapCell.update()
			}
		}
	}
	
	// MARK: - Table View
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		holder is Map ? 2 : 1
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if holder is Map {
			return [Localization.Section.thisMap, Localization.Section.childMaps][section]
		} else {
			return Localization.Section.childMaps
		}
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if holder is Map {
			return [1, maps.count][section]
		} else {
			return maps.count
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		tableView.dequeue(MapCell.self, for: indexPath)! <- {
			if indexPath.section == 0, holder is Map {
				$0.shouldUseRecursiveIssues = false
			}
			$0.map = map(for: indexPath)
			$0.isRefreshing = isRefreshing
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		if indexPath == tableView.indexPathForSelectedRow {
			// already selected
			return nil
		} else {
			return indexPath
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let mainController = self.mainController!
		if indexPath.section == 0, holder is Map {
			showOwnMap(in: mainController)
		} else {
			let map = maps[indexPath.row]
			let mapHasChildren = Repository.read(map.hasChildren)
			
			if mainController.isExtended {
				let mapController = mainController.detailNav.mapController
				mapController.holder = map
				
				if mapHasChildren {
					showListController(for: map)
				}
			} else {
				if mapHasChildren {
					showListController(for: map)
				} else {
					showMapController(for: map)
				}
			}
		}
	}
}
