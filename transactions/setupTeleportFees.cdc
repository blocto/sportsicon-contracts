import TeleportCustody from "../contracts/flow/TeleportCustody.cdc"

transaction(inwardFee: UFix64, outwardFee: UFix64) {
  prepare(teleportAdmin: AuthAccount) {

    let adminRef = teleportAdmin.borrow<&{TeleportCustody.TeleportControl}>(from: TeleportCustody.TeleportAdminStoragePath)
        ?? panic("Could not borrow a reference to the admin resource")

    adminRef.updateInwardFee(fee: inwardFee)
    adminRef.updateOutwardFee(fee: outwardFee)
  }
}
