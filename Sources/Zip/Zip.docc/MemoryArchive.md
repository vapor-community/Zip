# Archive Data saved in memory

Archive data saved in memory with Zip.

## Overview

Zip provides a way to archive data saved in memory.
This is useful when you want to create a zip archive without having the source files saved to disk.

### Usage

```swift
import Zip

do {
  let archiveFile = ArchiveFile(filename: "file.txt", data: "Hello, World!".data(using: .utf8)!)
  let zipFilePath = FileManager.default.temporaryDirectory.appendingPathComponent("archive.zip")
  try Zip.zipData(archiveFiles: [archiveFile], zipFilePath: zipFilePath)
} catch {
  print("Something went wrong")
}
```

## Topics

### Essentials

- ``Zip/zipData(archiveFiles:zipFilePath:password:compression:progress:)``
- ``ArchiveFile``
