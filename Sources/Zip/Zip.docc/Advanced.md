# Advanced Zip

Use the advanced functions in Zip.

## Overview

For more advanced usage, Zip has functions that let you set custom destination paths, work with password protected zips and use a progress handling closure.
These functions throw if there is an error, but don't return.

### Usage

```swift
import Zip

do {
  let filePath = Bundle.main.url(forResource: "file", withExtension: "zip")!
  let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  try Zip.unzipFile(filePath, destination: documentsDirectory, overwrite: true, password: "password") { progress in
    print(progress)
  }

  let zipFilePath = documentsFolder.appendingPathComponent("archive.zip")
  try Zip.zipFiles([filePath], zipFilePath: zipFilePath, password: "password") { progress in
    print(progress)
  }
} catch {
  print("Something went wrong")
}
```

## Topics

### Advanced Functions

- ``Zip/zipFiles(paths:zipFilePath:password:compression:progress:)``
- ``Zip/unzipFile(_:destination:overwrite:password:progress:fileOutputHandler:)``
