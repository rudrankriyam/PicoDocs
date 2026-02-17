//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers

extension PicoDocument {
    
    /// Fetches the content of a document and its children if recursive is true
    /// - Parameters:
    ///   - recursive: If true, fetches content of child documents
    ///   - progressHandler: Optional closure to handle progress updates
    nonisolated
    public func fetch(recursive: Bool = true, progressHandler: (@Sendable (Progress) -> Void)? = nil) async {
        
        let url = self.originURL
        do {
            // Fetch content of file
            let fetcher = Fetcher.fetcher(url: url)
            let (data, utType, urls) = try await fetcher.fetch (progressHandler: progressHandler)
            
            // Fetch content of children
            if let urls, recursive == true {
                for url in urls {
                    let doc = await PicoDocument(url: url, utType: utType, parent: self)
                    await doc.fetch(recursive: recursive)
                }
            }
            // TODO: update fetch to return multiple data?
            await updateData(data, utType: utType)
        } catch {
            print("Error fetching: \(error.localizedDescription)")
            await setError(error)
        }
    }
        
    /// Parses the file stored in the `originalContent` property to LLM readable format
    /// - Parameters:
    ///   - type: The desired export file type, if nil uses default
    ///   - recursive: If true, parses child documents
    ///   - enhanceReadability: If true, attempts to enhance readability of parsed content
    /// - Throws: PicoDocsError.emptyDocument if originalContent is nil
    public nonisolated func parse(to type: ExportFileType? = nil, recursive: Bool = true, enhanceReadability: Bool = true) async {

        // Parse children first. If a child cannot be parsed (likely because of an unsupported file type),
        // just set the error and continue
        if let children = await self.children, recursive == true {
            for child in children {
                await child.parse(to: type)
            }
        }
        
        do {
            guard let originalContent = await self.originalContent else {
                throw PicoDocsError.emptyDocument
            }
            
            let parser = try Parser.parser(for: originalContent, url: self.originURL)
            let parsedDocument = try await parser.parseDocument(to: type)
            await updateParsedDocument(parsedDocument)
        } catch {
            await self.setError(error)
        }
    }
    
    // MARK: - Private methods on MainActor
    
    /// Updates the document's data and metadata
    /// - Parameters:
    ///   - data: The raw data content of the document
    ///   - utType: The uniform type identifier of the document
    private func updateData(_ data: Data?, utType: UTType? = nil) {
        self.dateLastFetched = Date()
        self.originalContent = data
        
        self.status = .downloaded
        if let utType {
            // Some web URLs may not include a file extension. The file type can only be determined from the MIME type during the fetch phase.
            self.utType = utType
        }
    }
    
    private func updateParsedDocument(_ parsedDocument: ParsedDocument) {
        self.exportedContent = parsedDocument.content
        self.title = parsedDocument.title
        self.author = parsedDocument.author
        self.cover = parsedDocument.cover
        self.status = .parsed
    }
    
    /// Sets the document's status to failed with the given error
    /// - Parameter error: The error that caused the failure
    private func setError(_ error: Error) {
        self.status = .failed(error)
    }
}
