// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/Claim.sol";

contract ClaimReward {
    function claim(
        address[] calldata users,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs,
        address _contract
    ) public {
        Claim c = Claim(_contract);
        c.claim(users, tokens, amounts, proofs);
    }
}
