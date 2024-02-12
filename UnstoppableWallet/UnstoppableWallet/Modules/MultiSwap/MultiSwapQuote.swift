import Foundation
import MarketKit

protocol IMultiSwapQuote {
    var amountOut: Decimal { get }
    var feeQuote: MultiSwapFeeQuote? { get }
    var mainFields: [MultiSwapMainField] { get }
    var cautions: [CautionNew] { get }
    func confirmationPriceSectionFields(tokenIn: Token, tokenOut: Token, currency: Currency, rateIn: Decimal?, rateOut: Decimal?) -> [MultiSwapConfirmField]
    func confirmationFeeSectionFields(tokenIn: Token, tokenOut: Token, currency: Currency, rateIn: Decimal?, rateOut: Decimal?) -> [MultiSwapConfirmField]
    func confirmationOtherSections(tokenIn: Token, tokenOut: Token, currency: Currency, rateIn: Decimal?, rateOut: Decimal?) -> [[MultiSwapConfirmField]]
    var settingsModified: Bool { get }
    var canSwap: Bool { get }
}

struct MultiSwapTokenAmount {
    let token: Token
    let amount: Decimal
}

struct MultiSwapMainField: Identifiable {
    let title: String
    let description: AlertView.InfoDescription?
    let value: String
    let valueLevel: MultiSwapValueLevel
    let settingId: String?
    let modified: Bool

    init(title: String, description: AlertView.InfoDescription? = nil, value: String, valueLevel: MultiSwapValueLevel = .regular, settingId: String? = nil, modified: Bool = false) {
        self.title = title
        self.description = description
        self.value = value
        self.valueLevel = valueLevel
        self.settingId = settingId
        self.modified = modified
    }

    var id: String {
        title
    }
}

enum MultiSwapValueLevel {
    case regular
    case warning
    case error
}

enum MultiSwapConfirmField {
    case value(title: String, description: AlertView.InfoDescription?, coinValue: CoinValue, currencyValue: CurrencyValue?)
    case levelValue(title: String, value: String, level: MultiSwapValueLevel)
    case address(title: String, value: String)
}
