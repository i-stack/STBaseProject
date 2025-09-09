//
//  STData.swift
//  STBaseProject
//
//  Created by song on 2019/1/21.
//  Updated for STBaseProject 2.0.0
//

import Foundation
import CryptoKit

#if canImport(Compression)
import Compression
#endif

// MARK: - Data Extension
public extension Data {
    
    // MARK: - String Operations
    
    /// 追加字符串到 Data
    /// - Parameter string: 要追加的字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
    
    /// 转换为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 转换后的字符串，失败返回 nil
    func toString(encoding: String.Encoding = .utf8) -> String? {
        return String(data: self, encoding: encoding)
    }
    
    /// 转换为 UTF-8 字符串（安全）
    /// - Parameter defaultValue: 转换失败时的默认值
    /// - Returns: 转换后的字符串
    func toStringUTF8(defaultValue: String = "") -> String {
        return toString(encoding: .utf8) ?? defaultValue
    }
    
    // MARK: - Hex Operations
    
    /// 转换为十六进制字符串
    /// - Parameter uppercase: 是否使用大写字母，默认为 false
    /// - Returns: 十六进制字符串
    func toHexString(uppercase: Bool = false) -> String {
        let format = uppercase ? "%02X" : "%02x"
        return map { String(format: format, $0) }.joined()
    }
    
    /// 从十六进制字符串创建 Data
    /// - Parameter hexString: 十六进制字符串
    /// - Returns: Data 对象，失败返回 nil
    static func fromHexString(_ hexString: String) -> Data? {
        let cleanHex = hexString.replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return nil }
        
        var data = Data()
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
    
    // MARK: - Base64 Operations
    
    /// 转换为 Base64 字符串
    /// - Parameter options: Base64 编码选项
    /// - Returns: Base64 字符串
    func toBase64String(options: Data.Base64EncodingOptions = []) -> String {
        return base64EncodedString(options: options)
    }
    
    /// 从 Base64 字符串创建 Data
    /// - Parameter base64String: Base64 字符串
    /// - Parameter options: Base64 解码选项
    /// - Returns: Data 对象，失败返回 nil
    static func fromBase64String(_ base64String: String, options: Data.Base64DecodingOptions = []) -> Data? {
        return Data(base64Encoded: base64String, options: options)
    }
    
    /// 转换为 Base64 字符串（URL 安全）
    /// - Returns: URL 安全的 Base64 字符串
    func toBase64URLSafeString() -> String {
        return base64EncodedString(options: .endLineWithCarriageReturn)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// 从 URL 安全的 Base64 字符串创建 Data
    /// - Parameter base64URLSafeString: URL 安全的 Base64 字符串
    /// - Returns: Data 对象，失败返回 nil
    static func fromBase64URLSafeString(_ base64URLSafeString: String) -> Data? {
        var base64String = base64URLSafeString
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        // 添加填充
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        
        return Data(base64Encoded: base64String)
    }
    
    
    // MARK: - Hash Operations
    
    /// MD5 哈希
    /// - Returns: MD5 哈希字符串
    func md5() -> String {
        let digest = Insecure.MD5.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// SHA1 哈希
    /// - Returns: SHA1 哈希字符串
    func sha1() -> String {
        let digest = Insecure.SHA1.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// SHA256 哈希
    /// - Returns: SHA256 哈希字符串
    func sha256() -> String {
        let digest = SHA256.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    /// SHA512 哈希
    /// - Returns: SHA512 哈希字符串
    func sha512() -> String {
        let digest = SHA512.hash(data: self)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - File Operations
    
    /// 写入文件
    /// - Parameter url: 文件 URL
    /// - Parameter options: 写入选项
    /// - Returns: 是否写入成功
    @discardableResult
    func writeToFile(at url: URL, options: Data.WritingOptions = []) -> Bool {
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
    static func fromFile(at url: URL) -> Data? {
        do {
            return try Data(contentsOf: url)
        } catch {
            return nil
        }
    }
    
    /// 从文件路径读取 Data
    /// - Parameter path: 文件路径
    /// - Returns: Data 对象，失败返回 nil
    static func fromFile(path: String) -> Data? {
        let url = URL(fileURLWithPath: path)
        return fromFile(at: url)
    }
    
    // MARK: - Size Operations
    
    /// 数据大小（字节）
    var sizeInBytes: Int {
        return count
    }
    
    /// 数据大小（KB）
    var sizeInKB: Double {
        return Double(count) / 1024.0
    }
    
    /// 数据大小（MB）
    var sizeInMB: Double {
        return sizeInKB / 1024.0
    }
    
    /// 数据大小（GB）
    var sizeInGB: Double {
        return sizeInMB / 1024.0
    }
    
    /// 格式化的大小字符串
    /// - Parameter includeBytes: 是否包含字节单位
    /// - Returns: 格式化的大小字符串
    func formattedSize(includeBytes: Bool = true) -> String {
        let bytes = Double(count)
        
        if bytes < 1024 {
            return includeBytes ? "\(count) B" : "\(count)"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", bytes / 1024)
        } else if bytes < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB", bytes / (1024 * 1024))
        } else {
            return String(format: "%.1f GB", bytes / (1024 * 1024 * 1024))
        }
    }
    
    // MARK: - Compression
    
    #if canImport(Compression)
    /// 压缩数据（使用 LZFSE 算法）
    /// - Returns: 压缩后的数据，失败返回 nil
    func compressed() -> Data? {
        return self.withUnsafeBytes { buffer in
            let buffer = buffer.bindMemory(to: UInt8.self)
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            defer { destinationBuffer.deallocate() }
            
            let compressedSize = compression_encode_buffer(
                destinationBuffer, count,
                buffer.baseAddress!, count,
                nil, COMPRESSION_LZFSE
            )
            
            guard compressedSize > 0 else { return nil }
            return Data(bytes: destinationBuffer, count: compressedSize)
        }
    }
    
    /// 解压数据（使用 LZFSE 算法）
    /// - Parameter expectedSize: 预期的解压大小
    /// - Returns: 解压后的数据，失败返回 nil
    func decompressed(expectedSize: Int) -> Data? {
        return self.withUnsafeBytes { buffer in
            let buffer = buffer.bindMemory(to: UInt8.self)
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: expectedSize)
            defer { destinationBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destinationBuffer, expectedSize,
                buffer.baseAddress!, count,
                nil, COMPRESSION_LZFSE
            )
            
            guard decompressedSize > 0 else { return nil }
            return Data(bytes: destinationBuffer, count: decompressedSize)
        }
    }
    #endif
    
    // MARK: - Validation
    
    /// 是否为空
    var isEmpty: Bool {
        return count == 0
    }
    
    /// 是否为有效的 UTF-8 数据
    var isValidUTF8: Bool {
        return toString(encoding: .utf8) != nil
    }
    
    /// 是否为有效的 JSON 数据
    var isValidJSON: Bool {
        return st_toJSONObject() != nil
    }
    
    // MARK: - Utility
    
    /// 截取子数据
    /// - Parameters:
    ///   - from: 起始位置
    ///   - length: 长度，nil 表示到结尾
    /// - Returns: 子数据
    func subdata(from index: Int, length: Int? = nil) -> Data {
        let startIndex = Swift.max(0, index)
        let endIndex = length.map { startIndex + $0 } ?? count
        let validEndIndex = Swift.min(endIndex, count)
        
        guard startIndex < validEndIndex else { return Data() }
        
        return subdata(in: startIndex..<validEndIndex)
    }
    
    /// 分割数据
    /// - Parameter chunkSize: 每块的大小
    /// - Returns: 分割后的数据数组
    func chunked(into chunkSize: Int) -> [Data] {
        guard chunkSize > 0 else { return [self] }
        
        var chunks: [Data] = []
        var offset = 0
        
        while offset < count {
            let length = Swift.min(chunkSize, count - offset)
            let chunk = subdata(in: offset..<(offset + length))
            chunks.append(chunk)
            offset += length
        }
        
        return chunks
    }
}

// MARK: - String 编码转换扩展

public extension String {
    
    // MARK: - Base64 编码转换
    
    /// 转换为 Base64 编码字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: Base64 编码字符串
    func st_toBase64(encoding: String.Encoding = .utf8) -> String {
        guard let data = data(using: encoding) else { return "" }
        return data.toBase64String()
    }
    
    /// 从 Base64 解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func st_fromBase64(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data.fromBase64String(self) else { return "" }
        return data.toString(encoding: encoding) ?? ""
    }
    
    /// 转换为 URL 安全的 Base64 编码字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: URL 安全的 Base64 编码字符串
    func st_toBase64URLSafe(encoding: String.Encoding = .utf8) -> String {
        guard let data = data(using: encoding) else { return "" }
        return data.toBase64URLSafeString()
    }
    
    /// 从 URL 安全的 Base64 解码为字符串
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func st_fromBase64URLSafe(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data.fromBase64URLSafeString(self) else { return "" }
        return data.toString(encoding: encoding) ?? ""
    }
    
    // MARK: - 十六进制编码转换
    
    /// 转换为十六进制字符串
    /// - Parameters:
    ///   - encoding: 字符编码，默认为 UTF-8
    ///   - uppercase: 是否使用大写字母，默认为 false
    /// - Returns: 十六进制字符串
    func st_toHex(encoding: String.Encoding = .utf8, uppercase: Bool = false) -> String {
        guard let data = data(using: encoding) else { return "" }
        return data.toHexString(uppercase: uppercase)
    }
    
    /// 从十六进制字符串解码
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: 解码后的字符串
    func st_fromHex(encoding: String.Encoding = .utf8) -> String {
        guard let data = Data.fromHexString(self) else { return "" }
        return data.toString(encoding: encoding) ?? ""
    }
    
    // MARK: - 其他编码转换
    
    /// 转换为指定编码的 Data
    /// - Parameter encoding: 字符编码，默认为 UTF-8
    /// - Returns: Data 对象
    func st_toData(encoding: String.Encoding = .utf8) -> Data? {
        return data(using: encoding)
    }
    
    /// 检查是否为有效的 Base64 字符串
    /// - Returns: 是否为有效的 Base64 字符串
    func st_isValidBase64() -> Bool {
        return Data.fromBase64String(self) != nil
    }
    
    /// 检查是否为有效的十六进制字符串
    /// - Returns: 是否为有效的十六进制字符串
    func st_isValidHex() -> Bool {
        let cleanHex = replacingOccurrences(of: " ", with: "")
        guard cleanHex.count % 2 == 0 else { return false }
        
        let hexPattern = "^[0-9A-Fa-f]+$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: cleanHex.count)
        return regex?.firstMatch(in: cleanHex, options: [], range: range) != nil
    }
}

// MARK: - Data Utilities
public struct STDataUtils {
    
    /// 创建随机数据
    /// - Parameter length: 数据长度
    /// - Returns: 随机数据
    public static func randomData(length: Int) -> Data {
        var data = Data(count: length)
        _ = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, length, bytes.baseAddress!)
        }
        return data
    }
    
    /// 合并多个 Data
    /// - Parameter dataArray: Data 数组
    /// - Returns: 合并后的 Data
    static func merge(_ dataArray: [Data]) -> Data {
        var result = Data()
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
        
        var result: UInt8 = 0
        for i in 0..<lhs.count {
            result |= lhs[i] ^ rhs[i]
        }
        
        return result == 0
    }
}
