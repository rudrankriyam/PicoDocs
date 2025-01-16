//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation

struct PlainTextParser: DocumentParserProtocol {
    
    let content: String
    
    init(content: String) {
        self.content = content
    }
    
//    func parseDocument() async throws -> ParsedDocument {
//        return try await parseDocument(to: .plaintext)
//    }
    
    func parseDocument(to format: ExportFileType? = nil) async throws -> ParsedDocument {
        return ParsedDocument(title: nil, needsChunking: true, content: [content])        
    }
}
