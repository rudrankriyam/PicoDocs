//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/15/25.
//

import Foundation
import UniformTypeIdentifiers
import EPUBKit
import SwiftSoup

public struct EPUBParser: DocumentParserProtocol {
    
    public let content: Data?
    public let url: URL?
    
    public init(content: Data?) {
        self.content = content
        self.url = nil
    }
    
    public init(url: URL?) {
        self.url = url
        self.content = nil
    }
    
    public func parseDocument(to format: ExportFileType?) async throws -> ParsedDocument {
        
        var document: EPUBDocument?
        if let content {
            document = EPUBDocument(data: content)
        } else if let url {
            document = EPUBDocument(url: url)
        }
        guard let document = document else {
            throw PicoDocsError.fileCorrupted
        }
        
        // Fetch metadata
        let title = document.title
        let author = document.author
        var cover: Data? = nil
        if let url = document.cover, let data = try? Data(contentsOf: url) {
            cover = data
        }
        
        // Fetch chapters
        let manifestItems = document.manifest.items
        let chapterItems = document.spine.items
        var chapters = [String]()
        for item in chapterItems {
            guard let path = manifestItems[item.idref]?.path else { continue }
            let url = document.contentDirectory.appendingPathComponent(path)
            do {
                let chapterContent = try Data(contentsOf: url)
                if let string = String(data: chapterContent, encoding: .utf8) {
                    chapters.append(string)
                }
            } catch {
                // Skip chapters that can't be read
                print(error.localizedDescription)
            }
        }
        
        // Use SwiftSoup to parse XHTML
        var swiftSoupDocuments = [Document]()
        for chapter in chapters {
            let document = try SwiftSoup.parse(chapter)
            swiftSoupDocuments.append(document)
        }
    
        var convertedChapters = [String]()
        let format = format ?? .markdown
        switch format {
        case .plaintext:
            
            for document in swiftSoupDocuments {
                if let text = try? document.text() {
                    convertedChapters.append(text)
                }
            }
            
        case .html:
            
            for document in swiftSoupDocuments {
                if let htmlDoc = try? SwiftSoup.Cleaner(headWhitelist: .basic(), bodyWhitelist: .relaxed()).clean(document).html() {
                    convertedChapters.append(htmlDoc)
                }
            }
            
        case .markdown:

            for document in swiftSoupDocuments {
                if let htmlDoc = try? SwiftSoup.Cleaner(headWhitelist: .basic(), bodyWhitelist: .relaxed()).clean(document).html(),
                   let htmlData = htmlDoc.data(using: .utf8),
                   let attributedString = try? NSAttributedString(
                     data: htmlData,
                     options: [.documentType: NSAttributedString.DocumentType.html],
                     documentAttributes: nil
                   ) {
                    convertedChapters.append(attributedString.toMarkdown())
                }
            }
            
        case .csv, .xml:
            throw PicoDocsError.unableToExportToRequestedFormat
        }
        
        return ParsedDocument(title: title, author: author, cover: cover, content: convertedChapters)
    }
}
