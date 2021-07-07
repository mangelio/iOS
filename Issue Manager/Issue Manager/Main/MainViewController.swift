// Created by Julian Dunskus

import UIKit

final class MainViewController: UISplitViewController, InstantiableViewController {
	static let storyboardName = "Main"
	
	var site: ConstructionSite! {
		didSet { masterNav.mapList.holder = site }
	}
	
	var masterNav: MasterNavigationController!
	var detailNav: DetailNavigationController!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		preferredDisplayMode = .allVisible
		
		masterNav = (viewControllers.first as! MasterNavigationController)
		detailNav = (viewControllers.last as! DetailNavigationController)
	}
	
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		
		coder.encode(site.id.rawValue, forKey: "siteID")
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		let siteID = ConstructionSite.ID(coder.decodeObject(of: NSString.self, forKey: "siteID")! as String)
		if let site = Repository.object(siteID) {
			self.site = site
			DispatchQueue.main.async {
				self.masterNav.mapList.refreshManually()
			}
		} else {
			// site to decode has been deleted; this can only really happen in dev environment
			children.forEach(unembed) // cancel loading actual content
			DispatchQueue.main.async { // not in parent quite yet
				self.dismiss(animated: false)
			}
		}
	}
}

final class MasterNavigationController: UINavigationController {
	var mapList: MapListViewController {
		topViewController as! MapListViewController
	}
	
	override var title: String? {
		get { return topViewController!.navigationItem.title }
		set {} // dummy
	}
	
	override func separateSecondaryViewController(for splitViewController: UISplitViewController) -> UIViewController? {
		assert(!(topViewController is DetailNavigationController))
		let mainController = splitViewController as! MainViewController
		let detailNav = mainController.detailNav!
		
		let mapController = topViewController as? MapViewController
			?? MapViewController.instantiate()!
		
		detailNav.pushViewController(mapController, animated: false) // auto-pops from self
		viewControllers = viewControllers // update own controllers in case top was popped off
		mapController.didMove(toParent: detailNav)
		
		return detailNav
	}
	
	override func collapseSecondaryViewController(_ secondaryViewController: UIViewController, for splitViewController: UISplitViewController) {
		let detailNav = secondaryViewController as! DetailNavigationController
		
		let mapController = detailNav.mapController
		detailNav.viewControllers = [] // can't pop root view controller explicitly
		mapController.didMove(toParent: nil)
		
		if mapController.holder is Map {
			// worth keeping around
			pushViewController(mapController, animated: true)
			mapController.didMove(toParent: self)
		}
	}
}

final class DetailNavigationController: UINavigationController, Reusable {
	var mapController: MapViewController {
		topViewController as! MapViewController
	}
}

extension UISplitViewController {
	/// whether or not the split view is extended, i.e. not collapsed, so both panes are visible
	var isExtended: Bool {
		!isCollapsed
	}
}
