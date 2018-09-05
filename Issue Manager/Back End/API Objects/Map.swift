// Created by Julian Dunskus

import Foundation

final class Map: APIObject {
	let meta: ObjectMeta<Map>
	let children: [ID<Map>]
	var issues: [ID<Issue>]
	let filename: String?
	let name: String
	let buildingID: ID<Building>
}

extension Map: FileContainer {
	static let pathPrefix = "map"
	static let downloadRequestPath = \FileDownloadRequest.map
}

extension Map: MapHolder {
	func recursiveChildren() -> [Map] {
		return [self] + childMaps().flatMap { $0.recursiveChildren() }
	}
}

extension Map {
	func allIssues() -> [Issue] {
		if defaults.isInClientMode {
			return issues.lazy
				.compactMap { Client.shared.storage.issues[$0] }
				.filter { $0.wasAddedWithClient }
		} else {
			return issues.compactMap { Client.shared.storage.issues[$0] }
		}
	}
	
	func accessBuilding() -> Building {
		return Client.shared.storage.buildings[buildingID]!
	}
}
