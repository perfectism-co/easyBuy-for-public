
import SwiftUI
import PhotosUI
import UIKit
import CryptoKit

enum ImagePickerSourceType {
    case camera
    case photoLibrary
}

struct SelectedPhoto: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let assetId: String?
    let hash: String
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: ImagePickerSourceType
    var maxCount: Int
    var maxFileSizeKB: Double

    @Binding var selectedPhotos: [SelectedPhoto]
    @Binding var alertMessage: String
    @Binding var showAlert: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        switch sourceType {
        case .photoLibrary:
            var config = PHPickerConfiguration(photoLibrary: .shared())
            config.filter = .images
            config.selectionLimit = maxCount
            config.preselectedAssetIdentifiers = selectedPhotos.compactMap { $0.assetId }
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = context.coordinator
            return picker

        case .camera:
            let picker = UIImagePickerController()
            picker.delegate = context.coordinator
            picker.sourceType = .camera
            picker.allowsEditing = false
            return picker
        }
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        var didSkipOversizedImages = false
        var didSkipDuplicates = false

        init(parent: ImagePicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            // 使用者取消或清空全部選擇
            if results.isEmpty {
                DispatchQueue.main.async {
                    self.parent.selectedPhotos.removeAll()
                }
                return
            }

            // 取得最新選的 assetId 集合
            let newSelectedAssetIds = Set(results.compactMap { $0.assetIdentifier })

            DispatchQueue.main.async {
                // 移除已取消勾選的照片（有 assetId且不在新集合的）
                self.parent.selectedPhotos.removeAll { photo in
                    if let id = photo.assetId {
                        return !newSelectedAssetIds.contains(id)
                    }
                    // 無 assetId（相機拍攝）不刪除
                    return false
                }
            }

            didSkipOversizedImages = false
            didSkipDuplicates = false

            let group = DispatchGroup()
            for result in results {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                let assetId = result.assetIdentifier
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { reading, _ in
                    defer { group.leave() }
                    guard let image = reading as? UIImage else { return }

                    guard let finalData = self.compressImageData(image, toMaxKB: self.parent.maxFileSizeKB) else {
                        self.didSkipOversizedImages = true
                        return
                    }

                    let hash = self.sha256String(finalData)

                    DispatchQueue.main.async {
                        if self.parent.selectedPhotos.count >= self.parent.maxCount { return }

                        if let id = assetId, self.parent.selectedPhotos.contains(where: { $0.assetId == id }) {
                            self.didSkipDuplicates = true
                            return
                        }
                        if self.parent.selectedPhotos.contains(where: { $0.hash == hash }) {
                            self.didSkipDuplicates = true
                            return
                        }

                        if let uiImage = UIImage(data: finalData) {
                            self.parent.selectedPhotos.append(
                                SelectedPhoto(image: uiImage, assetId: assetId, hash: hash)
                            )
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                if self.didSkipOversizedImages {
                    self.parent.alertMessage = "部分圖片大小超過 \(Int(self.parent.maxFileSizeKB))KB，已略過。"
                    self.parent.showAlert = true
                } else if self.didSkipDuplicates {
                    self.parent.alertMessage = "已略過重複照片。"
                    self.parent.showAlert = true
                }
            }
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage,
               let finalData = compressImageData(image, toMaxKB: parent.maxFileSizeKB) {
                let hash = sha256String(finalData)
                DispatchQueue.main.async {
                    if self.parent.selectedPhotos.contains(where: { $0.hash == hash }) {
                        self.parent.alertMessage = "已略過重複照片。"
                        self.parent.showAlert = true
                        return
                    }
                    if self.parent.selectedPhotos.count < self.parent.maxCount,
                       let uiImage = UIImage(data: finalData) {
                        self.parent.selectedPhotos.append(
                            SelectedPhoto(image: uiImage, assetId: nil, hash: hash)
                        )
                    } else {
                        self.parent.alertMessage = "最多只能選 \(self.parent.maxCount) 張圖片。"
                        self.parent.showAlert = true
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.parent.alertMessage = "圖片大小超過 \(Int(self.parent.maxFileSizeKB))KB或讀取錯誤。後台容量為免費測試使用，容量不足敬請見諒。"
                    self.parent.showAlert = true
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }

        func compressImageData(_ image: UIImage, toMaxKB maxKB: Double) -> Data? {
            let maxBytes = Int(maxKB * 1024)
            var compression: CGFloat = 1.0
            guard var data = image.jpegData(compressionQuality: compression) else { return nil }
            while data.count > maxBytes && compression > 0.01 {
                compression -= 0.05
                if let d = image.jpegData(compressionQuality: compression) {
                    data = d
                } else { break }
            }
            return data.count <= maxBytes ? data : nil
        }

        func sha256String(_ data: Data) -> String {
            let digest = SHA256.hash(data: data)
            return digest.map { String(format: "%02x", $0) }.joined()
        }
    }
}


