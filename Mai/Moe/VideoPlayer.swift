//
//  VideoPlayer.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

final class VideoPlayer {

    private let disposeBag = DisposeBag()
    private let opQueue = DispatchQueue(label: UUID().uuidString)
    private let player: AVPlayer
    private var urls: [URL] = []
    private var currentURL: URL?
    private var timer: Timer?

    init(player: AVPlayer) {
        self.player = player

        EventBus.newVideo
            .bind { [weak self] (url) in
                self?.opQueue.sync {
                    self?.urls.insert(url, at: 0)
                    self?.play()
                }
            }
            .disposed(by: disposeBag)

        EventBus.onlyLiked
            .bind { [weak self] flag in
                if flag {
                    VideoManager.shared.stopTryingFetching()
                    let urls = VideoManager.shared.allLikedVideos
                    if !urls.isEmpty {
                        self?.opQueue.sync {
                            self?.urls = urls
                            self?.play()
                        }
                    }
                } else {
                    VideoManager.shared.fetchIfPossible()
                    let urls = VideoManager.shared.allCachedVideo
                    self?.opQueue.sync {
                        self?.urls = urls
                        self?.play()
                    }
                }
            }
            .disposed(by: disposeBag)

        EventBus.like
            .bind { [weak self] in
                self?.opQueue.sync {
                    if let url = self?.currentURL {
                        VideoManager.shared.like(url)
                    }
                }
            }
            .disposed(by: disposeBag)

        EventBus.dislike
            .bind { [weak self] in
                self?.opQueue.sync {
                    if let url = self?.currentURL {
                        VideoManager.shared.dislike(url)
                        self?.urls.removeFirst()
                        self?.play()
                    }
                }
            }
            .disposed(by: disposeBag)

        EventBus.next
            .bind { [weak self] (_) in
                self?.opQueue.sync {
                    self?.urls.removeFirst()
                    self?.play()
                }
            }
            .disposed(by: disposeBag)

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

        urls = VideoManager.shared.allCachedVideo
        Logger.debug("Video player got \(urls.count) urls from cache", "Start to play them")
        play()
    }

    private func play() {
        timer?.invalidate()
        defer {
            timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] (_) in
                self?.play()
            }
        }

        guard urls.count > 0 else {
            return
        }

        let url = urls.removeFirst()
        urls.append(url)

        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        player.actionAtItemEnd = .none
        currentURL = url
        player.play()
    }
}
