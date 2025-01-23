//
//  UTType.swift
//  PicoIndex
//
//  Created by Ronald Mannak on 11/21/24.
//

import Foundation
import UniformTypeIdentifiers

public extension UTType {

   // static let xhtml = UTType(importedAs: "public.xhtml", conformingTo: .xml)
  //  static let webloc = UTType(importedAs: "com.apple.web-internet-location")

    /// Array of all supported documents
    static let supportedDocumentTypes = [
        .folder, .directory,
      //  .webloc, .xhtml,
        .pdf, .rtf, .rtfd, .text, .flatRTFD, .plainText, .utf8PlainText, xml,
        .spreadsheet, .commaSeparatedText,
        .internetLocation, .internetShortcut, .url, .urlBookmarkData, .html,
        .sourceCode, .json, .objectiveCSource, .phpScript, .perlScript, .shellScript, .script, .javaScript, .pythonScript, .assemblyLanguageSource,
        .emailMessage, .spreadsheet,
    ]
    
    
    /// Returns true if type is listed in `supportedDocumentTypes`
    var isSupported: Bool {
        Self.supportedDocumentTypes.contains(self)
    }
}
