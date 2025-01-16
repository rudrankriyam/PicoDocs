//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/5/24.
//

import Foundation
import UniformTypeIdentifiers
import PDFKit

public struct PDFParser: DocumentParserProtocol {
    
    let document: PDFDocument
    
    public init(content: PDFDocument) {
        self.document = content
    }
    
//    public func parseDocument() async throws -> ParsedDocument {
//        return try await parseDocument(to: .markdown)
//    }
    
    public func parseDocument(to format: ExportFileType? = nil) async throws -> ParsedDocument {
        
        let title = document.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        
        // Get attributed string
        let attributedString = NSMutableAttributedString("")
        for pageIndex in 0 ..< document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            if let a = page.attributedString {
                attributedString.append(a)
            }
        }
        
        let format = format ?? .markdown
        
        let content: String
        switch format {
        case .plaintext:
            guard let plaintext = document.string else {
                throw PicoDocsError.emptyDocument
            }
            content = plaintext
        case .html:
            content = try await attributedString.toHTML()
        case .markdown:
            content = attributedString.toMarkdown()
        case .csv:
            throw PicoDocsError.unableToExportToRequestedFormat
        case .xml:
            throw PicoDocsError.unableToExportToRequestedFormat
        }
        
        let parsed = ParsedDocument(
            title: title,
            needsChunking: true,
            content: [content]
        )
        return parsed
    }
}
