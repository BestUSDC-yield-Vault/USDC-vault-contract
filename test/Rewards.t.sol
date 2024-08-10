// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/ClaimReward.sol";
import "../src/interfaces/Claim.sol";

contract ClaimRewardTest is Test {
    ClaimReward public claimReward;
    Claim public mockClaimContract;

    address public user = 0xd0a1BB20Fb52A72FFEE79bC01d64a009475450dD;
    address public token = 0xd5046B976188EB40f6DE40fB527F89c05b323385;
    uint256 public amount = 17876349700000000000;
    bytes32[][] public proofs;
    address public claimContractAddress =
        0x3Ef3D8bA38EBe18DB133cEc108f4D14CE00Dd9Ae;

    function setUp() public {
        // Deploy the ClaimReward contract
        claimReward = new ClaimReward();

        // Mock the Claim contract
        mockClaimContract = Claim(claimContractAddress);

        // Create mock proofs
        proofs.push(
            [
                bytes32(
                    0x1265b45b7e114bdcd8b295a1d177fa4cd5ebcf5681a10510d53eaf92e4ee149b
                ),
                bytes32(
                    0xde725423ad6b4d72cf20060f865de6e8d98945203b96648aa7a54bb6e6356869
                ),
                bytes32(
                    0xa033f86aa83500ecbd1849f36829b4f1f1d4bd59594c3ba89c1070e971379b8f
                ),
                bytes32(
                    0xecfb3d9f417e5b1798241c5d128b52d52db65bac7c218fd943ff896cc1f2a56d
                ),
                bytes32(
                    0xd7598a02fc7a91f94cf1f99f0e42fbfaa393c10bea41e2c4e98b62bb1cf0842d
                ),
                bytes32(
                    0x82aa0ef6d20b5268161b8980b85f01d347ea2ba8e3cf09717266ef41e9c4c4ef
                ),
                bytes32(
                    0xbeac780192f2db75a80c0009cf2d47fe36a4bc049c15a27d1b8e8f0fc50321b8
                ),
                bytes32(
                    0x81182f52d8b3de10970581ec5a6b6ddc6d9c7abca645b3c7c8209cbe2f5520db
                ),
                bytes32(
                    0xb5852e38c023b40feff9221d557975c2fdec5bd85350efc671a4d3915e37a90f
                ),
                bytes32(
                    0x2c7b6e7a9fe55369f3d41cfd32686aee28281977e11d2959fce8a5ffe7184316
                ),
                bytes32(
                    0x820f1d8ec314101078671e4f24fc8fc066eb758e2fffe4c1e64ab84382617699
                ),
                bytes32(
                    0x17e0d73b14fadce893455cfd2874f0fa16e9fe08baa4c8f0ae31743a2656fe36
                ),
                bytes32(
                    0xd47cc3f7a55fef20419c69efcf6c58aa1eb10b0c52fbb43e29bceaef24e9a700
                ),
                bytes32(
                    0xb53d10eaab35fa308e62d8775f8a0a9e5727fc47c4de802fc9f6b4775e7369ee
                ),
                bytes32(
                    0xe64298fbc49b4d3fec830ac53bec3fb9368fe0ebcbe67d9ae0486dd1b4d2d4d2
                )
            ]
        );
    }

    function testClaim() public {
        vm.startPrank(user);
        // Call the claim function on the ClaimReward contract
        address[] memory users = new address[](1);
        users[0] = user;

        address[] memory tokens = new address[](1);
        tokens[0] = token;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        claimReward.claim(users, tokens, amounts, proofs, claimContractAddress);
        vm.stopPrank();
    }
}
