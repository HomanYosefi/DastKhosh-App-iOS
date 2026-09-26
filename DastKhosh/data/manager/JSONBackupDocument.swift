//
//  JSONBackupDocument.swift
//  DastKhosh
//
//  Created by homan on 1405.07.02.
//

import SwiftUI
import UniformTypeIdentifiers

struct JSONBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var jsonData: Data

    init(jsonData: Data) {
        self.jsonData = jsonData
    }

    init(configuration: ReadConfiguration) throws {
        self.jsonData = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: jsonData)
    }
}
