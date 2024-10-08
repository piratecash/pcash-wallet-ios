import Foundation
import MarketKit
import RxRelay
import RxSwift

class NftAdapterManager {
    private let walletManager: WalletManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let disposeBag = DisposeBag()

    private let adaptersUpdatedRelay = PublishRelay<[NftKey: INftAdapter]>()
    private var _adapterMap = [NftKey: INftAdapter]()

    private let queue = DispatchQueue(label: "\(AppConfig.label).nft-adapter_manager", qos: .userInitiated)

    init(walletManager: WalletManager, evmBlockchainManager: EvmBlockchainManager) {
        self.walletManager = walletManager
        self.evmBlockchainManager = evmBlockchainManager

        walletManager.activeWalletDataUpdatedObservable
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] walletData in
                self?.handleAdaptersReady(wallets: walletData.wallets)
            })
            .disposed(by: disposeBag)

        _initAdapters(wallets: walletManager.activeWallets)
    }

    private func _initAdapters(wallets: [Wallet]) {
        let nftKeys = Array(Set(wallets.map { NftKey(account: $0.account, blockchainType: $0.token.blockchainType) }))

        var newAdapterMap = [NftKey: INftAdapter]()

        for nftKey in nftKeys {
            if let adapter = _adapterMap[nftKey] {
                newAdapterMap[nftKey] = adapter
                continue
            }

            guard !nftKey.blockchainType.supportedNftTypes.isEmpty else {
                continue
            }

            if evmBlockchainManager.blockchain(type: nftKey.blockchainType) != nil {
                let evmKitWrapper = try? evmBlockchainManager.evmKitManager(blockchainType: nftKey.blockchainType).evmKitWrapper(account: nftKey.account, blockchainType: nftKey.blockchainType)

                if let evmKitWrapper, let nftKit = evmKitWrapper.nftKit {
                    newAdapterMap[nftKey] = EvmNftAdapter(blockchainType: nftKey.blockchainType, evmKitWrapper: evmKitWrapper, nftKit: nftKit)
                }
            } else {
                // Init other blockchain adapter here (e.g. Solana)
            }
        }

//        print("NEW ADAPTERS: \(newAdapterMap.keys)")

        _adapterMap = newAdapterMap
        adaptersUpdatedRelay.accept(newAdapterMap)
    }

    private func handleAdaptersReady(wallets: [Wallet]) {
        queue.async {
            self._initAdapters(wallets: wallets)
        }
    }
}

extension NftAdapterManager {
    var adapterMap: [NftKey: INftAdapter] {
        queue.sync { _adapterMap }
    }

    var adaptersUpdatedObservable: Observable<[NftKey: INftAdapter]> {
        adaptersUpdatedRelay.asObservable()
    }

    func adapter(nftKey: NftKey) -> INftAdapter? {
        queue.sync { _adapterMap[nftKey] }
    }

    func refresh() {
        queue.async {
            for adapter in self._adapterMap.values {
                adapter.sync()
            }
        }
    }
}
