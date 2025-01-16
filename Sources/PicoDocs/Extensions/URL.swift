//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    
    /// Returns true if file is a directory
    var isDirectory: Bool {
        if (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            return true
        } else if let utType = UTType(filenameExtension: self.pathExtension) {
            return utType == .directory || utType == .folder
        } else {
            return false
        }
    }

    /// Returns true if the file is remote, e.g. on iCloud drive, and needs to be downloaded first from the cloud before being opened
    var isStoredOniCloud: Bool {
        get async throws {
            let resourceValues = try self.resourceValues(forKeys: [
                .isUbiquitousItemKey,
                .ubiquitousItemDownloadingStatusKey
            ])
            
            guard resourceValues.isUbiquitousItem == true else {
                return false // Not an iCloud file
            }
            
            return resourceValues.ubiquitousItemDownloadingStatus == .notDownloaded
        }
    }    
}
