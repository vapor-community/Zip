# ``Zip``

A framework for zipping and unzipping files in Swift.

## Overview

@Row {
    @Column { }
    @Column(size: 4) {
        ![Zip](zip-logo)
    }
    @Column { }
}

Simple and quick to use.
Built on top of [Minizip 1.2](https://github.com/zlib-ng/minizip-ng/tree/1.2).

### Getting Started

Use the SPM string to easily include the dependendency in your `Package.swift` file.

```swift
.package(url: "https://github.com/vapor-community/Zip.git", from: "2.2.0")
```

and add it to your target's dependencies:

```swift
.product(name: "Zip", package: "zip")
```

### Supported Platforms

Zip supports all platforms supported by Swift 5.9 and later.

To use Zip on Windows, you need to pass an available build of `zlib` to the build via extended flags. For example:

```shell
swift build -Xcc -I'C:/pathTo/zlib/include' -Xlinker -L'C:/pathTo/zlib/lib'
```

## Topics

### Essentials

- ``Zip``
- <doc:Quick>
- <doc:Advanced>
- <doc:MemoryArchive>
- ``ZipCompression``

### Errors

- ``ZipError``
