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

class MaiScreenSaverView: ScreenSaverView {

    private let disposeBag = DisposeBag()
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
            .bind { (flag) in
                shadowLayer.isHidden = !flag
            }
            .disposed(by: disposeBag)

        EventBus.isMuted
            .bind { (flag) in
                player.isMuted = flag
            }
            .disposed(by: disposeBag)

        EventBus.volume
            .bind { value in
                player.volume = value
            }
            .disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
