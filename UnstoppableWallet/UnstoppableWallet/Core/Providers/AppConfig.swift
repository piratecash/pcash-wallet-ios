import Foundation
import UIKit
import MarketKit

struct AppConfig {
    static let label = "cash.p.terminal"
    static let backupSalt = "pcash"

    static let companyName = "PirateCash"
    static let reportEmail = "i@p.cash"
    static let companyWebPageLink = "https://p.cash/"
    static let appWebPageLink = "https://p.cash/"
    static let analyticsLink = "https://portfolio.cash"
    static let appGitHubAccount = "piratecash"
    static let appGitHubRepository = "pcash-wallet-ios"
    static let appTwitterAccount = "PirateCash_NET"
    static let appTelegramAccount = "piratecash"
    static let appRedditAccount = "PirateCash"
    static let mempoolSpaceUrl = "https://mempool.space"
    static let guidesIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/v1.2/index.json")!
    static let faqIndexUrl = URL(string: "https://p.cash/s1/faq.json")!
    static let donationAddresses: [BlockchainType: String] = [
        .bitcoin: "3G5fwc9PP9Lcb1y3RAYGzoQZs5enJkmdxN",
        .bitcoinCash: "bitcoincash:qr4f0pkvx86vv6cuae48nj83txqhwyt2fgadd9smxg\n",
        .ecash: "ecash:qrzcal2fmm6vumxp3g2jndk0fepmt2racya9lc4yxy\n",
        .litecoin: "MNbHsci3A8u6UiqjBMMckXzfPrLjeMxdRC\n",
        .dash: "XcpUrR8LkohMNB9TfJaC97id6boUhRU3wk",
        .zcash: "zs1eqk4jh84tas5xv3xydeknm3pvg6cn3l7d2twxh8npcpus6h2gg3dqd8gkxj5zpm98lsj67fkm4f",
        .ethereum: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .binanceSmartChain: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .binanceChain: "bnb132w7sndlwn340jgqff2m9m4nsddx3hga55nx3l",
        .polygon: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .avalanche: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .optimism: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .arbitrumOne: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .gnosis: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .fantom: "0x696Ed8f9E2b3265Abc24a6A035d6c5094f61e61B",
        .tron: "TV4wYRcDun4iHb4oUgcse4Whptk9JKVui2",
        .solana: "CefzHT5zCUncm3yhTLck9bCRYkbjHrKToT1GpPUyqCMa"
    ]

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    static var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    }

    static var appId: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }

    static var appName: String {
        (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? ""
    }

    static var marketApiUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "MarketApiUrl") as? String) ?? ""
    }

    static var officeMode: Bool {
        Bundle.main.object(forInfoDictionaryKey: "OfficeMode") as? String == "true"
    }

    static var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    static var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    static var arbiscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "ArbiscanApiKey") as? String) ?? ""
    }

    static var gnosisscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "GnosisscanApiKey") as? String) ?? ""
    }

    static var ftmscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "FtmscanApiKey") as? String) ?? ""
    }

    static var optimismEtherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OptimismEtherscanApiKey") as? String) ?? ""
    }

    static var bscscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "BscscanApiKey") as? String) ?? ""
    }

    static var polygonscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "PolygonscanApiKey") as? String) ?? ""
    }

    static var snowtraceKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "SnowtraceApiKey") as? String) ?? ""
    }

    static var cryptoCompareApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CryptoCompareApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var defiYieldApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "DefiYieldApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var twitterBearerToken: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TwitterBearerToken") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var hsProviderApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "HsProviderApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var tronGridApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "TronGridApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var walletConnectV2ProjectKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "WallectConnectV2ProjectKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var unstoppableDomainsApiKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "UnstoppableDomainsApiKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var defaultWords: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultWords") as? String ?? ""
    }

    static var defaultPassphrase: String {
        Bundle.main.object(forInfoDictionaryKey: "DefaultPassphrase") as? String ?? ""
    }

    static var sharedCloudContainer: String? {
        Bundle.main.object(forInfoDictionaryKey: "SharedCloudContainerId") as? String
    }

    static var privateCloudContainer: String? {
        Bundle.main.object(forInfoDictionaryKey: "PrivateCloudContainerId") as? String
    }

    static var openSeaApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "OpenSeaApiKey") as? String) ?? ""
    }

}
