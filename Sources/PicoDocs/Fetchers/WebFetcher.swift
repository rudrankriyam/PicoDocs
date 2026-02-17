//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/12/25.
//

import Foundation
import UniformTypeIdentifiers

open class WebFetcher: FetcherProtocol {
    
    public let url: URL
    
    public required init(url: URL) {
        self.url = url
    }
    
    public func fetch(progressHandler: (@Sendable (Progress) -> Void)? = nil) async throws -> (Data?, UTType?, [URL]?) {
        
        let config = URLSessionConfiguration.default
        let urlSession = URLSession(configuration: config)
        
        // Create a URL request with proper validation
        var request = URLRequest(url: url)
        request.timeoutInterval = 30 // Add timeout
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Try to determine the file type
        var fileType: UTType?
        if let mimeType = httpResponse.mimeType {
            fileType = UTType(mimeType: mimeType)
        }
        
        // You might want to do something with the fileType here
        // For example, you could store it in a property or return it
        
        return (data, fileType, nil)
    }
}
