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

final class VideoManager {

    private enum K {
        static let cacheSizeLimit = 100 * (1 << 20)  // 100 MB

        static let id = "com.v2ambition.mai"
        static let cachePath = Path.userMovies + "Mai" + "Cache"
        static let favoritesPath = Path.userMovies + "Mai" + "Favorites"
        static let baseURL = "https://animeloop.org/api/v2"

        static let ascending = { (lhs: Path, rhs: Path) -> Bool in
            guard let ld = lhs.creationDate, let rd = rhs.creationDate else { return true }
            return ld < rd
        }
    }

    private let ioQueue = DispatchQueue(label: UUID().uuidString)
    private let reachabilityMgr = NetworkReachabilityManager(host: K.baseURL)
    private var fetchDisposable: Disposable?
    private let videoSubject = PublishSubject<String>()

    private init() {
        createDirIfNeeded()
        cleanCacheDirIfNeede()
    }

    static let shared = VideoManager()

    private func createDirIfNeeded() {
        for p in [K.cachePath, K.favoritesPath] {
            if !p.exists {
                do {
                    try p.createDirectory()
                } catch let err {
                    Logger.error("Failed to create directory", p, err)
                }
            }
        }
    }

    private func cleanCacheDirIfNeede() {
        ioQueue.async {
            var totalSize = K.cachePath.children().reduce(into: 0, { $0 += ($1.fileSize ?? 0) })
            var files = K.cachePath.children()
                .filter {
                    $0.pathExtension == "mp4"
                }
                .sorted(by: K.ascending)
                .reversed()
                .map({ $0 })

            while totalSize > (K.cacheSizeLimit / 3 * 2) {
                guard let path = files.popLast() else {
                    Logger.error("No file???")
                    preconditionFailure("No file???")
                }
                do {
                    guard let fileSize = path.fileSize else { continue }
                    totalSize -= fileSize
                    try path.deleteFile()
                    Logger.cheer("A video has been deleted from cache", path)
                } catch let err {
                    Logger.error("Failed to delete file", path, err)
                }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + 15) { [weak self] in
                self?.cleanCacheDirIfNeede()
            }
        }
    }

    var allCachedVideo: [URL] {
        return ioQueue.sync {
            return K.cachePath
                .children()
                .filter({ $0.pathExtension == "mp4" })
                .sorted(by: K.ascending)
                .reversed()
                .map({ $0.url })
        }
    }

    var allFavoriteVideos: [URL] {
        return ioQueue.sync {
            return K.favoritesPath
                .children()
                .filter({ $0.pathExtension == "mp4" })
                .sorted(by: K.ascending)
                .reversed()
                .map({ $0.url })
        }
    }

    func like(_ url: URL) {
        ioQueue.sync {
            if let path = Path(url: url) {
                let dest = K.favoritesPath + path.fileName
                do {
                    Logger.info("Copy the liked video to favorites path", dest)
                    try path.copyFile(to: dest)
                } catch let err {
                    Logger.error("Failed to move file to favorites dir", dest, err)
                }
            }
        }
    }

    func fetchIfPossible() {
        if reachabilityMgr?.listener == nil {
            reachabilityMgr?.listener = { [weak self] status in
                Logger.debug("API reachability changed,", "status: \(status)")
                guard let self = self, let mgr = self.reachabilityMgr else { return }
                if mgr.isReachable {
                    Logger.info("API is reachable, Start to fetch a new video")
                    self.fetch()
                } else if mgr.networkReachabilityStatus == .unknown {
                    Logger.info("we don't do anything")
                } else {
                    Logger.warn("API is unreachable, Stop fetching new videos")
                    self.fetchDisposable = nil
                }
            }
        }
        reachabilityMgr?.startListening()
    }

    private func fetch() {
        Logger.debug("Fetching...")
        fetchDisposable = RxAlamofire
            .json(.get,
                  K.baseURL + "/rand/loop",
                  parameters: ["full": true, "limit": 1]
            )
            .flatMap { (obj) -> Observable<(String, Data)> in
                if let url = JSON(obj)["data"][0]["files"]["mp4_1080p"].string {
                    return RxAlamofire.data(.get, url).map { (url, $0) }
                }
                return Observable.empty()
            }
            .subscribe(onNext: { [weak self] (url, data) in
                let fileName = Path(url).fileName
                Logger.cheer("A new video has been downloaded", fileName)
                let dest = K.cachePath + fileName
                do {
                    try self?.ioQueue.sync {
                        try data.write(to: dest)
                    }
                    EventBus.newVideo.accept(dest.url)
                    Logger.cheer("A new video has been written to disk", dest)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        self?.fetch()
                    }
                } catch let err {
                    Logger.error("Failed to write video to disk", dest, err)
                }
            }, onError: { [weak self] (err) in
                Logger.error("Failed to download video", err)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.fetch()
                }
            })
    }

    func stopFetching() {
        fetchDisposable = nil
        reachabilityMgr?.stopListening()
    }
}
