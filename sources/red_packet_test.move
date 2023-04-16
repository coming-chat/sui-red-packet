// Copyright 2022-2023 ComingChat Authors. Licensed under Apache-2.0 License.
#[test_only]
module 0x0::red_packet_tests {
    use std::option;

    use sui::coin::{Self, mint_for_testing, Coin, value};
    use sui::sui::SUI;
    use sui::test_scenario::{Scenario, next_tx, begin, end, ctx, take_from_sender, return_to_sender, take_shared, return_shared, most_recent_id_for_address};

    use 0x0::red_packet::{init_for_testing, create, open, close, Config, RedPacketInfo, withdraw};

    struct USDC has drop {}

    // Tests section
    #[test]
    fun test_create() {
        let scenario = scenario();
        test_create_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_open() {
        let scenario = scenario();
        test_open_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_close() {
        let scenario = scenario();
        test_close_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_withdraw() {
        let scenario = scenario();
        test_withdraw_(&mut scenario);
        end(scenario);
    }

    #[test]
    fun test_usdc_all() {
        let scenario = scenario();
        test_usdc_all_(&mut scenario);
        end(scenario);
    }

    fun test_create_(test: &mut Scenario) {
        let owner = @0x111;
        let user = @0x222;
        let admin = @0xaaa;
        let beneficiary = @0xbbb;

        next_tx(test, owner);
        {
            init_for_testing(ctx(test), admin, beneficiary)
        };

        next_tx(test, user);
        {
            let sui = mint_for_testing<SUI>(1000000, ctx(test));

            let config = take_shared<Config>(test);

            create(
                &mut config,
                vector<Coin<SUI>>[sui],
                1000,
                10000,
                ctx(test)
            );

            return_shared(config);
        };

        next_tx(test, user);
        {
            let remain_coins = take_from_sender<Coin<SUI>>(test);

            assert!(value(&remain_coins) == 1000000 - 10000, 1);

            return_to_sender(test, remain_coins)
        };
    }

    fun test_open_(test: &mut Scenario) {
        test_create_(test);

        let admin = @0xaaa;

        next_tx(test, admin);
        {
            let info = take_from_sender<RedPacketInfo<SUI>>(test);
            open(
                &mut info,
                vector<address>[@0x100, @0x200],
                vector<u64>[1000, 2000],
                ctx(test)
            );
            return_to_sender(test, info);
        };

        let beneficiary = @0xbbb;

        next_tx(test, beneficiary);
        {
            let id_opt = most_recent_id_for_address<Coin<SUI>>(beneficiary);
            assert!(option::is_none(&id_opt), 1);
        };
    }

    fun test_close_(test: &mut Scenario) {
        test_create_(test);

        test_open_(test);

        let admin = @0xaaa;

        next_tx(test, admin);
        {
            let info = take_from_sender<RedPacketInfo<SUI>>(test);
            close(
                info,
                ctx(test)
            );
        };

        let beneficiary = @0xbbb;

        next_tx(test, beneficiary);
        {
            let remain_coin = take_from_sender<Coin<SUI>>(test);

            assert!(coin::value(&remain_coin) == 6750, 2);

            return_to_sender(test, remain_coin);
        };
    }

    fun test_withdraw_(test: &mut Scenario) {
        test_create_(test);

        test_open_(test);

        test_close_(test);

        let beneficiary = @0xbbb;

        next_tx(test, beneficiary);
        {
            let config = take_shared<Config>(test);

            withdraw<SUI>(
                &mut config,
                ctx(test)
            );
            return_shared(config);
        };

        next_tx(test, beneficiary);
        {
            let fee_coin = take_from_sender<Coin<SUI>>(test);

            assert!(coin::value(&fee_coin) == 250, 3);

            return_to_sender(test, fee_coin);
        }
    }

    fun test_usdc_all_(test: &mut Scenario) {
        let owner = @0x111;
        let user = @0x222;
        let admin = @0xaaa;
        let beneficiary = @0xbbb;

        next_tx(test, owner);
        {
            init_for_testing(ctx(test), admin, beneficiary)
        };

        // create
        next_tx(test, user);
        {
            let usdc = mint_for_testing<USDC>(1000000, ctx(test));

            let config = take_shared<Config>(test);

            create(
                &mut config,
                vector<Coin<USDC>>[usdc],
                1000,
                10000,
                ctx(test)
            );

            return_shared(config);
        };

        // open
        next_tx(test, admin);
        {
            let info = take_from_sender<RedPacketInfo<USDC>>(test);
            open(
                &mut info,
                vector<address>[@0x100, @0x200],
                vector<u64>[1000, 2000],
                ctx(test)
            );
            return_to_sender(test, info);
        };

        // close
        next_tx(test, admin);
        {
            let info = take_from_sender<RedPacketInfo<USDC>>(test);
            close(
                info,
                ctx(test)
            );
        };

        // withdraw
        next_tx(test, beneficiary);
        {
            let config = take_shared<Config>(test);

            withdraw<USDC>(
                &mut config,
                ctx(test)
            );
            return_shared(config);
        };

        next_tx(test, beneficiary);
        {
            let fee_coin = take_from_sender<Coin<USDC>>(test);

            assert!(coin::value(&fee_coin) == 250, 3);

            return_to_sender(test, fee_coin);
        }
    }

    // utilities
    fun scenario(): Scenario { begin(@0x1) }
}
