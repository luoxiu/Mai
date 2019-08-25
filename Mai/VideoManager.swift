//
//  VideoManager.swift
//  Mai
//
//  Created by Quentin Jin on 2018/10/27.
//  Copyright © 2018 v2ambition. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire
import SwiftyJSON
import FileKit
import Cocoa
import Reachability
import RxReachability

extension VideoManager {
    
    private enum K {
        static let cacheSizeLimit: UInt64 = 100 * (1 << 20)  // 100 MB

        static let cacheDir = Path.userMovies + "Mai" + ".cache"
        static let likeDir = Path.userMovies + "Mai" + "like"
        static let dislikeDir = Path.userMovies + "Mai" + ".dislike"
        
        static let downloadInterval: TimeInterval = 5
        
        static let apiHost = "animeloop.org"
        static let baseURL = "https://animeloop.org/api/v2"
        
        static let descendingByCreationDate = { (lhs: Path, rhs: Path) -> Bool in
            guard let ld = lhs.creationDate, let rd = rhs.creationDate else { return true }
            return ld < rd
        }
    }
}

extension VideoManager {
 
    var async: Observable<VideoManager> {
        return Observable.just(self).observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
    }
}

final class VideoManager {

    private let disposeBag = DisposeBag()
    private let ioQueue = DispatchQueue(label: UUID().uuidString)
    private let reachability = Reachability(hostname: K.apiHost)!
    
    private var cacheTotalSize: UInt64 = 0
    
    private var fetchDisposable: Disposable?

    // MARK: - Init
    private init() {
        createDirIfNeeded()
        copyDefaultVideoIfNeeded()
        cleanCacheDirIfNeeded()
        
        do {
            try reachability.startNotifier()
        } catch let e {
            Logger.error("Failed to set up reachability notifier", e)
        }

        EventBus.onlyLiked
            .bind { [weak self] flag in
                guard let self = self else { return }
                if flag {
                    self.stopFetching()
                } else {
                    self.startFetching()
                }
            }
            .disposed(by: disposeBag)
    }

    static let shared = VideoManager()

    private func createDirIfNeeded() {
        for p in [K.cacheDir, K.likeDir, K.dislikeDir] {
            if p.exists { continue }
            
            do {
                try p.createDirectory()
            } catch let err {
                Logger.error("Failed to create directory", p, err)
            }
        }
    }

    private func copyDefaultVideoIfNeeded() {
        if let path = Bundle.main.path(forResource: "5bbadd3466e1f3205b7e4e98", ofType: "mp4") {
            let from = Path(path)
            let to = K.cacheDir + from.fileName
            if to.exists { return }
            
            do {
                try from.moveFile(to: to)
            } catch let err {
                Logger.error("Failed to copy default video", err)
            }
        }
    }

    private func cleanCacheDirIfNeeded() {
        ioQueue.async { [weak self] in
            guard let self = self else { return }
            self.cacheTotalSize = K.cacheDir.children().reduce(into: 0, { $0 += ($1.fileSize ?? 0) })
            var files = K.cacheDir.children()
                .filter {
                    $0.pathExtension == "mp4"
                }
                .sorted(by: K.descendingByCreationDate)

            while self.cacheTotalSize > K.cacheSizeLimit {
                guard let path = files.popLast() else {
                    Logger.error("Cache folder size is \(self.cacheTotalSize) but no mp4 file???")
                    return
                }
                
                do {
                    guard let fileSize = path.fileSize else { continue }
                    self.cacheTotalSize -= fileSize
                    try path.deleteFile()
                } catch let err {
                    Logger.error("Failed to delete file", path, err)
                }
            }
        }
    }

    // MARK: - All videos
    var allCachedVideos: [URL] {
        return ioQueue.sync {
            return K.cacheDir
                .children()
                .filter({ $0.pathExtension == "mp4" })
                .sorted(by: K.descendingByCreationDate)
                .map({ $0.url })
        }
    }

    var allLikedVideos: [URL] {
        return ioQueue.sync {
            return K.likeDir
                .children()
                .filter({ $0.pathExtension == "mp4" })
                .sorted(by: K.descendingByCreationDate)
                .map({ $0.url })
        }
    }
    
    var allDislikedVideos: [URL] {
        return ioQueue.sync {
            return K.dislikeDir
                .children()
                .filter({ $0.pathExtension == "mp4" })
                .sorted(by: K.descendingByCreationDate)
                .map({ $0.url })
        }
    }

    // MARK: Like & Dislike
    func like(_ url: URL) {
        ioQueue.async {
            guard let path = Path(url: url) else { return }
            
            let dest = K.likeDir + path.fileName
            if dest.exists { return }
            do {
                try path.copyFile(to: dest)
            } catch let err {
                Logger.error("Failed to copy file to like dir", err)
            }
        }
    }

    func dislike(_ url: URL) {
        ioQueue.async {
            guard let path = Path(url: url), path.exists else {
                return
            }
            let dest = K.dislikeDir + path.fileName
            if dest.exists { return }
            
            do {
                try path.moveFile(to: dest)
                self.cacheTotalSize -= dest.fileSize ?? 0
            } catch let err {
                Logger.error("Failed to move file to dislike dir", dest, err)
            }
        }
    }

    // MARK: Download
    private func fetch() {
        fetchDisposable?.dispose()
        fetchDisposable = Observable<Int>.timer(0, period: K.downloadInterval, scheduler: MainScheduler.asyncInstance)
            .flatMapLatest({ (_) -> Observable<Void> in
                
                guard self.reachability.isReachable else {
                    return .empty()
                }
                
                return RxAlamofire
                    .json(.get,
                          K.baseURL + "/rand/loop",
                          parameters: ["full": true, "limit": 1]
                    )
                    .flatMap { (obj) -> Observable<Void> in
                        guard
                            let path = JSON(obj)["data"][0]["files"]["mp4_1080p"].string,
                            let url = URL(string: path)
                            else {
                                return Observable.empty()
                        }
                        
                        if (self.allCachedVideos + self.allDislikedVideos).contains(where: { $0.lastPathComponent == url.lastPathComponent }) {
                            return Observable.empty()
                        }
                        
                        return Observable<Void>.create({ (o) -> Disposable in
                            let request = Alamofire.download(url)
                            request.response(completionHandler: { (res) in
                                if let err = res.error {
                                    o.onError(err)
                                    return
                                }
                                guard let url = res.temporaryURL else {
                                    return
                                }
                                
                                self.ioQueue.async {
                                    let tmpPath = Path(url: url)!
                                    let fileName = tmpPath.fileName
                                    let dest = K.cacheDir + fileName
                                    
                                    if dest.exists { return }
                                    
                                    do {
                                        try tmpPath.moveFile(to: dest)
                                        self.cacheTotalSize += dest.fileSize ?? 0
                                    } catch let e {
                                        Logger.error("Failed to download video", e)
                                    }
                                    DispatchQueue.main.async {
                                        EventBus.newVideo.accept(url)
                                    }
                                }
                            })
                            
                            return Disposables.create {
                                request.cancel()
                            }
                        })
                    }
            })
            .subscribe(onNext: { _ in
            }, onError: { (err) in
                Logger.error("Failed to download video", err)
            })
    }

    func startFetching() {
        if fetchDisposable == nil {
            fetch()
        }
    }

    func stopFetching() {
        fetchDisposable?.dispose()
        fetchDisposable = nil
    }
}
