import Foundation
import SwiftUI
import PDFKit

/// SwiftUI View'i A4 boyutlu PDF olarak render eder ve geçici dosyaya yazar.
@MainActor
enum PDFReportGenerator {
    static let pageSize = CGSize(width: 595, height: 842) // A4 @72dpi

    static func generate<Content: View>(
        fileName: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> URL? {
        let view = content()
            .frame(width: pageSize.width)
            .padding(24)
            .background(Color.white)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        renderer.proposedSize = .init(width: pageSize.width, height: nil)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).pdf")
        var box = CGRect(origin: .zero, size: pageSize)

        guard let consumer = CGDataConsumer(url: url as CFURL),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else {
            return nil
        }

        renderer.render { size, renderInContext in
            let pageRect = CGRect(origin: .zero, size: pageSize)
            pdfContext.beginPDFPage(nil)
            // Center content horizontally; allow taller-than-page (single long page)
            let scaleX = pageSize.width / size.width
            pdfContext.translateBy(x: 0, y: pageSize.height)
            pdfContext.scaleBy(x: scaleX, y: -scaleX)
            renderInContext(pdfContext)
            pdfContext.endPDFPage()
            _ = pageRect
        }

        pdfContext.closePDF()
        return url
    }
}
