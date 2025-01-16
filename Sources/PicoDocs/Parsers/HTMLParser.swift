//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation
import UniformTypeIdentifiers
import SwiftSoup

struct HTMLParser: DocumentParserProtocol {
    
    let url: URL
    
    init(url: URL) {
        self.url = url
    }

//    func parseDocument() async throws -> ParsedDocument {
//        return try await parseDocument(to: .html)
//    }
    
    func parseDocument(to format: ExportFileType?) async throws -> ParsedDocument {
        
        // Use Readability to clean up HTML and remove non-essential headers, footer, ads, etc
        let readability = await Readability(url: url)
        let readable = try await readability.parse()
        let title = readable.title
        
        // Clean HTML code of any unsafe code
        let cleanHTML: String
        if let htmlString = try? SwiftSoup.clean(readable.content, Whitelist.basic()) {
            cleanHTML = htmlString
        } else {
            cleanHTML = readable.content
        }
                
        // Convert HTML to attributed string
        guard let data = cleanHTML.data(using: .utf8),
              let attributedString = try? NSAttributedString(
                  data: data,
                  options: [.documentType: NSAttributedString.DocumentType.html],
                  documentAttributes: nil
              ) else {
            throw PicoDocsError.parsingError
        }

        let format = format ?? .html
        
        switch format {
        case .plaintext:
            return ParsedDocument(title: title, needsChunking: true, content: [attributedString.string])
        case .html:
            return ParsedDocument(title: title, needsChunking: true, content: [cleanHTML])
        case .xml:
            throw PicoDocsError.unableToExportToRequestedFormat            
        case .markdown:
            return try ParsedDocument(title: title, needsChunking: true, content: [attributedString.toMarkdown()])
        case .csv:
            throw PicoDocsError.unableToExportToRequestedFormat
        }
    }
    
    func parseContent(_ content: Data, url: URL) async throws -> (title: String, plaintext: String, pages: [String]?) {
        let readability = await Readability(url: url)
        let readable = try await readability.parse()
        let title = readable.title

        let plaintext: String
        if let htmlString = try? SwiftSoup.clean(readable.content, Whitelist.basic()) {
            plaintext = htmlString
        } else {
            plaintext = readable.content
        }
        return (title, plaintext, nil)
    }
}
