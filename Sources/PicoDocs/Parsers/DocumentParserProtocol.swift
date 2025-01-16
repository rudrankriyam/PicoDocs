//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/5/24.
//

import Foundation
import UniformTypeIdentifiers

public protocol DocumentParserProtocol {
    
//    func parseDocument() async throws -> ParsedDocument
    
    /// Parse document content and return title, plaintext and optional pages
    /// If no format is passed, the best fit for the original file type will be used. For example, Markdown for a text document and CSV for a spreadsheet
    func parseDocument(to format: ExportFileType?) async throws -> ParsedDocument
}

extension DocumentParserProtocol {
    
}

