// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface ILendingPool {
    // Interest Rate Config
    // The utilization rate and borrowing rate are expressed in RAY
    // utilizationB must gt utilizationA
    struct InterestRateConfig {
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationA;
        // The borrowing rate at utilization_rate_a
        uint128 borrowingRateA;
        // The utilization rate a, the end of the first slope on interest rate curve
        uint128 utilizationB;
        // The borrowing rate at utilization_rate_b
        uint128 borrowingRateB;
        // the max borrowing rate while the utilization is 100%
        uint128 maxBorrowingRate;
    }

    struct ReserveData {
        // variable borrow index.
        uint256 borrowingIndex;
        // the current borrow rate.
        uint256 currentBorrowingRate;
        // the total borrows of the reserve at a variable rate. Expressed in the currency decimals
        uint256 totalBorrows;
        // underlying token address
        address underlyingTokenAddress;
        // eToken address
        address eTokenAddress;
        // staking address
        address stakingAddress;
        // the capacity of the reserve pool
        uint256 reserveCapacity;
        // borrowing rate config
        InterestRateConfig borrowingRateConfig;
        // the id of the reserve. Represents the position in the list of the reserves
        uint256 id;
        uint128 lastUpdateTimestamp;
        // reserve fee charged, percent of the borrowing interest that is put into the treasury.
        uint16 reserveFeeRate;
        Flags flags;
    }

    struct Flags {
        bool isActive; // set to 1 if the reserve is properly configured
        bool frozen; // set to 1 if reserve is frozen, only allows repays and withdraws, but not deposits or new borrowings
        bool borrowingEnabled; // set to 1 if borrowing is enabled, allow borrowing from this pool
    }

    function utilizationRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function borrowingRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    function exchangeRateOfReserve(
        uint256 reserveId
    ) external view returns (uint256);

    // struct PositionStatus {
    //     uint256 reserveId;
    //     address user;
    //     uint256 eTokenStaked;
    //     uint256 eTokenUnStaked;
    //     uint256 liquidity;
    // }

    // function getPositionStatus(
    //     uint256[] calldata reserveIdArr,
    //     address user
    // ) external view returns (PositionStatus[] memory statusArr);

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying eTokens.
     * - E.g. User deposits 100 USDC and gets in return for specific amount of eUSDC
     * the eUSDC amount depends on the exchange rate between USDC and eUSDC
     * @param reserveId The ID of the reserve
     * @param amount The amount of reserve to be deposited
     * @param onBehalfOf The address that will receive the eTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of eTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable returns (uint256);

    function depositAndStake(
        uint256 reserveId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external payable returns (uint256);

    function unStakeAndWithdraw(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) external returns (uint256);

    /**
     * @dev User redeems eTokens in exchange for the underlying asset
     * E.g. User has 100 eUSDC, and the current exchange rate of eUSDC and USDC is 1:1.1
     * he will receive 110 USDC after redeem 100eUSDC
     * @param reserveId The id of the reserve
     * @param eTokenAmount The amount of eTokens to redeem
     *   - If the amount is type(uint256).max, all of user's eTokens will be redeemed
     * @param to Address that will receive the underlying tokens, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @param receiveNativeETH If receive native ETH, set this param to true
     * @return The underlying token amount user finally receive
     **/
    function redeem(
        uint256 reserveId,
        uint256 eTokenAmount,
        address to,
        bool receiveNativeETH
    ) external returns (uint256);

    function getUnderlyingTokenAddress(
        uint256 reserveId
    ) external view returns (address underlyingTokenAddress);

    function getETokenAddress(
        uint256 reserveId
    ) external view returns (address eTokenAddress);

    function reserves(
        uint256
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            address,
            address,
            uint256,
            InterestRateConfig memory,
            uint256,
            uint128,
            uint16,
            Flags memory
        );
}
