//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/13/25.
//

import Foundation

class iCloudFileMonitor {
    private let metadataQuery = NSMetadataQuery()
    
    func monitorFile(at url: URL) {
        metadataQuery.predicate = NSPredicate(format: "%K == %@",
            NSMetadataItemURLKey, url as NSURL)
        metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleQueryUpdate),
            name: .NSMetadataQueryDidUpdate,
            object: metadataQuery
        )
        
        metadataQuery.start()
    }
    
    @objc private func handleQueryUpdate(_ notification: Notification) {
        metadataQuery.disableUpdates()
        defer { metadataQuery.enableUpdates() }
        
        guard let item = metadataQuery.results.first as? NSMetadataItem else { return }
        
        let downloadProgress = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double ?? 0.0
        let isDownloaded = item.value(forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey) as? String == NSMetadataUbiquitousItemDownloadingStatusCurrent
        
        // Use the status information here
    }
}
