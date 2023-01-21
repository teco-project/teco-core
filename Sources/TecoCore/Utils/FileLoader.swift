//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// This source file was part of the Soto for AWS open source project
//
// Copyright (c) 2017-2020 the Soto project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Soto project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIOCore
import NIOPosix
#if os(Linux)
import Glibc
#else
import Foundation.NSString
#endif
import class Foundation.JSONDecoder

enum FileLoader {
    static let decoder = JSONDecoder()

    // MARK: File IO

    /// Load a file from disk without blocking the current thread.
    ///
    /// - Parameters:
    ///   - path: Path of the file to load.
    ///   - eventLoop: `EventLoop` to run everything on.
    ///   - callback: Process `ByteBuffer` containing file contents.
    static func loadFile<T>(path: String, on eventLoop: EventLoop, _ callback: @escaping (ByteBuffer) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        let threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()
        let fileIO = NonBlockingFileIO(threadPool: threadPool)

        return self.loadFile(path: path, on: eventLoop, using: fileIO)
            .flatMap(callback)
            .always { _ in
                // shutdown the threadpool async
                threadPool.shutdownGracefully { _ in }
            }
    }

    /// Load a file from disk without blocking the current thread.
    ///
    /// - Parameters:
    ///   - path: Path of the file to load.
    ///   - eventLoop: `EventLoop` to run everything on.
    ///   - fileIO: Non-blocking file IO.
    /// - Returns: File contents in a `ByteBuffer`.
    static func loadFile(path: String, on eventLoop: EventLoop, using fileIO: NonBlockingFileIO) -> EventLoopFuture<ByteBuffer> {
        let path = self.expandTildeInFilePath(path)

        return fileIO.openFile(path: path, eventLoop: eventLoop)
            .flatMap { handle, region in
                fileIO.read(fileRegion: region, allocator: ByteBufferAllocator(), eventLoop: eventLoop)
                    .map {
                        ($0, handle)
                    }
            }
            .flatMapThrowing { byteBuffer, handle in
                try handle.close()
                return byteBuffer
            }
    }

    // MARK: Path expansion

    static func expandTildeInFilePath(_ filePath: String) -> String {
        #if os(Linux)
        // We don't want to add more dependencies on Foundation than needed.
        // For this reason we get the expanded filePath on Linux from libc.
        // Since `wordexp` and `wordfree` are not available on iOS we stay
        // with NSString on Darwin.
        return filePath.withCString { ptr -> String in
            var wexp = wordexp_t()
            guard wordexp(ptr, &wexp, 0) == 0, let we_wordv = wexp.we_wordv else {
                return filePath
            }
            defer {
                wordfree(&wexp)
            }

            guard let resolved = we_wordv[0], let pth = String(cString: resolved, encoding: .utf8) else {
                return filePath
            }

            return pth
        }
        #elseif os(macOS)
        // can not use wordexp on macOS because for sandboxed application wexp.we_wordv == nil
        guard let home = getpwuid(getuid())?.pointee.pw_dir,
              let homePath = String(cString: home, encoding: .utf8)
        else {
            return filePath
        }
        return filePath.starts(with: "~") ? homePath + filePath.dropFirst() : filePath
        #else
        return NSString(string: filePath).expandingTildeInPath
        #endif
    }
}
