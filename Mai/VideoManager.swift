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

extension VideoManager {
    
    private enum K {
        static let cacheSizeLimit: UInt64 = 100 * (1 << 20)  // 100 MB

        static let cacheDir = Path.userMovies + "Mai" + ".cache"
        static let likeDir = Path.userMovies + "Mai" + "like"
        static let dislikeDir = Path.userMovies + "Mai" + ".dislike"
        
        static let downloadIntervalrea = 10
        
        static let apiHost = "animeloop.org"
        static let baseURL = "https://animeloop.org/api/v2"
        
        static let descendingByCreationDate = { (lhs: Path, rhs: Path) -> Bool in
            guard let ld = lhs.creationDate, let rd = rhs.creationDate else { return true }
            return ld < rd
        }
    }
}

final class VideoManager {

    private let disposeBag = DisposeBag()
    private let ioQueue = DispatchQueue(label: UUID().uuidString)
    private let reachability = NetworkReachabilityManager(host: K.apiHost)!
    
    private var downloadDisposable: Disposable?

    // MARK: - Init
    private init() {
        createDirIfNeeded()
        copyDefaultVideoIfNeeded()
        cleanCacheDirIfNeeded()
        
        reachability.startListening()
    }

    static let shared = VideoManager()

    private func createDirIfNeeded() {
        ioQueue.async {
            for p in [K.cacheDir, K.likeDir, K.dislikeDir] {
                if p.exists { continue }
                
                do {
                    try p.createDirectory()
                } catch let err {
                    Logger.error("Failed to create directory", p, err)
                }
            }
        }
    }

    private func copyDefaultVideoIfNeeded() {
        ioQueue.async {
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
    }

    private func cleanCacheDirIfNeeded() {
        ioQueue.async {
            var cacheTotalSize = K.cacheDir.children().reduce(into: 0, { $0 += ($1.fileSize ?? 0) })
            var files = K.cacheDir.children()
                .filter {
                    $0.pathExtension == "mp4"
                }
                .sorted(by: K.descendingByCreationDate)

            while cacheTotalSize > K.cacheSizeLimit, files.count > 0 {
                guard let path = files.popLast() else {
                    Logger.error("Cache folder size is \(cacheTotalSize) but no mp4 file???")
                    return
                }
                
                do {
                    guard let fileSize = path.fileSize else { continue }
                    cacheTotalSize -= fileSize
                    try path.deleteFile()
                } catch let err {
                    Logger.error("Failed to delete file", path, err)
                }
            }
        }
    }

    // MARK: - All videos
    func videos(in dir: Path, sorted: Bool = false) -> Observable<[URL]> {
        return .create { (o) -> Disposable in
            let d = BooleanDisposable(isDisposed: false)
            
            self.ioQueue.async {
                var videos = dir.children()
                    .filter { $0.pathExtension == "mp4" }
                if sorted {
                    videos.sort(by: K.descendingByCreationDate)
                }
                
                let urls = videos.map { $0.url }
                DispatchQueue.main.async {
                    if d.isDisposed {
                        return
                    }
                    o.onNext(urls)
                }
            }
            
            return d
        }
    }
    
    private var shouldDownload: Bool {
        guard self.reachability.isReachable else {
            return false
        }
        if EventBus.isStopped.value || EventBus.isRepeated.value || EventBus.onlyLiked.value {
            return false
        }
        return true
    }
    
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
            } catch let err {
                Logger.error("Failed to move file to dislike dir", dest, err)
            }
        }
    }

    // MARK: Download
    private func download() {
        downloadDisposable?.dispose()
        downloadDisposable = Observable<Int>.timer(DispatchTimeInterval.seconds(0), period: DispatchTimeInterval.seconds(K.downloadInterval), scheduler: MainScheduler.asyncInstance)
            .flatMapLatest({ (_) -> Observable<Void> in
                guard self.shouldDownload else {
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
                            Logger.error("Bad response", JSON(obj))
                            return Observable.empty()
                        }
                        return Observable.zip([self.videos(in: K.cacheDir), self.videos(in: K.dislikeDir)]) { (urls) -> [URL] in
                                urls.flatMap { $0 }
                            }
                            .flatMap({ (urls) -> Observable<Void> in
                                if urls.contains(url) {
                                    return .empty()
                                }
                                
                                return Observable<Void>.create({ (o) -> Disposable in
                                    let d = BooleanDisposable(isDisposed: false)
                                    
                                    let request = Alamofire.download(url, to: DownloadRequest.suggestedDownloadDestination())
                                    request.response(completionHandler: { (res) in
                                        if let err = res.error {
                                            o.onError(err)
                                            return
                                        }
                                        guard let destURL = res.destinationURL else {
                                            return
                                        }
                                        
                                        self.ioQueue.async {
                                            if d.isDisposed {
                                                return
                                            }
                                            
                                            let destPath = Path(url: destURL)!
                                            let fileName = destPath.fileName
                                            let newDestPath = K.cacheDir + fileName
                                            
                                            if newDestPath.exists { return }
                                            
                                            do {
                                                try destPath.moveFile(to: newDestPath)
                                            } catch let e {
                                                Logger.error("Failed to download video", e)
                                            }
                                            DispatchQueue.main.async {
                                                EventBus.newVideo.accept(destURL)
                                            }
                                        }
                                    })
                                    
                                    return Disposables.create {
                                        d.dispose()
                                        request.cancel()
                                    }
                                })
                    })
                }
                
            })
            .subscribe(onNext: { _ in
            }, onError: { (err) in
                if let e = err as? URLError, e.code == .cancelled {
                    return
                }
                Logger.error("Failed to download video", err)
            })
    }

    func startDownloading() {
        if downloadDisposable == nil {
            download()
        }
    }

    func stopDownloading() {
        downloadDisposable?.dispose()
        downloadDisposable = nil
    }
}
