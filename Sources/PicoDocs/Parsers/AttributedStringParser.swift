//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation

struct AttributedStringParser: DocumentParserProtocol {
    
    let content: NSAttributedString
    
    init(content: NSAttributedString) {
        self.content = content
    }
    
//    func parseDocument() async throws -> ParsedDocument {
//        return try await parseDocument(to: .markdown)
//    }
    
    func parseDocument(to format: ExportFileType?) async throws -> ParsedDocument {
        
        let format = format ?? .markdown
        
        switch format {
        case .html:
            return try await ParsedDocument(
                title: nil,
                needsChunking: true,
                content: [content.toHTML()]
            )
        case .xml:
            throw PicoDocsError.unableToExportToRequestedFormat            
        case .markdown:
            return ParsedDocument(
                title: nil,
                needsChunking: true,
                content: [content.toMarkdown()]
            )
        case .plaintext:
            return ParsedDocument(
                title: nil,
                needsChunking: false,
                content: [content.string]
            )
        case .csv:
            throw PicoDocsError.unableToExportToRequestedFormat
        }
    }    
}
