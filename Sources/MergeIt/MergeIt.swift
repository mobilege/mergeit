import ArgumentParser
import Foundation
import PDFKit

@main
struct MergeIt: ParsableCommand {

    @Argument var path: String = "/Users/rabinjoshi/Developer/proj/MergeIt/files"

    mutating func run() throws {
        do {
            try merge(path: path)
        } catch {
            print(">>> ", error)
        }
    }

    /**

    This function takes a single parameter, a string representing the directory path, and merges all the PDF files present in the directory into a single PDF file named "all.pdf" in the same directory.

    - Parameters:
        - path: A string representing the directory path.

    - Throws:
        - Error: If the provided path is invalid or if the write(toFile:) method fails.

    */
    func merge(path: String) throws {

        let fm = FileManager.default

        guard let url = URL(string: path) else {
            throw Error("Invalid path")
        }

        let urls = try fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        let filtered = urls.filter { $0.pathExtension == "pdf"}
        let sorted = filtered.sorted { $0.lastPathComponent < $1.lastPathComponent }
        let docs = sorted.compactMap { PDFDocument(url: $0) }

        let doc = PDFDocument()
        doc.append(docs)

        // Creates new file path, writes doc to it, throws error if it fails.
        let writePath = url.appending(path: "all.pdf")
        guard doc.write(toFile: writePath.absoluteString) else {
            throw Error("write(toFile:) failed")
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

enum Error: Swift.Error {
    case custom(String)

    init(_ str: String) {
        self = .custom(str)
    }
}

