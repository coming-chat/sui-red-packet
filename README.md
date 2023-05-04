# Sui Red Packet

Red packets implemented using the Move programming language

A red packet social application that combines the privacy chat on ComingChat and the omnichain wallet on ComingChat.

The code contract will be deployed to the Sui smart contract platform

### Supported dependencies

- sui-cli: `Sui mainnet @ ae1212baf8f0837e25926d941db3d26a61c1bea2`

package=0xf5244fdbeae35291fd829d5dd13cf8ce596c986ca1373687600808ee6d7c0241
config=0x1029909aa0c52524de0ce602cc80b52a17c3962b07fac67f982e6388c72be2e7
upgradeCap=0x1eab4733097767eb1fcb45b6b87883a323db885aefcb785fd49ff32427fdcbaa
publisher=0xd783bda9b895e1cd36a194dc7c66a73c78662f6d2a260384eec140d6c6782808
deployer=0x790059d92b3e1a6247a1363cb998efa01842181d4a85af6dda26718bce7266c5

### Roles and Calls

- `owner`: `publish`
- `admin`: `open`, `close`, `withdraw`
- `user`: `create`
- `beneficiary`: `withdraw`, receive all fee coins.

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
git checkout 83de679c8ad35bada725b66f2eb3293d6aac4b60

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
         '["0x16c60433f56382aee1ea14eef1324474dd90bcf3"]' \
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

- `withdraw`

```bash
sui client call --gas-budget 1000 \
    --package 0x3c538a3e86908e866bb422e36adbde2f32a740b6 \
    --module red_packet \
    --function withdraw \
    --type-args 0x2::sui::SUI \
    --args 0x7b1ad385b828bb9383d32739f7889baa27d35a42 \
    --type-args 0x2::sui::SUI
```