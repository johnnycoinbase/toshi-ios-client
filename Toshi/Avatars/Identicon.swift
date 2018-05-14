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
import BlockiesSwift

struct Identicon {

    private static let defaultBlocksSize: Int = 8
    private static let defaultScale: Int = 6

    /// Generates identicon for given address.
    ///
    /// - Parameters:
    ///   - seed: The seed to be used.
    ///   - size: The number of blocks per side for this image. Defaults to 8.
    ///   - scale: The number of pixels per block. Defaults to 6.
    ///   - color: The foreground color. Defaults to nil, then random is used indside Blockies.
    ///   - bgColor: The background color. Defaults to nil, then random is used indside Blockies.
    ///   - spotColor: A color which forms mouths and eyes. Defaults to nil, then random is used indside Blockies.
    static func generate(for address: String, size: Int = defaultBlocksSize, scale: Int = defaultScale, color: UIColor? = nil, bgColor: UIColor? = nil, spotColor: UIColor? = nil) -> UIImage? {

        let blockies = Blockies(seed: address,
                                size: size,
                                scale: scale,
                                color: color,
                                bgColor: bgColor,
                                spotColor: spotColor)
        return blockies.createImage()
    }
}
