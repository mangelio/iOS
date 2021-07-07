// Created by Julian Dunskus

import Foundation
import Promise
import GRDB

private struct IssuePatchRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let httpMethod = "PATCH"
	static let contentType: String? = "application/merge-patch+json"
	
	var path: String
	let body: APIIssuePatch
}

private struct IssueCreationRequest: JSONJSONRequest {
	typealias Response = APIObject<APIIssue>
	static let contentType: String? = "application/json"
	
	let path = Issue.apiPath
	let body: APIIssuePatch
}

private struct ImageUploadRequest: MultipartEncodingRequest {
	var path: String
	
	var fileURL: URL
	
	var parts: [MultipartPart] {
		MultipartPart(name: "image", content: .jpeg(at: fileURL))
	}
	
	init(issue: Issue, fileURL: URL) {
		self.path = "\(issue.apiPath)/image"
		self.fileURL = fileURL
	}
	
	func decode(from data: Data, using decoder: JSONDecoder) throws -> String {
		try String(bytes: data, encoding: .utf8)
			??? ImageUploadError.invalidPathResponse
	}
	
	enum ImageUploadError: Error {
		case invalidPathResponse
	}
}

private struct DeletionRequest: GetRequest, StatusCodeRequest {
	static var httpMethod: String { "DELETE" }
	
	var path: String
	
	init(for issue: Issue) {
		path = issue.apiPath
	}
	
	init(forImageOf issue: Issue) {
		path = "\(issue.apiPath)/image"
	}
}

extension Client {
	func pushLocalChanges() -> Future<Void> {
		pushChangesThen {}
	}
	
	func synchronouslyPushLocalChanges() -> [IssuePushError] {
		assertOnLinearQueue()
		
		let maxLastChangeTime = Issue.all().maxLastChangeTime()
		
		let issuesWithPatches = Issue
			.filter(Issue.Columns.patchIfChanged != nil)
			.order(Issue.Status.Columns.createdAt)
		let patchErrors = syncChanges(
			for: issuesWithPatches,
			stage: .patch
		) { issue in
			self.syncPatch(for: issue).map {
				Repository.shared.remove(issue) // remove non-canonical copy
				Repository.shared.save($0 <- {
					// keep local changes to image to sync next (this sets didChangeImage relative to remote image)
					$0.image = issue.image
					// fake older last change time to avoid skipping changes between last max change time and this upload
					$0.lastChangeTime = maxLastChangeTime
				})
			}
		}
		
		guard patchErrors.isEmpty else { return patchErrors }
		
		let imageErrors = syncChanges(
			for: Issue.filter(Issue.Columns.didChangeImage),
			stage: .imageUpload
		) { issue in
			self.syncImageChange(for: issue).map {
				Repository.shared.save(
					[.didChangeImage],
					of: issue <- { $0.didChangeImage = false }
				)
			}
		}
		
		let deletionErrors = syncChanges(
			for: Issue.filter(Issue.Columns.didDelete),
			stage: .deletion
		) { issue in
			self.send(DeletionRequest(for: issue)).map {
				Repository.shared.save(
					[.didDelete],
					of: issue <- { $0.didDelete = false }
				)
			}
		}
		
		return imageErrors + deletionErrors
	}
	
	private func syncPatch(for issue: Issue) -> Future<Issue> {
		let patch = issue.patchIfChanged!.makeModel()
		let canonical = issue.wasUploaded
			? send(IssuePatchRequest(path: issue.apiPath, body: patch))
			: send(IssueCreationRequest(body: patch))
		return canonical.map { $0.makeObject(context: issue.constructionSiteID) }
	}
	
	private func syncImageChange(for issue: Issue) -> Future<Void> {
		issue.image
			.map {
				send(ImageUploadRequest(issue: issue, fileURL: Issue.localURL(for: $0))).map { path in
					let image = File<Issue>(urlPath: path)
					Repository.shared.save([.image], of: issue <- { $0.image = image })
				}
			}
			?? send(DeletionRequest(forImageOf: issue))
	}
	
	private func syncChanges(
		for query: QueryInterfaceRequest<Issue>,
		stage: IssuePushError.Stage,
		performing upload: @escaping (Issue) -> Future<Void>
	) -> [IssuePushError] {
		// no concurrency to ensure correct ordering and avoid unforeseen issues
		Repository.shared.read(query.fetchAll).compactMap { issue in
			do {
				try upload(issue).await()
				return nil
			} catch {
				return IssuePushError(stage: stage, cause: error, issue: issue)
			}
		}
	}
}

struct IssuePushError: Error {
	var stage: Stage
	var cause: Error
	var issue: Issue
	
	enum Stage {
		case patch
		case imageUpload
		case deletion
	}
}

enum SyncProgress {
	case pushingLocalChanges
	case fetchingTopLevelObjects
	case pullingSiteData(ConstructionSite)
	case downloadingConstructionSiteFiles(FileDownloadProgress)
	case downloadingMapFiles(FileDownloadProgress)
}

extension Client {
	/// ensures local changes are pushed first
	func pullRemoteChanges(
		onProgress: ((SyncProgress) -> Void)? = nil,
		onIssueImageProgress: ((FileDownloadProgress) -> Void)? = nil
	) -> Future<Void> {
		sync(onProgress: onProgress, onIssueImageProgress: onIssueImageProgress) { onProgress in
			let sites = Repository.shared.read(ConstructionSite.fetchAll)
			for site in sites {
				onProgress?(.pullingSiteData(site))
				try self.doPullRemoteChanges(for: site).await()
			}
		}
	}
	
	/// ensures local changes are pushed first
	func pullRemoteChanges(
		for siteID: ConstructionSite.ID,
		onProgress: ((SyncProgress) -> Void)? = nil
	) -> Future<Void> {
		sync(onProgress: onProgress) { onProgress in
			guard let site = Repository.shared.read(siteID.get)
			else { throw SyncError.siteAccessRemoved }
			onProgress?(.pullingSiteData(site))
			try self.doPullRemoteChanges(for: site).await()
		}
	}
	
	private static let fileDownloadQueue = DispatchQueue(label: "missing file downloads")
	private func sync(
		onProgress: ((SyncProgress) -> Void)? = nil,
		onIssueImageProgress: ((FileDownloadProgress) -> Void)? = nil,
		running block: @escaping (((SyncProgress) -> Void)?) throws -> Void
	) -> Future<Void> {
		onProgress?(.pushingLocalChanges)
		return pushChangesThen {
			onProgress?(.fetchingTopLevelObjects)
			try self.doPullChangedTopLevelObjects().await()
			try block(onProgress)
			
			// download important files now
			try ConstructionSite.downloadMissingFiles(
				onProgress: onProgress.map { onProgress in
					{ onProgress(.downloadingConstructionSiteFiles($0)) }
				}
			).await()
			try Map.downloadMissingFiles(
				onProgress: onProgress.map { onProgress in
					{ onProgress(.downloadingMapFiles($0)) }
				}
			).await()
			
			// download issue images in the background
			Self.fileDownloadQueue.async {
				try? Issue.downloadMissingFiles(onProgress: onIssueImageProgress).await()
			}
		}
	}
	
	private func doPullChangedTopLevelObjects() -> Future<Void> {
		[
			doPullChangedObjects(existing: ConstructionManager.all(), context: ())
				.ignoringValue()
				.map { self.localUser = Repository.shared.object(self.localUser!.id) },
			doPullChangedObjects(existing: ConstructionSite.none(), context: ())
				// remove sites we don't have access to
				.map { $0
					.filter { !$0.managerIDs.contains(self.localUser!.id) }
					.forEach { Repository.shared.ensureNotPresent($0) }
				}
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
		.map { $0.makeObjects(context: context) }
		.map { $0 <- { Repository.shared.update(changing: $0) } }
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
		itemsPerPage: Int = 1000,
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
			let issues = collection.makeObjects(context: site.id)
			Repository.shared.update(changing: issues)
			
			return collection.view.nextPage == nil
				? .fulfilled
				: self.doPullChangedIssues(for: site, itemsPerPage: itemsPerPage, prevLastChangeTime: lastChangeTime)
		}
	}
}

enum SyncError: Error {
	case siteAccessRemoved
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
