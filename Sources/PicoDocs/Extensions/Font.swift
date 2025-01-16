//
//  File.swift
//  PicoDocs
//
//  Created by Ronald Mannak on 1/11/25.
//

import Foundation

#if canImport(AppKit)
import AppKit
typealias Font = NSFont
#elseif canImport(UIKit)
import UIKit
typealias Font = UIFont
#endif
