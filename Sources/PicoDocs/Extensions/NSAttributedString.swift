//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension NSAttributedString {
    public func toMarkdown() -> String {
        let fullRange = NSRange(location: 0, length: length)
        
        // First, process the entire text with formatting
        var markdownString = processFormattedText(in: fullRange)
        
        // Then collect and process all links
        var links: [(NSRange, String)] = []
        self.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            if let url = value as? URL {
                links.append((range, url.absoluteString))
            } else if let urlString = value as? String {
                if let url = URL(string: urlString) {
                    links.append((range, url.absoluteString))
                } else {
                    links.append((range, urlString))
                }
            }
        }
        
        // Sort links by location in reverse order to handle nested links correctly
        links.sort { $0.0.location > $1.0.location }
        
        // Replace text with markdown links
        for (linkRange, urlString) in links {
            let linkText = self.attributedSubstring(from: linkRange).string
            let markdownLink = "[\(linkText)](\(urlString))"
            
            let start = markdownString.index(markdownString.startIndex, offsetBy: linkRange.location)
            let end = markdownString.index(start, offsetBy: linkRange.length)
            markdownString.replaceSubrange(start..<end, with: markdownLink)
        }
        
        return markdownString.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func processFormattedText(in range: NSRange) -> String {
        var result = ""
        
        self.enumerateAttributes(in: range, options: []) { attributes, subrange, _ in
            var text = self.attributedSubstring(from: subrange).string
            var isHeader = false
            
            if let font = attributes[.font] as? Font {
                // Handle headers based on font size
                let fontSize = font.pointSize
                let baseSize: CGFloat = 12.0
                
                if fontSize >= baseSize * 2 {
                    text = "# \(text)"
                    isHeader = true
                } else if fontSize >= baseSize * 1.5 {
                    text = "## \(text)"
                    isHeader = true
                } else if fontSize >= baseSize * 1.25 {
                    text = "### \(text)"
                    isHeader = true
                }
                
                // Only apply bold/italic formatting if it's not a header
                if !isHeader {
                    #if canImport(AppKit)
                    let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                    let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                    #elseif canImport(UIKit)
                    let isBold = font.fontDescriptor.symbolicTraits.contains(.traitBold)
                    let isItalic = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
                    #endif
                    
                    // Apply formatting in a specific order: bold then italic
                    if isBold {
                        text = "**\(text)**"
                    }
                    if isItalic {
                        text = "*\(text)*"
                    }
                }
            }
            
            #if canImport(AppKit)
            // Handle tables
            if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
                // Find text table and block
                let textBlocks = paragraphStyle.textBlocks
                if let textTable = textBlocks.first(where: { $0 is NSTextTable }) as? NSTextTable,
                   let textTableBlock = textBlocks.first(where: { $0 is NSTextTableBlock }) as? NSTextTableBlock {
                    
                    // Create a dictionary to store table data
                    var tableData: [NSTextTable: [[String]]] = [:]
                    
                    // Initialize table data if needed
                    if tableData[textTable] == nil {
                        let rows = textBlocks.filter { $0 is NSTextTableBlock }.count / textTable.numberOfColumns
                        tableData[textTable] = Array(repeating: Array(repeating: "", count: textTable.numberOfColumns), count: rows)
                    }
                    
                    // Get the current cell's position
                    let cellCount = textBlocks.prefix(while: { $0 !== textTableBlock }).filter { $0 is NSTextTableBlock }.count
                    let row = cellCount / textTable.numberOfColumns
                    let col = cellCount % textTable.numberOfColumns
                    
                    // Store the cell content
                    tableData[textTable]?[row][col] = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // If this is the last cell in a row
                    if col == textTable.numberOfColumns - 1 {
                        let rowContent = tableData[textTable]?[row].joined(separator: " | ")
                        
                        if row == 0 {
                            // Header row
                            text = "| \(rowContent ?? "") |\n"
                            // Add separator
                            text += "|" + String(repeating: " --- |", count: textTable.numberOfColumns) + "\n"
                        } else {
                            // Regular row
                            text = "| \(rowContent ?? "") |\n"
                        }
                    } else {
                        text = "" // Clear intermediate cells to avoid duplication
                    }
                }
            }
            #endif
            
            result += text
        }
        
        return result
    }
    
    public func toHTML() async throws -> String {
        let options: [NSAttributedString.DocumentAttributeKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
            .defaultAttributes: [
                NSAttributedString.Key.paragraphStyle: {
                    #if os(iOS)
                    let style = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                    #else
                    let style = NSMutableParagraphStyle()
                    #endif
                    style.paragraphSpacing = 0
                    return style
                }()
            ]
        ]
        let data = try self.data(from: NSRange(location: 0, length: self.length), documentAttributes: options)
                
        guard let htmlString = String(data: data, encoding: .utf8) else {
            throw PicoDocsError.parsingError
        }

        let readability = await Readability(htmlString: htmlString)
        let readable = try await readability.parse()
        return readable.content
    }

}
