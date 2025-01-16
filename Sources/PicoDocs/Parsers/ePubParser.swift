//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/15/25.
//

import Foundation
import UniformTypeIdentifiers

struct EPUBParser: DocumentParserProtocol {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    func parseDocument(to format: ExportFileType?) async throws -> ParsedDocument {
        return ParsedDocument(title: "", needsChunking: true, content: [])
    }
    
    // what we probably want to do is get the XML files and store them in a 
    
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
