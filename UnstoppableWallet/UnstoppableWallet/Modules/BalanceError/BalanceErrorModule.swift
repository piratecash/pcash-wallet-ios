import UIKit

enum BalanceErrorModule {
    static func viewController(wallet: Wallet, error: Error, sourceViewController: UIViewController?) -> UIViewController {
        let service = BalanceErrorService(
            wallet: wallet,
            error: error,
            adapterManager: App.shared.adapterManager,
            btcBlockchainManager: App.shared.btcBlockchainManager,
            evmBlockchainManager: App.shared.evmBlockchainManager
        )
        let viewModel = BalanceErrorViewModel(service: service)
        let viewController = BalanceErrorViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return viewController.toBottomSheet
    }
}
