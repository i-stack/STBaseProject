//
//  STData.swift
//  STBaseProject
//
//  Created by 寒江孤影 on 2019/1/21.
//

import CryptoKit
import Foundation
#if canImport(Security)
import Security
#endif

#if canImport(Compression)
import Compression
#endif

private func encodeHexSequence<S: Sequence>(_ bytes: S, uppercase: Bool = false) -> String where S.Element == UInt8 {
    let format = uppercase ? "%02X" : "%02x"
    return bytes.map { String(format: format, $0) }.joined()
}

public extension Data {
    /// 追加字符串到 Data
    /// - Parameter string: 要追加的字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }

    // MARK: - String Conversion

    /// 使用指定编码将数据解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串，失败返回 nil
    func string(using encoding: String.Encoding = .utf8) -> String? {
        String(data: self, encoding: encoding)
    }

    /// UTF-8 字符串表示，失败返回 nil
    var utf8String: String? {
        string(using: .utf8)
    }

    /// UTF-8 字符串表示，失败时返回默认值
    /// - Parameter defaultValue: 解码失败时的默认值
    /// - Returns: 解码后的字符串
    func utf8String(or defaultValue: String = "") -> String {
        utf8String ?? defaultValue
    }
    
    // MARK: - Encodings

    /// 十六进制字符串表示（小写）
    var hexString: String {
        hexEncodedString()
    }

    /// 转换为十六进制字符串
    /// - Parameter uppercase: 是否使用大写字母，默认为 false
    /// - Returns: 十六进制字符串
    func hexEncodedString(uppercase: Bool = false) -> String {
        encodeHexSequence(self, uppercase: uppercase)
    }

    /// 从十六进制字符串解码为 Data
    /// - Parameter hexString: 十六进制字符串
    /// - Returns: Data 对象，失败返回 nil
    static func hexDecoded(_ hexString: String) -> Data? {
        let trimmedHex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedHex = if trimmedHex.hasPrefix("0x") || trimmedHex.hasPrefix("0X") {
            String(trimmedHex.dropFirst(2))
        } else {
            trimmedHex
        }
        let cleanHex = normalizedHex.unicodeScalars
            .filter { !$0.properties.isWhitespace }
            .map(String.init)
            .joined()
        guard cleanHex.count % 2 == 0 else { return nil }
        var data = Data(capacity: cleanHex.count / 2)
        var index = cleanHex.startIndex
        while index < cleanHex.endIndex {
            let nextIndex = cleanHex.index(index, offsetBy: 2)
            let byteString = cleanHex[index..<nextIndex]
            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        return data
    }

    /// Base64 字符串表示
    var base64String: String {
        base64EncodedString()
    }

    /// URL 安全的 Base64 字符串表示
    var base64URLSafeString: String {
        base64URLSafeEncodedString()
    }

    /// 转换为 Base64 字符串（URL 安全）
    /// - Returns: URL 安全的 Base64 字符串
    func base64URLSafeEncodedString() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// 从 URL 安全的 Base64 字符串解码为 Data
    /// - Parameter base64URLSafeString: URL 安全的 Base64 字符串
    /// - Returns: Data 对象，失败返回 nil
    static func base64URLSafeDecoded(_ base64URLSafeString: String) -> Data? {
        var base64String = base64URLSafeString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64String)
    }
    
    /// MD5 哈希
    /// - Returns: MD5 哈希字符串
    func md5() -> String {
        let digest = Insecure.MD5.hash(data: self)
        return encodeHexSequence(digest)
    }
    
    /// SHA1 哈希
    /// - Returns: SHA1 哈希字符串
    func sha1() -> String {
        let digest = Insecure.SHA1.hash(data: self)
        return encodeHexSequence(digest)
    }
    
    /// SHA256 哈希
    /// - Returns: SHA256 哈希字符串
    func sha256() -> String {
        let digest = SHA256.hash(data: self)
        return encodeHexSequence(digest)
    }
    
    /// SHA512 哈希
    /// - Returns: SHA512 哈希字符串
    func sha512() -> String {
        let digest = SHA512.hash(data: self)
        return encodeHexSequence(digest)
    }
        
    /// 写入文件
    /// - Parameter url: 文件 URL
    /// - Parameter options: 写入选项
    /// - Returns: 是否写入成功
    @discardableResult
    func writeIfPossible(to url: URL, options: Data.WritingOptions = []) -> Bool {
        do {
            try write(to: url, options: options)
            return true
        } catch {
            return false
        }
    }

    /// 从文件读取 Data
    /// - Parameter url: 文件 URL
    /// - Returns: Data 对象，失败返回 nil
    static func contentsOfFile(at url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }

    /// 从文件路径读取 Data
    /// - Parameter path: 文件路径
    /// - Returns: Data 对象，失败返回 nil
    static func contentsOfFile(path: String) -> Data? {
        contentsOfFile(at: URL(fileURLWithPath: path))
    }

    // MARK: - Size

    /// 字节数
    var byteCount: Int {
        count
    }

    /// KB 大小
    var kilobyteCount: Double {
        Double(count) / 1024.0
    }

    /// MB 大小
    var megabyteCount: Double {
        kilobyteCount / 1024.0
    }

    /// GB 大小
    var gigabyteCount: Double {
        megabyteCount / 1024.0
    }

    /// 格式化后的字节数字符串
    /// - Parameter includeUnit: 是否包含单位
    /// - Returns: 格式化后的字符串
    func formattedByteCount(includeUnit: Bool = true) -> String {
        let bytes = Double(count)

        if bytes < 1024 {
            return includeUnit ? "\(count) B" : "\(count)"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", bytes / (1024 * 1024 * 1024))
        }
    }
    
    #if canImport(Compression)
    /// 压缩数据（使用 LZFSE 算法）
    /// - Returns: 压缩后的数据，失败返回 nil
    func compressed() -> Data? {
        processedByCompressionStream(
            operation: COMPRESSION_STREAM_ENCODE,
            algorithm: COMPRESSION_LZFSE,
            initialCapacity: count
        )
    }
    
    /// 解压数据（使用 LZFSE 算法）
    /// - Parameter expectedSize: 预期的解压大小
    /// - Returns: 解压后的数据，失败返回 nil
    func decompressed(expectedSize: Int) -> Data? {
        processedByCompressionStream(
            operation: COMPRESSION_STREAM_DECODE,
            algorithm: COMPRESSION_LZFSE,
            initialCapacity: Swift.max(expectedSize, count)
        )
    }

    /// 解压数据（使用 LZFSE 算法）
    /// - Returns: 解压后的数据，失败返回 nil
    func decompressed() -> Data? {
        processedByCompressionStream(
            operation: COMPRESSION_STREAM_DECODE,
            algorithm: COMPRESSION_LZFSE,
            initialCapacity: count
        )
    }
    #endif
    
    /// 是否为有效的 UTF-8 数据
    var isValidUTF8: Bool {
        return string(using: .utf8) != nil
    }
    
    /// 是否为有效的 JSON 数据
    var isValidJSON: Bool {
        return jsonObject() != nil
    }

    // MARK: - Slicing

    /// 按偏移量切片
    /// - Parameters:
    ///   - index: 起始位置
    ///   - length: 长度，nil 表示到结尾
    /// - Returns: 切片后的 Data
    func slice(from index: Int, length: Int? = nil) -> Data {
        if let length, length <= 0 {
            return Data()
        }
        let startIndex = Swift.max(0, index)
        let endIndex = length.map { startIndex + $0 } ?? count
        let validEndIndex = Swift.min(endIndex, count)
        guard startIndex < validEndIndex else { return Data() }
        return subdata(in: startIndex..<validEndIndex)
    }

    /// 按固定大小切分为多个数据块
    /// - Parameter size: 每个数据块大小
    /// - Returns: 切分后的数组
    func chunks(ofSize size: Int) -> [Data] {
        guard size > 0 else { return [self] }
        guard !isEmpty else { return [] }
        var chunks: [Data] = []
        chunks.reserveCapacity((count + size - 1) / size)
        var offset = 0
        while offset < count {
            let length = Swift.min(size, count - offset)
            chunks.append(subdata(in: offset..<(offset + length)))
            offset += length
        }
        return chunks
    }
    
    // MARK: - Utility

    /// 创建指定长度的随机数据
    /// - Parameter length: 数据长度
    /// - Returns: 随机数据
    static func random(length: Int) -> Data {
        STDataUtils.randomData(length: length)
    }

    /// 常数时间比较，避免长度相同情况下的时序泄露
    /// - Parameter other: 需要比较的目标数据
    /// - Returns: 是否相等
    func constantTimeEquals(to other: Data) -> Bool {
        STDataUtils.constantTimeEquals(self, other)
    }
}

public extension String {
    // MARK: - Encodings

    /// 将字符串编码为 Data
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 编码后的 Data
    func encodedData(using encoding: String.Encoding = .utf8) -> Data? {
        data(using: encoding)
    }

    /// Base64 编码字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: Base64 编码结果
    func base64Encoded(encoding: String.Encoding = .utf8) -> String {
        guard let data = encodedData(using: encoding) else { return "" }
        return data.base64EncodedString()
    }

    /// 从 Base64 解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func base64DecodedString(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data(base64Encoded: self) else { return "" }
        return data.string(using: encoding) ?? ""
    }

    /// URL 安全的 Base64 编码字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: URL 安全的 Base64 编码结果
    func base64URLSafeEncoded(encoding: String.Encoding = .utf8) -> String {
        guard let data = encodedData(using: encoding) else { return "" }
        return data.base64URLSafeEncodedString()
    }

    /// 从 URL 安全的 Base64 解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func base64URLSafeDecodedString(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data.base64URLSafeDecoded(self) else { return "" }
        return data.string(using: encoding) ?? ""
    }

    /// 十六进制编码字符串
    /// - Parameters:
    ///   - encoding: 字符编码，默认为 UTF-8
    ///   - uppercase: 是否使用大写字母
    /// - Returns: 十六进制编码结果
    func hexEncoded(encoding: String.Encoding = .utf8, uppercase: Bool = false) -> String {
        guard let data = encodedData(using: encoding) else { return "" }
        return data.hexEncodedString(uppercase: uppercase)
    }

    /// 从十六进制解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func hexDecodedString(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data.hexDecoded(self) else { return "" }
        return data.string(using: encoding) ?? ""
    }

    /// 是否为有效的 Base64 字符串
    var isBase64Encoded: Bool {
        Data(base64Encoded: self) != nil
    }

    /// 是否为有效的十六进制字符串
    var isHexEncoded: Bool {
        let cleanHex = unicodeScalars
            .filter { !$0.properties.isWhitespace }
            .map(String.init)
            .joined()
        guard cleanHex.count % 2 == 0 else { return false }
        let hexPattern = "^[0-9A-Fa-f]+$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: cleanHex.count)
        return regex?.firstMatch(in: cleanHex, options: [], range: range) != nil
    }

}

public struct STDataUtils {
    /// 创建随机数据
    /// - Parameter length: 数据长度
    /// - Returns: 随机数据
    public static func randomData(length: Int) -> Data {
        guard length > 0 else { return Data() }
        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        guard status == errSecSuccess else { return Data() }
        return Data(bytes)
    }
    
    /// 合并多个 Data
    /// - Parameter dataArray: Data 数组
    /// - Returns: 合并后的 Data
    public static func merge(_ dataArray: [Data]) -> Data {
        let totalByteCount = dataArray.reduce(into: 0) { $0 += $1.count }
        var result = Data(capacity: totalByteCount)
        for data in dataArray {
            result.append(data)
        }
        return result
    }
    
    /// 比较两个 Data 是否相等（常数时间比较，防止时序攻击）
    /// - Parameters:
    ///   - lhs: 第一个 Data
    ///   - rhs: 第二个 Data
    /// - Returns: 是否相等
    public static func constantTimeEquals(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        guard !lhs.isEmpty else { return true }
        
        var result: UInt8 = 0
        lhs.withUnsafeBytes { (lhsBuffer: UnsafeRawBufferPointer) in
            rhs.withUnsafeBytes { (rhsBuffer: UnsafeRawBufferPointer) in
                guard
                    let lhsBaseAddress = lhsBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    let rhsBaseAddress = rhsBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self)
                else {
                    return
                }
                
                for index in 0..<lhs.count {
                    result |= lhsBaseAddress[index] ^ rhsBaseAddress[index]
                }
            }
        }
        
        return result == 0
    }
}

#if canImport(Compression)
private extension Data {
    func processedByCompressionStream(
        operation: compression_stream_operation,
        algorithm: compression_algorithm,
        initialCapacity: Int
    ) -> Data? {
        guard !isEmpty else { return Data() }

        return self.withUnsafeBytes { (rawBuffer: UnsafeRawBufferPointer) -> Data? in
            guard let sourceBaseAddress = rawBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return Data()
            }

            let destinationBufferSize = 64 * 1024
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: destinationBufferSize)
            defer { destinationBuffer.deallocate() }

            var stream = compression_stream(
                dst_ptr: destinationBuffer,
                dst_size: destinationBufferSize,
                src_ptr: sourceBaseAddress,
                src_size: count,
                state: nil
            )
            let status = compression_stream_init(&stream, operation, algorithm)
            guard status != COMPRESSION_STATUS_ERROR else { return nil }
            defer { compression_stream_destroy(&stream) }

            var output = Data()
            output.reserveCapacity(Swift.max(initialCapacity, destinationBufferSize))

            while true {
                let flags: Int32
                if operation == COMPRESSION_STREAM_ENCODE, stream.src_size == 0 {
                    flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
                } else {
                    flags = 0
                }

                let processStatus = compression_stream_process(&stream, flags)
                let producedSize = destinationBufferSize - stream.dst_size

                if producedSize > 0 {
                    output.append(destinationBuffer, count: producedSize)
                    stream.dst_ptr = destinationBuffer
                    stream.dst_size = destinationBufferSize
                }

                switch processStatus {
                case COMPRESSION_STATUS_OK:
                    continue
                case COMPRESSION_STATUS_END:
                    return output
                default:
                    return nil
                }
            }
        }
    }
}
#endif
