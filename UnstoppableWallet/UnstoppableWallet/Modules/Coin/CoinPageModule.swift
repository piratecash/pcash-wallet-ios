import MarketKit
import SwiftUI
import ThemeKit
import UIKit

enum CoinPageModule {
    static func view(fullCoin: FullCoin) -> some View {
        let viewModel = CoinPageViewModelNew(fullCoin: fullCoin, watchlistManager: App.shared.watchlistManager)

        let overviewView = CoinOverviewModule.view(coinUid: fullCoin.coin.uid)
        let analyticsView = CoinAnalyticsModule.view(fullCoin: fullCoin)
        let marketsView = CoinMarketsView(coin: fullCoin.coin)

        return CoinPageView(
            viewModel: viewModel,
            overviewView: { overviewView },
            analyticsView: { analyticsView.ignoresSafeArea(edges: .bottom) },
            marketsView: { marketsView.ignoresSafeArea(edges: .bottom) }
        )
    }

    static func viewController(coinUid: String) -> UIViewController? {
        guard let fullCoin = try? App.shared.marketKit.fullCoins(coinUids: [coinUid]).first else {
            return nil
        }

        let service = CoinPageService(
            fullCoin: fullCoin,
            watchlistManager: App.shared.watchlistManager
        )

        let viewModel = CoinPageViewModel(service: service)

        let overviewController = CoinOverviewModule.viewController(coinUid: coinUid)
        let marketsController = CoinMarketsView(coin: fullCoin.coin).toViewController()
        let analyticsController = CoinAnalyticsModule.viewController(fullCoin: fullCoin)
//        let tweetsController = CoinTweetsModule.viewController(fullCoin: fullCoin)

        let viewController = CoinPageViewController(
            viewModel: viewModel,
            overviewController: overviewController,
            analyticsController: analyticsController,
            marketsController: marketsController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }
}

extension CoinPageModule {
    enum Tab: Int, CaseIterable {
        case overview
        case analytics
        case markets
//        case tweets

        var title: String {
            switch self {
            case .overview: return "coin_page.overview".localized
            case .analytics: return "coin_page.analytics".localized
            case .markets: return "coin_page.markets".localized
//            case .tweets: return "coin_page.tweets".localized
            }
        }
    }
}

struct CoinPageViewNew: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIViewController

    let coinUid: String

    func makeUIViewController(context _: Context) -> UIViewController {
        CoinPageModule.viewController(coinUid: coinUid) ?? UIViewController()
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
