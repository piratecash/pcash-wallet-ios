import UIKit
import ThemeKit
import ComponentKit
import SectionsTableView
import RxSwift
import RxCocoa

class SendBitcoinViewController: BaseSendViewController {
    private let disposeBag = DisposeBag()

    private let feeWarningViewModel: ITitledCautionViewModel
    private let timeLockViewModel: SendTimeLockViewModel?

    private let feeCell: FeeCell
    private let feeCautionCell = TitledHighlightedDescriptionCell()

    private var timeLockCell: BaseSelectableThemeCell?

    init(confirmationFactory: ISendConfirmationFactory,
         feeSettingsFactory: ISendFeeSettingsFactory,
         viewModel: SendViewModel,
         availableBalanceViewModel: SendAvailableBalanceViewModel,
         amountInputViewModel: AmountInputViewModel,
         amountCautionViewModel: SendAmountCautionViewModel,
         recipientViewModel: RecipientAddressViewModel,
         feeViewModel: SendFeeViewModel,
         feeWarningViewModel: ITitledCautionViewModel,
         timeLockViewModel: SendTimeLockViewModel?
    ) {

        self.feeWarningViewModel = feeWarningViewModel
        self.timeLockViewModel = timeLockViewModel

        feeCell = FeeCell(viewModel: feeViewModel, title: "fee_settings.fee".localized)

        if timeLockViewModel != nil {
            let timeLockCell = BaseSelectableThemeCell()

            timeLockCell.set(backgroundStyle: .lawrence, isFirst: false, isLast: true)
            self.timeLockCell = timeLockCell
        }

        super.init(
                confirmationFactory: confirmationFactory,
                feeSettingsFactory: feeSettingsFactory,
                viewModel: viewModel,
                availableBalanceViewModel: availableBalanceViewModel,
                amountInputViewModel: amountInputViewModel,
                amountCautionViewModel: amountCautionViewModel,
                recipientViewModel: recipientViewModel
        )

        syncTimeLock()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        feeCell.onOpenInfo = { [weak self] in
            self?.openInfo(title: "fee_settings.fee".localized, description: "fee_settings.fee.info".localized)
        }

        subscribe(disposeBag, feeWarningViewModel.cautionDriver) { [weak self] in
            self?.handle(caution: $0)
        }

        if let timeLockViewModel = timeLockViewModel {
            subscribe(disposeBag, timeLockViewModel.lockTimeDriver) { [weak self] priority in
                self?.syncTimeLock(value: priority)
            }
        }

        didLoad()
    }

    private func syncTimeLock(value: String? = nil) {
        guard let cell = timeLockCell else {
            return
        }
        let elements = tableView.universalImage24Elements(
                title: .subhead2("send.hodler_locktime".localized),
                value: .subhead1(value),
                accessoryType: .dropdown)

        CellBuilderNew.buildStatic(cell: cell, rootElement: .hStack(elements))
    }

    private func handle(caution: TitledCaution?) {
        feeCautionCell.isVisible = caution != nil

        if let caution = caution {
            feeCautionCell.bind(caution: caution)
        }

        reloadTable()
    }

    private func onTapLockTimeSelect() {
        guard let timeLockViewModel = timeLockViewModel else {
            return
        }

        let alertController = AlertRouter.module(
                title: "send.hodler_locktime".localized,
                viewItems: timeLockViewModel.lockTimeViewItems
        ) { index in
            timeLockViewModel.onSelect(index)
        }

        present(alertController, animated: true)
    }

    private func openInfo(title: String, description: String) {
        let viewController = BottomSheetModule.description(title: title, text: description)
        present(viewController, animated: true)
    }

    var feeSection: SectionProtocol {
        Section(
                id: "fee",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCell,
                            id: "fee",
                            height: .heightDoubleLineCell
                    )
                ]
        )
    }

    var timeLockSection: SectionProtocol? {
        timeLockCell.map { cell in
            Section(
                    id: "time-lock",
                    rows: [
                        StaticRow(
                                cell: cell,
                                id: "time_lock_cell",
                                height: .heightSingleLineCell,
                                autoDeselect: true,
                                action: { [weak self] in
                                    self?.onTapLockTimeSelect()
                                }
                        )
                    ]
            )
        }
    }

    var feeWarningSection: SectionProtocol {
        Section(
                id: "fee-warning",
                headerState: .margin(height: .margin12),
                rows: [
                    StaticRow(
                            cell: feeCautionCell,
                            id: "fee-warning",
                            dynamicHeight: { [weak self] containerWidth in
                                self?.feeCautionCell.cellHeight(containerWidth: containerWidth) ?? 0
                            }
                    )
                ]
        )
    }

    override func buildSections() -> [SectionProtocol] {
        var sections = [availableBalanceSection, amountSection, recipientSection, feeSection]
        if let timeLockSection = timeLockSection {
            sections.append(timeLockSection)
        }
        sections.append(contentsOf: [feeWarningSection, buttonSection])

        return sections
    }

}
