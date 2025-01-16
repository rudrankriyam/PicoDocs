//
//  AttributedString.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/6/24.
//

import Foundation
/*
import AppKit
extension AttributedString {
    
    public func toMarkdown() -> String {
        var markdownString = ""
        var isInTable = false
        
        for run in runs {
            var text = String(run.attributedString)
            
            // Handle headers based on font size
            if let fontSize = run.appKitUIFont.systemFontSize.font?.pointSize {
                let baseSize: CGFloat = 12.0  // Assuming 12pt is base font size
                
                // Scale headers based on font size
                if fontSize >= baseSize * 2 {        // 24pt or larger
                    text = "# \(text)"
                } else if fontSize >= baseSize * 1.5 {  // 18pt
                    text = "## \(text)"
                } else if fontSize >= baseSize * 1.25 { // 15pt
                    text = "### \(text)"
                }
            }
            
            // Handle bold
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                text = "**\(text)**"
            }
            
            // Handle italic
            if run.inlinePresentationIntent?.contains(.emphasized) == true {
                text = "*\(text)*"
            }
            
            // Handle links
            if let url = run.link {
                text = "[\(text)](\(url))"
            }
            
            // Handle tables using tab stops
            if let paragraphStyle = run.appKit.paragraphStyle,
               !paragraphStyle.tabStops.isEmpty {
                // Consider text with tab stops as table content
                let components = text.components(separatedBy: "\t")
                if components.count > 1 {
                    if !isInTable {
                        isInTable = true
                        // Add table header separator on first row
                        markdownString += "\n|" + Array(repeating: "---|", count: components.count).joined()
                        markdownString += "\n"
                    }
                    // Add table row
                    let rowContent = components.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    markdownString += "| " + rowContent.joined(separator: " | ") + " |\n"
                } else {
                    isInTable = false
                    markdownString += text
                }
            } else {
                if isInTable {
                    isInTable = false
                    markdownString += "\n"
                }
                markdownString += text
            }
        }
        
        return markdownString
    }
}
*/
