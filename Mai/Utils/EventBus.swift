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

    static let like = PublishRelay<Void>()

    static let dislike = PublishRelay<Void>()

    static let next = PublishRelay<Void>()

    static let volume = BehaviorRelay<Float>(value: 0)

    static let isMuted = BehaviorRelay<Bool>(value: false)

    static let isShadowed = BehaviorRelay<Bool>(value: true)

    static let isPaused = BehaviorRelay<Bool>(value: false)

    static let onlyLiked = BehaviorRelay<Bool>(value: false)
}
