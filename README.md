# FileDownloadSDK
📥 DownloadManager (Swift)
A lightweight Swift utility to download large files with progress updates using URLSession.
Supports percentage-based progress when the server provides file size, and gracefully handles unknown file size (-1) by showing downloaded MB instead.

✨ Features
Download large files in the background with URLSessionDownloadDelegate.

Real-time progress updates:

Percentage-based when Content-Length is available.

MB downloaded when server does not return file size (i.e., -1).

Handles server responses with chunked transfer encoding.

Simple delegate-based API for easy integration in any iOS/macOS project.

🛠 Example Usage


```swift
class ViewController: UIViewController, DownloadManagerDelegate {
    func downloadProgress(url: URL, progress: Float, downloadedMB: Double?) {
        if progress >= 0 {
            print("Progress: \(progress * 100)%")
        } else {
            print("Downloaded: \(downloadedMB ?? 0) MB")
        }
    }

    func downloadCompleted(url: URL, location: URL) {
        print("Download finished: \(location)")
    }
}
```
🔹 How It Works

Uses URLSessionDownloadTask for efficient large file handling
Monitors didWriteData to calculate progress.

If totalBytesExpectedToWrite == -1, reports downloaded MB instead of percentage.
