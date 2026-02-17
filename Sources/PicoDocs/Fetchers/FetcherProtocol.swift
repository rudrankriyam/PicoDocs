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
    
    func fetch(progressHandler: (@Sendable (Progress) -> Void)?) async throws -> (Data?, UTType?, [URL]?)
}
