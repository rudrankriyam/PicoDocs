//
//  File.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 12/5/24.
//

import Foundation
import CoreXLSX
import UniformTypeIdentifiers

struct ExcelParser: DocumentParserProtocol {
    
    let content: Data
        
    init(content: Data) {
        self.content = content
    }
    
//    func parseDocument() async throws -> ParsedDocument {
//        return try await parseDocument(to: .html)
//    }
    
    func parseDocument(to format: ExportFileType? = nil) async throws -> ParsedDocument {
        
        let file = try XLSXFile(data: content)
        let sharedStrings = try file.parseSharedStrings()
        let format = format ?? .markdown
        var title = ""
        var workbookContents: [String] = []
        
        for wbk in try file.parseWorkbooks() {
            for (name, path) in try file.parseWorksheetPathsAndNames(workbook: wbk) {
                
                let worksheet = try file.parseWorksheet(at: path)
                guard let rows = worksheet.data?.rows else {
                    continue
                }
                
                var worksheetContent = ""
                
                switch format {
                case .html:
                    
                    worksheetContent = "<!DOCTYPE html>\n<html>\n<head>\n"
                    
                    if let worksheetName = name {
                        worksheetContent += "<title>\(worksheetName)</title>\n"
                        title += worksheetName + " "
                    }
                    
                    worksheetContent += "<style>\n"
                    worksheetContent += "table { border-collapse: collapse; width: 100%; }\n"
                    worksheetContent += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n"
                    worksheetContent += "tr:nth-child(even) { background-color: #f2f2f2; }\n"
                    worksheetContent += "</style>\n</head>\n<body>\n"
                    
                    if let worksheetName = name {
                        worksheetContent += "<h2>\(worksheetName)</h2>\n"
                    }
                    
                    worksheetContent += "<table>\n"
                    
                    for (rowIndex, row) in rows.enumerated() {
                        let cells = row.cells
                        worksheetContent += rowIndex == 0 ? "<thead>\n<tr>\n" : "<tr>\n"
                        
                        for cell in cells {
                            let tag = rowIndex == 0 ? "th" : "td"
                            worksheetContent += "<\(tag)>"
                            
                            if let sharedStrings, let stringValue = cell.stringValue(sharedStrings) {
                                worksheetContent += stringValue
                            } else if let value = cell.value {
                                worksheetContent += "\(value)"
                            }
                            
                            worksheetContent += "</\(tag)>\n"
                        }
                        
                        worksheetContent += rowIndex == 0 ? "</tr>\n</thead>\n<tbody>\n" : "</tr>\n"
                    }
                    
                    worksheetContent += "</tbody>\n</table>\n</body>\n</html>"
                    workbookContents.append(worksheetContent)
                    
                case .xml:
                    
                    worksheetContent = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                    worksheetContent += "<worksheet xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\" xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">\n"
                    worksheetContent += "<sheetData>\n"
                    
                    for (rowIndex, row) in rows.enumerated() {
                        let rowNum = rowIndex + 1
                        worksheetContent += "<row r=\"\(rowNum)\" ht=\"13.65\" customHeight=\"1\">\n"
                        
                        let cells = row.cells
                        for (colIndex, cell) in cells.enumerated() {
                            // Convert column index to Excel column name (A, B, C, etc.)
                            let colLetter = String(UnicodeScalar(65 + colIndex) ?? "A")
                            let cellRef = "\(colLetter)\(rowNum)"
                            
                            // Start cell tag
                            if let sharedStrings, cell.stringValue(sharedStrings) != nil {
                                worksheetContent += "<c r=\"\(cellRef)\" t=\"s\" s=\"3\">"
                            } else {
                                worksheetContent += "<c r=\"\(cellRef)\" s=\"2\">"
                            }
                            
                            // Add value
                            worksheetContent += "<v>"
                            if let sharedStrings, let stringValue = cell.stringValue(sharedStrings) {
                                worksheetContent += stringValue
                            } else if let value = cell.value {
                                worksheetContent += "\(value)"
                            } else {
                                worksheetContent += ""
                            }
                            worksheetContent += "</v>"
                            
                            // Close cell tag
                            worksheetContent += "</c>\n"
                        }
                        
                        worksheetContent += "</row>\n"
                    }
                    
                    worksheetContent += "</sheetData>\n"
                    worksheetContent += "</worksheet>"
                    
                    // Add this worksheet's content to the array
                    workbookContents.append(worksheetContent)
                    
                case .markdown:

                    if let worksheetName = name {
                        worksheetContent += "## \(worksheetName)\n\n"
                        title += worksheetName + " "
                    }
                    
                    for (index, row) in rows.enumerated() {
                        let cells = row.cells
                        worksheetContent += "|"
                        for (cellIndex, cell) in cells.enumerated() {
                            
                            // Cell is a shared string
                            if let sharedStrings, let stringValue = cell.stringValue(sharedStrings) {
                                worksheetContent += " \(stringValue)"
                            } else if let value = cell.value {
                                // Cell is number or formula
                                worksheetContent += " \(value)"
                            } else {
                                // Empty cell
                                worksheetContent += " "
                            }
                            worksheetContent += " |"
                        }
                        worksheetContent += "\n"
                        
                        if index == 0 {
                            for cell in cells {
                                worksheetContent += "|---"
                            }
                            worksheetContent += "|\n"
                        }
                    }
                        
                    // Add this worksheet's content to the array
                    workbookContents.append(worksheetContent)
                        
                    
                case .csv, .plaintext:
                    
                    if let worksheetName = name {
                        worksheetContent += worksheetName + ":\n"
                        title += worksheetName + " "
                    }
                    
                    for (index, row) in rows.enumerated() {
                        let cells = row.cells
                        for (index, cell) in cells.enumerated() {
                            // Cell is a shared string
                            if let sharedStrings, let stringValue = cell.stringValue(sharedStrings) {
                                worksheetContent += "\(stringValue)"
                            } else if let value = cell.value {
                                // Cell is number or formula
                                worksheetContent += "\(value)"
                            } else {
                                // Empty cell
                                worksheetContent += ""
                            }
                            if index < cells.count - 1 {
                                worksheetContent += ", "
                            }
                        }
                        worksheetContent += "\n"
                    }
                    
                    // Add this worksheet's content to the array
                    workbookContents.append(worksheetContent)
                }
            }
        }
        
        return ParsedDocument(title: title, needsChunking: false, content: workbookContents)
    }
}
