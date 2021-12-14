import FungibleToken from "../contracts/flow/FungibleToken.cdc"
import IconsToken from "../contracts/flow/IconsToken.cdc"
import TeleportCustody from "../contracts/flow/TeleportCustody.cdc"

transaction(teleportAdminAddress: Address, amount: UFix64, target: String) {
  prepare(signer: AuthAccount) {
    let teleportUserRef = getAccount(teleportAdminAddress).getCapability(TeleportCustody.TeleportUserPublicPath)!
        .borrow<&TeleportCustody.TeleportAdmin{TeleportCustody.TeleportUser}>()
        ?? panic("Could not borrow a reference to TeleportUser")

    let vaultRef = signer.borrow<&IconsToken.Vault>(from: IconsToken.VaultStoragePath)
        ?? panic("Could not borrow a reference to the vault resource")

    let vault <- vaultRef.withdraw(amount: amount) as! @IconsToken.Vault;
    
    teleportUserRef.lock(from: <- vault, to: target.decodeHex())
  }
}
