import Hodler
import RxCocoa
import RxRelay
import RxSwift

class TimeLockService {
    private var disposeBag = DisposeBag()

    private let lockTimeRelay = BehaviorRelay<Item>(value: .none)
    var lockTime: Item = .none {
        didSet {
            if oldValue != lockTime {
                lockTimeRelay.accept(lockTime)
                pluginData = pluginData(lockTime: lockTime)
            }
        }
    }

    private let pluginDataRelay = BehaviorRelay<[UInt8: IBitcoinPluginData]>(value: [:])
    var pluginData = [UInt8: IBitcoinPluginData]() {
        didSet {
            pluginDataRelay.accept(pluginData)
        }
    }

    private func pluginData(lockTime: Item) -> [UInt8: IBitcoinPluginData] {
        guard let lockTimeInterval = lockTime.lockTimeInterval else {
            return [:]
        }

        return [HodlerPlugin.id: HodlerData(lockTimeInterval: lockTimeInterval)]
    }

    var lockTimeList = Item.allCases
}

extension TimeLockService {
    var lockTimeObservable: Observable<Item> {
        lockTimeRelay.asObservable()
    }

    var pluginDataObservable: Observable<[UInt8: IBitcoinPluginData]> {
        pluginDataRelay.asObservable()
    }

    func set(index: Int) {
        guard index < lockTimeList.count else {
            return
        }

        lockTime = lockTimeList[index]
    }
}

extension TimeLockService {
    enum Item: UInt16, CaseIterable {
        case none
        case hour
        case month
        case halfYear
        case year

        var lockTimeInterval: HodlerPlugin.LockTimeInterval? {
            switch self {
            case .none: return nil
            case .hour: return .hour
            case .month: return .month
            case .halfYear: return .halfYear
            case .year: return .year
            }
        }

        var title: String {
            HodlerPlugin.LockTimeInterval.title(lockTimeInterval: lockTimeInterval)
        }
    }
}
