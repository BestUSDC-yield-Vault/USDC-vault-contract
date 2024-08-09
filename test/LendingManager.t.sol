// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "../src/LendingManager.sol";

/**
 * @title LendingManagerTest
 * @dev Test contract for LendingManager
 */
contract LendingManagerTest is Test {
    LendingManager lendingManager;
    IERC20 token;
    IERC20 atoken;
    IERC20 atokenSeamless;
    IERC20 etoken;
    IMToken mtoken;
    uint256 amount;
    uint128 aaveInterestRate;
    uint128 seamlessInterestRate;
    uint256 extrafiExchangeRate;
    uint128 extrafiInterestRate;
    uint256 moonwellInterestRate;
    uint256 moonwellExchangeRate;
    uint256 RESERVE_ID = 25; // Assuming 1 is the static reserve ID for ExtraFi

    // Mainnet fork configuration
    address LENDING_POOL_AAVE = vm.envAddress("LENDING_POOL_AAVE");
    address LENDING_POOL_SEAMLESS = vm.envAddress("LENDING_POOL_SEAMLESS");
    address LENDING_POOL_EXTRAFI = vm.envAddress("LENDING_POOL_EXTRAFI");
    address LENDING_POOL_MOONWELL = vm.envAddress("LENDING_POOL_MOONWELL");
    address USDC = vm.envAddress("USDC_ADDRESS");
    address USER = vm.envAddress("USER");

    function setUp() public {
        lendingManager = new LendingManager(USDC);
        token = IERC20(USDC);

        // Setup for AAVE
        address aTOKEN = lendingManager.getATokenAddress(LENDING_POOL_AAVE);
        atoken = IERC20(aTOKEN);
        aaveInterestRate = lendingManager.getInterestRate(LENDING_POOL_AAVE);
        // console.log("AAVE INTEREST RATE", aaveInterestRate);

        // Setup for Seamless
        address aTOKENSeamless = lendingManager.getATokenAddress(
            LENDING_POOL_SEAMLESS
        );
        atokenSeamless = IERC20(aTOKENSeamless);
        seamlessInterestRate = lendingManager.getInterestRate(
            LENDING_POOL_SEAMLESS
        );
        // console.log("SEAMLESS INTEREST RATE", seamlessInterestRate);

        // Setup for ExtraFi
        address eTOKEN = lendingManager.getATokenAddressOfExtraFi(
            RESERVE_ID,
            LENDING_POOL_EXTRAFI
        );
        etoken = IERC20(eTOKEN);
        extrafiExchangeRate = lendingManager.exchangeRateOfExtraFi(
            RESERVE_ID,
            LENDING_POOL_EXTRAFI
        );
        // console.log("ExtraFi EXCHANGE RATE", extrafiExchangeRate);

        // Setup for Moonwell
        mtoken = IMToken(LENDING_POOL_MOONWELL);
        moonwellInterestRate = lendingManager.getInterestRateOfMoonWell(
            LENDING_POOL_MOONWELL
        );
        moonwellExchangeRate = lendingManager.exchangeRateOfMoonWell(
            LENDING_POOL_MOONWELL
        );
        // console.log("Moonwell INTEREST RATE", moonwellInterestRate);
        console.log("Moonwell exchange RATE", moonwellExchangeRate);

        // setting up supply/withdraw amount
        amount = 100000000; // 100 USDC
    }

    // Tests for AAVE
    function testDepositToAave() public {
        vm.startPrank(USER);

        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        lendingManager.depositToLendingPool(
            amount,
            address(lendingManager),
            LENDING_POOL_AAVE
        );
        assertEq(
            atoken.balanceOf(address(lendingManager)),
            amount,
            "ATOKEN balance error"
        );
        vm.stopPrank();
    }

    function testWithdrawHalfFromAave() public {
        testDepositToAave();
        vm.startPrank(USER);

        uint256 usdcBalanceBefore = token.balanceOf(address(lendingManager));
        uint256 atokenBalanceBefore = atoken.balanceOf(address(lendingManager));
        uint256 amountToWithdraw = amount / 2; // 50 USDC

        lendingManager.withdrawFromLendingPool(
            amountToWithdraw,
            address(lendingManager),
            LENDING_POOL_AAVE
        );

        assertEq(
            token.balanceOf(address(lendingManager)),
            usdcBalanceBefore + amountToWithdraw,
            "USDC balance error on withdraw"
        );
        assertLe(
            atoken.balanceOf(address(lendingManager)),
            atokenBalanceBefore - amountToWithdraw,
            "ATOKEN balance error on withdraw"
        );

        vm.stopPrank();
    }

    function testWithdrawFullFromAave() public {
        testDepositToAave();
        vm.startPrank(USER);

        uint256 usdcBalanceBefore = token.balanceOf(address(lendingManager));
        uint256 atokenBalanceBefore = atoken.balanceOf(address(lendingManager));

        lendingManager.withdrawFromLendingPool(
            atokenBalanceBefore,
            address(lendingManager),
            LENDING_POOL_AAVE
        );
        assertEq(
            token.balanceOf(address(lendingManager)),
            usdcBalanceBefore + atokenBalanceBefore,
            "USDC balance error on withdraw"
        );
        assertEq(
            atoken.balanceOf(address(lendingManager)),
            0,
            "ATOKEN balance error on withdraw"
        );

        vm.stopPrank();
    }

    // Tests for Seamless
    function testDepositToSeamless() public {
        vm.startPrank(USER);

        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        lendingManager.depositToLendingPool(
            amount,
            address(lendingManager),
            LENDING_POOL_SEAMLESS
        );
        // console.log(
        //     "atoken seamless",
        //     atokenSeamless.balanceOf(address(lendingManager))
        // );
        assertEq(
            atokenSeamless.balanceOf(address(lendingManager)),
            amount,
            "ATOKEN balance error"
        );
        vm.stopPrank();
    }

    function testWithdrawHalfFromSeamless() public {
        testDepositToSeamless();
        vm.startPrank(USER);

        uint256 usdcBalanceBefore = token.balanceOf(address(lendingManager));
        uint256 atokenSeamlessBalanceBefore = atokenSeamless.balanceOf(
            address(lendingManager)
        );
        uint256 amountToWithdraw = amount / 2; // 50 USDC

        lendingManager.withdrawFromLendingPool(
            amountToWithdraw,
            address(lendingManager),
            LENDING_POOL_SEAMLESS
        );
        // console.log("usdc after", token.balanceOf(address(lendingManager)));
        // console.log(
        //     "ausdc after",
        //     atokenSeamless.balanceOf(address(lendingManager))
        // );
        assertEq(
            token.balanceOf(address(lendingManager)),
            usdcBalanceBefore + amountToWithdraw,
            "USDC balance error on withdraw"
        );
        assertGe(
            atokenSeamless.balanceOf(address(lendingManager)),
            atokenSeamlessBalanceBefore - amountToWithdraw,
            "ATOKEN balance error on withdraw"
        );

        vm.stopPrank();
    }

    // Tests for ExtraFi
    function testDepositToExtraFi() public {
        vm.startPrank(USER);

        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        uint256 eTokenBalanceBefore = etoken.balanceOf(address(lendingManager));
        // console.log(
        //     "user Etoken balance before deposit",
        //     etoken.balanceOf(address(lendingManager))
        // );

        lendingManager.depositToExtraFi(
            RESERVE_ID,
            amount,
            address(lendingManager),
            LENDING_POOL_EXTRAFI
        );

        // console.log(
        //     "user Etoken balance after deposit",
        //     etoken.balanceOf(address(lendingManager))
        // );
        assertLe(
            etoken.balanceOf(address(lendingManager)),
            eTokenBalanceBefore + amount,
            "ETOKEN balance error"
        );

        vm.stopPrank();
    }

    function testWithdrawHalfFromExtraFi() public {
        testDepositToExtraFi();
        vm.startPrank(USER);

        uint256 usdcBalanceBefore = token.balanceOf(USER);
        uint256 eTokenBalanceBefore = etoken.balanceOf(address(lendingManager));
        uint256 amountToWithdraw = amount / 2; // 50 USDC
        // console.log("user balance before withdraw...", token.balanceOf(USER));

        lendingManager.withdrawFromExtraFi(
            amountToWithdraw,
            USER,
            RESERVE_ID,
            LENDING_POOL_EXTRAFI
        );

        // console.log("user balance after withdraw...", token.balanceOf(USER));
        assertGe(
            usdcBalanceBefore +
                (amountToWithdraw * extrafiExchangeRate) /
                (10 ** 18),
            token.balanceOf(USER),
            "USDC balance error : withdraw"
        );
        // console.log("eTokenBalanceContract", eTokenBalanceContract);
        // console.log(
        //     "eTokenBalanceContract after withdraw",
        //     eTokenBalanceContract - amountToWithdraw
        // );
        assertEq(
            eTokenBalanceBefore - amountToWithdraw,
            etoken.balanceOf(address(lendingManager)),
            "ETOKEN balance error : withdraw"
        );
        vm.stopPrank();
    }

    function testWithdrawFullFromExtraFi() public {
        testDepositToExtraFi();
        vm.startPrank(USER);

        uint256 usdcBalanceBefore = token.balanceOf(USER);
        uint256 eTokenBalanceBefore = etoken.balanceOf(address(lendingManager));

        // console.log("user balance before withdraw", token.balanceOf(USER));

        lendingManager.withdrawFromExtraFi(
            eTokenBalanceBefore,
            USER,
            RESERVE_ID,
            LENDING_POOL_EXTRAFI
        );

        assertGe(
            usdcBalanceBefore +
                (eTokenBalanceBefore * extrafiExchangeRate) /
                (10 ** 18),
            token.balanceOf(USER),
            "USDC balance error : withdraw"
        );
        // console.log(
        //     "user balance after withdraw whole amount",
        //     token.balanceOf(USER)
        // );
        assertEq(
            etoken.balanceOf(address(lendingManager)),
            0,
            "ETOKEN balance error : withdraw"
        );

        vm.stopPrank();
    }

    // Tests for Moonwell
    function testDepositMoonwell() public {
        vm.startPrank(USER);

        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        console.log(
            "token balance of user before deposit... ",
            token.balanceOf(USER)
        );
        console.log(
            "mtoken balance of contract before deposit... ",
            mtoken.balanceOf(address(lendingManager))
        );

        // supply amount to Moonwell
        lendingManager.depositToMoonWell(amount, LENDING_POOL_MOONWELL);

        console.log(
            "token balance of user after deposit... ",
            token.balanceOf(USER)
        );
        console.log(
            "mtoken balance of contract after deposit... ",
            mtoken.balanceOf(address(lendingManager))
        );

        assertGe(
            mtoken.balanceOf(address(lendingManager)),
            amount,
            "MTOKEN balance error"
        );
        vm.stopPrank();
    }

    function testWithdrawHalfMoonwell() public {
        testDepositMoonwell();
        vm.startPrank(USER);
        uint256 usdcBalanceContract = token.balanceOf(address(lendingManager));
        uint256 amountToWithdraw = 50000000;

        console.log(
            "mtoken balance before withdraw",
            mtoken.balanceOf(address(lendingManager))
        );
        uint256 atokenAmount = (amountToWithdraw * (10 ** 18)) /
            moonwellExchangeRate;
        lendingManager.withdrawFromMoonWell(
            atokenAmount,
            // USER,
            LENDING_POOL_MOONWELL
        );

        console.log(
            "atoken amount from underlying token amount and it should be half of total",
            atokenAmount
        );
        console.log(
            "mtoken balance after withdraw",
            mtoken.balanceOf(address(lendingManager))
        );
        console.log(
            "usdc balance of contract after withdraw",
            token.balanceOf(address(lendingManager))
        );
        // need to understand this calculation
        assertGe(
            token.balanceOf(address(lendingManager)),
            usdcBalanceContract +
                (amountToWithdraw * moonwellExchangeRate) /
                (10 ** 18),
            "USDC balance error : withdraw"
        );

        assertGe(
            token.balanceOf(address(lendingManager)),
            amountToWithdraw,
            "USDC balance error : withdraw"
        );
        // this also
        assertGe(
            atokenAmount,
            mtoken.balanceOf(address(lendingManager)),
            "ETOKEN balance error : withdraw"
        );
        vm.stopPrank();
    }

    function testWithdrawFullMoonwell() public {
        testDepositMoonwell();
        vm.startPrank(USER);
        uint256 usdcBalanceContract = token.balanceOf(address(lendingManager));
        uint256 mTokenBalanceContract = mtoken.balanceOf(
            address(lendingManager)
        );
        uint256 amountToWithdraw = mTokenBalanceContract;
        console.log(
            "before withdraw contract balance is ",
            usdcBalanceContract
        );
        lendingManager.withdrawFromMoonWell(
            amountToWithdraw,
            // USER,
            LENDING_POOL_MOONWELL
        );
        console.log(
            "after withdraw contract balance is ",
            token.balanceOf(address(lendingManager))
        );
        assertGe(
            token.balanceOf(address(lendingManager)),
            usdcBalanceContract +
                (amountToWithdraw * moonwellExchangeRate) /
                (10 ** 18),
            "USDC balance error : withdraw"
        );

        assertEq(
            mtoken.balanceOf(address(lendingManager)),
            0,
            "MTOKEN balance error : withdraw"
        );
        vm.stopPrank();
    }
}
