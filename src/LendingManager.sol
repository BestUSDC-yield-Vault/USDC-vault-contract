// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/aave/IPool.sol";

contract LendingManager {
    function deposit(address _asset, uint256 _amount, address lendingPool) external {
        IPool pool = IPool(lendingPool);
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        IERC20(_asset).approve(address(pool), _amount);
        pool.deposit(_asset, _amount, address(this), 0);
    }

    function withdraw(address _asset, uint256 _amount, address to, address lendingPool) external returns (uint256) {
        IPool pool = IPool(lendingPool);
        IERC20(getATokenAddress(_asset, lendingPool)).approve(address(pool), _amount);
        return pool.withdraw(_asset, _amount, to);
    }

    function getATokenAddress(address _asset, address lendingPool) public view returns (address) {
        IPool pool = IPool(lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(_asset);
        return reserveData.aTokenAddress;
    }

    function getInterestRate(address _asset, address lendingPool) public view returns (uint128) {
        IPool pool = IPool(lendingPool);
        IPool.ReserveData memory reserveData = pool.getReserveData(_asset);
        return reserveData.currentLiquidityRate;
    }
}
