import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView
import CurrencyKit
import ComponentKit
import RxSwift
import SafariServices

class TransactionInfoViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: TransactionInfoViewModel
    private let pageTitle: String
    private var urlManager: UrlManager
    private let adapter: ITransactionsAdapter

    private var viewItems = [[TransactionInfoModule.ViewItem]]()

    private let tableView = SectionsTableView(style: .grouped)

    init(adapter: ITransactionsAdapter, viewModel: TransactionInfoViewModel, pageTitle: String, urlManager: UrlManager) {
        self.adapter = adapter
        self.viewModel = viewModel
        self.pageTitle = pageTitle
        self.urlManager = urlManager

        viewItems = viewModel.viewItems

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = pageTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapCloseButton))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: B7Cell.self)
        tableView.registerCell(forClass: D6Cell.self)
        tableView.registerCell(forClass: D7Cell.self)
        tableView.registerCell(forClass: D7MultiLineCell.self)
        tableView.registerCell(forClass: D9Cell.self)
        tableView.registerCell(forClass: D10Cell.self)
        tableView.registerCell(forClass: D10SecondaryCell.self)
        tableView.registerCell(forClass: CMultiLineCell.self)
        tableView.registerCell(forClass: C4MultiLineCell.self)
        tableView.registerCell(forClass: C6Cell.self)
        tableView.registerCell(forClass: C24Cell.self)
        tableView.sectionDataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] viewItems in
            self?.viewItems = viewItems
            self?.tableView.reload()
        }

        tableView.reload()
    }

    @objc private func onTapCloseButton() {
        dismiss(animated: true)
    }

    private func openStatusInfo() {
        let viewController = TransactionStatusInfoViewController()
        present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

    private func openResend(action: TransactionInfoModule.Option) {
        do {
            let viewController = try SendEvmConfirmationModule.resendViewController(adapter: adapter, action: action, transactionHash: viewModel.transactionHash)
            present(ThemeNavigationController(rootViewController: viewController), animated: true)
        } catch {
            HudHelper.instance.showError(title: error.localizedDescription)
        }
    }

    private func statusRow(rowInfo: RowInfo, status: TransactionStatus) -> RowProtocol {
        let hash: String
        var hasButton = true
        let value: String
        var icon: UIImage?
        var spinnerProgress: Double?

        switch status {
        case .pending:
            hash = "pending"
            value = "transactions.pending".localized
            spinnerProgress = 0.2
        case .processing(let progress):
            hash = "processing-\(progress)"
            value = "transactions.processing".localized
            spinnerProgress = progress * 0.8 + 0.2
        case .completed:
            hash = "completed"
            hasButton = false
            value = "transactions.completed".localized
            icon = UIImage(named: "check_1_20")?.withTintColor(.themeRemus)
        case .failed:
            hash = "failed"
            value = "transactions.failed".localized
            icon = UIImage(named: "warning_2_20")?.withTintColor(.themeLucian)
        }

        return CellBuilder.row(
                elements: [.transparentIconButton, .margin4, .text, .text, .margin8, .image20, .determiniteSpinner20],
                layoutMargins: UIEdgeInsets(top: 0, left: hasButton ? .margin4 : CellBuilder.defaultMargin, bottom: 0, right: CellBuilder.defaultMargin),
                tableView: tableView,
                id: "status",
                hash: hash,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TransparentIconButtonComponent) in
                        if hasButton {
                            component.isHidden = false
                            component.button.isSelected = true
                            component.button.set(image: UIImage(named: "circle_information_20"))
                            component.onTap = { [weak self] in
                                self?.openStatusInfo()
                            }
                        } else {
                            component.isHidden = true
                        }
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = "status".localized
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: .c2)
                        component.text = value
                    }

                    cell.bind(index: 3) { (component: ImageComponent) in
                        if let icon = icon {
                            component.isHidden = false
                            component.imageView.image = icon
                        } else {
                            component.isHidden = true
                        }
                    }

                    cell.bind(index: 4) { (component: DeterminiteSpinnerComponent) in
                        if let progress = spinnerProgress {
                            component.isHidden = false
                            component.set(progress: progress)
                        } else {
                            component.isHidden = true
                        }
                    }
                }
        )
    }

    private func optionsRow(rowInfo: RowInfo, viewItems: [TransactionInfoModule.OptionViewItem]) -> RowProtocol {
        var elements: [CellBuilder.CellElement] = [.text]

        for (index, _) in viewItems.enumerated() {
            elements.append(.secondaryButton)
            if index < viewItems.count - 1 {
                elements.append(.margin8)
            }
        }

        return CellBuilder.row(
                elements: elements,
                tableView: tableView,
                id: "options",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = "tx_info.options".localized
                    }

                    for (index, viewItem) in viewItems.enumerated() {
                        cell.bind(index: index + 1) { (component: SecondaryButtonComponent) in
                            component.button.set(style: .default)
                            component.button.setTitle(viewItem.title, for: .normal)
                            component.button.isEnabled = viewItem.active
                            component.onTap = { [weak self] in
                                self?.openResend(action: viewItem.option)
                            }
                        }
                    }
                }
        )
    }

    private func fromToRow(rowInfo: RowInfo, id: String, title: String, value: String, valueTitle: String?) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .secondaryButton],
                tableView: tableView,
                id: id,
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = title
                    }

                    cell.bind(index: 1) { (component: SecondaryButtonComponent) in
                        component.button.set(style: .default)
                        component.button.setTitle(valueTitle ?? value, for: .normal)
                        component.button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }
                }
        )
    }

    private func fromRow(rowInfo: RowInfo, value: String, valueTitle: String?) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, id: "from", title: "tx_info.from_hash".localized, value: value, valueTitle: valueTitle)
    }

    private func toRow(rowInfo: RowInfo, value: String, valueTitle: String?) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, id: "to", title: "tx_info.to_hash".localized, value: value, valueTitle: valueTitle)
    }

    private func spenderRow(rowInfo: RowInfo, value: String, valueTitle: String?) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, id: "spender", title: "tx_info.spender".localized, value: value, valueTitle: valueTitle)
    }

    private func recipientRow(rowInfo: RowInfo, value: String, valueTitle: String?) -> RowProtocol {
        fromToRow(rowInfo: rowInfo, id: "recipient", title: "tx_info.recipient_hash".localized, value: value, valueTitle: valueTitle)
    }

    private func idRow(rowInfo: RowInfo, value: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .secondaryButton, .margin8, .secondaryCircleButton],
                tableView: tableView,
                id: "transaction_id",
                hash: value,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = "tx_info.transaction_id".localized
                    }

                    cell.bind(index: 1) { (component: SecondaryButtonComponent) in
                        component.button.set(style: .default)
                        component.button.setTitle(value, for: .normal)
                        component.button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                        component.onTap = {
                            CopyHelper.copyAndNotify(value: value)
                        }
                    }

                    cell.bind(index: 2) { (component: SecondaryCircleButtonComponent) in
                        component.button.set(image: UIImage(named: "share_1_20"))
                        component.onTap = { [weak self] in
                            let activityViewController = UIActivityViewController(activityItems: [value], applicationActivities: [])
                            self?.present(activityViewController, animated: true)
                        }
                    }
                }
        )
    }

    private func valueRow(rowInfo: RowInfo, title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7Cell>(
                id: title,
                hash: value ?? "",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeLeah
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func multiLineValueRow(rowInfo: RowInfo, title: String, value: String?, valueItalic: Bool = false) -> RowProtocol {
        Row<D7MultiLineCell>(
                id: title,
                hash: value ?? "",
                dynamicHeight: { width in
                    D7MultiLineCell.height(containerWidth: width, backgroundStyle: .lawrence, title: title, value: value, valueItalic: valueItalic)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.value = value
                    cell.valueColor = .themeLeah
                    cell.valueItalic = valueItalic
                }
        )
    }

    private func feeRow(rowInfo: RowInfo, title: String, value: String) -> RowProtocol {
        valueRow(
                rowInfo: rowInfo,
                title: title,
                value: value
        )
    }

    private func warningRow(rowInfo: RowInfo, id: String, image: UIImage?, text: String, onTapButton: @escaping () -> ()) -> RowProtocol {
        Row<C4MultiLineCell>(
                id: id,
                hash: text,
                autoDeselect: true,
                dynamicHeight: { containerWidth in
                    C4MultiLineCell.height(containerWidth: containerWidth, backgroundStyle: .lawrence, title: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.titleImage = image?.withTintColor(.themeGray)
                    cell.title = text
                    cell.valueImage = UIImage(named: "circle_information_20")?.withRenderingMode(.alwaysTemplate)
                    cell.valueImageTintColor = .themeGray
                },
                action: { _ in
                    onTapButton()
                }
        )
    }

    private func doubleSpendRow(rowInfo: RowInfo, txHash: String, conflictingTxHash: String) -> RowProtocol {
        warningRow(
                rowInfo: rowInfo,
                id: "double_spend",
                image: UIImage(named: "double_send_20"),
                text: "tx_info.double_spent_note".localized
        ) { [weak self] in
            let module = DoubleSpendInfoRouter.module(txHash: txHash, conflictingTxHash: conflictingTxHash)
            self?.present(module, animated: true)
        }
    }

    private func lockInfoRow(rowInfo: RowInfo, lockState: TransactionLockState) -> RowProtocol {
        let id = "lock_info"
        let image = UIImage(named: lockState.locked ? "lock_20" : "unlock_20")
        let formattedDate = DateHelper.instance.formatFullTime(from: lockState.date)

        if lockState.locked {
            return warningRow(rowInfo: rowInfo, id: id, image: image, text: "tx_info.locked_until".localized(formattedDate)) { [weak self] in
                self?.present(InfoModule.timeLockInfo, animated: true)
            }
        } else {
            return noteRow(rowInfo: rowInfo, id: id, image: image, imageTintColor: .themeGray, text: "tx_info.unlocked_at".localized(formattedDate))
        }
    }

    private func noteRow(rowInfo: RowInfo, id: String, image: UIImage?, imageTintColor: UIColor, text: String) -> RowProtocol {
        Row<CMultiLineCell>(
                id: id,
                hash: text,
                dynamicHeight: { containerWidth in
                    CMultiLineCell.height(containerWidth: containerWidth, backgroundStyle: .lawrence, title: text)
                },
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.titleImage = image?.withTintColor(imageTintColor)
                    cell.title = text
                }
        )
    }

    private func sentToSelfRow(rowInfo: RowInfo) -> RowProtocol {
        noteRow(
                rowInfo: rowInfo,
                id: "sent_to_self",
                image: UIImage(named: "arrow_medium_main_down_left_20")?.withRenderingMode(.alwaysTemplate),
                imageTintColor: .themeRemus,
                text: "tx_info.to_self_note".localized
        )
    }

    private func rawTransactionRow(rowInfo: RowInfo) -> RowProtocol {
        Row<D9Cell>(
                id: "raw_transaction",
                height: .heightCell48,
                bind: { [weak self] cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.raw_transaction".localized
                    cell.viewItem = .init(type: .image, value: { [weak self] in self?.viewModel.rawTransaction ?? "" })
                }
        )
    }

    private func explorerRow(rowInfo: RowInfo, title: String, url: String?) -> RowProtocol {
        Row<A1Cell>(
                id: "explorer_row",
                hash: "explorer_row",
                height: .heightCell48,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = title
                    cell.titleImage = UIImage(named: "globe_20")
                },
                action: { [weak self] _ in
                    guard let url = url else {
                        return
                    }

                    self?.urlManager.open(url: url, from: self)
                }
        )
    }

    private func actionTitleRow(rowInfo: RowInfo, iconName: String?, iconDimmed: Bool, title: String, value: String) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .text],
                tableView: tableView,
                id: "action-\(rowInfo.index)",
                hash: "action-\(value)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        if let iconName = iconName {
                            component.isHidden = false
                            component.imageView.image = UIImage(named: iconName)?.withTintColor(iconDimmed ? .themeGray : .themeLeah)
                        } else {
                            component.isHidden = true
                        }
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .b2)
                        component.text = title
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = value
                    }
                }
        )
    }

    private func amountRow(rowInfo: RowInfo, iconUrl: String?, iconPlaceholderImageName: String, coinAmount: String, currencyAmount: String?, type: TransactionInfoModule.AmountType) -> RowProtocol {
        CellBuilder.row(
                elements: [.image24, .text, .text],
                tableView: tableView,
                id: "amount-\(rowInfo.index)",
                hash: "amount-\(coinAmount)-\(currencyAmount)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: iconUrl, placeholder: UIImage(named: iconPlaceholderImageName))
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        switch type {
                        case .incoming: component.set(style: .d4)
                        case .outgoing: component.set(style: .d5)
                        case .neutral: component.set(style: .d2)
                        }

                        component.text = coinAmount
                    }

                    cell.bind(index: 2) { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = currencyAmount
                    }
                }
        )
    }

    private func dateRow(rowInfo: RowInfo, date: Date) -> RowProtocol {
        CellBuilder.row(
                elements: [.text, .text],
                tableView: tableView,
                id: "date",
                hash: date.description,
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)

                    cell.bind(index: 0) { (component: TextComponent) in
                        component.set(style: .d1)
                        component.text = "tx_info.date".localized
                    }

                    cell.bind(index: 1) { (component: TextComponent) in
                        component.set(style: .c2)
                        component.text = DateHelper.instance.formatFullTime(from: date)
                    }
                }
        )
    }

    private func priceRow(rowInfo: RowInfo, price: String) -> RowProtocol {
        Row<D7Cell>(
                id: "price",
                hash: "\(price)",
                height: .heightCell48,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: rowInfo.isFirst, isLast: rowInfo.isLast)
                    cell.title = "tx_info.price".localized
                    cell.value = price
                    cell.valueColor = .themeLeah
                    cell.valueItalic = false
                }
        )
    }
    private func row(viewItem: TransactionInfoModule.ViewItem, rowInfo: RowInfo) -> RowProtocol {
        switch viewItem {
        case let .actionTitle(iconName, iconDimmed, title, subTitle): return actionTitleRow(rowInfo: rowInfo, iconName: iconName, iconDimmed: iconDimmed, title: title, value: subTitle ?? "")
        case let .amount(iconUrl, iconPlaceholderImageName, coinAmount, currencyAmount, type): return amountRow(rowInfo: rowInfo, iconUrl: iconUrl, iconPlaceholderImageName: iconPlaceholderImageName, coinAmount: coinAmount, currencyAmount: currencyAmount, type: type)
        case let .status(status): return statusRow(rowInfo: rowInfo, status: status)
        case let .options(actions: viewItems): return optionsRow(rowInfo: rowInfo, viewItems: viewItems)
        case let .date(date): return dateRow(rowInfo: rowInfo, date: date)
        case let .from(value, valueTitle): return fromRow(rowInfo: rowInfo, value: value, valueTitle: valueTitle)
        case let .to(value, valueTitle): return toRow(rowInfo: rowInfo, value: value, valueTitle: valueTitle)
        case let .spender(value, valueTitle): return spenderRow(rowInfo: rowInfo, value: value, valueTitle: valueTitle)
        case let .recipient(value, valueTitle): return recipientRow(rowInfo: rowInfo, value: value, valueTitle: valueTitle)
        case let .id(value): return idRow(rowInfo: rowInfo, value: value)
        case let .rate(value): return valueRow(rowInfo: rowInfo, title: "tx_info.rate".localized, value: value)
        case let .fee(title, value): return feeRow(rowInfo: rowInfo, title: title, value: value)
        case let .price(price): return priceRow(rowInfo: rowInfo, price: price)
        case let .doubleSpend(txHash, conflictingTxHash): return doubleSpendRow(rowInfo: rowInfo, txHash: txHash, conflictingTxHash: conflictingTxHash)
        case let .lockInfo(lockState): return lockInfoRow(rowInfo: rowInfo, lockState: lockState)
        case .sentToSelf: return sentToSelfRow(rowInfo: rowInfo)
        case .rawTransaction: return rawTransactionRow(rowInfo: rowInfo)
        case let .memo(value): return multiLineValueRow(rowInfo: rowInfo, title: "tx_info.memo".localized, value: value, valueItalic: true)
        case let .service(value): return valueRow(rowInfo: rowInfo, title: "tx_info.service".localized, value: value)
        case let .explorer(title, url): return explorerRow(rowInfo: rowInfo, title: title, url: url)
        }
    }

}

extension TransactionInfoViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { (index: Int, sectionViewItems: [TransactionInfoModule.ViewItem]) -> SectionProtocol in
            Section(
                    id: "section_\(index)",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: index == viewItems.count - 1 ? .margin32 : 0),
                    rows: sectionViewItems.enumerated().map { (index, viewItem) in
                        row(viewItem: viewItem, rowInfo: RowInfo(index: index, isFirst: index == 0, isLast: index == sectionViewItems.count - 1))
                    }
            )
        }
    }

}

fileprivate struct RowInfo {
    let index: Int
    let isFirst: Bool
    let isLast: Bool
}
