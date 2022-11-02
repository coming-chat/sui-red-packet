// Copyright 2022 ComingChat Authors. Licensed under Apache-2.0 License.
#[test_only]
module 0x0::red_packet_tests {
    use sui::coin::mint_for_testing;
    use sui::sui::SUI;
    use sui::coin;
    use sui::test_scenario::{
        Self, Scenario, next_tx, end, ctx, take_from_sender, return_to_sender
    };

    use 0x0::red_packet::{
        init_for_testing, create, open, close, Config, RedPacketInfo
    };

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

            let config = test_scenario::take_shared<Config>(test);

            create(
                &mut config,
                &mut sui,
                1000,
                10000,
                ctx(test)
            );

            coin::destroy_for_testing(sui);
            test_scenario::return_shared(config);
        }
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
        }
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
        }
    }

    // utilities
    fun scenario(): Scenario { test_scenario::begin(@0x1) }
}
