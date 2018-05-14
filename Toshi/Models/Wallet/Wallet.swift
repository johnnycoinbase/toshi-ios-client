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
import EtherealCereal
import HDWallet
import Haneke

struct Wallet {

    static private let walletsNumber: UInt32 = 10
    static var activeWalletPath: UInt32 {
        guard let storedActiveWalletPath = UserDefaultsWrapper.activeWalletPath else { return 0 }

        return UInt32(storedActiveWalletPath)
    }

    private static let identiconsCache = Shared.imageCache

    static private(set) var items = [Wallet]()

    static var walletsAddresses: [String] {
        return items.map { $0.address }
    }

    static var activeWallet: Wallet {
        return items.first(where: { $0.path == activeWalletPath }) ?? Wallet.items.first!
    }

    static private var identiconGenerationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = Int(walletsNumber)
        queue.name = "Identicons queue"

        return queue
    }()

    private let mnemonic: BTCMnemonic

    private(set) var path: UInt32
    private(set) var cereal: EtherealCereal

    var title: String {
        return String(format: Localized.wallet_title_format, "\(path + 1)")
    }

    var address: String {
        return cereal.address
    }

    var generatedAndCachedIdenticon: UIImage? {
        var image: UIImage?

        Wallet.identiconsCache.fetch(key: address).onSuccess { cachedImage in
            image = cachedImage
        }

        return image
    }

    var identiconOrPlaceholder: UIImage {
        return generatedAndCachedIdenticon ?? ImageAsset.avatar_placeholder
    }

    var isActive: Bool {
        return address == Wallet.activeWallet.address
    }

    init(path: UInt32, mnemonic: BTCMnemonic) {
        self.path = path
        self.mnemonic = mnemonic

        let walletKeychain: BTCKeychain = Wallet.walletKeychain(from: mnemonic, lastPath: path)
        let walletPrivateKey = walletKeychain.key.privateKey.hexadecimalString()
        self.cereal = EtherealCereal(privateKey: walletPrivateKey)
    }

    func activate() {
        UserDefaultsWrapper.activeWalletPath = Int(path)
    }

    static func generate(mnemonic: BTCMnemonic) {

        var generatedWalletItems = [Wallet]()

        for walletPath in 0...Wallet.walletsNumber - 1 {
            let wallet = Wallet(path: walletPath, mnemonic: mnemonic)
            generatedWalletItems.append(wallet)

            let operation = BlockOperation()
            operation.addExecutionBlock {
                if let identicon = IdenticonGenerator.identicon(for: wallet.address) {
                    Wallet.identiconsCache.set(value: identicon, key: wallet.address)
                }
            }

            identiconGenerationQueue.addOperation(operation)
        }

        items = generatedWalletItems
    }

    private static func walletKeychain(from mnemonic: BTCMnemonic, lastPath: UInt32) -> BTCKeychain {
        // wallet path: 44H/60H/0H/0 and then 0 again. Metamask root path, first key.
        // Metamask allows multiple addresses, by incrementing the last path. So second key would be: 44H/60H/0H/0/1 and so on.
        return mnemonic.keychain
            .derivedKeychain(at: 44, hardened: true)
            .derivedKeychain(at: 60, hardened: true)
            .derivedKeychain(at: 0, hardened: true)
            .derivedKeychain(at: 0)
            .derivedKeychain(at: lastPath)
    }
}
