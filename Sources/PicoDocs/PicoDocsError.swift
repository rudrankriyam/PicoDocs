//
//  PicoDocsError.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/11/25.
//

import Foundation

public enum PicoDocsError: Error {
    case documentTypeNotSupported
    case parsingError
    case emptyDocument
    case noContent
    case noAccess
    case stale
    case invalidURL
    case unableToExportToRequestedFormat
    case fileCorrupted
}

extension PicoDocsError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .documentTypeNotSupported:
            return String(localized: "Document type not supported")
        case .parsingError:
            return String(localized: "Error parsing document")
        case .emptyDocument:
            return String(localized: "The document is empty")
        case .noContent:
            return String(localized: "Document has no content")
        case .noAccess:
            return String(localized: "No access to File")
        case .stale:
            return String(localized: "Bookmark is stale. User needs to allow access to file(s) again")
        case .invalidURL:
            return String(localized: "Invalid URL")
        case .unableToExportToRequestedFormat:
            return String(localized: "The file cannot be exported to requested format")
        case .fileCorrupted:
            return String(localized: "File is corrupted")
        }
    }
}
