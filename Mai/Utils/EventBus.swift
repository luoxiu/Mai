//
//  Publisher.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

enum EventBus {
    
    static let newVideo = PublishRelay<URL>()

    // MARK: - Menus
    
    // MARK: Player Settings
    static let isShadowed = BehaviorRelay<Bool>(value: true)
    
    // MARK: Control Flows
    static let isStopped = BehaviorRelay<Bool>(value: false)
    static let isRepeated = BehaviorRelay<Bool>(value: false)
    static let onlyLiked = BehaviorRelay<Bool>(value: false)
    static let next = PublishRelay<Void>()
    static let like = PublishRelay<Void>()
    static let dislike = PublishRelay<Void>()
}
