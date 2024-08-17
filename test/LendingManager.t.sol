// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "../src/LendingManager.sol";

/**
 * @title LendingManagerTest
 * @dev Comprehensive test suite for the LendingManager contract
 * @notice This contract tests various lending protocols including AAVE, Seamless, ExtraFi, and Moonwell
 */
contract LendingManagerTest is Test {
    // Constants
    uint256 private constant DAY_IN_SECONDS = 86400;
    uint256 private constant FIVE_DAYS_IN_SECONDS = 5 * DAY_IN_SECONDS;
    uint256 private constant USDC_DECIMALS = 6;
    uint256 private constant AMOUNT = 1_000_000 * 10 ** USDC_DECIMALS; // 1 million USDC
    uint256 private constant TOLERANCE = 1e15; // 0.1% tolerance for floating-point comparisons
    uint256 private constant RESERVE_ID = 25; // ExtraFi reserve ID

    // Test contract variables
    LendingManager private lendingManager;
    IERC20 private token;
    IERC20 private extraToken;
    IERC20 private atoken;
    IERC20 private atokenSeamless;
    IERC20 private etoken;
    IMToken private mtoken;

    // Protocol-specific variables
    uint128 private aaveInterestRate;
    uint128 private seamlessInterestRate;
    uint256 private extrafiExchangeRate;
    uint256 private moonwellInterestRate;
    uint256 private moonwellExchangeRate;

    // Mainnet fork configuration
    address private LENDING_POOL_AAVE = vm.envAddress("LENDING_POOL_AAVE");
    address private LENDING_POOL_SEAMLESS =
        vm.envAddress("LENDING_POOL_SEAMLESS");
    address private LENDING_POOL_EXTRAFI =
        vm.envAddress("LENDING_POOL_EXTRAFI");
    address private LENDING_POOL_MOONWELL =
        vm.envAddress("LENDING_POOL_MOONWELL");
    address private STAKING_REWARD = vm.envAddress("STAKING_REWARD");
    address private EXTRA_ADDRESS = vm.envAddress("EXTRA_ADDRESS");
    address private USDC = vm.envAddress("USDC_ADDRESS");
    address private USER = vm.envAddress("USER");

    /**
     * @dev Sets up the test environment before each test
     */
    function setUp() public {
        lendingManager = new LendingManager(USDC);
        token = IERC20(USDC);
        extraToken = IERC20(EXTRA_ADDRESS);

        // Setup for AAVE
        atoken = IERC20(lendingManager.getATokenAddress(LENDING_POOL_AAVE));
        aaveInterestRate = lendingManager.getInterestRate(LENDING_POOL_AAVE);
        // console.log("AAVE INTEREST RATE", aaveInterestRate);

        // Setup for Seamless
        atokenSeamless = IERC20(
            lendingManager.getATokenAddress(LENDING_POOL_SEAMLESS)
        );
        seamlessInterestRate = lendingManager.getInterestRate(
            LENDING_POOL_SEAMLESS
        );
        // console.log("SEAMLESS INTEREST RATE", seamlessInterestRate);

        // Setup for ExtraFi
        etoken = IERC20(
            lendingManager.getATokenAddressOfExtraFi(
                RESERVE_ID,
                LENDING_POOL_EXTRAFI
            )
        );
        console.log("address", address(etoken));
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
        // console.log("Moonwell exchange RATE", moonwellExchangeRate);
        // Fund the USER account with USDC
        deal(USDC, USER, AMOUNT * 2);
    }

    /**
     * @dev Helper function to approve and deposit tokens to a lending pool
     * @param amount The amount of tokens to deposit
     * @param lendingPool The address of the lending pool
     */
    function approveAndDeposit(uint256 amount, address lendingPool) internal {
        vm.startPrank(USER);
        token.approve(address(lendingManager), amount);
        lendingManager.depositToLendingPool(
            amount,
            address(lendingManager),
            lendingPool
        );
        vm.stopPrank();
    }

    /**
     * @dev Helper function to withdraw tokens from a lending pool
     * @param amount The amount of tokens to withdraw
     * @param lendingPool The address of the lending pool
     */
    function withdraw(uint256 amount, address lendingPool) internal {
        vm.prank(USER);
        lendingManager.withdrawFromLendingPool(
            amount,
            address(lendingManager),
            lendingPool
        );
    }

    /**
     * @dev Test depositing and withdrawing from AAVE lending pool
     */
    function testDepositWithdrawAave() public {
        uint256 initialBalance = token.balanceOf(USER);
        approveAndDeposit(AMOUNT, LENDING_POOL_AAVE);

        assertGe(
            atoken.balanceOf(address(lendingManager)),
            AMOUNT,
            "Incorrect aToken balance after deposit"
        );
        assertEq(
            token.balanceOf(USER),
            initialBalance - AMOUNT,
            "Incorrect USDC balance after deposit"
        );

        // Simulate interest accrual
        vm.warp(block.timestamp + DAY_IN_SECONDS);

        uint256 balanceAfterOneDay = atoken.balanceOf(address(lendingManager));
        assertGt(
            balanceAfterOneDay,
            AMOUNT,
            "No interest accrued after one day"
        );

        // Withdraw half
        uint256 halfBalance = balanceAfterOneDay / 2;
        withdraw(halfBalance, LENDING_POOL_AAVE);

        assertApproxEqRel(
            atoken.balanceOf(address(lendingManager)),
            halfBalance,
            TOLERANCE,
            "Incorrect aToken balance after partial withdrawal"
        );

        // Withdraw remaining balance
        vm.warp(block.timestamp + FIVE_DAYS_IN_SECONDS);
        uint256 remainingBalance = atoken.balanceOf(address(lendingManager));

        // Ensure the aToken balance has increased due to further accrued interest
        assertGt(
            remainingBalance,
            halfBalance,
            "aToken balance should have increased due to additional interest accrual"
        );

        withdraw(remainingBalance, LENDING_POOL_AAVE);

        assertEq(
            atoken.balanceOf(address(lendingManager)),
            0,
            "aToken balance should be zero after full withdrawal"
        );
        assertGt(
            token.balanceOf(address(lendingManager)),
            AMOUNT,
            "Contract should have earned interest"
        );
    }

    /**
     * @dev Test depositing and withdrawing from Moonwell lending pool
     */
    function testDepositWithdrawMoonwell() public {
        uint256 initialBalance = token.balanceOf(USER);

        vm.startPrank(USER);
        token.approve(address(lendingManager), AMOUNT);
        lendingManager.depositToMoonWell(AMOUNT, LENDING_POOL_MOONWELL);
        vm.stopPrank();

        uint256 expectedMTokens = (AMOUNT * 1e18) / moonwellExchangeRate;

        assertApproxEqRel(
            mtoken.balanceOf(address(lendingManager)),
            expectedMTokens,
            TOLERANCE,
            "Incorrect mToken balance after deposit"
        );
        assertEq(
            token.balanceOf(USER),
            initialBalance - AMOUNT,
            "Incorrect USDC balance after deposit"
        );

        // Simulate interest accrual
        vm.warp(block.timestamp + DAY_IN_SECONDS);

        // Withdraw half
        uint256 halfBalance = mtoken.balanceOf(address(lendingManager)) / 2;
        vm.prank(USER);
        lendingManager.withdrawFromMoonWell(halfBalance, LENDING_POOL_MOONWELL);

        assertGe(
            token.balanceOf(address(lendingManager)),
            AMOUNT / 2,
            "Contract should have more than half USDC"
        );
        assertApproxEqRel(
            mtoken.balanceOf(address(lendingManager)),
            halfBalance,
            TOLERANCE,
            "Incorrect mToken balance after partial withdrawal"
        );

        // Simulate more interest accrual
        vm.warp(block.timestamp + FIVE_DAYS_IN_SECONDS);
        uint256 remainingBalance = mtoken.balanceOf(address(lendingManager));

        // Withdraw remaining balance
        vm.prank(USER);
        lendingManager.withdrawFromMoonWell(
            remainingBalance,
            LENDING_POOL_MOONWELL
        );

        assertEq(
            mtoken.balanceOf(address(lendingManager)),
            0,
            "mToken balance should be zero after full withdrawal"
        );
        assertGt(
            token.balanceOf(address(lendingManager)),
            AMOUNT,
            "Contract should have earned interest"
        );

        console.log("checking for rewards...");
        console.log(
            "WELL rewards before claim",
            IERC20(0xA88594D404727625A9437C3f886C7643872296AE).balanceOf(
                address(lendingManager)
            )
        );
        lendingManager.claimRewardFromMoonwell();
        console.log(
            "WELL rewards after claim",
            IERC20(0xA88594D404727625A9437C3f886C7643872296AE).balanceOf(
                address(lendingManager)
            )
        );
        assertGe(
            IERC20(0xA88594D404727625A9437C3f886C7643872296AE).balanceOf(
                address(lendingManager)
            ),
            0,
            "WELL rewards can be greater than or equals zero"
        );
    }

    function testDepositAndWithdrawExtraFi() public {
        // Initial deposit and stake
        uint256 etokenBeforeDeposit = etoken.balanceOf(STAKING_REWARD);
        console.log(
            "etoken balance in reward contract before deposit",
            etokenBeforeDeposit
        );

        vm.startPrank(USER);
        token.approve(address(lendingManager), AMOUNT);
        lendingManager.depositAndStakeToExtraFi(
            RESERVE_ID,
            AMOUNT,
            address(lendingManager),
            LENDING_POOL_EXTRAFI
        );
        vm.stopPrank();

        console.log(
            "eToken balance in reward contract after deposit:",
            etoken.balanceOf(STAKING_REWARD)
        );

        // Simulate time passing for potential interest accrual
        vm.warp(block.timestamp + DAY_IN_SECONDS);

        console.log("exchangeRate", extrafiExchangeRate);

        vm.startPrank(USER);
        uint256 eTokenBalanceAfterDay = etoken.balanceOf(STAKING_REWARD);
        console.log(
            "eToken amount in reward contract after 1 day:",
            eTokenBalanceAfterDay
        );

        // Calculate the eToken amount for withdrawal
        uint256 eTokenAmount = eTokenBalanceAfterDay - etokenBeforeDeposit;
        console.log(
            "increased etoken balance after deposit:",
            eTokenAmount - (AMOUNT * 1e18) / extrafiExchangeRate
        );
        console.log("Calculated eToken amount for withdrawal:", eTokenAmount);

        // Unstake and withdraw
        // eTokenBalanceAfterDay = etoken.balanceOf(STAKING_REWARD);
        console.log("eToken amount before withdraw:", eTokenBalanceAfterDay);

        console.log(
            "USDC balance of contract before withdraw",
            token.balanceOf(address(lendingManager))
        );

        lendingManager.unStakeAndWithdrawFromExtraFi(
            eTokenAmount,
            address(lendingManager),
            RESERVE_ID,
            LENDING_POOL_EXTRAFI
        );
        vm.stopPrank();

        console.log(
            "USDC amount after withdraw",
            token.balanceOf(address(lendingManager))
        );
        // Assertions
        assertGt(
            token.balanceOf(address(lendingManager)),
            AMOUNT,
            "User should have received their USDC back after withdrawal"
        );

        // Check that the eToken balance in the LendingManager contract decreased accordingly
        eTokenBalanceAfterDay = etoken.balanceOf(STAKING_REWARD);
        console.log("eToken amount after withdraw:", eTokenBalanceAfterDay);

        vm.warp(block.timestamp + FIVE_DAYS_IN_SECONDS);

        uint256 userRewardsClaimable = lendingManager.getRewardsForExtraFi(
            address(lendingManager),
            address(extraToken)
        );
        console.log("accured reward token balance: ", userRewardsClaimable);
        console.log(
            "extra token balance before claim",
            extraToken.balanceOf(address(lendingManager))
        );
        vm.startPrank(USER);
        lendingManager.claimRewardsFromExtraFi();
        vm.stopPrank();

        assertEq(
            userRewardsClaimable,
            extraToken.balanceOf(address(lendingManager)),
            "Extra token should be match with userRewardsClaimable amount of stakingReward contract."
        );

        assertEq(
            lendingManager.getRewardsForExtraFi(
                address(lendingManager),
                address(extraToken)
            ),
            0,
            "extra token should be 0 after claim all rewards."
        );

        console.log(
            "extra token balance after claim",
            extraToken.balanceOf(address(lendingManager))
        );

        console.log(
            "reward token balance after claim: ",
            lendingManager.getRewardsForExtraFi(
                address(lendingManager),
                address(extraToken)
            )
        );
    }

    // function testWithdrawHalfFromSeamless() public {
    //     testDepositToSeamless();
    //     vm.startPrank(USER);

    //     uint256 usdcBalanceBefore = token.balanceOf(address(lendingManager));
    //     uint256 atokenSeamlessBalanceBefore = atokenSeamless.balanceOf(
    //         address(lendingManager)
    //     );
    //     uint256 amountToWithdraw = amount / 2; // 50 USDC

    //     lendingManager.withdrawFromLendingPool(
    //         amountToWithdraw,
    //         address(lendingManager),
    //         LENDING_POOL_SEAMLESS
    //     );
    //     // console.log("usdc after", token.balanceOf(address(lendingManager)));
    //     // console.log(
    //     //     "ausdc after",
    //     //     atokenSeamless.balanceOf(address(lendingManager))
    //     // );
    //     assertEq(
    //         token.balanceOf(address(lendingManager)),
    //         usdcBalanceBefore + amountToWithdraw,
    //         "USDC balance error on withdraw"
    //     );
    //     assertGe(
    //         atokenSeamless.balanceOf(address(lendingManager)),
    //         atokenSeamlessBalanceBefore - amountToWithdraw,
    //         "ATOKEN balance error on withdraw"
    //     );

    //     vm.stopPrank();
    // }

    // // Tests for ExtraFi
    // function testDepositToExtraFi() public {
    //     vm.startPrank(USER);

    //     assertGt(
    //         token.balanceOf(USER),
    //         0,
    //         "USER does not hold the underlying token"
    //     );

    //     token.approve(address(lendingManager), amount);
    //     assertGe(
    //         token.allowance(USER, address(lendingManager)),
    //         amount,
    //         "Allowance should be equal to the approved amount"
    //     );

    //     uint256 eTokenBalanceBefore = etoken.balanceOf(address(lendingManager));
    //     // console.log(
    //     //     "user Etoken balance before deposit",
    //     //     etoken.balanceOf(address(lendingManager))
    //     // );

    //     lendingManager.depositToExtraFi(
    //         RESERVE_ID,
    //         amount,
    //         address(lendingManager),
    //         LENDING_POOL_EXTRAFI
    //     );

    //     // console.log(
    //     //     "user Etoken balance after deposit",
    //     //     etoken.balanceOf(address(lendingManager))
    //     // );
    //     assertLe(
    //         etoken.balanceOf(address(lendingManager)),
    //         eTokenBalanceBefore + amount,
    //         "ETOKEN balance error"
    //     );

    //     vm.stopPrank();
    // }
}
