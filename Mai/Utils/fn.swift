//
//  fn.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/30.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation

func debugOnly(_ task: () -> Void) {
    assert({ task(); return true }(), "")
}
