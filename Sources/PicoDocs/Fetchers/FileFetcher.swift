//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers
import CoreXLSX

#if os(macOS)
import Foundation
#else
import Foundation
import XMLCoder
#endif

open class FileFetcher: FetcherProtocol {
    
    public let url: URL
    
    public required init(url: URL) {
        self.url = url
    }
    
    public func fetch(progressHandler: ((Progress) -> Void)? = nil) async throws -> (Data?, UTType?, [URL]?) {
        
        let fileManager = FileManager.default
        
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
        let fileManager = FileManager.default
        try fileManager.startDownloadingUbiquitousItem(at: self.url)
        
        await withCheckedContinuation { continuation in
            let query = NSMetadataQuery()
            query.predicate = NSPredicate(format: "%K == %@", NSMetadataItemURLKey, url as NSURL)
            query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
            
            NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidUpdate, object: query, queue: .main) { _ in
                query.disableUpdates()
                //                defer { query.enableUpdates() }
                
                guard let item = query.results.first as? NSMetadataItem else { return }
                
                // Report progress
                if let percentDownloaded = item.value(forAttribute: NSMetadataUbiquitousItemPercentDownloadedKey) as? Double {
                    let progress = Progress(totalUnitCount: 100)
                    progress.completedUnitCount = Int64(percentDownloaded)
                    progressHandler?(progress)
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
    /*
    #if os(macOS)
    private func handleEpub() throws -> (Data?, UTType?, [URL]?) {
        let fileManager = FileManager.default
        let tmpURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tmpURL, withIntermediateDirectories: true)
        try fileManager.unzipItem(at: url, to: tmpURL)
        
        // Original XMLDocument-based implementation
        let containerURL = tmpURL.appendingPathComponent("META-INF/container.xml")
        let containerData = try Data(contentsOf: containerURL)
        let containerXML = try XMLDocument(data: containerData)
        
        // 3. Get path to content.opf from container.xml
        guard let contentPath = containerXML.rootElement()?
            .elements(forName: "rootfiles")
            .first?
            .elements(forName: "rootfile")
            .first?
            .attribute(forName: "full-path")?
            .stringValue else {
            throw PicoDocsError.parsingError
        }
        
        // 4. Parse content.opf to get spine reading order
        let contentURL = tmpURL.appendingPathComponent(contentPath)
        let contentData = try Data(contentsOf: contentURL)
        let contentXML = try XMLDocument(data: contentData)
        
        // 5. Get manifest items
        var manifestItems: [String: URL] = [:]
        if let manifest = contentXML.rootElement()?.elements(forName: "manifest").first {
            for item in manifest.elements(forName: "item") ?? [] {
                if let id = item.attribute(forName: "id")?.stringValue,
                   let href = item.attribute(forName: "href")?.stringValue {
                    let itemURL = contentURL.deletingLastPathComponent().appendingPathComponent(href)
                    manifestItems[id] = itemURL
                }
            }
        }
        
        // 6. Get spine order
        var orderedFiles: [URL] = []
        if let spine = contentXML.rootElement()?.elements(forName: "spine").first {
            for itemref in spine.elements(forName: "itemref") ?? [] {
                if let idref = itemref.attribute(forName: "idref")?.stringValue,
                   let fileURL = manifestItems[idref] {
                    orderedFiles.append(fileURL)
                }
            }
        }
        return (nil, nil, orderedFiles)
    }
    #else
    private func handleEpub() throws -> (Data?, UTType?, [URL]?) {
        let fileManager = FileManager.default
        let tmpURL = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tmpURL, withIntermediateDirectories: true)
        try fileManager.unzipItem(at: url, to: tmpURL)
        
        // iOS XML parsing implementation using XMLCoder
        let containerURL = tmpURL.appendingPathComponent("META-INF/container.xml")
        let containerData = try Data(contentsOf: containerURL)
        let container = try XMLDecoder().decode(EPubContainer.self, from: containerData)
        
        guard let contentPath = container.rootfiles.first?.fullPath else {
            throw PicoDocsError.parsingError
        }
        
        let contentURL = tmpURL.appendingPathComponent(contentPath)
        let contentData = try Data(contentsOf: contentURL)
        let content = try XMLDecoder().decode(EPubContent.self, from: contentData)
        
        var orderedFiles: [URL] = []
        for spineItem in content.spine.itemrefs {
            if let file = content.manifest.items.first(where: { $0.id == spineItem.idref }) {
                let fileURL = contentURL.deletingLastPathComponent().appendingPathComponent(file.href)
                orderedFiles.append(fileURL)
            }
        }
        
        return (nil, nil, orderedFiles)
    }
    #endif
    
    
}

#if !os(macOS)
// Add these structures for iOS XML parsing
struct EPubContainer: Codable {
    let rootfiles: [Rootfile]
    
    enum CodingKeys: String, CodingKey {
        case rootfiles = "rootfiles"
    }
    
    struct Rootfile: Codable {
        let fullPath: String
        
        enum CodingKeys: String, CodingKey {
            case fullPath = "full-path"
        }
    }
}

struct EPubContent: Codable {
    let manifest: Manifest
    let spine: Spine
    
    struct Manifest: Codable {
        let items: [Item]
        
        struct Item: Codable {
            let id: String
            let href: String
        }
    }
    
    struct Spine: Codable {
        let itemrefs: [ItemRef]
        
        struct ItemRef: Codable {
            let idref: String
        }
    }
}
#endif
*/
