//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/16/25.
//

import Foundation
import UniformTypeIdentifiers


/// A factory struct that creates appropriate fetchers for different URL types.
///
/// The Fetcher struct determines whether to use a FileFetcher for local files
/// or a WebFetcher for remote URLs, providing a unified interface for fetching content.
public struct Fetcher {
    
    /// Creates and returns an appropriate fetcher implementation based on the URL type.
    ///
    /// - Parameter url: The URL to create a fetcher for. Can be either a local file URL or a remote web URL.
    /// - Returns: An object conforming to FetcherProtocol, either FileFetcher for local files or WebFetcher for remote URLs.
    /// - Throws: Any errors that occur during fetcher creation.
    public static func fetcher(url: URL) -> FetcherProtocol {
        if url.isFileURL {
            return FileFetcher(url: url)
        } else {
            return WebFetcher(url: url)
        }
    }
}
