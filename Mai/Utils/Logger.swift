//
//  Logger.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation
import FileKit
import Then

struct Logger {
    
    static var isEnabled = true

    enum Level {
        case error
        case warn
        case debug
        case info
        case success
    }

    private static func log(file: String = #file, function: String = #function, line: UInt = #line, level: Level, _ items: [Any]) {
        
        guard isEnabled else { return }
        
        debugOnly {
            
            enum Cache {
                static let formatter = DateFormatter().then { $0.dateFormat = "HH:mm:ss.SSS" }
            }
            
            let time = Cache.formatter.string(from: Date())
            var flag = ""
            switch level {
            case .error:        flag = "❤️"
            case .warn:         flag = "💛"
            case .debug:        flag = "🖤"
            case .info:         flag = "💙"
            case .success:     	flag = "💚"
            }
            
            let msg = items.map({ "\($0)" }).joined(separator: " ")
            let filename = Path(file).fileName.split(separator: ".").first!

            print("[Mai] \(time) \(flag) \(filename):\(line) \(function) ➜ \(msg)")
        }
    }

    static func error(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .error, items)
    }

    static func warn(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .warn, items)
    }

    static func debug(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .debug, items)
    }

    static func info(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .info, items)
    }

    static func success(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .success, items)
    }
}
