// Created by Julian Dunskus

import Foundation
import Promise
import GRDB

private struct IssuePatchRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let httpMethod = "PATCH"
	static let contentType: String? = "application/merge-patch+json"
	
	var path: String
	let body: IssuePatch
}

extension Client {
	private static let issuePatchLimiter = ConcurrencyLimiter(label: "issue patch", maxConcurrency: 16)
	
	func pushLocalChanges() -> Future<Void> {
		pushChangesThen {}
	}
	
	func synchronouslyPushLocalChanges() throws {
		assertOnLinearQueue()
		let changesQuery = Issue.filter(Issue.Columns.patchIfChanged != nil)
		try Repository.shared.read(changesQuery.fetchAll)
			.traverse { issue in
				// TODO: I'm 99% sure this handles things concurrently, but I should check
				Self.issuePatchLimiter
					.dispatch { self.send(IssuePatchRequest(path: issue.apiPath, body: issue.patchIfChanged!)) }
					.map { Repository.shared.save($0.makeObject(context: issue.constructionSiteID)) }
			}
			.await()
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges() -> Future<Void> {
		pushChangesThen {
			try self.doPullRemoteChanges().await()
			Repository.shared.downloadMissingFiles()
		}
	}
	
	private func doPullRemoteChanges() -> Future<Void> {
		[
			doPullChangedObjects(existing: ConstructionManager.all(), context: ())
				.ignoringValue()
				.map { self.localUser = Repository.shared.object(self.localUser!.id) },
			doPullChangedObjects(existing: ConstructionSite.all(), context: ())
				.flatMap { $0.traverse(self.doPullRemoteChanges(for:)) }
		].sequence()
	}
	
	private func doPullChangedObjects<Object: StoredObject>(
		for site: ConstructionSite? = nil,
		existing: QueryInterfaceRequest<Object>,
		context: Object.Model.Context
	) -> Future<[Object]> {
		send(GetObjectsRequest<Object>(
			constructionSite: site?.id,
			minLastChangeTime: existing.maxLastChangeTime()
		))
		.map { $0.members.map { $0.makeObject(context: context) } }
		.map { $0 <- { Repository.shared.update(changing: $0) } }
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for siteID: ConstructionSite.ID) -> Future<Void> {
		pullRemoteChanges(for: Repository.shared.read(siteID.get)!)
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(for site: ConstructionSite) -> Future<Void> {
		pushChangesThen {
			try self.doPullRemoteChanges(for: site).await()
			Repository.shared.downloadMissingFiles()
		}
	}
	
	private func doPullRemoteChanges(for site: ConstructionSite) -> Future<Void> {
		[
			doPullChangedObjects(for: site, existing: site.maps, context: site.id)
				.ignoringValue(),
			doPullChangedObjects(for: site, existing: site.craftsmen, context: site.id)
				.ignoringValue(),
		]
		.sequence() // insert issues only after maps & craftsmen to keep intact foreign key constraints
		.flatMap { self.doPullChangedIssues(for: site) }
	}
	
	private func doPullChangedIssues(
		for site: ConstructionSite,
		itemsPerPage: Int = 100,
		prevLastChangeTime: Date? = nil
	) -> Future<Void> {
		// detect loops (making the same request multiple times) and respond by asking for larger pages
		let lastChangeTime = site.issues.maxLastChangeTime()
		let itemsPerPage = lastChangeTime != prevLastChangeTime ? itemsPerPage : itemsPerPage * 2
		
		return send(GetPagedObjectsRequest<APIIssue>(
			constructionSite: site.id,
			minLastChangeTime: lastChangeTime,
			itemsPerPage: itemsPerPage
		))
		.flatMap { collection in
			let issues = collection.members.map { $0.makeObject(context: site.id) }
			Repository.shared.update(changing: issues)
			
			return collection.view.nextPage == nil
				? .fulfilled
				: self.doPullChangedIssues(for: site, itemsPerPage: itemsPerPage, prevLastChangeTime: lastChangeTime)
		}
	}
}

private extension QueryInterfaceRequest where RowDecoder: StoredObject {
	func maxLastChangeTime() -> Date {
		Repository.shared.read(
			self
				.select(max(Issue.Meta.Columns.lastChangeTime), as: Date.self)
				.expectingSingleResult()
				.fetchOne
		) ?? .distantPast
	}
}
