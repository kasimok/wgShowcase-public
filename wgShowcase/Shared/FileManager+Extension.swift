// SPDX-License-Identifier: MIT
// Copyright © 2018-2021 WireGuard LLC. All Rights Reserved.

import Foundation
import os.log

extension FileManager {
    static var appGroupId: String? {
        #if os(iOS)
        let appGroupIdInfoDictionaryKey = "EXTENSION_GROUP_ID"
        #elseif os(macOS)
        let appGroupIdInfoDictionaryKey = "EXTENSION_GROUP_ID"
        #else
        #error("Unimplemented")
        #endif
        return Bundle.main.object(forInfoDictionaryKey: appGroupIdInfoDictionaryKey) as? String
    }
    private static var sharedFolderURL: URL? {
        guard let appGroupId = FileManager.appGroupId else {
            os_log("Cannot obtain app group ID from bundle", log: OSLog.default, type: .error)
            return nil
        }
        guard let sharedFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            wg_log(.error, message: "Cannot obtain shared folder URL")
            return nil
        }
        return sharedFolderURL
    }

    static var logFileURL: URL? {
        return sharedFolderURL?.appendingPathComponent("tunnel-log.bin")
    }

    static var networkExtensionLastErrorFileURL: URL? {
        return sharedFolderURL?.appendingPathComponent("last-error.txt")
    }

    static var loginHelperTimestampURL: URL? {
        return sharedFolderURL?.appendingPathComponent("login-helper-timestamp.bin")
    }

    static func deleteFile(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            return false
        }
        return true
    }
}
