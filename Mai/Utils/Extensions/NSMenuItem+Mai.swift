//
//  NSMenuItem+Mai.swift
//  Mai
//
//  Created by Quentin Jin on 2019/8/24.
//  Copyright © 2019 v2ambition. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension Reactive where Base: NSMenuItem {
    
    var state: Binder<Bool> {
        return Binder(self.base) {
            $0.state = $1 ? .on : .off
        }
    }
}
