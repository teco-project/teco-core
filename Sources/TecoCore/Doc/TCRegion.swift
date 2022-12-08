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

// THIS FILE IS AUTOMATICALLY GENERATED by TecoRegionGenerator.
// DO NOT EDIT.

public struct TCRegion: RawRepresentable, Equatable, Sendable, Codable {
    public var rawValue: String
    
    public init (rawValue: String) {
        self.rawValue = rawValue
    }
    
    /// 华南地区(广州) / South China(Guangzhou)
    public static var ap_guangzhou: TCRegion {
        TCRegion(rawValue: "ap-guangzhou")
    }
    
    /// 华南地区(深圳金融) / South China(Shenzhen Finance)
    public static var ap_shenzhen_fsi: TCRegion {
        TCRegion(rawValue: "ap-shenzhen-fsi")
    }
    
    /// 华南地区(广州OPEN) / South China(Guangzhou OPEN)
    public static var ap_guangzhou_open: TCRegion {
        TCRegion(rawValue: "ap-guangzhou-open")
    }
    
    /// 华南地区(清远) / South China(Qingyuan)
    public static var ap_qingyuan: TCRegion {
        TCRegion(rawValue: "ap-qingyuan")
    }
    
    /// 华南地区(清远信安) / South China(Qingyuan Xinan)
    public static var ap_qingyuan_xinan: TCRegion {
        TCRegion(rawValue: "ap-qingyuan-xinan")
    }
    
    /// 华南地区(深圳深宇财付通) / South China(Shenzhen Shenyu Tenpay)
    public static var ap_shenzhen_sycft: TCRegion {
        TCRegion(rawValue: "ap-shenzhen-sycft")
    }
    
    /// 华东地区(上海) / East China(Shanghai)
    public static var ap_shanghai: TCRegion {
        TCRegion(rawValue: "ap-shanghai")
    }
    
    /// 华东地区(上海金融) / East China(Shanghai Finance)
    public static var ap_shanghai_fsi: TCRegion {
        TCRegion(rawValue: "ap-shanghai-fsi")
    }
    
    /// 华东地区(济南) / East China(Jinan)
    public static var ap_jinan_ec: TCRegion {
        TCRegion(rawValue: "ap-jinan-ec")
    }
    
    /// 华东地区(杭州) / East China(Hangzhou)
    public static var ap_hangzhou_ec: TCRegion {
        TCRegion(rawValue: "ap-hangzhou-ec")
    }
    
    /// 华东地区(南京) / East China(Nanjing)
    public static var ap_nanjing: TCRegion {
        TCRegion(rawValue: "ap-nanjing")
    }
    
    /// 华东地区(福州) / East China(Fuzhou)
    public static var ap_fuzhou_ec: TCRegion {
        TCRegion(rawValue: "ap-fuzhou-ec")
    }
    
    /// 华东地区(合肥) / East China(Hefei)
    public static var ap_hefei_ec: TCRegion {
        TCRegion(rawValue: "ap-hefei-ec")
    }
    
    /// 华东地区(上海自动驾驶云) / East China(Shanghai Self-driving Cloud)
    public static var ap_shanghai_adc: TCRegion {
        TCRegion(rawValue: "ap-shanghai-adc")
    }
    
    /// 港澳台地区(中国香港) / Hong Kong, Macau and Taiwan (China)(Hong Kong, China)
    public static var ap_hongkong: TCRegion {
        TCRegion(rawValue: "ap-hongkong")
    }
    
    /// 港澳台地区(中国台北) / Hong Kong, Macau and Taiwan (China)(Taiwan, China)
    public static var ap_taipei: TCRegion {
        TCRegion(rawValue: "ap-taipei")
    }
    
    /// 北美地区(多伦多) / North America(Toronto)
    public static var na_toronto: TCRegion {
        TCRegion(rawValue: "na-toronto")
    }
    
    /// 华北地区(北京) / North China region(Beijing)
    public static var ap_beijing: TCRegion {
        TCRegion(rawValue: "ap-beijing")
    }
    
    /// 华北地区(北京金融) / North China region(Beijing Finance)
    public static var ap_beijing_fsi: TCRegion {
        TCRegion(rawValue: "ap-beijing-fsi")
    }
    
    /// 华北地区(石家庄) / North China region(Shijiazhuang)
    public static var ap_shijiazhuang_ec: TCRegion {
        TCRegion(rawValue: "ap-shijiazhuang-ec")
    }
    
    /// 亚太东南(新加坡) / Southeast Asia(Singapore)
    public static var ap_singapore: TCRegion {
        TCRegion(rawValue: "ap-singapore")
    }
    
    /// 亚太东南(曼谷) / Southeast Asia(Bangkok)
    public static var ap_bangkok: TCRegion {
        TCRegion(rawValue: "ap-bangkok")
    }
    
    /// 亚太东南(雅加达) / Southeast Asia(Jakarta)
    public static var ap_jakarta: TCRegion {
        TCRegion(rawValue: "ap-jakarta")
    }
    
    /// 美国西部(硅谷) / US West(Silicon Valley)
    public static var na_siliconvalley: TCRegion {
        TCRegion(rawValue: "na-siliconvalley")
    }
    
    /// 西南地区(成都) / Southwest China(Chengdu)
    public static var ap_chengdu: TCRegion {
        TCRegion(rawValue: "ap-chengdu")
    }
    
    /// 西南地区(重庆) / Southwest China(Chongqing)
    public static var ap_chongqing: TCRegion {
        TCRegion(rawValue: "ap-chongqing")
    }
    
    /// 西南地区(贵阳) / Southwest China(Guiyang)
    public static var ap_guiyang: TCRegion {
        TCRegion(rawValue: "ap-guiyang")
    }
    
    /// 欧洲地区(法兰克福) / Europe(Frankfurt)
    public static var eu_frankfurt: TCRegion {
        TCRegion(rawValue: "eu-frankfurt")
    }
    
    /// 欧洲地区(莫斯科) / Europe(Northeastern Europe)
    public static var eu_moscow: TCRegion {
        TCRegion(rawValue: "eu-moscow")
    }
    
    /// 亚太东北(首尔) / Northeast Asia(Seoul)
    public static var ap_seoul: TCRegion {
        TCRegion(rawValue: "ap-seoul")
    }
    
    /// 亚太东北(东京) / Northeast Asia(Tokyo)
    public static var ap_tokyo: TCRegion {
        TCRegion(rawValue: "ap-tokyo")
    }
    
    /// 亚太南部(孟买) / South Asia(Mumbai)
    public static var ap_mumbai: TCRegion {
        TCRegion(rawValue: "ap-mumbai")
    }
    
    /// 美国东部(弗吉尼亚) / US East(Virginia)
    public static var na_ashburn: TCRegion {
        TCRegion(rawValue: "na-ashburn")
    }
    
    /// 华中地区(武汉) / Central China(Wuhan)
    public static var ap_wuhan_ec: TCRegion {
        TCRegion(rawValue: "ap-wuhan-ec")
    }
    
    /// 华中地区(长沙) / Central China(Changsha)
    public static var ap_changsha_ec: TCRegion {
        TCRegion(rawValue: "ap-changsha-ec")
    }
    
    /// 华中地区(郑州) / Central China(Zhengzhou)
    public static var ap_zhengzhou_ec: TCRegion {
        TCRegion(rawValue: "ap-zhengzhou-ec")
    }
    
    /// 东北地区(沈阳) / Northeast China(Shenyang)
    public static var ap_shenyang_ec: TCRegion {
        TCRegion(rawValue: "ap-shenyang-ec")
    }
    
    /// 西北地区(西安) / Northwest region(Xi'an)
    public static var ap_xian_ec: TCRegion {
        TCRegion(rawValue: "ap-xian-ec")
    }
    
    /// 西北地区(西北) / Northwest region(Northwest China)
    public static var ap_xibei_ec: TCRegion {
        TCRegion(rawValue: "ap-xibei-ec")
    }
    
    /// 南美地区(圣保罗) / South America(São Paulo)
    public static var sa_saopaulo: TCRegion {
        TCRegion(rawValue: "sa-saopaulo")
    }
    
    /// Other region.
    public static func other(_ name: String) -> TCRegion {
        TCRegion(rawValue: name)
    }
}

extension TCRegion: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}

// Isolation and domain helpers.
extension TCRegion {
    // FSI regions are isolated, which means they can only be accessed with region-specific domains.
    public var isolated: Bool {
        self.rawValue.hasSuffix("-fsi")
    }
    
    public func hostname(for service: String, preferringRegional: Bool = false) -> String {
        guard self.isolated || preferringRegional else {
            return "tencentcloudapi.com"
        }
        return "\(self.rawValue).tencentcloudapi.com"
    }
}
