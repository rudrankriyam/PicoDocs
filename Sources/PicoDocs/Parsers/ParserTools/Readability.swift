//
//  Readability.swift
//  Pico
//
//  Created by Ronald Mannak on 4/19/24.
//
// See: https://www.artemnovichkov.com/blog/async-await-offline
// https://github.com/artemnovichkov/OfflineDataAsyncExample/blob/main/OfflineDataAsyncExample/WebDataManager.swift

import Foundation
import WebKit
import SwiftSoup

enum ReadabilityError: Error {
    case scriptNotFound
    case invalidResponse
    case jsonSerializationError
    case jsonDecodingError
}

@MainActor
public class Readability: NSObject {
    
    enum Source {
        case url(URL)
        case htmlString(String)
    }
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(frame: .zero)
        webView.configuration.suppressesIncrementalRendering = true
        webView.configuration.userContentController.addUserScript(ReadabilityUserScript())
        webView.navigationDelegate = self
        return webView
    }()
    
    private let source: Source
    private var completionHandler: ((Result<Readable, Error>) -> Void)?
    private var continuation: CheckedContinuation<Void, Error>?
    
    public init(url: URL) {
        source = .url(url)
        super.init()
    }
    
    public init(htmlString: String) {
        let htmlString = (try? SwiftSoup.clean(htmlString, Whitelist.basic())) ?? htmlString
        source = .htmlString(htmlString)
        super.init()
    }
    
    public func parse() async throws -> Readable {
        
        // 1. Load page
        try await load(self.source)
        
        // 2. Inject and execute Readability script
        let readabilityScript = """
            var article = new Readability(document).parse();
            article;
            """
        
        guard let result = try await self.webView.evaluateJavaScript(readabilityScript) as? [String: Any] else {
            throw ReadabilityError.invalidResponse
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: result, options: []) else {
            throw ReadabilityError.jsonSerializationError
        }
        
        let decoder = JSONDecoder()
        guard let readable = try? decoder.decode(Readable.self, from: jsonData) else {
            throw ReadabilityError.jsonDecodingError
        }
        
        return readable
    }
    
    private func load(_ source: Source) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            switch source {
            case .url(let url):
                self.webView.load(.init(url: url))
            case .htmlString(let htmlString):
                self.webView.loadHTMLString(htmlString, baseURL: nil)
            }
        }
    }
}

extension Readability: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        continuation?.resume(returning: ())
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        continuation?.resume(throwing: error)
    }
}

class ReadabilityUserScript: WKUserScript {
    convenience override init() {
        let js: String
        do {
            js = try Self.loadFile(name: "Readability", type: "js")
        } catch {
            fatalError("Couldn't load Readability.js")
        }
        self.init(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
        
    static func loadFile(name: String, type: String) throws -> String {
        guard let url = Bundle.module.url(forResource: name, withExtension: type) else {
            throw ReadabilityError.scriptNotFound
        }
        return try String(contentsOfFile: url.path(), encoding: .utf8)
    }
}
