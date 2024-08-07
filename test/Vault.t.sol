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
    address USER = vm.envAddress("USER");
    address USER2 = vm.envAddress("USER2");
    address USER3 = vm.envAddress("USER3");

    /**
     * @dev Sets up the testing environment
     */
    function setUp() public {
        token = IERC20(TOKEN);
        vault = new Vault(token, 0, LENDING_POOL_AAVE, LENDING_POOL_SEAMLESS);

        // console.log("Deployed Vault contract at: %s", address(vault));

        amount1 = 100 * 10 ** 6; // 100 USDC (6 decimals)
        amount2 = 1000 * 10 ** 6; // 1000 USDC (6 decimals)
        shares1 = 50 * 10 ** 6; // 50 USDC (6 decimals)
        shares2 = 500 * 10 ** 6; // 500 USDC (6 decimals)
    }

    /**
     * @dev Tests depositing USDC to the Vault
     */
    function testDeposit() public {
        vm.startPrank(USER);

        deal(TOKEN, USER, amount1);
        token.approve(address(vault), amount1);

        assertEq(
            token.allowance(USER, address(vault)),
            amount1,
            "ALLOWANCE ERROR: testDeposit"
        );
        // console.log(".............before deposit.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        vault.deposit(amount1, USER);
        // console.log(".............after deposit.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(vault.balanceOf(USER), amount1, "SHARES ERROR: testDeposit");
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            amount1,
            "ATOKEN ERROR: testDeposit"
        );

        vm.stopPrank();
    }

    /**
     * @dev Tests depositing USDC to the Vault for USER2
     */
    function testDepositUSER2() public {
        testDeposit();
        vm.startPrank(USER2);

        deal(TOKEN, USER2, amount2);
        token.approve(address(vault), amount2);

        assertEq(
            token.allowance(USER2, address(vault)),
            amount2,
            "ALLOWANCE ERROR: testDepositUSER2"
        );
        // console.log(".............before deposit.............");
        // console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        // console.log("Shares of USER2 ", vault.balanceOf(USER2));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        vault.deposit(amount2, USER2);
        // console.log(".............after deposit.............");
        // console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        // console.log("Shares of USER2 ", vault.balanceOf(USER2));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

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

    /**
     * @dev Tests minting shares for USDC deposit
     */
    function testMint() public {
        vm.startPrank(USER);
        deal(TOKEN, USER, amount1);

        uint256 sharesToAssets = vault.previewMint(shares1);
        // console.log("Shares To Assets", sharesToAssets);
        token.approve(address(vault), sharesToAssets);

        assertEq(
            token.allowance(USER, address(vault)),
            sharesToAssets,
            "ALLOWANCE ERROR: testMint"
        );
        // console.log(".............before mint.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        vault.mint(shares1, USER);
        // console.log(".............after deposit.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

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

    /**
     * @dev Tests minting shares for USER2
     */
    function testMintUSER2() public {
        testMint();
        vm.startPrank(USER2);
        deal(TOKEN, USER2, amount2);

        uint256 sharesToAssets = vault.previewMint(shares2);
        // console.log("Shares To Assets", sharesToAssets);
        token.approve(address(vault), sharesToAssets);

        assertEq(
            token.allowance(USER2, address(vault)),
            sharesToAssets,
            "ALLOWANCE ERROR: testMint"
        );
        // console.log(".............before mint.............");
        // console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        // console.log("Shares of USER2 ", vault.balanceOf(USER2));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        vault.mint(shares2, USER2);
        // console.log(".............after deposit.............");
        // console.log("USDC balance of USER2 ", token.balanceOf(USER2));
        // console.log("Shares of USER2 ", vault.balanceOf(USER2));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(
            vault.balanceOf(USER2),
            sharesToAssets,
            "SHARES ERROR: testMint"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            vault.balanceOf(USER) + sharesToAssets,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();
    }

    /**
     * @dev Tests depositing and minting shares
     */
    function testDepositMint() public {
        testDeposit();
        vm.startPrank(USER);
        deal(TOKEN, USER, amount2);

        uint256 sharesToAssets = vault.previewMint(shares1);
        // console.log("Shares To Assets", sharesToAssets);
        token.approve(address(vault), sharesToAssets);

        assertEq(
            token.allowance(USER, address(vault)),
            sharesToAssets,
            "ALLOWANCE ERROR: testMint"
        );
        // console.log(".............before mint.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        vault.mint(shares1, USER);
        // console.log(".............after deposit.............");
        // console.log("USDC balance of user ", token.balanceOf(USER));
        // console.log("Shares of user ", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault ",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(
            vault.balanceOf(USER),
            sharesToAssets + amount1,
            "SHARES ERROR: testMint"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            sharesToAssets + amount1,
            "ATOKEN ERROR: testMint"
        );
        vm.stopPrank();
    }

    /**
     * @dev Tests depositing and withdrawing USDC
     */
    function testDepositWithdraw() public {
        testDeposit();
        vm.startPrank(USER);

        uint256 withdrawAmount = amount1;

        // uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
        //     .balanceOf(address(vault));

        // console.log(".............before withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        // console.log(".............after withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(vault.balanceOf(USER), 0, "SHARES ERROR: testDepositWithdraw");
        assertGe(
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

    /**
     * @dev Tests depositing, minting shares, and withdrawing USDC
     */
    function testDepositMintWithdraw() public {
        testDepositMint();
        vm.startPrank(USER);

        uint256 withdrawAmount = amount1;

        // uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
        //     .balanceOf(address(vault));

        // console.log(".............before withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log("Atoken balance of Vault", atokenVault);

        vault.withdraw(withdrawAmount, USER, USER);

        // console.log(".............after withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(
            vault.balanceOf(USER),
            50000000,
            "SHARES ERROR: testDepositWithdraw"
        );
        assertGe(
            token.balanceOf(USER),
            1050000000,
            "USDC ERROR: testDepositWithdraw"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            50000000,
            "ATOKEN ERROR: testDepositWithdraw"
        );

        vm.stopPrank();
    }

    /**
     * @dev Tests depositing and redeeming shares
     */
    function testDepositRedeem() public {
        testDeposit();
        vm.startPrank(USER);

        uint256 withdrawShares = shares1;

        // uint256 atokenVault = IERC20(vault.getCurrentProtocolAtoken())
        //     .balanceOf(address(vault));

        // console.log(".............before withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log("Atoken balance of Vault", atokenVault);

        vault.redeem(withdrawShares, USER, USER);

        // console.log(".............after withdraw.............");
        // console.log("USDC balance of user", token.balanceOf(USER));
        // console.log("Shares of user", vault.balanceOf(USER));
        // console.log(
        //     "Atoken balance of Vault",
        //     IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault))
        // );

        assertEq(
            vault.balanceOf(USER),
            50000000,
            "SHARES ERROR: testDepositRedeem"
        );
        assertGe(
            token.balanceOf(USER),
            50000000,
            "USDC ERROR: testDepositRedeem"
        );
        assertEq(
            IERC20(vault.getCurrentProtocolAtoken()).balanceOf(address(vault)),
            50000000,
            "ATOKEN ERROR: testDepositRedeem"
        );

        vm.stopPrank();
    }
}
