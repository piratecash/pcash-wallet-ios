import RxSwift
import RxRelay
import HsToolKit
import UniswapKit
import CurrencyKit
import BigInt
import EthereumKit
import Foundation
import CoinKit

class OneInchService {
    let dex: SwapModuleNew.DexNew
    private let tradeService: OneInchTradeService
    private let allowanceService: SwapAllowanceService
    private let pendingAllowanceService: SwapPendingAllowanceService
    private let adapterManager: AdapterManager

    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            if oldValue != state {
                stateRelay.accept(state)
            }
        }
    }

    private let errorsRelay = PublishRelay<[Error]>()
    private(set) var errors: [Error] = [] {
        didSet {
            errorsRelay.accept(errors)
        }
    }

    private let balanceInRelay = PublishRelay<Decimal?>()
    private(set) var balanceIn: Decimal? {
        didSet {
            balanceInRelay.accept(balanceIn)
        }
    }

    private let balanceOutRelay = PublishRelay<Decimal?>()
    private(set) var balanceOut: Decimal? {
        didSet {
            balanceOutRelay.accept(balanceOut)
        }
    }

    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.swap_service")

    init(dex: SwapModuleNew.DexNew, evmKit: EthereumKit.Kit, tradeService: OneInchTradeService, allowanceService: SwapAllowanceService, pendingAllowanceService: SwapPendingAllowanceService, adapterManager: AdapterManager) {
        self.dex = dex
        self.tradeService = tradeService
        self.allowanceService = allowanceService
        self.pendingAllowanceService = pendingAllowanceService
        self.adapterManager = adapterManager

        subscribe(scheduler, disposeBag, tradeService.stateObservable) { [weak self] state in
            self?.onUpdateTrade(state: state)
        }

        subscribe(scheduler, disposeBag, tradeService.coinInObservable) { [weak self] coin in
            self?.onUpdate(coinIn: coin)
        }
        onUpdate(coinIn: tradeService.coinIn)

        subscribe(scheduler, disposeBag, tradeService.coinOutObservable) { [weak self] coin in
            self?.onUpdate(coinOut: coin)
        }

        subscribe(scheduler, disposeBag, tradeService.amountInObservable) { [weak self] amount in
            self?.onUpdate(amountIn: amount)
        }
        subscribe(scheduler, disposeBag, allowanceService.stateObservable) { [weak self] _ in
            self?.syncState()
        }
        subscribe(scheduler, disposeBag, pendingAllowanceService.isPendingObservable) { [weak self] isPending in
            self?.onUpdate(isAllowancePending: isPending)
        }
    }

    private func onUpdateTrade(state: OneInchTradeService.State) {
        syncState()
    }

    private func onUpdate(coinIn: Coin?) {
        balanceIn = coinIn.flatMap { balance(coin: $0) }
        allowanceService.set(coin: coinIn)
        pendingAllowanceService.set(coin: coinIn)
    }

    private func onUpdate(amountIn: Decimal?) {
        syncState()
    }

    private func onUpdate(coinOut: Coin?) {
        balanceOut = coinOut.flatMap { balance(coin: $0) }
    }

    private func onUpdate(isAllowancePending: Bool) {
        syncState()
    }

    private func syncState() {
        var allErrors = [Error]()
        var loading = false

        var transactionData: Int = 0

        switch tradeService.state {
        case .loading:
            loading = true
        case .ready:
            transactionData = 1
        case .notReady(let errors):
            allErrors.append(contentsOf: errors)
        }

        if let allowanceState = allowanceService.state {
            switch allowanceState {
            case .loading:
                loading = true
            case .ready(let allowance):
                if tradeService.amountIn > allowance.value {
                    allErrors.append(SwapModuleNew.SwapError.insufficientAllowance)
                }
            case .notReady(let error):
                allErrors.append(error)
            }
        }

        if let balanceIn = balanceIn {
            if tradeService.amountIn > balanceIn {
                allErrors.append(SwapModuleNew.SwapError.insufficientBalanceIn)
            }
        } else {
            allErrors.append(SwapModuleNew.SwapError.noBalanceIn)
        }

        if pendingAllowanceService.isPending {
            loading = true
        }

        errors = allErrors

        if loading {
            state = .loading
        } else if transactionData != 0, allErrors.isEmpty {
            state = .ready(transactionData: 1)
        } else {
            state = .notReady
        }
    }

    private func balance(coin: Coin) -> Decimal? {
        (adapterManager.adapter(for: coin) as? IBalanceAdapter)?.balanceData.balance
    }

}

extension OneInchService: ISwapErrorProvider {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var errorsObservable: Observable<[Error]> {
        errorsRelay.asObservable()
    }

    var balanceInObservable: Observable<Decimal?> {
        balanceInRelay.asObservable()
    }

    var balanceOutObservable: Observable<Decimal?> {
        balanceOutRelay.asObservable()
    }

    var approveData: SwapAllowanceService.ApproveData? {
        guard let amount = balanceIn else {
            return nil
        }

        return allowanceService.approveData(dex: dex, amount: amount)
    }

}

extension OneInchService {

    enum State: Equatable {
        case loading
        case ready(transactionData: Int)
        case notReady

        static func ==(lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading): return true
            case (.ready(let lhsTransactionData), .ready(let rhsTransactionData)): return lhsTransactionData == rhsTransactionData
            case (.notReady, .notReady): return true
            default: return false
            }
        }
    }

}