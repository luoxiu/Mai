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
    private let player = AVPlayer()
    
    private var currentPlayList: Queue<URL> = Queue()
    private var currentPlay: URL?

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)

        self.wantsLayer = true
        guard let layer = self.layer else { return }

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.autoresizingMask = [ .layerWidthSizable, .layerHeightSizable]
        playerLayer.frame = bounds
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        
        self.setupLoop()

        // MARK: Player Settings
        self.setupShadow()
        
        // MARK: Controls
        self.setupStop()
        self.setupRepeat()
        
        EventBus.onlyLiked
            .bind { [weak self] onlyLiked in
                guard let self = self else { return }
                
                if onlyLiked {
                    let urls = VideoManager.shared.allLikedVideos
                    if !urls.isEmpty {
                        self.opQueue.sync {
                            self.currentPlayList = Queue()
                            self.currentPlayList.append(contentsOf: urls)
                            self.play()
                        }
                    }
                } else {
                    let urls = VideoManager.shared.allCachedVideos
                    if !urls.isEmpty {
                        self.opQueue.async {
                            self.currentPlayList = Queue()
                            self.currentPlayList.append(contentsOf: urls)
                            self.play()
                        }
                    }
                }
            }
            .disposed(by: rx.disposeBag)
        
        EventBus.newVideo
            .bind { [weak self] (url) in
                guard let self = self else { return }
                if EventBus.onlyLiked.value {
                    return
                }
                self.opQueue.sync {
                    self.currentPlayList.prepend(url)
                }
            }
            .disposed(by: rx.disposeBag)
        
    
        EventBus.next
            .bind { [weak self] in
                self?.play()
            }
            .disposed(by: rx.disposeBag)
        
        EventBus.like
            .bind { [weak self] in
                guard let self = self else { return }
                self.opQueue.async {
                    if let url = self.currentPlay {
                        VideoManager.shared.like(url)
                    }
                }
            }
            .disposed(by: rx.disposeBag)
        
        EventBus.dislike
            .bind { [weak self] in
                guard let self = self else { return }
                self.opQueue.async {
                    if let url = self.currentPlay {
                        VideoManager.shared.dislike(url)
                        _ = self.currentPlayList.popLast()
                        self.play()
                    }
                }
            }
            .disposed(by: rx.disposeBag)
        
        self.currentPlayList.append(contentsOf: VideoManager.shared.allCachedVideos)
        self.play()
    }
    
    private func play() {
        self.opQueue.async {
            guard let url = self.currentPlayList.popFirst() else { return }
            self.currentPlayList.append(url)
            self.currentPlay = url
            
            DispatchQueue.main.async {
                let item = AVPlayerItem(url: url)
                self.player.replaceCurrentItem(with: item)
                self.player.actionAtItemEnd = .none
                self.player.play()
            }
        }
    }
    
    private func setupLoop() {
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { [weak self] n in
            guard let self = self else { return }
            if EventBus.isRepeated.value {
                (n.object as? AVPlayerItem)?.seek(to: .zero)
            } else {
                self.play()
            }
        }
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: nil, queue: .main) { [weak self] n in
            guard let self = self else { return }
            if EventBus.isRepeated.value {
                (n.object as? AVPlayerItem)?.seek(to: .zero)
            } else {
                self.play()
            }
        }
    }
    
    // MARK: Player Settings
    private func setupShadow() {
        guard let layer = self.layer else { return }
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
    }
    
    
    // MARK: Controls
    private func setupStop() {
        EventBus.isStopped
            .bind { [weak self] stopped in
                guard let self = self else { return }
                stopped ? self.player.pause() : self.player.play()
            }
            .disposed(by: rx.disposeBag)
    }
    
    private func setupRepeat() {
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

