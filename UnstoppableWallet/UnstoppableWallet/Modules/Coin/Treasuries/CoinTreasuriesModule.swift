import MarketKit
import UIKit

struct CoinTreasuriesModule {
    static func viewController(coin: Coin) -> UIViewController {
        let service = CoinTreasuriesService(coin: coin, marketKit: App.shared.marketKit, currencyManager: App.shared.currencyManager)
        let viewModel = CoinTreasuriesViewModel(service: service)
        return CoinTreasuriesViewController(viewModel: viewModel)
    }
}
