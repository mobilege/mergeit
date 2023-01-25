import ArgumentParser
import Foundation
import PDFKit

@main
struct MergeIt: ParsableCommand {

    @Argument var path: String = "/Users/rabinjoshi/Developer/proj/MergeIt/files"

    mutating func run() throws {
        printPaths()
    }

    func printPaths() {
        print("Path: \(path)")

        guard let url = URL(string: path) else {
            print(">>> Error: Path invalid")
            return
        }

        let files = FileDesc.contentsOfDirectory(url: url)
        let pdfs = files.filter({ $0.isPDF })
        pdfs.forEach({
            print($0.lastPathComponent)
        })

        let sorted = pdfs.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let docs = sorted.compactMap(\.pdfDoc)

        let doc = PDFDocument()
        doc.outlineRoot = PDFOutline()
        doc.append(docs)

        let writePath = url.appending(path: "all.pdf")
        doc.write(toFile: writePath.absoluteString)
    }
}



struct FileDesc {
    let url: URL
    let lastPathComponent: String
    let absoluteString: String

    var isPDF: Bool {
        lastPathComponent.hasSuffix(".pdf")
    }

    var pdfDoc: PDFDocument? {
        PDFDocument(url: url)
    }

    init(url: URL) {
        self.url = url
        self.lastPathComponent = url.lastPathComponent
        self.absoluteString = url.absoluteString
    }

    static func contentsOfDirectory(url: URL) -> [FileDesc] {
        do {
            let fm = FileManager.default
            let contents = try fm.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )
            let files = contents.map({ FileDesc(url: $0) })
            return files
        } catch {
            print("failed to read directory – bad permissions, perhaps?")
            return []
        }
    }
}


extension PDFDocument {
    func append(_ doc: PDFDocument) {
        for p in 0..<doc.pageCount {
            if let page = doc.page(at: p) {
                insert(page, at: pageCount)

                let bounds = page.bounds(for: .mediaBox)
                let topLeft = NSMakePoint(bounds.minX, bounds.height)
                let outline = PDFOutline()
                outline.label = "Page \(pageCount)"
                outline.destination = PDFDestination(page: page, at: topLeft)
                outlineRoot?.insertChild(outline, at: pageCount - 1)
            }
        }
    }

    func append(_ docs: [PDFDocument]) {
        for doc in docs {
            append(doc)
        }
    }
}
