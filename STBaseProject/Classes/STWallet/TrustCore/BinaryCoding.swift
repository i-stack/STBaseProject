// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import Foundation

public protocol BinaryDecoding {
    init(decoding data: Data)
}

public protocol BinaryEncoding {
    func encode(into data: inout Data)
}

public typealias BinaryCoding = BinaryDecoding & BinaryEncoding

extension Data: BinaryEncoding {
    public func encode(into data: inout Data) {
        data.append(self)
    }
}

extension Array: BinaryEncoding where Iterator.Element: BinaryEncoding {
    public func encode(into data: inout Data) {
        writeCompactSize(count, into: &data)
        for item in self {
            item.encode(into: &data)
        }
    }
}

private func writeCompactSize(_ size: Int, into data: inout Data) {
    if size < 253 {
        data.append(UInt8(size))
    } else if size <= UInt16.max {
        data.append(253)
        UInt16(size).encode(into: &data)
    } else if size <= UInt32.max {
        data.append(254)
        UInt32(size).encode(into: &data)
    } else {
        data.append(255)
        UInt64(size).encode(into: &data)
    }
}

// MARK: - Int coding

extension Int: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension UInt: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension Int8: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension UInt8: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension Int16: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension UInt16: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension Int32: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension UInt32: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension Int64: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}

extension UInt64: BinaryCoding {
    public init(decoding data: Data) {
        self.init(littleEndian: data.withUnsafeBytes { $0.pointee })
    }

    public func encode(into data: inout Data) {
        var leValue = littleEndian
        data.append(Data(buffer: UnsafeBufferPointer(start: &leValue, count: 1)))
    }
}
