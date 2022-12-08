//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project.
//
// Copyright (c) 2022 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Teco project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// THIS FILE IS AUTOMATICALLY GENERATED by TecoCommonErrorGenerator.
// DO NOT EDIT.

extension TCCommonError {
    public struct AuthFailure: TCErrorType {
        enum Code: String {
            case invalidAuthorization = "AuthFailure.InvalidAuthorization"
            case invalidSecretId = "AuthFailure.InvalidSecretId"
            case mfaFailure = "AuthFailure.MFAFailure"
            case secretIdNotFound = "AuthFailure.SecretIdNotFound"
            case signatureExpire = "AuthFailure.SignatureExpire"
            case signatureFailure = "AuthFailure.SignatureFailure"
            case tokenFailure = "AuthFailure.TokenFailure"
            case unauthorizedOperation = "AuthFailure.UnauthorizedOperation"
        }
        
        private let error: Code
        
        public let context: TCErrorContext?
        
        public var errorCode: String {
            self.error.rawValue
        }
        
        public init ?(errorCode: String, context: TCErrorContext) {
            guard let error = Code(rawValue: errorCode) else {
                return nil
            }
            self.error = error
            self.context = context
        }
        
        internal init (_ error: Code, context: TCErrorContext? = nil) {
            self.error = error
            self.context = context
        }
        
        /// 请求头部的Authorization不符合腾讯云标准。
        public static var invalidAuthorization: AuthFailure {
            AuthFailure(.invalidAuthorization)
        }
        
        /// Invalid key (not a TencentCloud API key type). / 密钥非法（不是云API密钥类型）。
        public static var invalidSecretId: AuthFailure {
            AuthFailure(.invalidSecretId)
        }
        
        /// MFA failed. / MFA错误。
        public static var mfaFailure: AuthFailure {
            AuthFailure(.mfaFailure)
        }
        
        /// The key does not exist. / 密钥不存在。请在控制台检查密钥是否已被删除或者禁用，如状态正常，请检查密钥是否填写正确，注意前后不得有空格。
        public static var secretIdNotFound: AuthFailure {
            AuthFailure(.secretIdNotFound)
        }
        
        /// Signature expired. / 签名过期。Timestamp和服务器时间相差不得超过五分钟，请检查本地时间是否和标准时间同步。
        public static var signatureExpire: AuthFailure {
            AuthFailure(.signatureExpire)
        }
        
        /// Signature error. / 签名错误。签名计算错误，请对照调用方式中的签名方法文档检查签名计算过程。
        public static var signatureFailure: AuthFailure {
            AuthFailure(.signatureFailure)
        }
        
        /// Token error. / token错误。
        public static var tokenFailure: AuthFailure {
            AuthFailure(.tokenFailure)
        }
        
        /// The request does not have CAM authorization. / 请求未授权。请参考CAM文档对鉴权的说明。
        public static var unauthorizedOperation: AuthFailure {
            AuthFailure(.unauthorizedOperation)
        }
    }
}

extension TCCommonError.AuthFailure: Equatable {
    public static func == (lhs: TCCommonError.AuthFailure, rhs: TCCommonError.AuthFailure) -> Bool {
        lhs.error == rhs.error
    }
}

extension TCCommonError.AuthFailure: CustomStringConvertible {
    public var description: String {
        return "\(self.error.rawValue): \(message ?? "")"
    }
}

extension TCCommonError.AuthFailure {
    public func toCommonError() -> TCCommonError {
        guard let code = TCCommonError.Code(rawValue: self.error.rawValue) else {
            fatalError("Unexpected internal conversion error!\nPlease file a bug at https://github.com/teco-project/teco to help address the problem.")
        }
        return TCCommonError(code, context: self.context)
    }
}