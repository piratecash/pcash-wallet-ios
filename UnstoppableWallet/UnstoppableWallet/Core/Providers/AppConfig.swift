import Foundation

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
    static let btcCoreRpcUrl = "https://btc.blocksdecoded.com/rpc"
    static let guidesIndexUrl = URL(string: "https://raw.githubusercontent.com/horizontalsystems/blockchain-crypto-guides/v1.2/index.json")!
    static let faqIndexUrl = URL(string: "https://p.cash/s1/faq.json")!

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

    static var coinzixHCaptchaKey: String? {
        (Bundle.main.object(forInfoDictionaryKey: "CoinzixHCaptchaKey") as? String).flatMap { $0.isEmpty ? nil : $0 }
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
