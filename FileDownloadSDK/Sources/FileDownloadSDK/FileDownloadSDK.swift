// The Swift Programming Language


import Foundation

public protocol DownloadDelegate: AnyObject {
    func downloadProgress(url: URL, progress: Float)
    func downloadCompleted(url: URL, location: URL)
    func downloadFailed(url: URL, error: Error?)
}

final public class DownloadManager: NSObject, @unchecked Sendable {
    
    public static let shared = DownloadManager()
    
    private var session: URLSession
    private var activeDownloads: [URL: URLSessionDownloadTask] = [:]
    private var resumeDataDict: [URL: Data] = [:]
    
    public weak var delegate: DownloadDelegate?
    
    private override init() {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 5
        self.session = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        super.init()
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    // MARK: - Public API
    
    public func startDownload(url: URL) {
        let task = session.downloadTask(with: url)
        activeDownloads[url] = task
        task.resume()
    }
    
    public func pauseDownload(url: URL) {
        guard let task = activeDownloads[url] else { return }
        task.cancel { data in
            if let data = data {
                self.resumeDataDict[url] = data
            }
        }
    }
    
    public func resumeDownload(url: URL) {
        if let data = resumeDataDict[url] {
            let task = session.downloadTask(withResumeData: data)
            activeDownloads[url] = task
            task.resume()
            resumeDataDict.removeValue(forKey: url)
        } else {
            startDownload(url: url)
        }
    }
    
    public func cancelDownload(url: URL) {
        guard let task = activeDownloads[url] else { return }
        task.cancel()
        activeDownloads.removeValue(forKey: url)
    }
    
    public func getFileSize(url: URL, completion: @escaping @Sendable (Int64?) -> Void) {
        fetchFileSize(url: url) { data in
            completion(data)
        }
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didWriteData bytesWritten: Int64,
                           totalBytesWritten: Int64,
                           totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url else { return }
        if totalBytesExpectedToWrite > 0 {
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            delegate?.downloadProgress(url: url, progress: progress)
        } else {
            // Indeterminate progress
            delegate?.downloadProgress(url: url, progress: -1)
        }
    }
    
    public func urlSession(_ session: URLSession,
                           downloadTask: URLSessionDownloadTask,
                           didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url else { return }
        delegate?.downloadCompleted(url: url, location: location)
        activeDownloads.removeValue(forKey: url)
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        if let error = error, let url = task.originalRequest?.url {
            delegate?.downloadFailed(url: url, error: error)
            activeDownloads.removeValue(forKey: url)
        }
    }
    
    public func fetchFileSize(url: URL, completion: @escaping @Sendable (Int64?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession.shared.dataTask(with: request) { _, response, _ in
            if #available(macOS 10.15, *) {
                if let httpResponse = response as? HTTPURLResponse,
                   let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
                   let size = Int64(contentLength) {
                    completion(size)
                } else {
                    completion(nil)
                }
            } else {
            }
        }.resume()
    }
}
