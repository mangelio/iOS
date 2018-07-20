// Created by Julian Dunskus

import UIKit

fileprivate let markerSize = CGSize(width: 32, height: 32)

class IssueMarker: UIView {
	let issue: Issue
	
	var zoomScale: CGFloat = 1 {
		didSet {
			resize()
		}
	}
	
	var buttonAction: (() -> Void)!
	
	var isStatusShown = true {
		didSet {
			updateVisibility()
		}
	}
	
	private let button = UIButton()
	
	init(issue: Issue) {
		self.issue = issue
		
		super.init(frame: CGRect(origin: .zero, size: markerSize))
		autoresizingMask = [ // keep relative position during superview resize
			.flexibleTopMargin,
			.flexibleBottomMargin,
			.flexibleLeftMargin,
			.flexibleRightMargin,
		]
		
		addSubview(button)
		button.frame = self.bounds
		button.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError()
	}
	
	@objc func buttonPressed(_ sender: UIButton) {
		buttonAction()
	}
	
	func update() {
		button.setImage(issue.status.simplified.shadedIcon, for: .normal)
		updateVisibility()
		reposition()
	}
	
	func updateVisibility() {
		isHidden = !isStatusShown || issue.position == nil
	}
	
	private func resize() {
		// for some reason the size is rounded to nearest integer values anyway, but the view is off-center if that happens, so it's best to manually round it here.
		bounds.size = markerSize
			.map { max(round($0 / zoomScale), 1) }
	}
	
	private func reposition() {
		guard let position = issue.position else { return }
		
		center.x = CGFloat(position.x) * superview!.bounds.width
		center.y = CGFloat(position.y) * superview!.bounds.height
	}
}
