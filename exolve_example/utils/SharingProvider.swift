import SwiftUI
import Foundation

class SharingProvider {

    static let instance = SharingProvider()

    private let logtag = "SharingProvider:"

    func share() {
        if let vc = getTopViewController() {
            cleanup()
            copyFiles()
            let files = getFiles()
            if files.isEmpty {
                cleanup()
                return;
            }

            let shareVC = UIActivityViewController(activityItems: files, applicationActivities: nil)
            shareVC.completionWithItemsHandler = { [self] (activityType: UIActivity.ActivityType?,
                completed:Bool, returnedItems:[Any]?, error: Error?) in
                NSLog("\(logtag) sending files \(completed ? "done" : "cancelled")")
                cleanup()
            }
            vc.present(shareVC, animated: true)
        }
    }

    private func getDocDirectory() -> URL? {
        let dir = try? FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false)
        return dir
    }

    private func copyFiles() {
        if let srcDir = getDocDirectory() {
            do {
                let destDir = srcDir.appendingPathComponent("temp")
                let fm = FileManager.default
                try fm.createDirectory(at: destDir, withIntermediateDirectories: true)

                let content = try fm.contentsOfDirectory(
                    at: srcDir, includingPropertiesForKeys: nil)
                    .filter({ url in url.isFileURL
                    && (url.lastPathComponent.hasPrefix("sdk")
                    || url.lastPathComponent.hasPrefix("voip")) })
                for url in content {
                    try? fm.copyItem(at: url, to: destDir.appendingPathComponent(url.lastPathComponent))
                }
            } catch {
                cleanup()
            }
        }
    }

    private func cleanup() {
        if let dir = getDocDirectory() {
            let tempDir = dir.appendingPathComponent("temp")
            try? FileManager.default.removeItem(at: tempDir)
        }
    }

    private func getFiles() -> [URL] {
        var files: [URL] = []
        if let dir = getDocDirectory() {
            let tempDir = dir.appendingPathComponent("temp")
            if let content = try? FileManager.default.contentsOfDirectory(
                at: tempDir, includingPropertiesForKeys: nil)
                .sorted(by: {$0.lastPathComponent < $1.lastPathComponent}) {
                files.append(contentsOf: content)
            }
        }

        return files
    }

}
