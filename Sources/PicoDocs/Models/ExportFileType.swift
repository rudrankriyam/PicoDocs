//
//  ExportFileType.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/14/25.
//

import Foundation

/// Supported LLM-friendly file types PicoDocs can export to. Use in `PicoDocument.parse(to:)`
public enum ExportFileType: String, Equatable, Codable, CaseIterable, Identifiable, Sendable {
    case plaintext
    case html
    case xml
    case markdown
    case csv
    
    public var id: String { rawValue }
}


//public enum ParseFormat: Sendable {
//    case html, markdown, plaintext, csv
//}
