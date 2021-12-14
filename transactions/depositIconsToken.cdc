import IconsToken from "../contracts/flow/IconsToken.cdc"
import TeleportCustody from "../contracts/flow/TeleportCustody.cdc"

transaction(amount: UFix64) {
  prepare(admin: AuthAccount) {

    let adminRef = admin.borrow<&TeleportCustody.Administrator>(from: TeleportCustody.AdminStoragePath)
      ?? panic("Could not borrow a reference to the admin resource")

    let iconsVaultRef = admin.borrow<&IconsToken.Vault>(from: IconsToken.VaultStoragePath)
      ?? panic("Could not borrow a reference to the IconsToken vault")

    let iconsVault <- iconsVaultRef.withdraw(amount: amount)

    adminRef.depositIconsToken(from: <- (iconsVault as! @IconsToken.Vault))
  }
}
 