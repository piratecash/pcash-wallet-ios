import Foundation
import RxRelay
import RxSwift

protocol IWalletAdapterServiceDelegate: AnyObject {
    func didPrepareAdapters()
    func didUpdate(balanceData: BalanceData, wallet: Wallet)
    func didUpdate(state: AdapterState, wallet: Wallet)
}

class WalletAdapterService {
    weak var delegate: IWalletAdapterServiceDelegate?

    private let account: Account
    private let adapterManager: AdapterManager
    private let disposeBag = DisposeBag()
    private var adaptersDisposeBag = DisposeBag()

    private var adapterMap: [Wallet: IBalanceAdapter]

    private let queue = DispatchQueue(label: "\(AppConfig.label).wallet-adapter-service", qos: .userInitiated)

    init(account: Account, adapterManager: AdapterManager) {
        self.account = account
        self.adapterManager = adapterManager

        adapterMap = adapterManager.adapterData.adapterMap.compactMapValues { $0 as? IBalanceAdapter }
        subscribeToAdapters()

        subscribe(disposeBag, adapterManager.adapterDataReadyObservable) { [weak self] adapterData in
            guard adapterData.account == self?.account else {
                return
            }

            self?.handleAdaptersReady(adapterMap: adapterData.adapterMap)
        }
    }

    private func handleAdaptersReady(adapterMap: [Wallet: IAdapter]) {
        queue.async {
            self.adapterMap = adapterMap.compactMapValues { $0 as? IBalanceAdapter }
            self.subscribeToAdapters()
            self.delegate?.didPrepareAdapters()
        }
    }

    private func subscribeToAdapters() {
        adaptersDisposeBag = DisposeBag()

        for (wallet, adapter) in adapterMap {
            subscribe(adaptersDisposeBag, adapter.balanceDataUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(balanceData: $0, wallet: wallet)
            }

            subscribe(adaptersDisposeBag, adapter.balanceStateUpdatedObservable) { [weak self] in
                self?.delegate?.didUpdate(state: $0, wallet: wallet)
            }
        }
    }
}

extension WalletAdapterService {
    func isMainNet(wallet: Wallet) -> Bool? {
        queue.sync { adapterMap[wallet]?.isMainNet }
    }

    func balanceData(wallet: Wallet) -> BalanceData? {
        queue.sync { adapterMap[wallet]?.balanceData }
    }

    func state(wallet: Wallet) -> AdapterState? {
        queue.sync { adapterMap[wallet]?.balanceState }
    }

    func refresh() {
        adapterManager.refresh()
    }
}
