import Foundation
import SwiftUI
import CoreGraphics

/// SwiftUI View'i A4 boyutlu, çok sayfalı PDF olarak render eder ve geçici dosyaya yazar.
///
/// Yöntem: İçerik tek seferde yüksek çözünürlüklü bir `CGImage`'e raster'lanır,
/// ardından A4 yüksekliğinde dilimlere bölünüp her sayfaya **doğru yönde** çizilir.
/// (Eskiden `ImageRenderer.render` closure'ı + manuel y-flip kullanılıyordu; bu
/// çift çevirmeye yol açıp çıktıyı baş aşağı yapıyordu.)
@MainActor
enum PDFReportGenerator {
    static let pageSize = CGSize(width: 595, height: 842) // A4 @72dpi
    private static let margin: CGFloat = 24

    static func generate<Content: View>(
        fileName: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> URL? {
        let view = content()
            .frame(width: pageSize.width - margin * 2, alignment: .leading)
            .padding(margin)
            .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // baskı için keskin

        guard let cgImage = renderer.cgImage else { return nil }

        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        guard imageWidth > 0, imageHeight > 0 else { return nil }

        // Görüntüyü A4 genişliğine ölçekle; toplam çizim yüksekliği ve sayfa sayısı.
        let drawScale = pageSize.width / imageWidth
        let drawHeight = imageHeight * drawScale
        let pageCount = max(1, Int(ceil(drawHeight / pageSize.height)))

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        var box = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdf = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return nil
        }

        for pageIndex in 0..<pageCount {
            pdf.beginPDFPage(nil)
            pdf.saveGState()
            pdf.clip(to: CGRect(origin: .zero, size: pageSize))

            // PDF context'i y-yukarı (origin alt-sol); bu context'te draw(cgImage:in:)
            // görüntüyü doğru yönde çizer — manuel flip YOK.
            // İçeriğin üstü ilk sayfada üstte olacak şekilde dilime hizala.
            let y0 = pageSize.height - drawHeight + CGFloat(pageIndex) * pageSize.height
            pdf.draw(cgImage, in: CGRect(x: 0, y: y0, width: pageSize.width, height: drawHeight))

            pdf.restoreGState()
            pdf.endPDFPage()
        }

        pdf.closePDF()
        return url
    }
}
