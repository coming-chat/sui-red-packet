# Sui Red Packet
Red packets implemented using the Move programming language

A red packet social application that combines the privacy chat on ComingChat and the omnichain wallet on ComingChat.

The code contract will be deployed to the Sui smart contract platform

### Supported dependencies
- sui-cli: `Sui devnet v0.14.0 @ 2a9ad74262554d2c753d6eaaa057d6612eab8678`

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
git checkout 2a9ad74262554d2c753d6eaaa057d6612eab8678

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
- `create`
```bash
# create 2 red-packets with total 10000
sui client call --gas-budget 1000 \
    --package 0x3c538a3e86908e866bb422e36adbde2f32a740b6 \
    --module red_packet \
    --function create \
    --type-args 0x2::sui::SUI \
    --args 0x7b1ad385b828bb9383d32739f7889baa27d35a42 \
         0x16c60433f56382aee1ea14eef1324474dd90bcf3 \
         2 \
         10000
```

- `open`
```bash
sui client call --gas-budget 1000 \ 
    --package 0x3c538a3e86908e866bb422e36adbde2f32a740b6 \
    --module red_packet \
    --function open \
    --type-args 0x2::sui::SUI \
    --args 0xee61854d42ca06451bad4e4cde31711b658b2ec7 \
          '["0x82d770bab2d607b919f2dcc45a7491ede65fe6db"]' \
          '[5000]'
```

- `close`
```bash
sui client call --gas-budget 1000 \
    --package 0x3c538a3e86908e866bb422e36adbde2f32a740b6 \
    --module red_packet \
    --function close \
    --type-args 0x2::sui::SUI \
    --args 0xee61854d42ca06451bad4e4cde31711b658b2ec7
```
