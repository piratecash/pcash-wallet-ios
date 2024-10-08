import HsToolKit
import RxRelay
import RxSwift

class GuidesRepository {
    private let disposeBag = DisposeBag()

    private let guidesManager: GuidesManager
    private let reachabilityManager: IReachabilityManager

    private let categoriesRelay = BehaviorRelay<DataState<[GuideCategory]>>(value: .loading)

    init(guidesManager: GuidesManager, reachabilityManager: IReachabilityManager) {
        self.guidesManager = guidesManager
        self.reachabilityManager = reachabilityManager

        reachabilityManager.reachabilityObservable
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onNext: { [weak self] reachable in
                if reachable {
                    self?.onReachable()
                }
            })
            .disposed(by: disposeBag)

        fetch()
    }

    private func onReachable() {
        if case .error = categoriesRelay.value {
            fetch()
        }
    }

    private func fetch() {
        categoriesRelay.accept(.loading)

        guidesManager.guideCategoriesSingle(url: AppConfig.guidesIndexUrl)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(onSuccess: { [weak self] categories in
                self?.categoriesRelay.accept(.success(result: categories))
            }, onError: { [weak self] error in
                self?.categoriesRelay.accept(.error(error: error))
            })
            .disposed(by: disposeBag)
    }

    var categories: Observable<DataState<[GuideCategory]>> {
        categoriesRelay.asObservable()
    }
}
