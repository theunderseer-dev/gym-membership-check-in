import UIKit
import CoreImage.CIFilterBuiltins
import Vision

enum QRDecodeResult: Equatable {
    case success(String)
    case noQRCodeFound
    case couldNotReadImage
}

enum QRCodeHelper {

    static func generateQRCode(from string: String, size: CGSize = CGSize(width: 512, height: 512)) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }

        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    static func decodeQRCode(from image: UIImage) -> QRDecodeResult {
        guard let ciImage = CIImage(image: image) ?? (image.cgImage.map { CIImage(cgImage: $0) }) else {
            return .couldNotReadImage
        }

        var detectedText: String?

        // Try Vision framework
        let request = VNDetectBarcodesRequest { request, error in
            guard error == nil else { return }
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            for result in results where result.symbology == .qr {
                if let payload = result.payloadStringValue, !payload.isEmpty {
                    detectedText = payload
                    break
                }
            }
        }
        request.symbologies = [.qr]

        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try? handler.perform([request])

        if let text = detectedText {
            return .success(text)
        }

        // Fallback to CIDetector
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        let features = detector?.features(in: ciImage) ?? []
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature,
               let message = qrFeature.messageString,
               !message.isEmpty {
                return .success(message)
            }
        }

        return .noQRCodeFound
    }
}
