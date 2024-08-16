// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IComptroller {
    function claimReward(address holder) external;
}
