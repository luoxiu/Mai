//
//  BehaviorRelay+Mai.swift
//  Mai
//
//  Created by Quentin Jin on 2019/8/24.
//  Copyright © 2019 v2ambition. All rights reserved.
//

import Foundation
import RxCocoa

extension BehaviorRelay where Element == Bool {
    
    func toggle() {
        self.accept(!self.value)
    }
}
