<div align="center">
    <img src="https://cloud.githubusercontent.com/assets/889949/12374908/252373d0-bcac-11e5-8ece-6933aeae8222.png" max-height="200" alt="avatar" />
    <a href="https://swiftpackageindex.com/vapor-community/Zip/documentation">
        <img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
    <a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
    <a href="https://github.com/vapor-community/Zip/actions/workflows/test.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vapor-community/Zip/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration">
    </a>
    <a href="https://codecov.io/github/vapor-community/Zip">
        <img src="https://img.shields.io/codecov/c/github/vapor-community/Zip?style=plastic&logo=codecov&label=codecov">
    </a>
    <a href="https://swift.org">
        <img src="https://design.vapor.codes/images/swift58up.svg" alt="Swift 5.8+">
    </a>
</div>
<br>

A framework for zipping and unzipping files in Swift.

Simple and quick to use.
Built on top of [Minizip 1.2](https://github.com/zlib-ng/minizip-ng/tree/1.2).

Use the SPM string to easily include the dependendency in your `Package.swift` file.

```swift
.package(url: "https://github.com/vapor-community/Zip.git", from: "2.2.0")
```

## Usage

### Quick Functions

The easiest way to use Zip is through quick functions. Both take local file paths as `URL`s, throw if an error is encountered and return an `URL` to the destination if successful.

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

### Advanced Zip

For more advanced usage, Zip has functions that let you set custom destination paths, work with password protected zips and use a progress handling closure. These functions throw if there is an error, but don't return.

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

### Custom File Extensions

Zip supports `.zip` and `.cbz` files out of the box. To support additional zip-derivative file extensions:

```swift
Zip.addCustomFileExtension("file-extension-here")
```
