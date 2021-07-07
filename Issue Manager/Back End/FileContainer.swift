// Created by Julian Dunskus

import Foundation
import Promise

private let manager = FileManager.default

/// can be deleted at any time, used for images that are no longer immediately in use (e.g. sites that have been deselected or from other accounts)
private let baseCacheURL = try! manager.url(
	for: .cachesDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

/// for images from all sites the user has access to
private let baseLocalURL = try! manager.url(
	for: .applicationSupportDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

/// to migrate data from previous installations
private let baseLegacyLocalURL = try! manager.url(
	for: .documentDirectory,
	in: .userDomainMask,
	appropriateFor: nil,
	create: true
)

func wipeDownloadedFiles() {
	[baseCacheURL, baseLocalURL]
		.compactMap { try? manager.contentsOfDirectory(at: $0, includingPropertiesForKeys: nil) }
		.joined()
		.forEach { try? manager.removeItem(at: $0) }
}

protocol FileContainer: StoredObject {
	static var pathPrefix: String { get }
	
	var file: File<Self>? { get }
}

private extension File {
	static var subpath: String {
		"files/\(Container.pathPrefix)"
	}
	
	var localFilename: String {
		urlPath.replacingOccurrences(of: "/", with: "#")
	}
}

/// limit max concurrent file downloads
/// (otherwise we start getting overrun with timeouts, though URLSession automatically limits concurrent connections per host)
private let downloadLimiter = ConcurrencyLimiter(label: "file download", maxConcurrency: 3)

enum FileDownloadProgress: Hashable {
	/// going through local files to figure out what's missing, but also already downloading if necessary
	case undetermined
	/// downloading missing files, `current` out of `total` done
	case determined(current: Int, total: Int)
	/// downloads complete
	case done
}

extension Issue {
	/// Since we're changing from the documents folder to the application support folder, we should make sure to take any issue images from the former that haven't been uploaded yet with us.
	static func moveLegacyFiles() {
		let legacy = baseLegacyLocalURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
		guard manager.fileExists(atPath: legacy.path) else { return }
		try! manager.createDirectory(
			at: baseLocalFolder.deletingLastPathComponent(),
			withIntermediateDirectories: true
		)
		print("migrating legacy files from \(legacy) to \(baseLocalFolder)")
		do {
			try manager.moveItem(at: legacy, to: baseLocalFolder)
		} catch {
			error.printDetails(context: "could not migrate legacy files!")
		}
	}
}

extension FileContainer {
	private static var baseCacheFolder: URL {
		baseCacheURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
	}
	
	static var baseLocalFolder: URL {
		baseLocalURL.appendingPathComponent(File<Self>.subpath, isDirectory: true)
	}
	
	private static func cacheURL(for file: File<Self>) -> URL {
		baseCacheFolder.appendingPathComponent(file.localFilename, isDirectory: false)
	}
	
	static func localURL(for file: File<Self>) -> URL {
		baseLocalFolder.appendingPathComponent(file.localFilename, isDirectory: false)
	}
	
	/// Identifies files in the local folder that are no longer actively needed (e.g. because their construction site is no longer selected for this user), and moves them to the caches folder.
	static func moveDisusedFiles(inUse: [Self]) {
		let allLocalFiles: Set<String>
		do {
			allLocalFiles = Set(try manager.contentsOfDirectory(atPath: baseLocalFolder.path))
		} catch {
			error.printDetails(context: "could not establish present files in \(baseLocalFolder)")
			return
		}
		
		let necessaryFiles = inUse.compactMap(\.file?.localFilename)
		let filesToMove = allLocalFiles.subtracting(necessaryFiles)
		
		// move all files that are no longer necessary to the caches folder
		try? manager.createDirectory(at: baseCacheFolder, withIntermediateDirectories: true, attributes: nil)
		for filename in filesToMove {
			let localURL = baseLocalFolder.appendingPathComponent(filename, isDirectory: false)
			let cacheURL = baseCacheFolder.appendingPathComponent(filename, isDirectory: false)
			do {
				try? manager.removeItem(at: cacheURL)
				try manager.moveItem(at: localURL, to: cacheURL)
			} catch {
				error.printDetails(context: "could not move local file at \(localURL) to \(cacheURL)")
			}
		}
	}
	
	static func downloadMissingFiles(
		onProgress: ((FileDownloadProgress) -> Void)? = nil
	) -> Future<Void> {
		onProgress?(.undetermined)
		
		let containers = Repository.shared.read(
			Self.order(Meta.Columns.lastChangeTime.desc)
				.withoutDeleted
				.fetchAll
		)
		
		moveDisusedFiles(inUse: containers)
		
		let futures = containers.compactMap { $0.downloadFile() }
		
		// this is much easier if we don't have to report progress
		guard let onProgress = onProgress else { return futures.sequence() }
		
		let total = futures.count
		var completed: Int32 = 0
		
		onProgress(.determined(current: 0, total: total))
		
		return futures
			.map {
				$0.map {
					OSAtomicIncrement32(&completed)
					onProgress(.determined(current: Int(completed), total: total))
				}
			}
			.sequence()
			.always { onProgress(.done) }
	}
	
	/// - returns: A `Future` that resolves when the file is downloaded, or `nil` if there's nothing to do.
	@discardableResult func downloadFile() -> Future<Void>? {
		guard let file = file else { return nil }
		
		// check if it already exists
		let url = Self.localURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return nil }
		
		// check if we already have it cached
		let cached = Self.cacheURL(for: file)
		if manager.fileExists(atPath: cached.path) {
			do {
				try manager.moveItem(at: cached, to: url)
				return nil
			} catch {
				error.printDetails(context: "could not restore local file at \(url) from cached file at \(cached)")
			}
		}
		
		return downloadLimiter.dispatch(_downloadFile)
	}
		
	private func _downloadFile() -> Future<Void> {
		// check again in case it's changed by now (defensive coding, i know…)
		guard let file = file else { return .fulfilled }
		let url = Self.localURL(for: file)
		guard !manager.fileExists(atPath: url.path) else { return .fulfilled }
		
		let debugDesc = "for \(Self.pathPrefix) (id \(id))"
		print("Downloading \(file)", debugDesc)
		
		return Client.shared.download(file)
			.map { data in
				try? manager.createDirectory(
					at: url.deletingLastPathComponent(),
					withIntermediateDirectories: true
				)
				let success = manager.createFile(atPath: url.path, contents: data)
				print(success ? "Saved file to" : "Could not save file to", url, debugDesc)
			}
			.catch { error in
				error.printDetails(context: "Could not download \(file) \(debugDesc)")
			}
	}
	
	func deleteFile() {
		guard let file = file else { return }
		try? manager.removeItem(at: Self.cacheURL(for: file))
		try? manager.removeItem(at: Self.localURL(for: file))
	}
}
