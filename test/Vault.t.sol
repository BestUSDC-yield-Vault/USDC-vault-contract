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
    uint256 private constant DAY_IN_SECONDS = 86400;

    Vault private vault;
    IERC20 private token;
    IERC20 private aToken;

    uint256 amount1 = 100 * 10 ** 6; // 100 USDC (6 decimals)
    uint256 amount2 = 500 * 10 ** 6; // 500 USDC (6 decimals)
    uint256 amount3 = 50 * 10 ** 6; // 50 USDC (6 decimals)
    uint256 shares1 = 50 * 10 ** 6; // 50 USDC (6 decimals)
    uint256 shares2 = 500 * 10 ** 6; // 500 USDC (6 decimals)

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
    }

    function testVaultForAave() public {
        // user1 deposits 100 USDC
        vm.startPrank(USER);

        // Fund USER with USDC and approve the vault
        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        // Check allowance before deposit
        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR"
        );

        console.log(".............before USER deposit 100 USDC.............");
        console.log("USDC balance of USER ", token.balanceOf(USER));
        console.log("Shares of USER ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            vault.getCurrentAtokenBalance()
        );

        vault.deposit(amount1, USER);

        console.log(".............after USER deposit 100 USDC.............");
        console.log("USDC balance of USER ", token.balanceOf(USER));
        console.log("Shares of USER ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            vault.getCurrentAtokenBalance()
        );

        assertEq(
            vault.balanceOf(USER),
            amount1,
            "Incorrect shares after deposit"
        );
        assertGe(
            vault.getCurrentAtokenBalance(),
            amount1,
            "aToken balance less than expected after deposit"
        );
        vm.stopPrank();

        vm.warp(block.timestamp + DAY_IN_SECONDS);

        // user2 mints 50 shares
        vm.startPrank(USER2);

        deal(TOKEN, USER2, amount2);
        token.approve(address(vault), amount2);

        assertEq(
            token.allowance(USER2, address(vault)),
            amount2,
            "ALLOWANCE ERROR"
        );

        uint256 aTokenBalanceBefore = vault.getCurrentAtokenBalance();

        console.log(".............before USER2 mints 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault ", aTokenBalanceBefore);

        uint256 requiredAssets = vault.previewMint(shares1);
        console.log("preview mint", requiredAssets);
        vault.mint(shares1, USER2);

        console.log(".............after USER2 mints 50 shares.............");
        console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        console.log("Shares of USER2 ", vault.balanceOf(USER2));
        console.log(
            "Atoken balance of Vault ",
            vault.getCurrentAtokenBalance()
        );

        assertEq(
            token.balanceOf(USER2),
            amount2 - requiredAssets,
            "Incorrect USDC balance after minting"
        );
        assertEq(
            vault.balanceOf(USER2),
            shares1,
            "Incorrect shares after minting"
        );
        assertEq(
            vault.getCurrentAtokenBalance(),
            aTokenBalanceBefore + requiredAssets,
            "aToken balance less than expected after minting"
        );
        vm.stopPrank();

        vm.warp(block.timestamp + DAY_IN_SECONDS);

        // user1 deposits 50 USDC
        vm.startPrank(USER);

        deal(TOKEN, USER, amount3);
        token.approve(address(vault), amount3);

        assertEq(
            token.allowance(USER, address(vault)),
            amount3,
            "ALLOWANCE ERROR"
        );

        uint256 userSharesBefore = vault.balanceOf(USER);
        aTokenBalanceBefore = vault.getCurrentAtokenBalance();

        console.log(".............before USER deposit 50 USDC.............");
        console.log("USDC balance of USER ", token.balanceOf(USER));
        console.log("Shares of USER ", userSharesBefore);
        console.log("Atoken balance of Vault ", aTokenBalanceBefore);

        uint256 shares = vault.previewDeposit(amount3);
        console.log("Shares will be minted", shares);
        vault.deposit(amount3, USER);

        console.log(".............after USER deposit 50 USDC.............");
        console.log("USDC balance of USER ", token.balanceOf(USER));
        console.log("Shares of USER ", vault.balanceOf(USER));
        console.log(
            "Atoken balance of Vault ",
            vault.getCurrentAtokenBalance()
        );

        assertEq(
            vault.balanceOf(USER),
            userSharesBefore + shares,
            "Incorrect shares after deposit"
        );
        assertGe(
            vault.getCurrentAtokenBalance(),
            aTokenBalanceBefore + amount3,
            "aToken balance less than expected after deposit"
        );
        vm.stopPrank();

        // user1 withdraws 20 USDC from 150 USDC deposited
        vm.startPrank(USER);

        uint256 withdrawAmount = 20 * 10 ** 6; // 20 USDC
        uint256 userUSDCBalance = token.balanceOf(USER);
        uint256 totalSupplyBefore = vault.totalSupply();
        aTokenBalanceBefore = vault.getCurrentAtokenBalance();
        userSharesBefore = vault.balanceOf(USER);

        console.log(
            ".............before USER withdraw 20 USDC from 150 USDC deposited............."
        );
        console.log("USDC balance of USER", userUSDCBalance);
        console.log("Shares of USER", userSharesBefore);
        console.log("Atoken balance of Vault", aTokenBalanceBefore);

        uint256 assetsToBurn = vault.previewWithdraw(withdrawAmount);
        console.log("Asstes to burn", assetsToBurn);
        vault.withdraw(withdrawAmount, USER, USER);

        console.log(
            ".............after USER withdraw 20 USDC from 100 USDC deposited............."
        );
        console.log("USDC balance of USER", token.balanceOf(USER));
        console.log("Shares of USER", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", vault.getCurrentAtokenBalance());

        assertEq(
            vault.balanceOf(USER),
            userSharesBefore - assetsToBurn,
            "SHARES ERROR: testWithdraw"
        );
        assertEq(
            token.balanceOf(USER),
            userUSDCBalance + withdrawAmount,
            "USDC ERROR: testWithdraw"
        );
        assertApproxEqAbs(
            vault.getCurrentAtokenBalance(),
            aTokenBalanceBefore -
                ((assetsToBurn * aTokenBalanceBefore) / totalSupplyBefore),
            1,
            "ATOKEN ERROR: testWithdraw"
        );

        vm.stopPrank();

        vm.warp(block.timestamp + DAY_IN_SECONDS);

        // user2 wants to redeem all the shares
        vm.startPrank(USER2);

        console.log("maxRedeem(owner)", vault.maxRedeem(USER2));
        uint256 withdrawShares = 50 * 10 ** 6;

        aTokenBalanceBefore = vault.getCurrentAtokenBalance();
        userUSDCBalance = token.balanceOf(USER2);
        totalSupplyBefore = vault.totalSupply();

        console.log(".............before user2 redeem 50 shares.............");
        console.log("USDC balance of USER2", userUSDCBalance);
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault", aTokenBalanceBefore);

        uint256 assetWillBe = vault.previewRedeem(withdrawShares);
        console.log("Assets will be", assetWillBe);
        vault.redeem(withdrawShares, USER2, USER2);

        console.log(".............after user2 redeem 50 shares.............");
        console.log("USDC balance of USER2", token.balanceOf(USER2));
        console.log("Shares of USER2", vault.balanceOf(USER2));
        console.log("Atoken balance of Vault", vault.getCurrentAtokenBalance());

        assertEq(
            token.balanceOf(USER2),
            userUSDCBalance + assetWillBe,
            "USDC ERROR: testWithdraw"
        );
        assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testRedeem");
        assertApproxEqAbs(
            vault.getCurrentAtokenBalance(),
            aTokenBalanceBefore -
                ((withdrawShares * aTokenBalanceBefore) / totalSupplyBefore),
            1,
            "ATOKEN ERROR: testWithdraw"
        );

        vm.stopPrank();

        // user wants to redeem all the shares
        vm.startPrank(USER);

        withdrawShares = vault.maxRedeem(USER);
        aTokenBalanceBefore = vault.getCurrentAtokenBalance();
        userUSDCBalance = token.balanceOf(USER);
        totalSupplyBefore = vault.totalSupply();

        console.log("maxRedeem(owner)", withdrawShares);
        console.log(".............before USER redeem 50 shares.............");
        console.log("USDC balance of USER", userUSDCBalance);
        console.log("Shares of USER", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", aTokenBalanceBefore);

        assetWillBe = vault.previewRedeem(withdrawShares);
        console.log("Assets will be", assetWillBe);
        vault.redeem(withdrawShares, USER, USER);

        console.log(".............after USER redeem 50 shares.............");
        console.log("USDC balance of USER", token.balanceOf(USER));
        console.log("Shares of USER", vault.balanceOf(USER));
        console.log("Atoken balance of Vault", vault.getCurrentAtokenBalance());

        assertApproxEqAbs(
            token.balanceOf(USER),
            userUSDCBalance + assetWillBe,
            1,
            "USDC ERROR: testWithdraw"
        );
        assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testRedeem");
        assertApproxEqAbs(
            vault.getCurrentAtokenBalance(),
            aTokenBalanceBefore -
                ((withdrawShares * aTokenBalanceBefore) / totalSupplyBefore),
            1,
            "ATOKEN ERROR: testWithdraw"
        );

        vm.stopPrank();
    }

    // testing for moonwell
    // function testVaultForMoonwell() public {
    //     // user deposits 100 USDC
    //     vm.startPrank(USER);
    //     vault.setProtocol(Vault.Protocol.Moonwell);

    //     deal(TOKEN, USER, amount1);
    //     token.approve(address(vault), amount1);

    //     assertEq(
    //         token.allowance(USER, address(vault)),
    //         amount1,
    //         "ALLOWANCE ERROR: testDeposit"
    //     );
    //     console.log(".............before USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.deposit(amount1, USER);
    //     console.log(".............after USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         amount1,
    //         "ATOKEN ERROR: testDeposit"
    //     );
    //     vm.stopPrank();

    //     // user 2 mints 50 shares
    //     vm.startPrank(USER2);

    //     deal(TOKEN, USER2, shares1);
    //     token.approve(address(vault), shares1);

    //     assertEq(
    //         token.allowance(USER2, address(vault)),
    //         shares1,
    //         "ALLOWANCE ERROR: testDepositUSER2"
    //     );
    //     console.log(".............before USER mint 50 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.mint(shares1, USER2);

    //     console.log(
    //         ".............after USER deposit mint 50 shares............."
    //     );
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER2),
    //         shares1,
    //         "SHARES ERROR: testDepositUSER2"
    //     );
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         amount1 + shares1,
    //         "ATOKEN ERROR: testDepositUSER2"
    //     );

    //     vm.stopPrank();

    //     // user 1 withdraws 30 USDC from 100 USDC
    //     vm.startPrank(USER);

    //     uint256 withdrawAmount = 30000000; // 30 USDC

    //     uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(".............before USER withdraw 30 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("USDC balance of vault ", token.balanceOf(address(vault)));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log("Atoken balance of Vault", atokenVault);

    //     vault.withdraw(withdrawAmount, USER, USER);

    //     console.log(".............after USER withdraw 30 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("USDC balance of vault ", token.balanceOf(address(vault)));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER),
    //         70000000,
    //         "SHARES ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         token.balanceOf(USER),
    //         30000000,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         120000000,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();

    //     // user 2 withdraws full
    //     vm.startPrank(USER2);
    //     // uint w = vault.maxWithdraw(USER2);
    //     // console.log("maximum withdraw", w);
    //     uint256 withdrawAmount2 = shares1; // 70 USDC

    //     uint256 atokenVault2 = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(
    //         ".............before USER2 withdraw 50 shares............."
    //     );
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log("Atoken balance of Vault", atokenVault2);

    //     vault.withdraw(withdrawAmount2, USER2, USER2);

    //     console.log(".............after USER2 withdraw 50 shares.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER2),
    //         0,
    //         "SHARES ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         token.balanceOf(USER2),
    //         shares1,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         70000000,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();

    //     // user 1 redeem remaining 70 shares
    //     vm.startPrank(USER);
    //     uint w = vault.maxWithdraw(USER);
    //     console.log("maximum withdraw", w);
    //     uint256 withdrawAmount1 = 70000000; // 70 USDC

    //     uint256 atokenVault1 = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(".............before USER redeem 70 shares.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log("Atoken balance of Vault", atokenVault1);

    //     vault.redeem(withdrawAmount1, USER, USER);

    //     console.log(".............after USER redeem 70 shares.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testDepositWithdraw");
    //     assertLe(
    //         token.balanceOf(USER),
    //         amount1,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertEq(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         0,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();
    // }

    // testing for extrafi
    // function testVaultForExtraFi() public {
    //     // user deposits 100 USDC
    //     vm.startPrank(USER);
    //     vault.setProtocol(Vault.Protocol.ExtraFi);

    //     deal(TOKEN, USER, amount1);
    //     token.approve(address(vault), amount1);

    //     assertEq(
    //         token.allowance(USER, address(vault)),
    //         amount1,
    //         "ALLOWANCE ERROR: testDeposit"
    //     );
    //     console.log(".............before USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.deposit(amount1, USER);
    //     console.log(".............after USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         amount1,
    //         "ATOKEN ERROR: testDeposit"
    //     );
    //     vm.stopPrank();

    //     // user 2 mints 50 shares
    //     vm.startPrank(USER2);

    //     deal(TOKEN, USER2, shares1);
    //     token.approve(address(vault), shares1);

    //     assertEq(
    //         token.allowance(USER2, address(vault)),
    //         shares1,
    //         "ALLOWANCE ERROR: testDepositUSER2"
    //     );
    //     console.log(".............before USER mint 50 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.mint(shares1, USER2);

    //     console.log(
    //         ".............after USER deposit mint 50 shares............."
    //     );
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Etoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER2),
    //         shares1,
    //         "SHARES ERROR: testDepositUSER2"
    //     );
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         amount1 + shares1,
    //         "ATOKEN ERROR: testDepositUSER2"
    //     );

    //     vm.stopPrank();

    //     // user 1 withdraws 30 USDC from 100 USDC
    //     vm.startPrank(USER);

    //     uint256 withdrawAmount = 30000000; // 30 USDC

    //     uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(".............before USER withdraw 30 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log("Atoken balance of Vault", atokenVault);

    //     vault.withdraw(withdrawAmount, USER, USER);

    //     console.log(".............after USER withdraw 30 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER),
    //         70000000,
    //         "SHARES ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         token.balanceOf(USER),
    //         30000000,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         120000000,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();

    //     // user 2 withdraws full
    //     vm.startPrank(USER2);
    //     // uint w = vault.maxWithdraw(USER2);
    //     // console.log("maximum withdraw", w);
    //     uint256 withdrawAmount2 = shares1; // 70 USDC

    //     uint256 atokenVault2 = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(
    //         ".............before USER2 withdraw 50 shares............."
    //     );
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log("Atoken balance of Vault", atokenVault2);

    //     vault.withdraw(withdrawAmount2, USER2, USER2);

    //     console.log(".............after USER2 withdraw 50 shares.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(
    //         vault.balanceOf(USER2),
    //         0,
    //         "SHARES ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         token.balanceOf(USER2),
    //         shares1,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         70000000,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();

    //     // user 1 redeem remaining 70 shares
    //     vm.startPrank(USER);
    //     uint w = vault.maxWithdraw(USER);
    //     console.log("maximum withdraw", w);
    //     uint256 withdrawAmount1 = 70000000; // 70 USDC

    //     uint256 atokenVault1 = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(".............before USER redeem 70 shares.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log("Atoken balance of Vault", atokenVault1);

    //     vault.redeem(withdrawAmount1, USER, USER);

    //     console.log(".............after USER redeem 70 shares.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testDepositWithdraw");
    //     assertLe(
    //         token.balanceOf(USER),
    //         amount1,
    //         "USDC ERROR: testDepositWithdraw"
    //     );
    //     assertEq(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         0,
    //         "ATOKEN ERROR: testDepositWithdraw"
    //     );

    //     vm.stopPrank();
    // }

    // function testRebalancing() public {
    //     // user1 deposits 100 USDC
    //     vm.startPrank(USER);

    //     deal(TOKEN, USER, amount1);
    //     token.approve(address(vault), amount1);

    //     assertEq(
    //         token.allowance(USER, address(vault)),
    //         amount1,
    //         "ALLOWANCE ERROR: testDeposit"
    //     );
    //     console.log(".............before USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.deposit(amount1, USER);
    //     console.log(".............after USER deposit 100 USDC.............");
    //     console.log("USDC balance of user ", token.balanceOf(USER));
    //     console.log("Shares of user ", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
    //     assertEq(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         amount1,
    //         "ATOKEN ERROR: testDeposit"
    //     );
    //     vm.stopPrank();

    //     // user2 mints 500 shares
    //     vm.startPrank(USER2);
    //     deal(TOKEN, USER2, amount2);

    //     token.approve(address(vault), shares2);

    //     assertEq(
    //         token.allowance(USER2, address(vault)),
    //         shares2,
    //         "ALLOWANCE ERROR: testMint"
    //     );
    //     console.log(".............before USER2 mints 500 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.mint(shares2, USER2);
    //     console.log(".............after USER2 mints 500 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER2), shares2, "SHARES ERROR: testMint");
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         vault.balanceOf(USER) + shares2,
    //         "ATOKEN ERROR: testMint"
    //     );
    //     vm.stopPrank();

    //     // user1 withdraws 20 USDC from 100 USDC deposited
    //     vm.startPrank(USER);

    //     uint256 withdrawAmount = 20000000; // 20 USDC
    //     uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
    //         .balanceOf(address(vault));

    //     console.log(
    //         ".............before USER1 withdraw 20 USDC from 100 USDC deposited............."
    //     );
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log("Atoken balance of Vault", atokenVault);

    //     vault.withdraw(withdrawAmount, USER, USER);

    //     console.log(
    //         ".............after USER1 withdraw 20 USDC from 100 USDC deposited............."
    //     );
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(vault.balanceOf(USER), 80000000, "SHARES ERROR: testWithdraw");
    //     assertLe(
    //         token.balanceOf(USER),
    //         withdrawAmount,
    //         "USDC ERROR: testWithdraw"
    //     );
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         580000000,
    //         "ATOKEN ERROR: testWithdraw"
    //     );
    //     assertEq(
    //         uint(vault.currentProtocol()),
    //         uint(Vault.Protocol.Aave),
    //         "CURRENT PROTOCOL ERROR"
    //     );
    //     console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
    //     vm.stopPrank();

    //     // owner calls rebalance function - extrafi
    //     console.log("Before Rebalancing");
    //     console.log(
    //         "Current AToken of AAVE Balance",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     vault.rebalance(Vault.Protocol.ExtraFi);
    //     console.log("After Rebalancing");
    //     console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
    //     console.log(
    //         "Current EToken of ExtraFi Balance",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(
    //         uint(vault.currentProtocol()),
    //         uint(Vault.Protocol.ExtraFi),
    //         "CURRENT PROTOCOL ERROR"
    //     );

    //     // user2 withdraws 500 USDC
    //     vm.startPrank(USER2);

    //     console.log(".............before USER2 withdraw 500 USDC.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.withdraw(shares2, USER2, USER2);

    //     console.log(".............after USER2 withdraw 500 USDC.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testWithdraw");
    //     assertLe(token.balanceOf(USER2), shares2, "USDC ERROR: testWithdraw");
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         80000000,
    //         "ATOKEN ERROR: testWithdraw"
    //     );
    //     vm.stopPrank();

    //     // user2 mints 50 shares
    //     vm.startPrank(USER2);
    //     deal(TOKEN, USER2, shares1);

    //     token.approve(address(vault), shares1);

    //     assertEq(
    //         token.allowance(USER2, address(vault)),
    //         shares1,
    //         "ALLOWANCE ERROR: testMint"
    //     );
    //     console.log(".............before USER2 mints 50 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.mint(shares1, USER2);
    //     console.log(".............after USER2 mints 50 shares.............");
    //     console.log("USDC balance of USER2 ", token.balanceOf(USER2));
    //     console.log("Shares of USER2 ", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault ",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     assertEq(vault.balanceOf(USER2), shares1, "SHARES ERROR: testMint");
    //     assertLe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         vault.balanceOf(USER) + shares1,
    //         "ATOKEN ERROR: testMint"
    //     );
    //     vm.stopPrank();

    //     // owner calls rebalance function - moonwell
    //     console.log("Before Rebalancing");
    //     console.log(
    //         "Current EToken of ExtraFi Balance",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     vault.rebalance(Vault.Protocol.Moonwell);
    //     console.log("After Rebalancing");
    //     console.log("CURRENT PROTOCOL", uint(vault.currentProtocol()));
    //     console.log(
    //         "Current MToken of Moonwell Balance",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(
    //         uint(vault.currentProtocol()),
    //         uint(Vault.Protocol.Moonwell),
    //         "CURRENT PROTOCOL ERROR"
    //     );

    //     // user1 withdraws 80 USDC
    //     vm.startPrank(USER);

    //     uint256 withdrawAmount1 = 80000000; // 80 USDC

    //     console.log(".............before USER1 withdraw 80 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.redeem(withdrawAmount1, USER, USER);

    //     console.log(".............after USER1 withdraw 80 USDC.............");
    //     console.log("USDC balance of user", token.balanceOf(USER));
    //     console.log("Shares of user", vault.balanceOf(USER));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testWithdraw");
    //     assertLe(token.balanceOf(USER), amount1, "USDC ERROR: testWithdraw");
    //     assertGe(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         130000000,
    //         "ATOKEN ERROR: testWithdraw"
    //     );
    //     vm.stopPrank();

    //     // user2 withdraws 50 USDC
    //     vm.startPrank(USER2);

    //     console.log(".............before USER2 withdraw 50 USDC.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );

    //     vault.withdraw(shares1, USER2, USER2);

    //     console.log(".............after USER2 withdraw 50 USDC.............");
    //     console.log("USDC balance of USER2", token.balanceOf(USER2));
    //     console.log("Shares of USER2", vault.balanceOf(USER2));
    //     console.log(
    //         "Atoken balance of Vault",
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
    //     );
    //     assertEq(vault.balanceOf(USER2), 0, "SHARES ERROR: testWithdraw");
    //     assertLe(token.balanceOf(USER2), shares1, "USDC ERROR: testWithdraw");
    //     assertEq(
    //         IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
    //         0,
    //         "ATOKEN ERROR: testWithdraw"
    //     );
    //     vm.stopPrank();
    // }
}
