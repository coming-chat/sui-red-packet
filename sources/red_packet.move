// Copyright 2022-2023 ComingChat Authors. Licensed under Apache-2.0 License.
module rp::red_packet {
    use std::ascii::into_bytes;
    use std::type_name::{get, into_string};
    use std::vector;

    use sui::bag::{Self, Bag};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, value, destroy_zero};
    use sui::event::emit;
    use sui::object::{Self, UID, ID};
    use sui::package;
    use sui::pay::join_vec;
    use sui::transfer;
    use sui::tx_context::{Self, TxContext, sender};

    const MAX_COUNT: u64 = 1000;
    const MIN_BALANCE: u64 = 10000;
    // 0.0001 SUI(decimals=9)
    const INIT_FEE_POINT: u8 = 250; // 2.5%

    const EREDPACKET_ACCOUNTS_BALANCES_MISMATCH: u64 = 1;
    const EREDPACKET_INSUFFICIENT_BALANCES: u64 = 2;
    const EREDPACKET_ACCOUNT_TOO_MANY: u64 = 3;
    const EREDPACKET_BALANCE_TOO_LITTLE: u64 = 4;
    const EREDPACKET_NO_PERMISSIONS: u64 = 5;

    const EVENT_TYPE_CREATE: u8 = 0;
    const EVENT_TYPE_OPEN: u8 = 1;
    const EVENT_TYPE_CLOASE: u8 = 2;

    struct Config has key {
        id: UID,
        admin: address,
        beneficiary: address,
        owner: address,
        count: u64,
        fees: Bag
    }

    struct RedPacketInfo<phantom CoinType> has key,store {
        id: UID,
        remain_coin: Balance<CoinType>,
        remain_count: u64,
        beneficiary: address
    }

    /// Event emitted when created/opened/closed a red packet.
    struct RedPacketEvent has copy, drop {
        id: ID,
        event_type: u8,
        remain_count: u64,
        remain_balance: u64
    }

    /// One-Time-Witness for the module.
    struct RED_PACKET has drop {}

    fun init(
        otw: RED_PACKET,
        ctx: &mut TxContext
    ) {
        transfer::share_object(Config {
            id: object::new(ctx),
            admin: @admin,
            beneficiary: @beneficiary,
            owner: tx_context::sender(ctx),
            count: 0,
            fees: bag::new(ctx)
        });

        // Claim the `Publisher` for the package!
        let publisher = package::claim(otw, ctx);

        transfer::public_transfer(publisher, sender(ctx));
    }

    public entry fun create<CoinType>(
        config: &mut Config,
        coins: vector<Coin<CoinType>>,
        count: u64,
        total_balance: u64,
        ctx: &mut TxContext
    ) {
        // 1. check args
        let merged_coin = vector::pop_back(&mut coins);
        join_vec(&mut merged_coin, coins);
        assert!(
            coin::value<CoinType>(&merged_coin) >= total_balance,
            EREDPACKET_INSUFFICIENT_BALANCES
        );
        assert!(
            total_balance >= MIN_BALANCE,
            EREDPACKET_BALANCE_TOO_LITTLE
        );
        assert!(
            count <= MAX_COUNT,
            EREDPACKET_ACCOUNT_TOO_MANY,
        );

        // 2. handle assets
        let (fee, escrow) = calculate_fee(total_balance, INIT_FEE_POINT);

        let fee_balance = coin::into_balance<CoinType>(
            coin::split<CoinType>(&mut merged_coin, fee, ctx)
        );
        let coin_name = into_bytes(into_string(get<CoinType>()));
        if (bag::contains(&config.fees, coin_name)) {
            let fee = bag::borrow_mut(&mut config.fees, coin_name);
            balance::join(fee, fee_balance);
        } else {
            bag::add(&mut config.fees, coin_name, fee_balance);
        };

        let escrow_balance = coin::into_balance<CoinType>(
            coin::split<CoinType>(&mut merged_coin, escrow, ctx)
        );

        // 3. transfer to admin
        let uid = object::new(ctx);
        let id = object::uid_to_inner(&uid);
        transfer::transfer(
            RedPacketInfo<CoinType> {
                id: uid,
                remain_coin: escrow_balance,
                remain_count: count,
                beneficiary: config.beneficiary,
            },
            config.admin
        );

        // 4. transfer remain to sender
        if (value(&merged_coin) > 0) {
            transfer::public_transfer(
                merged_coin,
                tx_context::sender(ctx)
            )
        } else {
            destroy_zero(merged_coin)
        };

        // 5. update count
        config.count = config.count + 1;

        // 6. emit event
        emit(
            RedPacketEvent {
                id,
                event_type: EVENT_TYPE_CREATE,
                remain_count: count,
                remain_balance: escrow,
            }
        )
    }

    public entry fun open<CoinType>(
        info: &mut RedPacketInfo<CoinType>,
        lucky_accounts: vector<address>,
        balances: vector<u64>,
        ctx: &mut TxContext
    ) {
        // 1. check args
        let accounts_len = vector::length(&lucky_accounts);
        let balances_len = vector::length(&balances);
        assert!(
            accounts_len == balances_len,
            EREDPACKET_ACCOUNTS_BALANCES_MISMATCH,
        );

        // 2. check red packet stats
        let total = 0u64;
        let i = 0u64;
        while (i < balances_len) {
            total = total + *vector::borrow(&balances, i);
            i = i + 1;
        };
        assert!(
            total <= balance::value<CoinType>(&info.remain_coin),
            EREDPACKET_INSUFFICIENT_BALANCES,
        );
        assert!(
            accounts_len <= info.remain_count,
            EREDPACKET_ACCOUNT_TOO_MANY
        );

        // 3. handle assets
        let i = 0u64;
        while (i < accounts_len) {
            let account = vector::borrow(&lucky_accounts, i);
            let balance = vector::borrow(&balances, i);

            transfer::public_transfer(
                coin::take(
                    &mut info.remain_coin,
                    *balance,
                    ctx
                ),
                *account
            );

            i = i + 1;
        };

        // 4. update red packet stats
        // update remain count
        info.remain_count = info.remain_count - accounts_len;

        // 5. emit event
        emit(
            RedPacketEvent {
                id: object::uid_to_inner(&info.id),
                event_type: EVENT_TYPE_OPEN,
                remain_count: info.remain_count,
                remain_balance: balance::value(&info.remain_coin),
            }
        )
    }

    public entry fun close<CoinType>(
        info: RedPacketInfo<CoinType>,
        ctx: &mut TxContext
    ) {
        let RedPacketInfo<CoinType> {
            id,
            remain_coin,
            remain_count,
            beneficiary
        } = info;

        let close_event = RedPacketEvent {
            id: object::uid_to_inner(&id),
            event_type: EVENT_TYPE_CLOASE,
            remain_count,
            remain_balance: balance::value(&remain_coin),
        };

        transfer::public_transfer(
            coin::from_balance(remain_coin, ctx),
            beneficiary
        );

        object::delete(id);

        emit(close_event)
    }

    public entry fun withdraw<CoinType>(
        config: &mut Config,
        ctx: &mut TxContext
    ) {
        let operator = tx_context::sender(ctx);
        assert!(
            operator == config.admin || operator == config.beneficiary || operator == @backup,
            EREDPACKET_NO_PERMISSIONS
        );

        let coin_name = into_bytes(into_string(get<CoinType>()));

        if (bag::contains(&config.fees, coin_name)) {
            let fee = bag::borrow_mut(&mut config.fees, coin_name);
            let fee_value = balance::value(fee);

            if (fee_value > 0) {
                let fee_coin = coin::from_balance<CoinType>(balance::split(fee, fee_value), ctx);

                transfer::public_transfer(
                    fee_coin,
                    config.beneficiary
                );
            }
        };
    }

    public fun calculate_fee(
        balance: u64,
        fee_point: u8,
    ): (u64, u64) {
        let fee = balance / 10000 * (fee_point as u64);

        // never overflow
        (fee, balance - fee)
    }

    #[test_only]
    public fun init_for_testing(
        ctx: &mut TxContext,
        admin: address,
        beneficiary: address
    ) {
        transfer::share_object(Config{
            id: object::new(ctx),
            admin,
            beneficiary,
            owner: tx_context::sender(ctx),
            count: 0,
            fees: bag::new(ctx)
        })
    }
}
