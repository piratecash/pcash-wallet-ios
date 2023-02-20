import UIKit
import CurrencyKit
import MarketKit

struct TransactionInfoModule {

    static func instance(transactionRecord: TransactionRecord) -> UIViewController? {
        guard let adapter = App.shared.transactionAdapterManager.adapter(for: transactionRecord.source) else {
            return nil
        }
        let rateService = HistoricalRateService(marketKit: App.shared.marketKit, currencyKit: App.shared.currencyKit)
        let nftMetadataService = NftMetadataService(nftMetadataManager: App.shared.nftMetadataManager)

        let service = TransactionInfoService(transactionRecord: transactionRecord, adapter: adapter, currencyKit: App.shared.currencyKit, rateService: rateService, nftMetadataService: nftMetadataService)
        let factory = TransactionInfoViewItemFactory(evmLabelManager: App.shared.evmLabelManager, actionEnabled: transactionRecord.source.blockchainType.resendable)
        let viewModel = TransactionInfoViewModel(service: service, factory: factory)
        let viewController = TransactionInfoViewController(adapter: adapter, viewModel: viewModel, pageTitle: "tx_info.title".localized, urlManager: UrlManager(inApp: true))

        return viewController
    }

}

extension TransactionInfoModule {

    enum Option {
        case resend(type: ResendEvmTransactionType)
    }

    enum ViewItem {
        case actionTitle(iconName: String?, iconDimmed: Bool, title: String, subTitle: String?)
        case amount(iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: AmountType, coinUid: String?)
        case nftAmount(iconUrl: String?, iconPlaceholderImageName: String, nftAmount: String, type: AmountType, providerCollectionUid: String?, nftUid: NftUid?)
        case status(status: TransactionStatus)
        case option(option: Option)
        case date(date: Date)
        case from(value: String, valueTitle: String?)
        case to(value: String, valueTitle: String?)
        case spender(value: String, valueTitle: String?)
        case recipient(value: String, valueTitle: String?)
        case id(value: String)
        case rate(value: String)
        case fee(title: String, value: String)
        case price(price: String)
        case doubleSpend(txHash: String, conflictingTxHash: String)
        case lockInfo(lockState: TransactionLockState)
        case sentToSelf
        case rawTransaction
        case memo(text: String)
        case service(value: String)
        case explorer(title: String, url: String?)
    }

}
