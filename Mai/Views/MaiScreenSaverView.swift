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
    
    private let opQueue = DispatchQueue(label: UUID().uuidString)
    private var urls: [URL] = []
    private var currentPlayList: [URL] = []
    private var currentPlay: URL?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        self.wantsLayer = true
        guard let layer = self.layer else { return }

        let player = AVPlayer()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.autoresizingMask = [ .layerWidthSizable, .layerHeightSizable]
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        let repeatPlay = { (n: Notification) -> Void in
            (n.object as? AVPlayerItem)?.seek(to: .zero, completionHandler: nil)
        }
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: nil,
                                               queue: .main,
                                               using: repeatPlay)
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime,
                                               object: nil,
                                               queue: .main,
                                               using: repeatPlay)
        
        func play() {
            
        }
        

        // MARK: Player Settings
        let shadowLayer = CALayer()
        shadowLayer.backgroundColor = NSColor.black.withAlphaComponent(0.6).cgColor
        shadowLayer.autoresizingMask = [ .layerWidthSizable, .layerHeightSizable]
        shadowLayer.frame = bounds
        layer.addSublayer(shadowLayer)

        EventBus.isShadowed
            .bind { (shadow) in
                shadowLayer.isHidden = !shadow
            }
            .disposed(by: rx.disposeBag)

        EventBus.volume
            .bind { value in
                player.volume = value
            }
            .disposed(by: rx.disposeBag)
        
        // MARK: Control Flows
        EventBus.isStopped
            .bind { stopped in
                stopped ? player.pause() : player.play()
            }
            .disposed(by: rx.disposeBag)
        
        EventBus.isRepeated
            .bind { [weak self] repeated in
                guard let self = self else { return }
                self.opQueue.async {
                    guard let url = self.currentPlay else { return }
                    self.currentPlayList = [url]
                }
            }
            .disposed(by: rx.disposeBag)
        
        
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
