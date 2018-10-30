//
//  Extensions.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/28.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation

extension DispatchQueue {

    static func `is`(_ queue: DispatchQueue) -> Bool {
        let key = DispatchSpecificKey<Void>()

        queue.setSpecific(key: key, value: ())
        defer { queue.setSpecific(key: key, value: nil) }

        return DispatchQueue.getSpecific(key: key) != nil
    }
}
