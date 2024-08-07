// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/aave/IPool.sol";

/**
 * @title LendingManager
 * @author Bhumi Sadariya
 * @dev A contract to manage deposits and withdrawals to and from lending pools.
 */
contract LendingManager {
    /**
     * @dev Deposits the specified amount of the asset to the lending pool. (Aave/Seamless)
     * @param _asset The address of the asset to deposit.
     * @param _amount The amount of the asset to deposit.
     * @param _onBehalfOf The address on whose behalf the deposit is made.
     * @param lendingPool The address of the lending pool.
     */
    function depositToLendingPool(
        address _asset,
        uint256 _amount,
        address _onBehalfOf,
        address lendingPool
    ) public {
        IPool pool = IPool(lendingPool);
        // IERC20(_asset).transferFrom(msg.sender, address(this), _amount); // to test this contract individually uncomment it.
        IERC20(_asset).approve(address(pool), _amount);
        pool.deposit(_asset, _amount, _onBehalfOf, 0);
    }

    /**
     * @dev Withdraws the specified amount of the asset from the lending pool. (Aave/Seamless)
     * @param _asset The address of the asset to withdraw.
     * @param _amount The amount of the asset to withdraw.
     * @param to The address to which the withdrawn asset is sent.
     * @param lendingPool The address of the lending pool.
     * @return The amount withdrawn.
     */
    function withdrawFromLendingPool(
        address _asset,
        uint256 _amount,
        address to,
        address lendingPool
    ) public returns (uint256) {
        IPool pool = IPool(lendingPool);
        IERC20(getATokenAddress(_asset, lendingPool)).approve(
            address(pool),
            _amount
        );
        return pool.withdraw(_asset, _amount, to);
    }

    /**
     * @dev Gets the address of the aToken for the specified asset and lending pool. (Aave/Seamless)
     * @param _asset The address of the asset.
     * @param lendingPool The address of the lending pool.
     * @return The address of the aToken.
     */
    function getATokenAddress(
        address _asset,
        address lendingPool
    ) public view returns (address) {
        IPool pool = IPool(lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(_asset);
        return reserveData.aTokenAddress;
    }

    /**
     * @dev Gets the current liquidity rate for a given asset from the lending pool. (Aave/Seamless)
     * @param _asset The address of the asset.
     * @param lendingPool The address of the lending pool.
     * @return The current liquidity rate in human-readable APR format (annual percentage rate).
     */
    function getInterestRate(
        address _asset,
        address lendingPool
    ) public view returns (uint128) {
        IPool pool = IPool(lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(_asset);
        uint128 liquidityRate = reserveData.currentLiquidityRate;
        return liquidityRate / 1e9; // Convert ray (1e27) to a percentage (1e2)
    }
}
