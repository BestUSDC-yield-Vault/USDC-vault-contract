// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingRewards {
    function claim() external;

    function userRewardsClaimable(
        address,
        address
    ) external view returns (uint256);
}
