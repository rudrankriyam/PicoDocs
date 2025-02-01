//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers

#if os(macOS)
import Foundation
#else
import Foundation
#endif

open class FileFetcher: FetcherProtocol {
    
    public let url: URL
    
    public required init(url: URL) {
        self.url = url
    }
    
    public func fetch(progressHandler: ((Progress) -> Void)? = nil) async throws -> (Data?, UTType?, [URL]?) {
        
        // Check if file needs to be downloaded from the cloud first
        if try await self.url.isStoredOniCloud {
            try await downloadFromCloud(progressHandler: progressHandler)
        }
        
        if self.url.isDirectory {
            
            // url is a directory
            
            let files = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .isUbiquitousItemKey,
                    .nameKey,
                    .fileSizeKey
                ],
                options: [
                    .skipsHiddenFiles,
                ]
            )
            
            return (nil, nil, files)

        } else {
            
            // url is a file
            
            let data = try Data(contentsOf: self.url)
            let utType = UTType(filenameExtension: self.url.path())
            return (data, utType, nil)
        }
    }
    
    private func downloadFromCloud(progressHandler: ((Progress) -> Void)?) async throws {
        try FileManager.default.startDownloadingUbiquitousItem(at: self.url)
        
        await withCheckedContinuation { continuation in
            let query = NSMetadataQuery()
            query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemURLKey, url as NSURL)
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            
            NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: query, queue: .main) { [weak query, progressHandler] _ in
                guard let query = query else { return }
                query.disableUpdates()
                //                defer { query.enableUpdates() }
                
                guard let item = query.results.first as? NSMetadataItem else { return }
                
                // Report progress
                if let percentDownloaded = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double {
                    let progress = Progress(totalUnitCount: 100)
                    progress.completedUnitCount = Int64(percentDownloaded)
                    Task { @MainActor [progressHandler] in
                        progressHandler?(progress)
                    }
                    query.enableUpdates()
                }
                
                // Check if download is complete
                if item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                    query.stop()
                    continuation.resume()
                } else {
                    query.enableUpdates()
                }
            }
            
            query.start()
        }
    }
}
