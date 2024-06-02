import MarketKit
import UIKit

extension Coin {
    var imageUrl: String {
        switch uid{
        case "piratecash":
            return "https://p.cash/logo.png"
        case "cosanta":
            return "https://cosanta.net/logo.png"
        case "wdash":
            return "https://wdash.org/logo.png"
        default:
            let scale = Int(UIScreen.main.scale)
            return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
        }
    }

    static func imageUrl(uid: String) -> String {
        let scale = Int(UIScreen.main.scale)
        return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
    }
}
