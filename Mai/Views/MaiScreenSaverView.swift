//
//  MaiScreenSaverView.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import RxSwift
import Cocoa
import AVFoundation
import ScreenSaver
import FileKit
import NSObject_Rx

class MaiScreenSaverView: ScreenSaverView {

    private var videoPlayer: VideoPlayer!

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        wantsLayer = true
        guard let layer = layer else { return }

        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.autoresizingMask = [ .layerWidthSizable, .layerHeightSizable]
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)

        videoPlayer = VideoPlayer(player: player)

        let shadowLayer = CALayer()
        shadowLayer.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        shadowLayer.autoresizingMask = [ .layerWidthSizable, .layerHeightSizable]
        shadowLayer.frame = bounds
        layer.addSublayer(shadowLayer)

        EventBus.isShadowed
            .bind { (isShadowed) in
                shadowLayer.isHidden = !isShadowed
            }
            .disposed(by: rx.disposeBag)

        EventBus.isMuted
            .bind { isMuted in
                player.isMuted = isMuted
            }
            .disposed(by: rx.disposeBag)

        EventBus.volume
            .bind { value in
                player.volume = value
            }
            .disposed(by: rx.disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
