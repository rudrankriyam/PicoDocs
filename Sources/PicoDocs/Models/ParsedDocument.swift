//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation

public struct ParsedDocument: Sendable {
    public let title: String?
    public let author: String?
    public let cover: Data?
    public let content: [String]        
}
