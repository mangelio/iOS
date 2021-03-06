// Created by Julian Dunskus

import Foundation
import GRDB
import UserDefault

final class Repository {
	static let shared = Repository()
	
	static func read<Result>(_ block: (Database) throws -> Result) -> Result {
		shared.read(block)
	}
	
	static func object<Object>(_ id: Object.ID) -> Object? where Object: StoredObject {
		shared.object(id)
	}
	
	@UserDefault("repository.userID") private var userID: ConstructionManager.ID?
	
	private let dataStore: DatabaseDataStore
	
	init() {
		self.dataStore = try! DatabaseDataStore()
	}
	
	func signedIn(as manager: ConstructionManager) {
		guard manager.id != userID else { return } // nothing changed
		resetAllData()
		userID = manager.id
	}
	
	func resetAllData() {
		try! dataStore.dbPool.write { db in
			try Issue.deleteAll(db)
			try Map.deleteAll(db)
			try Craftsman.deleteAll(db)
			try ConstructionSite.deleteAll(db)
			try ConstructionManager.deleteAll(db)
		}
	}
	
	func read<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.read(block)
	}
	
	private func write<Result>(_ block: (Database) throws -> Result) -> Result {
		try! dataStore.dbPool.write(block)
	}
	
	func object<Object>(_ id: Object.ID) -> Object? where Object: StoredObject {
		read(id.get)
	}
	
	/// saves modifications to an issue
	func save(_ issue: Issue) {
		write(issue.save)
	}
	
	/// saves modifications to some columns of an issue
	func save(_ columns: [Issue.Columns], of issue: Issue) {
		write { try issue.update($0, columns: columns) }
	}
	
	func remove(_ issue: Issue) {
		let wasDeleted = write(issue.delete)
		assert(wasDeleted)
	}
	
	@discardableResult
	func ensureNotPresent(_ site: ConstructionSite) -> Bool {
		write(site.delete)
	}
	
	// MARK: -
	// MARK: Management
	
	func update<Object>(changing changedEntries: [Object]) where Object: StoredObject {
		write { db in
			// this may seem overcomplicated, but it's actually a significant (>2x) performance improvement over the naive version and massively reduces database operations thanks to `updateChanges`
			
			let previous = Dictionary(
				uniqueKeysWithValues: try Object
					.fetchAll(db, keys: changedEntries.map { $0.id })
					.map { ($0.id, $0) }
			)
			for object in changedEntries {
				if let old = previous[object.id] {
					try object.updateChanges(db, from: old)
				} else {
					try object.insert(db)
				}
			}
		}
	}
}

extension ObjectID: DefaultsValueConvertible {}
