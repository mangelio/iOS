// Created by Julian Dunskus

import UIKit
import CGeometry

fileprivate let shadowOpacity: Float = 0.2
fileprivate let shadowOffset = CGSize(width: 0, height: 6)
fileprivate let shadowRadius: CGFloat = 12

final class SiteCell: UICollectionViewCell, Reusable {
	fileprivate typealias Localization = L10n.SiteList.SiteSummary
	
	@IBOutlet private var imageView: UIImageView!
	@IBOutlet private var nameLabel: UILabel!
	@IBOutlet private var openIssuesLabel: UILabel!
	@IBOutlet private var totalIssuesLabel: UILabel!
	@IBOutlet private var issueBadge: IssueBadge!
	
	override var isHighlighted: Bool {
		didSet { updateAppearance() }
	}
	
	var isRefreshing = false {
		didSet {
			updateAppearance()
			isUserInteractionEnabled = !isRefreshing
		}
	}
	
	var site: ConstructionSite! {
		didSet { update() }
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		contentView.layer.cornerRadius = 8
		contentView.clipsToBounds = true
		layer.cornerRadius = 8
		
		updateAppearance()
	}
	
	func updateAppearance() {
		UIView.animate(withDuration: 0.1) {
			self.contentView.alpha = self.isRefreshing ? 1 / 4 : 1
			self.layer.shadowOpacity = self.isRefreshing ? shadowOpacity / 4 : shadowOpacity
			
			let isHighlighted = self.isHighlighted
			self.layer.shadowOffset = isHighlighted ? shadowOffset / 4 : shadowOffset
			self.layer.shadowRadius = isHighlighted ? shadowRadius / 4 : shadowRadius
			self.transform = isHighlighted ? .init(scaleX: 0.95, y: 0.95) : .identity
		}
	}
	
	func update() {
		updateImage()
		nameLabel.text = site.name
		
		issueBadge.holder = site
		
		let meta = site.meta // capture current site
		let issues = site.issues(recursively: true)
		// async because there could be a lot of issues (e.g. if we're calculating it for a whole site)
		DispatchQueue.global().async {
			let totalCount = Repository.read(issues.fetchCount)
			let openCount = Repository.read(issues.openIssues.fetchCount)
			DispatchQueue.main.async {
				guard self.site.meta == meta else { return }
				self.totalIssuesLabel.text = Localization.totalIssues(String(totalCount))
				self.openIssuesLabel.text = Localization.openIssues(String(openCount))
			}
		}
	}
	
	private var imageTimer: Timer?
	func updateImage() {
		imageTimer?.invalidate()
		if let imageURL = site.image.map(ConstructionSite.localURL(for:)) {
			if let image = UIImage(contentsOfFile: imageURL.path) {
				imageView.image = image
			} else {
				// because images may not be downloaded right away and we don't have a callback for that
				imageTimer = .scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
					self.updateImage()
				}
			}
		} else {
			imageView.image = nil
		}
	}
}
