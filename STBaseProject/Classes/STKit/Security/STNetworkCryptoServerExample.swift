//
//  STNetworkCryptoServerExample.swift
//  STBaseProject
//
//  Created by AI Assistant on 2024/12/19.
//

import Foundation

// MARK: - 服务器端加密解密实现示例
// 这个文件包含了服务器端（Node.js/Express）的完整实现示例
// 用于与iOS客户端进行加密通信

/*
 
 // ===== Node.js/Express 服务器端实现 =====
 
 const crypto = require('crypto');
 const express = require('express');
 const app = express();
 
 // 密钥配置
 const CRYPTO_CONFIG = {
     SHARED_KEY: process.env.SHARED_ENCRYPTION_KEY || 'shared-secret-key-32-chars',
     SIGNING_SECRET: process.env.SIGNING_SECRET || 'signing-secret-key',
     ALGORITHM: 'aes-256-gcm',
     KEY_LENGTH: 32,
     NONCE_LENGTH: 12,
     TAG_LENGTH: 16
 };
 
 // 加密函数
 function encryptData(data, key) {
     try {
         // 生成随机nonce
         const nonce = crypto.randomBytes(CRYPTO_CONFIG.NONCE_LENGTH);
         
         // 创建加密器
         const cipher = crypto.createCipher(CRYPTO_CONFIG.ALGORITHM, key);
         cipher.setAAD(nonce);
         
         // 加密数据
         let encrypted = cipher.update(JSON.stringify(data), 'utf8');
         encrypted += cipher.final();
         
         // 获取认证标签
         const authTag = cipher.getAuthTag();
         
         // 组合nonce + 加密数据 + 认证标签
         return Buffer.concat([nonce, encrypted, authTag]);
     } catch (error) {
         throw new Error('加密失败: ' + error.message);
     }
 }
 
 // 解密函数
 function decryptData(encryptedData, key) {
     try {
         // 提取组件
         const nonce = encryptedData.slice(0, CRYPTO_CONFIG.NONCE_LENGTH);
         const ciphertext = encryptedData.slice(CRYPTO_CONFIG.NONCE_LENGTH, -CRYPTO_CONFIG.TAG_LENGTH);
         const authTag = encryptedData.slice(-CRYPTO_CONFIG.TAG_LENGTH);
         
         // 创建解密器
         const decipher = crypto.createDecipher(CRYPTO_CONFIG.ALGORITHM, key);
         decipher.setAuthTag(authTag);
         decipher.setAAD(nonce);
         
         // 解密数据
         let decrypted = decipher.update(ciphertext, null, 'utf8');
         decrypted += decipher.final('utf8');
         
         return JSON.parse(decrypted);
     } catch (error) {
         throw new Error('解密失败: ' + error.message);
     }
 }
 
 // 生成签名
 function generateSignature(data, timestamp, secret) {
     const dataString = Buffer.isBuffer(data) ? data.toString('base64') : JSON.stringify(data);
     const signString = `${dataString}${timestamp}${secret}`;
     return crypto.createHmac('sha256', secret).update(signString).digest('hex');
 }
 
 // 验证签名
 function verifySignature(data, signature, timestamp, secret) {
     const expectedSignature = generateSignature(data, timestamp, secret);
     return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSignature));
 }
 
 // 密钥管理类
 class KeyManager {
     constructor() {
         this.sharedKey = CRYPTO_CONFIG.SHARED_KEY;
         this.signingSecret = CRYPTO_CONFIG.SIGNING_SECRET;
         this.keyRotationInterval = 24 * 60 * 60 * 1000; // 24小时
         this.lastKeyRotation = Date.now();
     }
     
     // 获取当前密钥
     getCurrentKey() {
         return this.sharedKey;
     }
     
     // 获取签名密钥
     getSigningSecret() {
         return this.signingSecret;
     }
     
     // 检查是否需要轮换密钥
     shouldRotateKey() {
         return Date.now() - this.lastKeyRotation > this.keyRotationInterval;
     }
     
     // 轮换密钥
     rotateKeys() {
         this.sharedKey = crypto.randomBytes(32).toString('hex');
         this.signingSecret = crypto.randomBytes(32).toString('hex');
         this.lastKeyRotation = Date.now();
         console.log('密钥已轮换');
     }
 }
 
 // 创建密钥管理器实例
 const keyManager = new KeyManager();
 
 // 加密解密中间件
 function cryptoMiddleware(req, res, next) {
     // 检查是否需要轮换密钥
     if (keyManager.shouldRotateKey()) {
         keyManager.rotateKeys();
     }
     
     // 解密请求数据
     if (req.headers['x-content-encoding'] === 'encrypted') {
         try {
             const decryptedData = decryptData(req.body, keyManager.getCurrentKey());
             req.body = decryptedData;
             console.log('请求数据解密成功');
         } catch (error) {
             console.error('请求解密失败:', error.message);
             return res.status(400).json({ 
                 error: '请求解密失败',
                 code: 'DECRYPTION_FAILED'
             });
         }
     }
     
     // 验证请求签名
     if (req.headers['x-request-signature'] && req.headers['x-timestamp']) {
         const signature = req.headers['x-request-signature'];
         const timestamp = req.headers['x-timestamp'];
         
         if (!verifySignature(req.body, signature, timestamp, keyManager.getSigningSecret())) {
             console.error('请求签名验证失败');
             return res.status(400).json({ 
                 error: '请求签名验证失败',
                 code: 'SIGNATURE_VERIFICATION_FAILED'
             });
         }
         console.log('请求签名验证成功');
     }
     
     // 重写res.send方法以支持响应加密
     const originalSend = res.send;
     res.send = function(data) {
         // 如果请求要求加密响应
         if (req.headers['x-content-encoding'] === 'encrypted') {
             try {
                 const encryptedData = encryptData(data, keyManager.getCurrentKey());
                 
                 // 设置响应头
                 this.set({
                     'Content-Type': 'application/octet-stream',
                     'X-Content-Encoding': 'encrypted',
                     'X-Response-Signature': generateSignature(encryptedData, req.headers['x-timestamp'], keyManager.getSigningSecret()),
                     'X-Timestamp': req.headers['x-timestamp']
                 });
                 
                 console.log('响应数据加密成功');
                 originalSend.call(this, encryptedData);
             } catch (error) {
                 console.error('响应加密失败:', error.message);
                 originalSend.call(this, { error: '响应加密失败' });
             }
         } else {
             originalSend.call(this, data);
         }
     };
     
     next();
 }
 
 // 应用中间件
 app.use(express.raw({ type: 'application/octet-stream', limit: '10mb' }));
 app.use(express.json({ limit: '10mb' }));
 app.use(cryptoMiddleware);
 
 // 安全登录接口
 app.post('/api/secure-login', (req, res) => {
     try {
         console.log('收到登录请求:', req.body);
         
         const { username, password } = req.body;
         
         // 验证用户名和密码
         if (!username || !password) {
             return res.status(400).json({
                 success: false,
                 message: '用户名和密码不能为空'
             });
         }
         
         // 模拟用户验证
         const isValidUser = validateUser(username, password);
         
         if (isValidUser) {
             // 生成JWT token
             const token = generateJWT({ username, userId: 123 });
             
             const responseData = {
                 success: true,
                 message: '登录成功',
                 data: {
                     token: token,
                     user: {
                         id: 123,
                         username: username,
                         loginTime: new Date().toISOString()
                     }
                 }
             };
             
             res.json(responseData);
         } else {
             res.status(401).json({
                 success: false,
                 message: '用户名或密码错误'
             });
         }
         
     } catch (error) {
         console.error('登录处理错误:', error);
         res.status(500).json({
             success: false,
             message: '服务器内部错误'
         });
     }
 });
 
 // 获取用户信息接口
 app.get('/api/user/profile', (req, res) => {
     try {
         // 验证token
         const token = req.headers.authorization?.replace('Bearer ', '');
         if (!token) {
             return res.status(401).json({
                 success: false,
                 message: '未提供认证token'
             });
         }
         
         // 验证token有效性
         const decoded = verifyJWT(token);
         if (!decoded) {
             return res.status(401).json({
                 success: false,
                 message: 'token无效或已过期'
             });
         }
         
         const userProfile = {
             success: true,
             data: {
                 id: decoded.userId,
                 username: decoded.username,
                 email: 'user@example.com',
                 avatar: 'https://example.com/avatar.jpg',
                 lastLogin: new Date().toISOString()
             }
         };
         
         res.json(userProfile);
         
     } catch (error) {
         console.error('获取用户信息错误:', error);
         res.status(500).json({
             success: false,
             message: '服务器内部错误'
         });
     }
 });
 
 // 模拟用户验证函数
 function validateUser(username, password) {
     // 这里应该连接数据库进行真实验证
     // 示例中简单验证
     return username === 'user123' && password === 'password123';
 }
 
 // 生成JWT token
 function generateJWT(payload) {
     const jwt = require('jsonwebtoken');
     const secret = process.env.JWT_SECRET || 'jwt-secret-key';
     return jwt.sign(payload, secret, { expiresIn: '24h' });
 }
 
 // 验证JWT token
 function verifyJWT(token) {
     const jwt = require('jsonwebtoken');
     const secret = process.env.JWT_SECRET || 'jwt-secret-key';
     try {
         return jwt.verify(token, secret);
     } catch (error) {
         return null;
     }
 }
 
 // 错误处理中间件
 app.use((error, req, res, next) => {
     console.error('服务器错误:', error);
     res.status(500).json({
         success: false,
         message: '服务器内部错误',
         error: process.env.NODE_ENV === 'development' ? error.message : undefined
     });
 });
 
 // 启动服务器
 const PORT = process.env.PORT || 3000;
 app.listen(PORT, () => {
     console.log(`服务器运行在端口 ${PORT}`);
     console.log('加密通信已启用');
 });
 
 // ===== 使用示例 =====
 
 // 1. 安装依赖
 // npm install express crypto jsonwebtoken
 
 // 2. 环境变量配置
 // SHARED_ENCRYPTION_KEY=your-32-character-encryption-key
 // SIGNING_SECRET=your-signing-secret-key
 // JWT_SECRET=your-jwt-secret-key
 
 // 3. 启动服务器
 // node server.js
 
 // 4. 测试加密通信
 // 使用Postman或其他工具发送加密请求到 http://localhost:3000/api/secure-login
 
 */

// MARK: - iOS客户端使用示例
public class STNetworkCryptoClientExample {
    
    /// 发送加密登录请求
    public static func st_sendEncryptedLoginRequest() {
        let url = "https://api.example.com/api/secure-login"
        let parameters = [
            "username": "user123",
            "password": "password123"
        ]
        
        // 配置加密请求
        let requestConfig = STRequestConfig(
            enableEncryption: true,
            encryptionKey: "shared-secret-key-32-chars",
            enableRequestSigning: true,
            signingSecret: "signing-secret-key"
        )
        
        // 发送加密请求
        STHTTPSession.shared.st_post(
            url: url,
            parameters: parameters,
            requestConfig: requestConfig
        ) { response in
            if response.isSuccess {
                print("✅ 加密登录请求成功")
                if let json = response.json as? [String: Any] {
                    print("📦 响应数据: \(json)")
                    
                    // 保存token
                    if let data = json["data"] as? [String: Any],
                       let token = data["token"] as? String {
                        UserDefaults.standard.set(token, forKey: "auth_token")
                        print("🔑 Token已保存")
                    }
                }
            } else {
                print("❌ 加密登录请求失败: \(response.error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    /// 发送加密用户信息请求
    public static func st_sendEncryptedUserProfileRequest() {
        guard let token = UserDefaults.standard.string(forKey: "auth_token") else {
            print("❌ 未找到认证token")
            return
        }
        
        let url = "https://api.example.com/api/user/profile"
        
        // 配置请求头
        let requestHeaders = STRequestHeaders()
        requestHeaders.st_setAuthorization("Bearer \(token)")
        
        // 配置加密请求
        let requestConfig = STRequestConfig(
            enableEncryption: true,
            encryptionKey: "shared-secret-key-32-chars",
            enableRequestSigning: true,
            signingSecret: "signing-secret-key"
        )
        
        // 发送加密请求
        STHTTPSession.shared.st_get(
            url: url,
            requestHeaders: requestHeaders,
            requestConfig: requestConfig
        ) { response in
            if response.isSuccess {
                print("✅ 加密用户信息请求成功")
                if let json = response.json as? [String: Any] {
                    print("📦 用户信息: \(json)")
                }
            } else {
                print("❌ 加密用户信息请求失败: \(response.error?.localizedDescription ?? "未知错误")")
            }
        }
    }
    
    /// 测试加密解密功能
    public static func st_testCryptoFunctionality() {
        let testData = "这是测试数据"
        let key = "test-encryption-key"
        
        do {
            // 加密数据
            let encryptedData = try STNetworkCrypto.st_encryptString(testData, keyString: key)
            print("✅ 数据加密成功: \(encryptedData.count) 字节")
            
            // 解密数据
            let decryptedString = try STNetworkCrypto.st_decryptToString(encryptedData, keyString: key)
            print("✅ 数据解密成功: \(decryptedString)")
            
            // 验证数据完整性
            let isIntegrityValid = STNetworkCrypto.st_verifyDataIntegrity(
                testData.data(using: .utf8)!,
                encryptedData,
                keyString: key
            )
            print("✅ 数据完整性验证: \(isIntegrityValid ? "通过" : "失败")")
            
        } catch {
            print("❌ 加密解密测试失败: \(error)")
        }
    }
    
    /// 测试签名验证功能
    public static func st_testSignatureFunctionality() {
        let testData = "这是需要签名的数据".data(using: .utf8)!
        let secret = "signing-secret"
        let timestamp = Date().timeIntervalSince1970
        
        // 生成签名
        let signature = STNetworkCrypto.st_signData(testData, secret: secret, timestamp: timestamp)
        print("✅ 签名生成成功: \(signature)")
        
        // 验证签名
        let isValid = STNetworkCrypto.st_verifySignature(testData, signature: signature, secret: secret, timestamp: timestamp)
        print("✅ 签名验证: \(isValid ? "通过" : "失败")")
        
        // 测试错误签名
        let invalidSignature = "invalid-signature"
        let isInvalid = STNetworkCrypto.st_verifySignature(testData, signature: invalidSignature, secret: secret, timestamp: timestamp)
        print("✅ 错误签名验证: \(isInvalid ? "通过" : "失败")")
    }
}

// MARK: - 安全最佳实践
public extension STNetworkCryptoClientExample {
    
    /// 安全最佳实践指南
    static func st_securityBestPractices() {
        print("""
        🔒 加密通信安全最佳实践:
        
        1. 密钥管理
           - 使用强密钥（至少32字符）
           - 定期轮换密钥
           - 使用环境变量存储密钥
           - 不要在代码中硬编码密钥
        
        2. 传输安全
           - 始终使用HTTPS
           - 启用SSL证书绑定
           - 验证服务器证书
        
        3. 数据保护
           - 对敏感数据进行端到端加密
           - 使用强加密算法（AES-256-GCM）
           - 包含认证标签防止篡改
        
        4. 签名验证
           - 对所有请求进行签名
           - 包含时间戳防止重放攻击
           - 使用HMAC-SHA256算法
        
        5. 错误处理
           - 不暴露详细的加密错误信息
           - 记录安全事件日志
           - 实现安全降级策略
        
        6. 性能优化
           - 使用异步加密解密
           - 缓存密钥避免重复计算
           - 合理使用加密（不是所有数据都需要加密）
        
        7. 测试验证
           - 测试加密解密功能
           - 验证签名功能
           - 测试错误处理
           - 进行安全渗透测试
        """)
    }
}
