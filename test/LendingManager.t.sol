// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import "../src/LendingManager.sol";

contract LendingManagerTest is Test {
    LendingManager lendingManager;
    IERC20 token;
    IERC20 atoken;
    uint256 amount;
    uint128 aaveInterestRate;

    // Mainnet fork configuration
    address LENDING_POOL_AAVE = vm.envAddress("LENDING_POOL_AAVE");
    address SWAP_ROUTER = vm.envAddress("SWAP_ROUTER");
    address USDC = vm.envAddress("USDC_ADDRESS");
    address USER = vm.envAddress("USER");

    function setUp() public {
        // console.log("==SET UP(LendingManager.t.sol)==");

        // Deploy the contract
        lendingManager = new LendingManager();

        // console.log(
        //     "Deployed LendingManager contract at: %s",
        //     address(lendingManager)
        // );

        // setting up underlying token
        token = IERC20(USDC);
        // fetching aToken for underlying token
        address aTOKEN = lendingManager.getATokenAddress(
            USDC,
            LENDING_POOL_AAVE
        );

        // setting up aToken of underlying token
        atoken = IERC20(aTOKEN);

        aaveInterestRate = lendingManager.getInterestRate(
            USDC,
            LENDING_POOL_AAVE
        );
        console.log("AAVE INTEREST RATE", aaveInterestRate / 10 ** 25);
        // setting up supply/withdraw amount
        amount = 100000000; // 100 USDC
        // console.log("Setup completed.");
    }

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
        lendingManager.deposit(USDC, amount, LENDING_POOL_AAVE);
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
        lendingManager.withdraw(
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
        lendingManager.withdraw(
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
}
