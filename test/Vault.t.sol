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
    uint256 shares1;
    uint256 shares2;

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
        shares1 = 50000000; //50 USDC
        shares2 = 500000000; //500 USDC
    }

    function testDeposit() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount1);

        token.approve(address(vault), amount1);
        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
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

        assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1,
            "ATOKEN ERROR: testDeposit"
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
            "ALLOWANCE ERROR: testDepositUSER2"
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

        assertEq(
            vault.balanceOf(USER2),
            amount2,
            "SHARES ERROR: testDepositUSER2"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1 + amount2,
            "ATOKEN ERROR: testDepositUSER2"
        );

        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(USER);

        // deal amount of TOKENs to USER
        deal(TOKEN, USER, amount1);

        uint256 sharesToAssets = vault.previewMint(shares1);
        console.log("Shares To Assets", sharesToAssets);

        token.approve(address(vault), sharesToAssets);
        assertEq(
            token.allowance(USER, address(vault)),
            sharesToAssets,
            "ALLOWANCE ERROR: testMint"
        );
        console.log(".............before mint.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares1, USER);
        console.log(".............after deposit.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER),
            sharesToAssets,
            "SHARES ERROR: testMint"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            sharesToAssets,
            "ATOKEN ERROR: testMint"
        );

        vm.stopPrank();
    }
}
