// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/aave/IPool.sol";
import "./interfaces/extrafi/ILendingPool.sol";
import "./interfaces/extrafi/IStakingRewards.sol";
import "./interfaces/moonwell/IMtoken.sol";
import "./interfaces/moonwell/IComptroller.sol";

/**
 * @title LendingManager
 * @author Bhumi Sadariya
 * @notice Manages deposits and withdrawals to and from various lending pools.
 * @dev Supports Aave, Seamless, ExtraFi, and MoonWell protocols.
 */
contract LendingManager {
    address public immutable usdc;

    constructor(address _usdc) {
        usdc = _usdc;
    }

    /**
     * @notice Deposits the specified amount of USDC to the Aave or Seamless lending pool.
     * @param _amount The amount of USDC to deposit.
     * @param _onBehalfOf The address on whose behalf the deposit is made.
     * @param _lendingPool The address of the lending pool.
     */
    function depositToLendingPool(
        uint256 _amount,
        address _onBehalfOf,
        address _lendingPool
    ) public {
        IPool pool = IPool(_lendingPool);
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount); // to test this contract individually uncomment it.
        IERC20(usdc).approve(address(pool), _amount);
        pool.deposit(usdc, _amount, _onBehalfOf, 0);
    }

    /**
     * @notice Deposits the specified amount of USDC to the ExtraFi lending pool.
     * @param _reserveId The ID of the reserve to deposit into.
     * @param _amount The amount of USDC to deposit.
     * @param _lendingPool The address of the ExtraFi lending pool.
     */
    function depositToExtraFi(
        uint256 _reserveId,
        uint256 _amount,
        address _onBehalfOf,
        address _lendingPool
    ) public {
        ILendingPool pool = ILendingPool(_lendingPool);
        // IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
        IERC20(usdc).approve(address(pool), _amount);
        pool.deposit(_reserveId, _amount, _onBehalfOf, 0);
    }

    function depositAndStakeToExtraFi(
        uint256 _reserveId,
        uint256 _amount,
        address _onBehalfOf,
        address _lendingPool
    ) public {
        ILendingPool pool = ILendingPool(_lendingPool);
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
        IERC20(usdc).approve(address(pool), _amount);
        pool.depositAndStake(_reserveId, _amount, _onBehalfOf, 0);
    }

    /**
     * @notice Deposits the specified amount of USDC to the MoonWell lending pool.
     * @param _amount The amount of USDC to deposit.
     * @param _lendingPool The address of the MoonWell lending pool.
     */
    function depositToMoonWell(uint256 _amount, address _lendingPool) public {
        IMToken pool = IMToken(_lendingPool);
        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);
        IERC20(usdc).approve(address(pool), _amount);
        pool.mint(_amount);
    }

    /**
     * @notice Withdraws the specified amount of USDC from the Aave or Seamless lending pool.
     * @param _amount The amount of USDC to withdraw.
     * @param _to The address to which the withdrawn USDC is sent.
     * @param _lendingPool The address of the lending pool.
     * @return The amount withdrawn.
     */
    function withdrawFromLendingPool(
        uint256 _amount,
        address _to,
        address _lendingPool
    ) public returns (uint256) {
        IPool pool = IPool(_lendingPool);
        IERC20(getATokenAddress(_lendingPool)).approve(address(pool), _amount);
        return pool.withdraw(usdc, _amount, _to);
    }

    /**
     * @notice Withdraws the specified amount of eTokens from the ExtraFi lending pool.
     * @param _eTokenAmount The amount of eTokens to redeem.
     * @param _to The address to which the redeemed USDC is sent.
     * @param _reserveId The ID of the reserve to redeem from.
     * @param _lendingPool The address of the ExtraFi lending pool.
     * @return The amount redeemed.
     */
    function withdrawFromExtraFi(
        uint256 _eTokenAmount,
        address _to,
        uint256 _reserveId,
        address _lendingPool
    ) public returns (uint256) {
        ILendingPool pool = ILendingPool(_lendingPool);
        IERC20(getATokenAddressOfExtraFi(_reserveId, _lendingPool)).approve(
            address(pool),
            _eTokenAmount
        );
        return pool.redeem(_reserveId, _eTokenAmount, _to, false); //can be static first and last value (receiveNativeEth = false)
    }

    function unStakeAndWithdrawFromExtraFi(
        uint256 _eTokenAmount,
        address _to,
        uint256 _reserveId,
        address _lendingPool
    ) public returns (uint256) {
        ILendingPool pool = ILendingPool(_lendingPool);
        IERC20(getATokenAddressOfExtraFi(_reserveId, _lendingPool)).approve(
            address(pool),
            _eTokenAmount
        );
        return pool.unStakeAndWithdraw(_reserveId, _eTokenAmount, _to, false); //can be static first and last value (receiveNativeEth = false)
    }

    /**
     * @notice Withdraws the specified amount of mTokens from the MoonWell lending pool.
     * @param _redeemTokens The amount of mTokens to redeem.
     * @param _lendingPool The address of the MoonWell lending pool.
     * @return The amount redeemed.
     */
    function withdrawFromMoonWell(
        uint256 _redeemTokens,
        // address _to,
        address _lendingPool
    ) public returns (uint256) {
        IMToken pool = IMToken(_lendingPool);
        return pool.redeem(_redeemTokens); //can be static first and last value
        // IERC20(usdc).transfer(_to, withdrawAmount);
    }

    /**
     * @notice Gets the address of the aToken for the specified asset and lending pool.
     * @param _lendingPool The address of the lending pool.
     * @return The address of the aToken.
     */
    function getATokenAddress(
        address _lendingPool
    ) public view returns (address) {
        IPool pool = IPool(_lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(usdc);
        return reserveData.aTokenAddress;
    }

    /**
     * @notice Gets the address of the eToken for the specified reserve and ExtraFi lending pool.
     * @param _reserveId The ID of the reserve.
     * @param _lendingPool The address of the ExtraFi lending pool.
     * @return The address of the eToken.
     */
    function getATokenAddressOfExtraFi(
        uint256 _reserveId,
        address _lendingPool
    ) public view returns (address) {
        ILendingPool pool = ILendingPool(_lendingPool);
        return pool.getETokenAddress(_reserveId);
    }

    /**
     * @notice Gets the current liquidity rate for USDC from the Aave or Seamless lending pool.
     * @param _lendingPool The address of the lending pool.
     * @return The current liquidity rate in APR format.
     */
    function getInterestRate(
        address _lendingPool
    ) public view returns (uint128) {
        IPool pool = IPool(_lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(usdc);
        uint128 liquidityRate = reserveData.currentLiquidityRate;
        return liquidityRate / 1e9; // Convert ray (1e27) to a percentage (1e2)
    }

    /**
     * @notice Gets the current exchange rate for the specified reserve from the ExtraFi lending pool.
     * @param _reserveId The ID of the reserve.
     * @param _lendingPool The address of the ExtraFi lending pool.
     * @return The current exchange rate.
     */
    function exchangeRateOfExtraFi(
        uint256 _reserveId,
        address _lendingPool
    ) public view returns (uint256) {
        ILendingPool pool = ILendingPool(_lendingPool);
        return pool.exchangeRateOfReserve(_reserveId);
    }

    //need to change this
    function getInterestRateOfMoonWell(
        address lendingPool
    ) public view returns (uint256 rate) {
        IMToken pool = IMToken(lendingPool);
        rate = pool.supplyRatePerTimestamp();
    }

    function exchangeRateOfMoonWell(
        address lendingPool
    ) public view returns (uint256 rate) {
        IMToken pool = IMToken(lendingPool);
        rate = pool.exchangeRateStored();
    }

    function claimRewardFromMoonwell() public {
        IComptroller comptroller = IComptroller(
            0xfBb21d0380beE3312B33c4353c8936a0F13EF26C
        );
        comptroller.claimReward(address(this));
    }

    function claimRewardsFromExtraFi() public {
        IStakingRewards rewardController = IStakingRewards(
            0xE61662C09c30E1F3f3CbAeb9BC1F13838Ed18957
        );
        rewardController.claim();
    }

    function getRewardsForExtraFi(
        address sender,
        address rewardToken
    ) public view returns (uint256 rewards) {
        IStakingRewards rewardController = IStakingRewards(
            0xE61662C09c30E1F3f3CbAeb9BC1F13838Ed18957
        );
        rewards = rewardController.userRewardsClaimable(sender, rewardToken);
    }
}
