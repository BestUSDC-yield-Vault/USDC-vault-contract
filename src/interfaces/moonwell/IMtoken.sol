// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IMToken {
    function supplyRatePerTimestamp() external view returns (uint);

    // // function exchangeRateCurrent() external  returns (uint);

    function exchangeRateStored() external view returns (uint);

    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function balanceOf(address owner) external returns (uint);

    function redeemUnderlying(
        //need to check it once.
        uint redeemAmount
    ) external returns (uint);
}
