//
//  Logger.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation
import FileKit

struct Logger {

    enum Level {
        case error
        case warn
        case debug
        case info
        case cheer
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .medium
        return f
    }()

    private static func log(file: String = #file, function: String = #function, line: UInt = #line, level: Level, _ items: [Any]) {
        let time = formatter.string(from: Date())
        var char = ""
        switch level {
        case .debug:    char = "🌀"
        case .warn:     char = "❗️"
        case .info:     char = "💧"
        case .error: 	char = "❌"
        case .cheer: 	char = "🎉"
        }
        let msg = items.map({ "\($0)" }).joined(separator: " ")
        let filename = Path(file).fileName
        print("[\(time)] \(char) \(filename).\(function) - \(msg)")
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

    static func cheer(file: String = #file, function: String = #function, line: UInt = #line, _ items: Any...) {
        log(file: file, function: function, line: line, level: .cheer, items)
    }
}