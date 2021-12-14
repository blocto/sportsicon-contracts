# IconsToken Teleport Contracts
Cadence and Solidity contracts used in IconsToken Teleport

Flow Playground: https://play.onflow.org/8afc7ece-5e1c-4be1-a80d-1fdaa955c133?type=account&id=0

## Preparation
Get [Flow CLI](https://docs.onflow.org/flow-cli/install/) for development and deployment.

## Deployment
Deploy the updated contracts to Flow testnet with Flow CLI.
The accounts to deploy to are defined in `flow.json`
```sh
flow project deploy --network testnet --update
```

## Operation
### Setup Teleport Admin
```
# Create build folder
mkdir build

# Build the trasnaction
flow transactions build ./transactions/setupTeleportAdmin.cdc \
  --network testnet \
  --arg UFix64:1000000000.0 \
  --proposer 0xdbbf409d954a92ab \
  --proposer-key-index 0 \
  --authorizer 0xdbbf409d954a92ab \
  --authorizer 0x3fd8f94084b09274 \
  --payer 0x3fd8f94084b09274 \
  --gas-limit 1000 \
  -x payload \
  --save ./build/unsigned.rlp

# Sign with IconsToken TeleportCustody account
flow transactions sign ./build/unsigned.rlp \
  --signer icons-teleport-contract-testnet \
  --filter payload \
  --save ./build/signed-1.rlp

# Sign with IconsToken TeleportAdmin account
flow transactions sign ./build/signed-1.rlp \
  --signer icons-teleport-admin-testnet \
  --filter payload \
  --save ./build/signed-2.rlp

# Send signed transaction
flow transactions send-signed --network testnet ./build/signed-2.rlp
```

### Unlock
```
flow transactions send ./transactions/unlock.cdc \
  --network testnet \
  --arg UFix64:30.0 \
  --arg Address:0x03d1e02a48354e2b \
  --arg String:5251d54735bf01a20f03c44b9dd1f667373ab4da7a8c777ae2a178100e0ded80 \
  --arg String:7b01a77096696de1e019ea9a3c511dfbb88e4a5ec0267441c1e17477f3dfb8569b82a112b6a8a4a4f3075bee6bf1965791b3e04010c3830f3bdc4ecfdec9390e \
  --signer icons-teleport-admin-testnet \
  --gas-limit 1000
```

### Unlock
```
flow transactions send ./transactions/setupTeleportFees.cdc \
  --network testnet \
  --arg UFix64:0.5 \
  --arg UFix64:0.5 \
  --signer icons-teleport-admin-testnet \
  --gas-limit 1000
```
