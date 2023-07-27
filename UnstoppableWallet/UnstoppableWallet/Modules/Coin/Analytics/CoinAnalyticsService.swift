import Combine
import EvmKit
import MarketKit
import CurrencyKit
import HsToolKit
import HsExtensions

class CoinAnalyticsService {
    private let fullCoin: FullCoin
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let subscriptionManager: SubscriptionManager
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    @PostPublished private(set) var state: State = .loading

    init(fullCoin: FullCoin, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, subscriptionManager: SubscriptionManager) {
        self.fullCoin = fullCoin
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.subscriptionManager = subscriptionManager

        subscriptionManager.$isAuthenticated
                .sink { [weak self] isAuthenticated in
                    if isAuthenticated {
                        self?.sync()
                    }
                }
                .store(in: &cancellables)
    }

    private func loadPreview() {
        Task { [weak self, marketKit, fullCoin] in
            do {
                let analyticsPreview = try await marketKit.analyticsPreview(coinUid: fullCoin.coin.uid)
                self?.state = .preview(analyticsPreview: analyticsPreview)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinAnalyticsService {

    var currency: Currency {
        currencyKit.baseCurrency
    }

    var coin: Coin {
        fullCoin.coin
    }

    var auditAddresses: [String]? {
        let addresses = fullCoin.tokens.compactMap { token in
            switch (token.blockchainType, token.type) {
            case (.ethereum, .eip20(let address)): return address
            case (.binanceSmartChain, .eip20(let address)): return address
            default: return nil
            }
        }

        return addresses.isEmpty ? nil : addresses
    }

    func blockchains(uids: [String]) -> [Blockchain] {
        do {
            return try marketKit.blockchains(uids: uids)
        } catch {
            return []
        }
    }

    func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, fullCoin, currency] in
            do {
                let analytics = try await marketKit.analytics(coinUid: fullCoin.coin.uid, currencyCode: currency.code)
                self?.state = .success(analytics: analytics)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

}

extension CoinAnalyticsService {

    enum State {
        case loading
        case failed(Error)
        case preview(analyticsPreview: AnalyticsPreview)
        case success(analytics: Analytics)
    }

}
