//
//  DocumentParser.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/5/24.
//

import Foundation
import UniformTypeIdentifiers
import PDFKit

/// Factory for creating document parsers
struct Parser {
    
    /// Create appropriate parser for the given UTType
    static func parser(for content: Data, url: URL) throws -> DocumentParserProtocol {
        
        guard let utType = UTType(filenameExtension: url.pathExtension), utType.isSupported else {
            if !url.isFileURL {
                // File could be HTML, e.g. electrek doesn't add HTML extension
                // TODO: why don't we use Mime here?
                return HTMLParser(url: url)
            } else {
                throw PicoDocsError.documentTypeNotSupported
            }
        }
        
        if utType.conforms(to: .epub) {
            
            return EPUBParser(url: url)
            
        } else if utType.conforms(to: .xlsx) || utType.conforms(to: .spreadsheet) {
                            
            return try ExcelParser(content: content)
            
        } else if utType.conforms(to: .pdf) {
            
            guard let pdfDocument = PDFDocument(data: content) else {
                throw PicoDocsError.parsingError
            }
            return PDFParser(content: pdfDocument)
            
        } else if utType.conforms(to: .rtf) {
                        
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.rtf,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: attributedString)
            
        } else if utType.conforms(to: .rtfd) {
            
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.rtfd,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: attributedString)
            
        } else if utType.conforms(to: .doc) {
            
#if os(iOS)
            throw PicoDocsError.documentTypeNotSupported
#else
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.docFormat,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: attributedString)
#endif
            
        } else if utType.conforms(to: .docx) {
            
#if os(iOS)
            throw PicoDocsError.documentTypeNotSupported
#else
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.wordML,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: attributedString)
#endif
            
        } else if utType.conforms(to: .text) || utType.conforms(to: .flatRTFD) || utType.conforms(to: .plainText) || utType.conforms(to: .utf8PlainText) || utType.conforms(to: .xml) || utType.conforms(to: .swiftSource) || utType.conforms(to: .cSource) || utType.conforms(to: .cPlusPlusSource) || utType.conforms(to: .pythonScript) || utType.conforms(to: .javaScript) {
            
            guard let text = String(data: content, encoding: .utf8) else {
                throw PicoDocsError.documentTypeNotSupported
            }
            
            return PlainTextParser(content: text)
            
        } else if utType.conforms(to: .webArchive) {
            
            #if os(iOS)
            throw PicoDocsError.documentTypeNotSupported
            #else
            
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.webArchive,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: attributedString)
            #endif
            
        } else if utType.conforms(to: .html) || !url.isFileURL {
            
            return HTMLParser(url: url)
            
            /*
        } else if utType.conforms(to: .odt) {
            
#if os(iOS)
            throw EmbeddingsError.unsupported
#else
            let attributedString = try NSAttributedString(data: content, options: [
                .documentType: NSAttributedString.DocumentType.openDocument,
                .characterEncoding: String.Encoding.utf8.rawValue
            ], documentAttributes: nil)
            return AttributedStringParser(content: AttributedString(attributedString))
#endif
            */
            
        } else {
            throw PicoDocsError.documentTypeNotSupported
        }
    }
}
