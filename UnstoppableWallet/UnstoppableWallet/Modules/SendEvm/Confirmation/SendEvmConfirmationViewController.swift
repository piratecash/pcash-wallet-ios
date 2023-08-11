import UIKit
import ThemeKit
import SnapKit
import RxSwift
import RxCocoa
import ComponentKit

class SendEvmConfirmationViewController: SendEvmTransactionViewController {
    private let sendButton = SliderButton()

    var confirmationTitle = "confirm".localized
    var confirmationButtonTitle = "send.confirmation.slide_to_send".localized

    override func viewDidLoad() {
        super.viewDidLoad()

        title = confirmationTitle

        bottomWrapper.addSubview(sendButton)

        sendButton.title = confirmationButtonTitle
        sendButton.image = UIImage(named: "arrow_medium_2_right_24")
        sendButton.onTap = { [weak self] in
            self?.transactionViewModel.send()
        }

        subscribe(disposeBag, transactionViewModel.sendEnabledDriver) { [weak self] in self?.sendButton.isEnabled = $0 }
    }

    override func handleSending() {
        HudHelper.instance.show(banner: .sending)
    }

    override func handleSendSuccess(transactionHash: Data) {
        HudHelper.instance.show(banner: .sent)

        super.handleSendSuccess(transactionHash: transactionHash)
    }

}
