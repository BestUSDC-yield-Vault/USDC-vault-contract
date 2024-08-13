// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";

import "../src/Vault.sol";

/**
 * @title VaultTest
 * @author Bhumi Sadariya
 * @dev Test suite for the Vault contract
 */
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
    address LENDING_POOL_EXTRAFI = vm.envAddress("LENDING_POOL_EXTRAFI");
    address LENDING_POOL_MOONWELL = vm.envAddress("LENDING_POOL_MOONWELL");
    address USER = vm.envAddress("USER");
    address USER2 = vm.envAddress("USER2");
    address USER3 = vm.envAddress("USER3");

    /**
     * @dev Sets up the testing environment
     */
    function setUp() public {
        token = IERC20(TOKEN);
        vault = new Vault(
            token,
            LENDING_POOL_AAVE,
            LENDING_POOL_SEAMLESS,
            LENDING_POOL_EXTRAFI,
            LENDING_POOL_MOONWELL
        );

        // console.log("Deployed Vault contract at: %s", address(vault));

        amount1 = 100 * 10 ** 6; // 100 USDC (6 decimals)
        amount2 = 500 * 10 ** 6; // 500 USDC (6 decimals)
        shares1 = 50 * 10 ** 6; // 100 USDC (6 decimals)
        shares2 = 500 * 10 ** 6; // 500 USDC (6 decimals)
    }

    function testVaultForAave() public {
        // user1 deposits 100 USDC
        vm.startPrank(USER);

        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
        );
        console.log(".............before USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount1, USER);
        console.log(".............after USER deposit 100 USDC.............");
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

        // user2 mints 500 shares
        vm.startPrank(USER2);
        deal(TOKEN, USER2, amount2);

        token.approve(address(vault), shares2);

        assertEq(
            token.allowance(USER2, address(vault)),
            shares2,
            "ALLOWANCE ERROR: testMint"
        );
        console.log(".............before USER2 mints 500 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares2, USER2);
        console.log(".............after USER2 mints 500 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER2), shares2, "SHARES ERROR: testMint");
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            vault.balanceOf(USER) + shares2,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();

        // user1 withdraws 20 USDC from 100 USDC deposited
        vm.startPrank(USER);

        uint256 withdrawAmount = 20000000; // 20 USDC
        uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(
            ".............before USER1 withdraw 20 USDC from 100 USDC deposited............."
        );
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        console.log(
            ".............after USER1 withdraw 20 USDC from 100 USDC deposited............."
        );
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(vault.balanceOf(USER), 80000000, "SHARES ERROR: testWithdraw");
        assertLe(
            token.balanceOf(USER),
            withdrawAmount,
            "USDC ERROR: testWithdraw"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            580000000,
            "ATOKEN ERROR: testWithdraw"
        );

        vm.stopPrank();

        //user1 mints 10 shares ---- available shares 80 + wants to mint 10 shares
        vm.startPrank(USER);

        uint256 shares = 10000000; // 10 shares
        token.approve(address(vault), shares);

        assertEq(
            token.allowance(USER, address(vault)),
            shares,
            "ALLOWANCE ERROR: testMint"
        );
        console.log(".............before USER mint 10 shares.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares, USER);

        console.log(".............after USER mint 10 shares.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER),
            shares + 80000000,
            "SHARES ERROR: testMint"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            shares + 580000000,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();

        // user2 wants to redeem all the shares
        vm.startPrank(USER2);
        console.log("maxRedeem(owner)", vault.maxRedeem(USER2));
        uint256 withdrawShares = 500000000;

        uint256 atokenOfVault = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(".............before user2 redeem 500 shares.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault", atokenOfVault);

        vault.redeem(withdrawShares, USER2, USER2);

        console.log(".............after user2 redeem 500 shares.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testRedeem");
        // assertGe(token.balanceOf(USER2), 500000000, "USDC ERROR: testRedeem");
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            90000000,
            "ATOKEN ERROR: testRedeem"
        );

        vm.stopPrank();
    }

    // testing for extrafi
    function testVaultForExtraFi() public {
        // user deposits 100 USDC
        vm.startPrank(USER);
        vault.setProtocol(Vault.Protocol.ExtraFi);

        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
        );
        console.log(".............before USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount1, USER);
        console.log(".............after USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1,
            "ATOKEN ERROR: testDeposit"
        );
        vm.stopPrank();

        // user 2 mints 50 shares
        vm.startPrank(USER2);

        deal(TOKEN, USER2, shares1);
        token.approve(address(vault), shares1);

        assertEq(
            token.allowance(USER2, address(vault)),
            shares1,
            "ALLOWANCE ERROR: testDepositUSER2"
        );
        console.log(".............before USER mint 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares1, USER2);

        console.log(
            ".............after USER deposit mint 50 shares............."
        );
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER2),
            shares1,
            "SHARES ERROR: testDepositUSER2"
        );
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1 + shares1,
            "ATOKEN ERROR: testDepositUSER2"
        );

        vm.stopPrank();

        // user 1 withdraws 30 USDC from 100 USDC
        vm.startPrank(USER);

        uint256 withdrawAmount = 30000000; // 30 USDC

        uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(".............before USER withdraw 30 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        console.log(".............after USER withdraw 30 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER),
            70000000,
            "SHARES ERROR: testDepositWithdraw"
        );
        assertLe(
            token.balanceOf(USER),
            30000000,
            "USDC ERROR: testDepositWithdraw"
        );
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            120000000,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();

        // user 2 withdraws full
        vm.startPrank(USER2);
        // uint w = vault.maxWithdraw(USER2);
        // console.log("maximum withdraw", w);
        uint256 withdrawAmount2 = shares1; // 70 USDC

        uint256 atokenVault2 = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(
            ".............before USER2 withdraw 50 shares............."
        );
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault", atokenVault2);

        vault.withdraw(withdrawAmount2, USER2, USER2);

        console.log(".............after USER2 withdraw 50 shares.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER2),
            0,
            "SHARES ERROR: testDepositWithdraw"
        );
        assertLe(
            token.balanceOf(USER2),
            shares1,
            "USDC ERROR: testDepositWithdraw"
        );
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            70000000,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();

        // user 1 redeem remaining 70 shares
        vm.startPrank(USER);
        uint w = vault.maxWithdraw(USER);
        console.log("maximum withdraw", w);
        uint256 withdrawAmount1 = 70000000; // 70 USDC

        uint256 atokenVault1 = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(".............before USER redeem 70 shares.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault1);

        vault.redeem(withdrawAmount1, USER, USER);

        console.log(".............after USER redeem 70 shares.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testDepositWithdraw");
        assertLe(
            token.balanceOf(USER),
            amount1,
            "USDC ERROR: testDepositWithdraw"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            0,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();
    }

    // testing for moonwell
    function testVaultForMoonwell() public {
        // user deposits 100 USDC
        vm.startPrank(USER);
        vault.setProtocol(Vault.Protocol.Moonwell);

        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
        );
        console.log(".............before USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount1, USER);
        console.log(".............after USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1,
            "ATOKEN ERROR: testDeposit"
        );
        vm.stopPrank();

        // user 2 mints 50 shares
        vm.startPrank(USER2);

        deal(TOKEN, USER2, shares1);
        token.approve(address(vault), shares1);

        assertEq(
            token.allowance(USER2, address(vault)),
            shares1,
            "ALLOWANCE ERROR: testDepositUSER2"
        );
        console.log(".............before USER mint 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares1, USER2);

        console.log(
            ".............after USER deposit mint 50 shares............."
        );
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Etoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER2),
            shares1,
            "SHARES ERROR: testDepositUSER2"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1 + shares1,
            "ATOKEN ERROR: testDepositUSER2"
        );

        vm.stopPrank();

        // user 1 withdraws 30 USDC from 100 USDC
        vm.startPrank(USER);

        uint256 withdrawAmount = 30000000; // 30 USDC

        uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(".............before USER withdraw 30 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("USDC balance of vault ", token.balanceOf(address(vault)));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        console.log(".............after USER withdraw 30 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("USDC balance of vault ", token.balanceOf(address(vault)));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER),
            70000000,
            "SHARES ERROR: testDepositWithdraw"
        );
        assertLe(
            token.balanceOf(USER),
            30000000,
            "USDC ERROR: testDepositWithdraw"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            120000000,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();

        // user 2 withdraws full
        vm.startPrank(USER2);
        // uint w = vault.maxWithdraw(USER2);
        // console.log("maximum withdraw", w);
        uint256 withdrawAmount2 = shares1; // 70 USDC

        uint256 atokenVault2 = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(
            ".............before USER2 withdraw 50 shares............."
        );
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault", atokenVault2);

        vault.withdraw(withdrawAmount2, USER2, USER2);

        console.log(".............after USER2 withdraw 50 shares.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(
            vault.balanceOf(USER2),
            0,
            "SHARES ERROR: testDepositWithdraw"
        );
        assertLe(
            token.balanceOf(USER2),
            shares1,
            "USDC ERROR: testDepositWithdraw"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            70000000,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();

        // user 1 redeem remaining 70 shares
        vm.startPrank(USER);
        uint w = vault.maxWithdraw(USER);
        console.log("maximum withdraw", w);
        uint256 withdrawAmount1 = 70000000; // 70 USDC

        uint256 atokenVault1 = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(".............before USER redeem 70 shares.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault1);

        vault.redeem(withdrawAmount1, USER, USER);

        console.log(".............after USER redeem 70 shares.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testDepositWithdraw");
        assertLe(
            token.balanceOf(USER),
            amount1,
            "USDC ERROR: testDepositWithdraw"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            0,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();
    }

    function testRebalancing() public {
        // user1 deposits 100 USDC
        vm.startPrank(USER);

        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
        );
        console.log(".............before USER deposit 100 USDC.............");
        console.log("USDC balance of user ", token.balanceOf(USER));
        console.log("Shares of user ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.deposit(amount1, USER);
        console.log(".............after USER deposit 100 USDC.............");
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

        // user2 mints 500 shares
        vm.startPrank(USER2);
        deal(TOKEN, USER2, amount2);

        token.approve(address(vault), shares2);

        assertEq(
            token.allowance(USER2, address(vault)),
            shares2,
            "ALLOWANCE ERROR: testMint"
        );
        console.log(".............before USER2 mints 500 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares2, USER2);
        console.log(".............after USER2 mints 500 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER2), shares2, "SHARES ERROR: testMint");
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            vault.balanceOf(USER) + shares2,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();

        // user1 withdraws 20 USDC from 100 USDC deposited
        vm.startPrank(USER);

        uint256 withdrawAmount = 20000000; // 20 USDC
        uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
            .balanceOf(address(vault));

        console.log(
            ".............before USER1 withdraw 20 USDC from 100 USDC deposited............."
        );
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        console.log(
            ".............after USER1 withdraw 20 USDC from 100 USDC deposited............."
        );
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(vault.balanceOf(USER), 80000000, "SHARES ERROR: testWithdraw");
        assertLe(
            token.balanceOf(USER),
            withdrawAmount,
            "USDC ERROR: testWithdraw"
        );
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            580000000,
            "ATOKEN ERROR: testWithdraw"
        );
        assertEq(
            uint(vault.currentProtocol()),
            uint(Vault.Protocol.Aave),
            "CURRENT PROTOCOL ERROR"
        );
        console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
        vm.stopPrank();

        // owner calls rebalance function - extrafi
        console.log("Before Rebalancing");
        console.log(
            "Current AToken of AAVE Balance",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        vault.rebalance(Vault.Protocol.ExtraFi);
        console.log("After Rebalancing");
        console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
        console.log(
            "Current EToken of ExtraFi Balance",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(
            uint(vault.currentProtocol()),
            uint(Vault.Protocol.ExtraFi),
            "CURRENT PROTOCOL ERROR"
        );

        // user2 withdraws 500 USDC
        vm.startPrank(USER2);

        console.log(".............before USER2 withdraw 500 USDC.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.withdraw(shares2, USER2, USER2);

        console.log(".............after USER2 withdraw 500 USDC.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testWithdraw");
        assertLe(token.balanceOf(USER2), shares2, "USDC ERROR: testWithdraw");
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            80000000,
            "ATOKEN ERROR: testWithdraw"
        );
        vm.stopPrank();

        // user2 mints 50 shares
        vm.startPrank(USER2);
        deal(TOKEN, USER2, shares1);

        token.approve(address(vault), shares1);

        assertEq(
            token.allowance(USER2, address(vault)),
            shares1,
            "ALLOWANCE ERROR: testMint"
        );
        console.log(".............before USER2 mints 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.mint(shares1, USER2);
        console.log(".............after USER2 mints 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        assertEq(vault.balanceOf(USER2), shares1, "SHARES ERROR: testMint");
        assertLe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            vault.balanceOf(USER) + shares1,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();

        // owner calls rebalance function - moonwell
        console.log("Before Rebalancing");
        console.log(
            "Current EToken of ExtraFi Balance",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        vault.rebalance(Vault.Protocol.Moonwell);
        console.log("After Rebalancing");
        console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
        console.log(
            "Current MToken of Moonwell Balance",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(
            uint(vault.currentProtocol()),
            uint(Vault.Protocol.Moonwell),
            "CURRENT PROTOCOL ERROR"
        );

        // user1 withdraws 80 USDC
        vm.startPrank(USER);

        uint256 withdrawAmount1 = 80000000; // 80 USDC

        console.log(".............before USER1 withdraw 80 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.redeem(withdrawAmount1, USER, USER);

        console.log(".............after USER1 withdraw 80 USDC.............");
        console.log("USDC balance of user", token.balanceOf(USER));
        console.log("Shares of user", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testWithdraw");
        assertLe(token.balanceOf(USER), amount1, "USDC ERROR: testWithdraw");
        assertGe(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            130000000,
            "ATOKEN ERROR: testWithdraw"
        );
        vm.stopPrank();

        // user2 withdraws 50 USDC
        vm.startPrank(USER2);

        console.log(".............before USER2 withdraw 50 USDC.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );

        vault.withdraw(shares1, USER2, USER2);

        console.log(".............after USER2 withdraw 50 USDC.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault",
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        );
        assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testWithdraw");
        assertLe(token.balanceOf(USER2), shares1, "USDC ERROR: testWithdraw");
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            0,
            "ATOKEN ERROR: testWithdraw"
        );
        vm.stopPrank();
    }
}
