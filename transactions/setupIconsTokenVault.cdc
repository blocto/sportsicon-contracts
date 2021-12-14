import FungibleToken from "../contracts/flow/FungibleToken.cdc"
import IconsToken from "../contracts/flow/IconsToken.cdc"

// This transaction is a template for a transaction
// to add a Vault resource to their account
// so that they can use the IconsToken

transaction {

  prepare(signer: AuthAccount) {

    if signer.borrow<&IconsToken.Vault>(from: IconsToken.VaultStoragePath) == nil {
      // Create a new IconsToken Vault and put it in storage
      signer.save(<-IconsToken.createEmptyVault(), to: IconsToken.VaultStoragePath)

      // Create a public capability to the Vault that only exposes
      // the deposit function through the Receiver interface
      signer.link<&IconsToken.Vault{FungibleToken.Receiver}>(
        IconsToken.VaultReceiverPublicPath,
        target: IconsToken.VaultStoragePath
      )

      // Create a public capability to the Vault that only exposes
      // the balance field through the Balance interface
      signer.link<&IconsToken.Vault{FungibleToken.Balance}>(
        IconsToken.VaultBalancePublicPath,
        target: IconsToken.VaultStoragePath
      )
    }
  }
}
