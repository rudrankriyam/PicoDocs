//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers

public protocol FetcherProtocol {

    var url: URL { get }
    
    init(url: URL)
    
    func fetch(progressHandler: ((Progress) -> Void)?) async throws -> (Data?, UTType?, [URL]?)
}

public struct Fetcher {    
    public func fetch(url: URL, recursive: Bool = true, progressHandler: ((Progress) -> Void)? = nil) async throws -> (Data?, UTType?, [URL]?) {
        let fetcher: FetcherProtocol
        if url.isFileURL {
            fetcher = FileFetcher(url: url)
        } else {
            fetcher = WebFetcher(url: url)
        }
        return try await fetcher.fetch(progressHandler: progressHandler)
    }
}
