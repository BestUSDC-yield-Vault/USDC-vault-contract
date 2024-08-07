// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/Vault.sol";

contract VaultTest is Test {
    Vault vault;
    IERC20 token;
    IERC20 atoken;
    uint256 amount1;
    uint256 amount2;
    uint256 amount3;

    // Mainnet fork configuration
    address TOKEN = vm.envAddress("USDC_ADDRESS");
    address LENDING_POOL_AAVE = vm.envAddress("LENDING_POOL_AAVE");
    address LENDING_POOL_SEAMLESS = vm.envAddress("LENDING_POOL_SEAMLESS");
    address USER = vm.envAddress("USER");
    address USER2 = vm.envAddress("USER2");
    address USER3 = vm.envAddress("USER3");

    function setUp() public {
        // contract instance
        token = IERC20(TOKEN);
        vault = new Vault(
            token,
            0,
            0,
            0,
            LENDING_POOL_AAVE,
            LENDING_POOL_SEAMLESS
        );

        // console.log("Deployed Vault contract at: %s", address(vault));

        // setting up supply/withdraw amount
        amount1 = 100000000; //100 USDC
        amount2 = 1000000000; //1000 USDC
        amount3 = 100000000; // 100 USDC
    }

    function testDeposit() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount1);

        token.approve(address(vault), amount1);
        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR"
        );
        console.log(".............before deposit.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount1, USER);
        console.log(".............after deposit.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER), amount1, "Not received enough funds");
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1,
            "Not received enough funds"
        );

        vm.stopPrank();
    }

    function testDepositUSER2() public {
        testDeposit();
        vm.startPrank(USER2);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER2, amount2);

        token.approve(address(vault), amount2);
        assertEq(
            token.allowance(USER2, address(vault)),
            amount2,
            "ALLOWANCE ERROR"
        );
        console.log(".............before deposit.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount2, USER2);
        console.log(".............after deposit.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER2), amount2, "Not received enough funds");
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1 + amount2,
            "Not received enough funds"
        );

        vm.stopPrank();
    }
}
