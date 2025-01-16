//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation

public struct ParsedDocument: Sendable {
    let title: String?
    let needsChunking: Bool
    let content: [String]
}
