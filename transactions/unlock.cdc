import FungibleToken from "../contracts/flow/FungibleToken.cdc"
import IconsToken from "../contracts/flow/IconsToken.cdc"
import TeleportCustody from "../contracts/flow/TeleportCustody.cdc"

transaction(amount: UFix64, target: Address, from: String, hash: String) {
  prepare(teleportAdmin: AuthAccount) {
    let teleportControlRef = teleportAdmin.getCapability(TeleportCustody.TeleportAdminPrivatePath)
        .borrow<&TeleportCustody.TeleportAdmin{TeleportCustody.TeleportControl}>()
        ?? panic("Could not borrow a reference to TeleportControl")
    
    let vault <- teleportControlRef.unlock(amount: amount, from: from.decodeHex(), hash: hash)

    let receiverRef = getAccount(target).getCapability(IconsToken.VaultReceiverPublicPath)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Could not borrow a reference to Receiver")

    receiverRef.deposit(from: <- vault)
  }
}