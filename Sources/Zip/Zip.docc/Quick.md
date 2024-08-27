# Quick Functions

Quickly zip and unzip files with Zip.

## Overview

The easiest way to use Zip is through quick functions.
Both take local file paths as `URL`s, throw if an error is encountered and return an `URL` to the destination if successful.

### Usage

```swift
import Zip

do {
  let filePath = Bundle.main.url(forResource: "file", withExtension: "zip")!
  let unzipDirectory = try Zip.quickUnzipFile(filePath)
  let zipFilePath = try Zip.quickZipFiles([filePath], fileName: "archive")
} catch {
  print("Something went wrong")
}
```

## Topics

### Quick Functions

- ``Zip/quickZipFiles(_:fileName:)``
- ``Zip/quickZipFiles(_:fileName:progress:)``
- ``Zip/quickUnzipFile(_:)``
- ``Zip/quickUnzipFile(_:progress:)``
