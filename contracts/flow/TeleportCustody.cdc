import FungibleToken from "./FungibleToken.cdc"
import IconsToken from "./IconsToken.cdc"

pub contract TeleportCustody {

  // Event that is emitted when new tokens are teleported in from BSC (from: BSC Address, 20 bytes)
  pub event TokensTeleportedIn(amount: UFix64, from: [UInt8], hash: String)

  // Event that is emitted when tokens are destroyed and teleported to BSC (to: BSC Address, 20 bytes)
  pub event TokensTeleportedOut(amount: UFix64, to: [UInt8])

  // Event that is emitted when teleport fee is collected (type 0: out, 1: in)
  pub event FeeCollected(amount: UFix64, type: UInt8)

  // Event that is emitted when a new burner resource is created
  pub event TeleportAdminCreated(allowedAmount: UFix64)

  // The storage path for the admin resource (equivalent to root)
  pub let AdminStoragePath: StoragePath

  // The storage path for the teleport-admin resource (less priviledged than admin)  
  pub let TeleportAdminStoragePath: StoragePath

  // The private path for the teleport-admin resource
  pub let TeleportAdminPrivatePath: PrivatePath 

  // The public path for the teleport user
  pub let TeleportUserPublicPath: PublicPath 

  // Frozen flag controlled by Admin
  pub var isFrozen: Bool

  // Record teleported BSC hashes
  access(contract) var teleported: {String: Bool}

  // Controls IconsToken vault
  access(contract) let iconVault: @IconsToken.Vault

  pub resource Allowance {
    pub var balance: UFix64

    // initialize the balance at resource creation time
    init(balance: UFix64) {
      self.balance = balance
    }
  }

  pub resource Administrator {

    // createNewTeleportAdmin
    //
    // Function that creates and returns a new teleport admin resource
    //
    pub fun createNewTeleportAdmin(allowedAmount: UFix64): @TeleportAdmin {
      emit TeleportAdminCreated(allowedAmount: allowedAmount)
      return <- create TeleportAdmin(allowedAmount: allowedAmount)
    }

    pub fun freeze() {
      TeleportCustody.isFrozen = true
    }

    pub fun unfreeze() {
      TeleportCustody.isFrozen = false
    }

    pub fun createAllowance(allowedAmount: UFix64): @Allowance {
      return <- create Allowance(balance: allowedAmount)
    }

    // deposit
    // 
    // Function that deposits IconsToken token into the contract controlled
    // vault.
    //
    pub fun depositIconsToken(from: @IconsToken.Vault) {
      TeleportCustody.iconVault.deposit(from: <- from)
    }

    pub fun withdrawIconsToken(amount: UFix64): @FungibleToken.Vault {
      return <- TeleportCustody.iconVault.withdraw(amount: amount)
    }
  }

  pub resource interface TeleportUser {
    // fee collected when token is teleported from BSC to Flow
    pub var inwardFee: UFix64

    // fee collected when token is teleported from Flow to BSC
    pub var outwardFee: UFix64
    
    // the amount of tokens that the admin is allowed to teleport
    pub var allowedAmount: UFix64

    // corresponding controller account on BSC
    pub var bscAdminAccount: [UInt8]

    pub fun lock(from: @IconsToken.Vault, to: [UInt8])

    pub fun depositAllowance(from: @Allowance)

    pub fun getFeeAmount(): UFix64
  }

  pub resource interface TeleportControl {
    pub fun unlock(amount: UFix64, from: [UInt8], hash: String): @FungibleToken.Vault

    pub fun withdrawFee(amount: UFix64): @FungibleToken.Vault
    
    pub fun updateInwardFee(fee: UFix64)

    pub fun updateOutwardFee(fee: UFix64)

    pub fun updateBSCAdminAccount(account: [UInt8])
  }

  // TeleportAdmin resource
  //
  //  Resource object that has the capability to teleport tokens
  //  upon receiving teleport request from BSC side
  //
  pub resource TeleportAdmin: TeleportUser, TeleportControl {
    
    // the amount of tokens that the admin is allowed to teleport
    pub var allowedAmount: UFix64

    // receiver reference to collect teleport fee
    pub let feeCollector: @IconsToken.Vault

    // fee collected when token is teleported from BSC to Flow
    pub var inwardFee: UFix64

    // fee collected when token is teleported from Flow to BSC
    pub var outwardFee: UFix64

    // corresponding controller account on BSC
    pub var bscAdminAccount: [UInt8]

    // unlock
    //
    // Function that release IconsToken tokens from custody,
    // and returns them to the calling context.
    //
    pub fun unlock(amount: UFix64, from: [UInt8], hash: String): @FungibleToken.Vault {
      pre {
        !TeleportCustody.isFrozen: "Teleport service is frozen"
        amount <= self.allowedAmount: "Amount teleported must be less than the allowed amount"
        amount > self.inwardFee: "Amount teleported must be greater than inward teleport fee"
        from.length == 20: "BSC address should be 20 bytes"
        hash.length == 64: "BSC tx hash should be 32 bytes"
        !(TeleportCustody.teleported[hash] ?? false): "Same hash already teleported"
      }
      self.allowedAmount = self.allowedAmount - amount

      TeleportCustody.teleported[hash] = true
      emit TokensTeleportedIn(amount: amount, from: from, hash: hash)

      let vault <- TeleportCustody.iconVault.withdraw(amount: amount)
      let fee <- vault.withdraw(amount: self.inwardFee)

      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.inwardFee, type: 1)

      return <- vault
    }

    // lock
    //
    // Function that destroys a Vault instance, effectively burning the tokens.
    //
    // Note: the burned tokens are automatically subtracted from the 
    // total supply in the Vault destructor.
    //
    pub fun lock(from: @IconsToken.Vault, to: [UInt8]) {
      pre {
        !TeleportCustody.isFrozen: "Teleport service is frozen"
        to.length == 20: "BSC address should be 20 bytes"
      }

      let vault <- from
      let fee <- vault.withdraw(amount: self.outwardFee)

      self.feeCollector.deposit(from: <-fee)
      emit FeeCollected(amount: self.outwardFee, type: 0)

      let amount = vault.balance
      TeleportCustody.iconVault.deposit(from: <- vault)
      emit TokensTeleportedOut(amount: amount, to: to)
    }

    pub fun withdrawFee(amount: UFix64): @FungibleToken.Vault {
      return <- self.feeCollector.withdraw(amount: amount)
    }

    pub fun updateInwardFee(fee: UFix64) {
      self.inwardFee = fee
    }

    pub fun updateOutwardFee(fee: UFix64) {
      self.outwardFee = fee
    }

    pub fun updateBSCAdminAccount(account: [UInt8]) {
      pre {
        account.length == 20: "BSC address should be 20 bytes"
      }

      self.bscAdminAccount = account
    }

    pub fun getFeeAmount(): UFix64 {
      return self.feeCollector.balance
    }

    pub fun depositAllowance(from: @Allowance) {
      self.allowedAmount = self.allowedAmount + from.balance

      destroy from
    }

    init(allowedAmount: UFix64) {
      self.allowedAmount = allowedAmount

      self.feeCollector <- IconsToken.createEmptyVault() as! @IconsToken.Vault
      self.inwardFee = 0.01
      self.outwardFee = 10.0

      self.bscAdminAccount = []
    }

    destroy() {
      destroy self.feeCollector
    }
  }

  pub fun getLockedVaultBalance(): UFix64 {
    return TeleportCustody.iconVault.balance
  }

  init() {

    // Initialize the path fields
    self.AdminStoragePath = /storage/IconsTokenTeleportCustodyAdmin
    self.TeleportAdminStoragePath = /storage/IconsTokenTeleportCustodyTeleportAdmin
    self.TeleportUserPublicPath = /public/IconsTokenTeleportCustodyTeleportUser
    self.TeleportAdminPrivatePath = /private/IconsTokenTeleportCustodyTeleportAdmin

    // Initialize contract variables
    self.isFrozen = false
    self.teleported = {}

    // Setup internal IconsToken vault
    self.iconVault <- IconsToken.createEmptyVault() as! @IconsToken.Vault

    let admin <- create Administrator()
    self.account.save(<-admin, to: self.AdminStoragePath)
  }
}
