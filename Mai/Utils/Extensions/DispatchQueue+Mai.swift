//
//  DispatchQueue+Mai.swift
//  Mai
//
//  Created by Quentin Jin on 2019/8/24.
//  Copyright © 2019 v2ambition. All rights reserved.
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
