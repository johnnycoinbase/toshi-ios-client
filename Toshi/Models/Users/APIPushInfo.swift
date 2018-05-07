// Copyright (c) 2018 Token Browser, Inc
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

struct APIPushInfo: Codable {

    // NOTE: Order matters on these - if the JSON is not sent in the registration_id -> address order, the signature verification fails.
    let registrationID: String
    let address: String

    enum CodingKeys: String, CodingKey {
        case
        registrationID = "registration_id",
        address
    }

    /// Grabs the default information for the user.
    static var defaultInfo: APIPushInfo {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Could not access the app delegate!")
        }

        return APIPushInfo(registrationID: appDelegate.token,
                           address: Cereal.shared.paymentAddress)
    }
}
