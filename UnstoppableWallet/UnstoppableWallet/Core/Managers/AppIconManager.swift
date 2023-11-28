import RxRelay
import RxSwift
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", title: "Dark"),
        .alternate(name: "AppIconMono", title: "Mono"),
        .alternate(name: "AppIconMsg", title: "Corsa"),
        .alternate(name: "AppIconWorld", title: "World"),
        .alternate(name: "AppIconSafe", title: "Safe")
    ]

    private let appIconRelay = PublishRelay<AppIcon>()
    var appIcon: AppIcon {
        didSet {
            appIconRelay.accept(appIcon)
            UIApplication.shared.setAlternateIconName(appIcon.name)
        }
    }

    init() {
        appIcon = Self.currentAppIcon
    }
}

extension AppIconManager {
    var appIconObservable: Observable<AppIcon> {
        appIconRelay.asObservable()
    }

    static var currentAppIcon: AppIcon {
        if let alternateIconName: String = UIApplication.shared.alternateIconName, let appIcon = allAppIcons.first(where: { $0.name == alternateIconName }) {
            return appIcon
        } else {
            return .main
        }
    }
}
