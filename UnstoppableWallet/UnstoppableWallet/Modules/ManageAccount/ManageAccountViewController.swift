import UIKit
import ThemeKit
import SectionsTableView
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit
import PinKit

class ManageAccountViewController: KeyboardAwareViewController {
    private let viewModel: ManageAccountViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)

    private let nameCell = TextFieldCell()

    private var warningViewItem: CancellableTitledCaution?
    private var keyActions: [[ManageAccountViewModel.KeyAction]] = []
    private var isLoaded = false

    private weak var sourceViewController: ManageAccountsViewController?

    init(viewModel: ManageAccountViewModel, sourceViewController: ManageAccountsViewController) {
        self.viewModel = viewModel
        self.sourceViewController = sourceViewController

        super.init(scrollViews: [tableView])

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = viewModel.accountName
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.save".localized, style: .done, target: self, action: #selector(onTapSave))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.largeTitleDisplayMode = .never

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: TitledHighlightedDescriptionCell.self)

        nameCell.inputText = viewModel.accountName
        nameCell.autocapitalizationType = .words
        nameCell.onChangeText = { [weak self] in self?.viewModel.onChange(name: $0) }

        subscribe(disposeBag, viewModel.saveEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.keyActionsDriver) { [weak self] in
            self?.keyActions = $0
            self?.reloadTable()
        }
        subscribe(disposeBag, viewModel.showWarningDriver) { [weak self] in self?.sync(warning: $0) }
        subscribe(disposeBag, viewModel.openUnlockSignal) { [weak self] in self?.openUnlock() }
        subscribe(disposeBag, viewModel.openRecoveryPhraseSignal) { [weak self] in self?.openRecoveryPhrase(account: $0) }
        subscribe(disposeBag, viewModel.openBackupSignal) { [weak self] in self?.openBackup(account: $0) }
        subscribe(disposeBag, viewModel.openBackupAndDeleteCloudSignal) { [weak self] in
            self?.openBackup(account: $0) { [weak self] in
                self?.deleteCloudBackup()
            }
        }
        subscribe(disposeBag, viewModel.openCloudBackupSignal) { [weak self] in self?.openCloudBackup(account: $0) }
        subscribe(disposeBag, viewModel.confirmDeleteCloudBackupSignal) { [weak self] in self?.confirmDeleteCloudBackup(manualBackedUp: $0) }
        subscribe(disposeBag, viewModel.cloudBackupDeletedSignal) { [weak self] in self?.cloudBackupDeleted($0) }
        subscribe(disposeBag, viewModel.openUnlinkSignal) { [weak self] in self?.openUnlink(account: $0) }
        subscribe(disposeBag, viewModel.finishSignal) { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.sourceViewController?.handleDismiss()
            }
        }

        tableView.buildSections()

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    @objc private func onTapSave() {
        viewModel.onSave()
    }

    private func openUnlock() {
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: .margin48, right: 0)
        let viewController = App.shared.pinKit.unlockPinModule(
                biometryUnlockMode: .auto,
                insets: insets,
                cancellable: true,
                autoDismiss: true,
                onUnlock: { [weak self] in
                    self?.viewModel.onUnlock()
                }
        )
        present(viewController, animated: true)
    }

    private func openRecoveryPhrase(account: Account) {
        guard let viewController = RecoveryPhraseModule.viewController(account: account) else {
            return
        }

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openPublicKeys() {
        let viewController = PublicKeysModule.viewController(account: viewModel.account)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openPrivateKeys() {
        let viewController = PrivateKeysModule.viewController(account: viewModel.account)
        navigationController?.pushViewController(viewController, animated: true)
    }

    private func openBackup(account: Account, onComplete: (() -> ())? = nil) {
        guard let viewController = BackupModule.manualViewController(account: account, onComplete: onComplete) else {
            return
        }

        present(viewController, animated: true)
    }

    private func openCloudBackup(account: Account) {
        let viewController = BackupModule.cloudViewController(account: account)
        present(viewController, animated: true)
    }

    private func confirmDeleteCloudBackup(manualBackedUp: Bool) {
        if manualBackedUp {
            let viewController = BottomSheetModule.confirmDeleteCloudBackupController { [weak self] in
                self?.viewModel.deleteCloudBackup()
            }
            present(viewController, animated: true)
        } else {
            let viewController = BottomSheetModule.deleteCloudBackupAfterManualBackupController { [weak self] in
                self?.viewModel.deleteCloudBackupAfterManualBackup()
            }
            present(viewController, animated: true)
        }
    }

    private func deleteCloudBackup() {
        viewModel.deleteCloudBackup()
    }

    private func cloudBackupDeleted(_ successful: Bool) {
        if successful {
            HudHelper.instance.show(banner: .deleted)
        } else {
            HudHelper.instance.show(banner: .error(string: "backup.cloud.cant_delete_file".localized))
        }
    }

    private func onTapUnlink() {
        viewModel.onTapUnlink()
    }

    private func openUnlink(account: Account) {
        let viewController = UnlinkModule.viewController(account: account)
        present(viewController, animated: true)
    }

    private func reloadTable() {
        guard isLoaded else {
            return
        }

        tableView.reload()
    }

    private func sync(warning: CancellableTitledCaution?) {
        warningViewItem = warning
        tableView.reloadData()
    }

    private func onOpenWarning() {
        guard let url = viewModel.warningUrl else {
            return
        }
        let module = MarkdownModule.viewController(url: url)
        DispatchQueue.main.async {
            let controller = ThemeNavigationController(rootViewController: module)
            return self.present(controller, animated: true)
        }
    }

}

extension ManageAccountViewController: SectionsDataSource {

    private func row(keyAction: ManageAccountViewModel.KeyAction, isFirst: Bool, isLast: Bool) -> RowProtocol {
        switch keyAction {
        case .recoveryPhrase:
            return tableView.universalRow48(
                    id: "recovery-phrase",
                    image: .local(UIImage(named: "paper_contract_24")),
                    title: .body("manage_account.recovery_phrase".localized),
                    accessoryType: .disclosure,
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapRecoveryPhrase()
            }
        case .privateKeys:
            return tableView.universalRow48(
                    id: "private-keys",
                    image: .local(UIImage(named: "key_24")),
                    title: .body("manage_account.private_keys".localized),
                    accessoryType: .disclosure,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.openPrivateKeys()
            }
        case .publicKeys:
            return tableView.universalRow48(
                    id: "public-keys",
                    image: .local(UIImage(named: "binocule_24")),
                    title: .body("manage_account.public_keys".localized),
                    accessoryType: .disclosure,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.openPublicKeys()
            }
        case .backup(let isCloudBackedUp):
            return tableView.universalRow48(
                    id: "backup-recovery-phrase",
                    image: .local(UIImage(named: "edit_24")?.withTintColor(.themeJacob)),
                    title: .body("manage_account.backup_recovery_phrase".localized, color: .themeJacob),
                    accessoryType: CellBuilderNew.CellElement.ImageAccessoryType(
                            image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian),
                            visible: !isCloudBackedUp
                    ),
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapBackup()
            }
        case .cloudBackedUp(let isBackedUp, manualBackedUp: let manualBackedUp):
            if isBackedUp {
                return tableView.universalRow48(
                        id: "cloud-backup-recovery",
                        image: .local(UIImage(named: "no_internet_24")?.withTintColor(.themeLucian)),
                        title: .body("manage_account.cloud_delete_backup_recovery_phrase".localized, color: .themeLucian),
                        autoDeselect: true,
                        isFirst: isFirst,
                        isLast: isLast
                ) { [weak self] in
                    self?.viewModel.onTapDeleteCloudBackup()
                }
            }

            return tableView.universalRow48(
                    id: "cloud-backup-recovery",
                    image: .local(UIImage(named: "icloud_24")?.withTintColor(.themeJacob)),
                    title: .body("manage_account.cloud_backup_recovery_phrase".localized, color: .themeJacob),
                    accessoryType: CellBuilderNew.CellElement.ImageAccessoryType(
                            image: UIImage(named: "warning_2_24")?.withTintColor(.themeLucian),
                            visible: !manualBackedUp
                    ),
                    autoDeselect: true,
                    isFirst: isFirst,
                    isLast: isLast
            ) { [weak self] in
                self?.viewModel.onTapCloudBackup()
            }
        }
    }

    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [
            Section(
                    id: "margin",
                    headerState: .margin(height: .margin12)
            ),
            Section(
                    id: "name",
                    headerState: tableView.sectionHeader(text: "manage_account.name".localized),
                    footerState: .margin(height: .margin32),
                    rows: [
                        StaticRow(
                                cell: nameCell,
                                id: "name",
                                height: .heightSingleLineCell
                        )
                    ]
            )
        ]

        if let warningViewItem = warningViewItem {
            sections.append(
                    Section(
                        id: "migration-warning",
                        footerState: .margin(height: .margin32),
                        rows: [
                            Row<TitledHighlightedDescriptionCell>(
                                    id: "migration-cell",
                                    dynamicHeight: { [weak self] containerWidth in
                                        let text = self?.warningViewItem?.text ?? ""
                                        return TitledHighlightedDescriptionCell.height(containerWidth: containerWidth, text: text)
                                    },
                                    bind: { [weak self] cell, _ in
                                        cell.set(backgroundStyle: .transparent, isFirst: true)
                                        cell.bind(caution: warningViewItem)
                                        cell.onBackgroundButton = { self?.onOpenWarning() }
                                    }
                            )
                        ]
                    )
            )
        }

        sections.append(contentsOf:
            keyActions.enumerated().map { (index, section) in
                Section(
                        id: "actions-\(index)",
                        footerState: .margin(height: .margin32),
                        rows: section.enumerated().map { index, keyAction in
                            row(keyAction: keyAction, isFirst: index == 0, isLast: index == section.count - 1)
                        }
                )
            }
        )

        sections.append(
                Section(
                        id: "unlink",
                        footerState: .margin(height: .margin32),
                        rows: [
                            tableView.universalRow48(
                                    id: "unlink",
                                    image: .local(UIImage(named: "trash_24")?.withTintColor(.themeLucian)),
                                    title: .body("manage_account.unlink".localized, color: .themeLucian),
                                    autoDeselect: true,
                                    isFirst: true,
                                    isLast: true
                            ) { [weak self] in
                                self?.onTapUnlink()
                            }
                        ]
                )
        )

        return sections
    }

}
