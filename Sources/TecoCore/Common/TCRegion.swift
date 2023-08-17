//===----------------------------------------------------------------------===//
//
// This source file is part of the Teco open source project
//
// Copyright (c) 2022-2023 the Teco project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// THIS FILE IS AUTOMATICALLY GENERATED by TecoRegionGenerator.
// DO NOT EDIT.

/// Tencent Cloud region identified by Region ID.
public struct TCRegion: Equatable, Sendable {
    /// Raw region ID.
    public var rawValue: String

    /// Tencent Cloud service region kind.
    public enum Kind: Equatable, Sendable {
        /// Global service regions that are open and accessible within each other.
        case global
        /// Financial service regions that are isolated, yet accessible within each other.
        case financial
        /// Special service regions that are assumed to be fully isolated.
        case `internal`
    }

    /// Region type by data isolation.
    public var kind: Kind

    public init(id: String, kind: Kind = .global) {
        self.rawValue = id
        self.kind = kind
    }

    /// South China(Guangzhou) / 华南地区(广州)
    public static var ap_guangzhou: TCRegion {
        TCRegion(id: "ap-guangzhou")
    }

    /// East China(Shanghai) / 华东地区(上海)
    public static var ap_shanghai: TCRegion {
        TCRegion(id: "ap-shanghai")
    }

    /// East China(Nanjing) / 华东地区(南京)
    public static var ap_nanjing: TCRegion {
        TCRegion(id: "ap-nanjing")
    }

    /// Hong Kong, Macau and Taiwan (China)(Hong Kong, China) / 港澳台地区(中国香港)
    public static var ap_hongkong: TCRegion {
        TCRegion(id: "ap-hongkong")
    }

    /// North America(Toronto) / 北美地区(多伦多)
    public static var na_toronto: TCRegion {
        TCRegion(id: "na-toronto")
    }

    /// North China region(Beijing) / 华北地区(北京)
    public static var ap_beijing: TCRegion {
        TCRegion(id: "ap-beijing")
    }

    /// Southeast Asia(Singapore) / 亚太东南(新加坡)
    public static var ap_singapore: TCRegion {
        TCRegion(id: "ap-singapore")
    }

    /// Southeast Asia(Bangkok) / 亚太东南(曼谷)
    public static var ap_bangkok: TCRegion {
        TCRegion(id: "ap-bangkok")
    }

    /// Southeast Asia(Jakarta) / 亚太东南(雅加达)
    public static var ap_jakarta: TCRegion {
        TCRegion(id: "ap-jakarta")
    }

    /// US West(Silicon Valley) / 美国西部(硅谷)
    public static var na_siliconvalley: TCRegion {
        TCRegion(id: "na-siliconvalley")
    }

    /// Southwest China(Chengdu) / 西南地区(成都)
    public static var ap_chengdu: TCRegion {
        TCRegion(id: "ap-chengdu")
    }

    /// Southwest China(Chongqing) / 西南地区(重庆)
    public static var ap_chongqing: TCRegion {
        TCRegion(id: "ap-chongqing")
    }

    /// Europe(Frankfurt) / 欧洲地区(法兰克福)
    public static var eu_frankfurt: TCRegion {
        TCRegion(id: "eu-frankfurt")
    }

    /// Europe(Northeastern Europe) / 欧洲地区(莫斯科)
    public static var eu_moscow: TCRegion {
        TCRegion(id: "eu-moscow")
    }

    /// Northeast Asia(Seoul) / 亚太东北(首尔)
    public static var ap_seoul: TCRegion {
        TCRegion(id: "ap-seoul")
    }

    /// Northeast Asia(Tokyo) / 亚太东北(东京)
    public static var ap_tokyo: TCRegion {
        TCRegion(id: "ap-tokyo")
    }

    /// South Asia(Mumbai) / 亚太南部(孟买)
    public static var ap_mumbai: TCRegion {
        TCRegion(id: "ap-mumbai")
    }

    /// US East(Virginia) / 美国东部(弗吉尼亚)
    public static var na_ashburn: TCRegion {
        TCRegion(id: "na-ashburn")
    }

    /// South America(São Paulo) / 南美地区(圣保罗)
    public static var sa_saopaulo: TCRegion {
        TCRegion(id: "sa-saopaulo")
    }

    /// Returns a ``TCRegion`` with custom Region ID.
    ///
    /// - Parameters:
    ///   - id: Region ID.
    ///   - kind: Region type by data isolation. Defaults to `.financial` if region ID is suffixed with `-fsi`, else defaults to `.internal`.
    public static func custom(_ id: String, kind: Kind? = nil) -> TCRegion {
        TCRegion(id: id, kind: kind ?? Self.defaultKind(from: id))
    }

    public static func == (lhs: TCRegion, rhs: TCRegion) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

extension TCRegion: CustomStringConvertible {
    public var description: String {
        self.rawValue
    }
}

extension TCRegion {
    /// Returns a Boolean value indicating whether a region is accessible from another.
    public func isAccessible(from region: TCRegion) -> Bool {
        self == region || (self.kind == region.kind && self.kind != .internal)
    }

    /// Returns the default region kind inferred from region ID.
    private static func defaultKind(from regionId: String) -> Kind {
        regionId.hasSuffix("-fsi") ? .financial : .internal
    }
}
