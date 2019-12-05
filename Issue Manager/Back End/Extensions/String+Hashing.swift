// Created by Julian Dunskus

import Foundation
import CommonCrypto

extension Data {
	func sha256() -> Data {
		withUnsafeBytes { input in
			Data(count: Int(CC_SHA256_DIGEST_LENGTH)) <- { 
				$0.withUnsafeMutableBytes { output in
					_ = CC_SHA256(
						input.baseAddress!,
						CC_LONG(input.count),
						output.baseAddress!.assumingMemoryBound(to: UInt8.self)
					)
				}
			}
		}
	}
	
	func hexEncodedString() -> String {
		self
			.map { String(format: "%02x", $0) } // best way to get 0-padded hex string
			.joined()
	}
}

extension String {
	func sha256() -> String {
		data(using: .utf8)!.sha256().hexEncodedString()
	}
}
