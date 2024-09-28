import RxRelay
import RxSwift
import UIKit

class AppIconManager {
    static let allAppIcons: [AppIcon] = [
        .main,
        .alternate(name: "AppIconDark", imageName: "app_icon_dark", title: "Dark"),
        .alternate(name: "AppIconMono", imageName: "app_icon_mono", title: "Mono"),
        .alternate(name: "AppIconMsg", imageName: "app_icon_corsa", title: "Corsa"),
        .alternate(name: "AppIconWorld", imageName: "app_icon_world", title: "World"),
        .alternate(name: "AppIconSafe", imageName: "app_icon_safe", title: "Safe")
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
