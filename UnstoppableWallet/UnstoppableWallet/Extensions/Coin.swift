import UIKit
import MarketKit

extension Coin {

    var imageUrl: String {
        switch uid{
        case "piratecash":
            return "https://p.cash/logo.png"
        case "cosanta":
            return "https://cosanta.net/logo.png"
        default:
            let scale = Int(UIScreen.main.scale)
            return "https://cdn.blocksdecoded.com/coin-icons/32px/\(uid)@\(scale)x.png"
        }
    }

}
