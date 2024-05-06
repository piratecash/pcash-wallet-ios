import MarketKit

protocol ISendHandler {
    var baseToken: Token { get }
    var syncingText: String? { get }
    var expirationDuration: Int? { get }
    var initialTransactionSettings: InitialTransactionSettings? { get }
    func sendData(transactionSettings: TransactionSettings?) async throws -> ISendData
    func send(data: ISendData) async throws
}

extension ISendHandler {
    var initialTransactionSettings: InitialTransactionSettings? {
        nil
    }
}