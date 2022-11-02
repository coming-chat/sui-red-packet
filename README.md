# Sui Red Packet
Red packets implemented using the Move programming language

A red packet social application that combines the privacy chat on ComingChat and the omnichain wallet on ComingChat.

The code contract will be deployed to the Sui smart contract platform

### Supported dependencies
- sui-cli: `Sui devnet v0.13.3 @ d847e064ff06f77b1b8a0ae099298cf1344d3427`

### Roles and Calls
- `owner`: `publish`
- `admin`: `open`, `close`
- `user`: `create`
- `beneficiary`: receive all fee coins.

### Install
```bash
# sui-cli
Install Sui cli
https://docs.sui.io/build/install#install-sui-binaries

# sui-red-packet
git clone https://github.com/coming-chat/sui-red-packet.git
cd sui-red-packet

# sui
git clone https://github.com/MystenLabs/sui.git
cd sui
git checkout d847e064ff06f77b1b8a0ae099298cf1344d3427

# sui-red-packet tree

├── sui
├── build
├── LICENSE
├── Move.toml
├── README.md
└── sources
```

### Compile & Test & Publish
```bash
sui move build
sui move test
sui client publish --gas-budget 10000
```
