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
    public func fetch(recursive: Bool = true, progressHandler: ((Progress) -> Void)? = nil) async {
        
        let url = self.originURL
        do {
            // Fetch content of file
            let (data, utType, urls) = try await Fetcher().fetch(url: url, recursive: recursive)
            
            // Fetch content of children
            if let urls, recursive == true {
                for url in urls {
                    let doc = await PicoDocument(url: url, utType: utType, parent: self)
                    do {
                        try await doc.fetch(recursive: recursive)
                    } catch {
                        await doc.setError(error)
                    }
                }
            }
            // TODO: update fetch to return multiple data?
            await updateData( data == nil ? nil : [data!], utType: utType)
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
                do {
                    try await child.parse(to: type)
                } catch {
                    await child.setError(error)
                }
            }
        }
        
        do {
            guard let originalContent = await self.originalContent else {
                throw PicoDocsError.emptyDocument
            }
            
            let parser = try DocumentParser.parser(for: originalContent, url: self.originURL)
            
            let parsedDocument = try await parser.parseDocument(to: type)
            Task { @MainActor in
                // Consolidate parsed content into a single string with double newlines between worksheets
                self.exportedContent = parsedDocument.content
                self.status = .parsed
            }
        } catch {
            await self.setError(error)
        }
    }
    
    // MARK: - Private methods on MainActor
    
    /// Updates the document's data and metadata
    /// - Parameters:
    ///   - data: The raw data content of the document
    ///   - utType: The uniform type identifier of the document
    private func updateData(_ data: [Data]?, utType: UTType? = nil) {
        self.dateLastFetched = Date()
        self.originalContent = data
        
        /*
         why do we set original content again?
        if let data, let content = String(data: data, encoding: .utf8) {
            self.originalContent = data
            self.exportedContent = [content]
        } else {
            self.originalContent = nil
            self.exportedContent = nil
        }
         */
        self.status = .downloaded
        if let utType {
            // Some web URLs may not include a file extension. The file type can only be determined from the MIME type during the fetch phase.
            self.utType = utType
        }
    }
    
    /// Sets the document's status to failed with the given error
    /// - Parameter error: The error that caused the failure
    private func setError(_ error: Error) {
        self.status = .failed(error)
    }
}
