// Created by Julian Dunskus

import Foundation
import GRDB

protocol MapHolder: AnyStoredObject {
	var name: String { get }
	var children: QueryInterfaceRequest<Map> { get }
	var constructionSiteID: ConstructionSite.ID { get }
	
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map
	var recursiveIssues: QueryInterfaceRequest<Issue> { get }
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue>
}

extension MapHolder {
	var recursiveIssues: QueryInterfaceRequest<Issue> {
		Issue
			.all()
			.withoutDeleted
			.consideringClientMode
			.joining(required: Issue.map.recursiveChildren(of: self))
	}
}

extension DerivableRequest where RowDecoder == Map {
	func recursiveChildren(of holder: MapHolder) -> Self {
		holder.recursiveChildren(in: self)
	}
}

extension ConstructionSite: MapHolder {
	var children: QueryInterfaceRequest<Map> { maps.filter(Map.Columns.parentID == nil) }
	
	var constructionSiteID: ID { id }
	
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map {
		request.filter(Map.Columns.constructionSiteID == id)
	}
	
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue> {
		precondition(recursively, "construction sites only have recursive issues")
		return recursiveIssues
	}
}

extension Map: MapHolder {
	func recursiveChildren<R>(in request: R) -> R where R: DerivableRequest, R.RowDecoder == Map {
		// recursive common table expression, in case you want to google that
		request.filter(
			literal: """
			\(sql: Map.databaseTableName).id IN (
				WITH rec_maps AS (
					SELECT \(rawID) AS id
					UNION ALL
					SELECT child.id
						FROM \(sql: Map.databaseTableName) child
						JOIN rec_maps parent ON child.parentID = parent.id
				)
				SELECT id FROM rec_maps
			)
			"""
		)
	}
	
	func issues(recursively: Bool) -> QueryInterfaceRequest<Issue> {
		recursively ? recursiveIssues : issues
	}
}
