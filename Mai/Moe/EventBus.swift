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

    static let like = PublishRelay<()>()

    static let next = PublishRelay<()>()

    static let volume = BehaviorRelay<Float>(value: 0)

    static let isMuted = BehaviorRelay<Bool>(value: false)

    static let isShadowed = BehaviorRelay<Bool>(value: true)

    static let isPaused = BehaviorRelay<Bool>(value: false)

    static let onlyFavorites = BehaviorRelay<Bool>(value: false)
}
