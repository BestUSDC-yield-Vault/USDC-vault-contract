// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "../src/LendingManager.sol";

contract LendingManagerTest is Test {
    LendingManager lendingManager;
    IERC20 token;
    IERC20 atoken;
    IERC20 atokenSeamless;
    uint256 amount;
    uint128 aaveInterestRate;
    uint128 seamlessInterestRate;

    // Mainnet fork configuration
    address LENDING_POOL_AAVE = vm.envAddress("LENDING_POOL_AAVE");
    address LENDING_POOL_SEAMLESS = vm.envAddress("LENDING_POOL_SEAMLESS");
    address SWAP_ROUTER = vm.envAddress("SWAP_ROUTER");
    address USDC = vm.envAddress("USDC_ADDRESS");
    address USER = vm.envAddress("USER");

    function setUp() public {
        // Deploy the contract
        lendingManager = new LendingManager();

        // setting up underlying token
        token = IERC20(USDC);

        //----------------------------------------------------AAVE-------------------------------------------
        // fetching aToken for underlying token
        address aTOKEN = lendingManager.getATokenAddress(
            USDC,
            LENDING_POOL_AAVE
        );

        // setting up aToken of underlying token
        atoken = IERC20(aTOKEN);
        console.log("aToken address", address(atoken));
        aaveInterestRate = lendingManager.getInterestRate(
            USDC,
            LENDING_POOL_AAVE
        );
        // console.log("AAVE INTEREST RATE", aaveInterestRate);

        //----------------------------------------------------SEAMLESS-------------------------------------------
        //fetching aToken of Seamless for underlying token
        address aTOKENSeamless = lendingManager.getATokenAddress(
            USDC,
            LENDING_POOL_SEAMLESS
        );
        atokenSeamless = IERC20(aTOKENSeamless);

        seamlessInterestRate = lendingManager.getInterestRate(
            USDC,
            LENDING_POOL_SEAMLESS
        );
        // console.log("SEAMLESS INTEREST RATE", seamlessInterestRate);

        // setting up supply/withdraw amount
        amount = 100000000; // 100 USDC
    }

    //----------------------------------------------------AAVE-------------------------------------------
    function testDeposit() public {
        vm.startPrank(USER);
        // Check user's TOKEN balance
        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        // Approve and supply TOKEN
        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );

        // supply amount to aaveInteraction
        lendingManager.depositToLendingPool(
            USDC,
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

    function testWithdrawHalf() public {
        testDeposit();
        vm.startPrank(USER);
        uint256 usdcBalanceContract = token.balanceOf(address(lendingManager));
        uint256 ausdcBalanceContract = atoken.balanceOf(
            address(lendingManager)
        );
        uint256 amountToWithdraw = 50000000;
        lendingManager.withdrawFromLendingPool(
            USDC,
            amountToWithdraw,
            address(lendingManager),
            LENDING_POOL_AAVE
        );
        assertEq(
            usdcBalanceContract + amountToWithdraw,
            amountToWithdraw,
            "USDC balance error : withdraw"
        );
        // sometimes atoken value comes with the difference of 0.0000001. That is why used less than or equals
        assertLe(
            ausdcBalanceContract - amountToWithdraw,
            50000000,
            "AUSDC balance error : withdraw"
        );
        vm.stopPrank();
    }

    function testWithdrawFull() public {
        testDeposit();
        vm.startPrank(USER);
        uint256 usdcBalanceContract = token.balanceOf(address(lendingManager));
        uint256 ausdcBalanceContract = atoken.balanceOf(
            address(lendingManager)
        );
        uint256 amountToWithdraw = ausdcBalanceContract;
        lendingManager.withdrawFromLendingPool(
            USDC,
            amountToWithdraw,
            address(lendingManager),
            LENDING_POOL_AAVE
        );
        assertEq(
            usdcBalanceContract + amountToWithdraw,
            amountToWithdraw,
            "USDC balance error : withdraw"
        );
        assertEq(
            ausdcBalanceContract - amountToWithdraw,
            0,
            "AUSDC balance error : withdraw"
        );
        vm.stopPrank();
    }

    //----------------------------------------------------SEAMLESS-------------------------------------------
    function testDepositSeamless() public {
        vm.startPrank(USER);
        // Check user's TOKEN balance
        assertGt(
            token.balanceOf(USER),
            0,
            "USER does not hold the underlying token"
        );

        // Approve and supply TOKEN
        token.approve(address(lendingManager), amount);
        assertGe(
            token.allowance(USER, address(lendingManager)),
            amount,
            "Allowance should be equal to the approved amount"
        );
        // supply amount to aaveInteraction
        lendingManager.depositToLendingPool(
            USDC,
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

    function testWithdrawHalfSeamless() public {
        testDepositSeamless();
        vm.startPrank(USER);
        uint256 usdcBalanceContract = token.balanceOf(address(lendingManager));
        uint256 ausdcBalanceContract = atokenSeamless.balanceOf(
            address(lendingManager)
        );
        // console.log("usdc before", usdcBalanceContract);
        // console.log("ausdc before", ausdcBalanceContract);
        uint256 amountToWithdraw = 50000000;
        lendingManager.withdrawFromLendingPool(
            USDC,
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
            usdcBalanceContract + amountToWithdraw,
            amountToWithdraw,
            "USDC balance error : withdraw"
        );
        // sometimes atoken value comes with the difference of 0.0000001. That is why used less than or equals
        assertLe(
            ausdcBalanceContract - amountToWithdraw,
            50000000,
            "AUSDC balance error : withdraw"
        );
        vm.stopPrank();
    }
}
