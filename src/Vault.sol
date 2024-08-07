// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./LendingManager.sol";

/**
 * @title Vault
 * @author Bhumi Sadariya
 * @dev A vault contract that allows users to deposit asset(USDC) and earn best yield from multiple lending protocols.
 */
contract Vault is ERC4626, LendingManager {
    using Math for uint256;

    // Enum to represent different protocols
    enum Protocol {
        Aave,
        Extrafi,
        Moonwell,
        Seamless
    }
    Protocol public currentProtocol = Protocol.Aave;

    // Addresses of the lending pools
    address public lendingPoolAave;
    address public lendingPoolSeamless;

    // Underlying asset and other configuration variables
    IERC20 public underlyingAsset;
    uint32 public stakeDuration;
    uint16 public referralCode;

    // Mapping to keep track of staking times
    mapping(address lender => uint32 epoch) public stakeTimeEpochMapping;

    /**
     * @dev Constructor to initialize the vault.
     * @param _asset The underlying asset of the vault.
     * @param _duration The staking duration.
     * @param _lendingPoolAave  The address of the Aave lending pool.
     * @param _lendingPoolSeamless The address of the Seamless lending pool.
     */
    constructor(
        IERC20 _asset,
        uint32 _duration,
        address _lendingPoolAave,
        address _lendingPoolSeamless
    ) ERC4626(_asset) ERC20("Vault Token", "vFFI") {
        stakeDuration = _duration;
        underlyingAsset = IERC20(_asset);
        lendingPoolAave = _lendingPoolAave;
        lendingPoolSeamless = _lendingPoolSeamless;
    }

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensures the vaule is non-zero.
     * @param _value The value to check.
     */
    modifier nonZero(uint256 _value) {
        require(_value != 0, "Value must be greater than zero");
        _;
    }

    /**
     * @dev Ensures the owner can withdraw their funds.
     * @param _owner The address of the owner.
     */
    modifier canWithdraw(address _owner) {
        require(
            getWithdrawEpoch(_owner) <= uint32(block.timestamp),
            "Not eligible for withdrawal yet"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Gets the withdrawal epoch for a given address.
     * @param _owner The address of the owner.
     * @return The withdrawal epoch.
     */
    function getWithdrawEpoch(address _owner) public view returns (uint32) {
        return stakeTimeEpochMapping[_owner] + stakeDuration;
    }

    /*//////////////////////////////////////////////////////////////
                          ERC4626 overrides
    //////////////////////////////////////////////////////////////*/

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(
        uint256 shares
    ) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewWithdraw}. */
    function previewWithdraw(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Ceil);
    }

    /** @dev See {IERC4626-previewRedeem}. */
    function previewRedeem(
        uint256 shares
    ) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(
        uint256 assets,
        Math.Rounding rounding
    ) internal view virtual override returns (uint256) {
        return
            assets.mulDiv(
                totalSupply() + 10 ** _decimalsOffset(),
                IERC20(getCurrentProtocolAtoken()).balanceOf(address(this)) + 1,
                rounding
            );
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(
        uint256 shares,
        Math.Rounding rounding
    ) internal view virtual override returns (uint256) {
        return
            shares.mulDiv(
                IERC20(getCurrentProtocolAtoken()).balanceOf(address(this)) + 1,
                totalSupply() + 10 ** _decimalsOffset(),
                rounding
            );
    }

    /*//////////////////////////////////////////////////////////////
                         DEPOSIT functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposits the specified amount of assets and mints shares to the receiver.
     * @param assets The amount of assets to deposit.
     * @param receiver The address receiving the shares.
     * @return The amount of shares minted.
     */
    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override nonZero(assets) returns (uint256) {
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }
        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets);
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return shares;
    }

    /**
     * @dev Mints the specified amount of shares to the receiver.
     * @param shares The amount of shares to mint.
     * @param receiver The address receiving the assets.
     * @return The amount of assets deposited.
     */
    function mint(
        uint256 shares,
        address receiver
    ) public virtual override nonZero(shares) returns (uint256) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }
        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets);
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return assets;
    }

    /**
     * @dev Internal function to handle post-deposit actions.
     * @param _amount The amount deposited.
     */
    function afterDeposit(uint256 _amount) internal virtual nonZero(_amount) {
        if (currentProtocol == Protocol.Aave) {
            depositToLendingPool(
                address(underlyingAsset),
                _amount,
                address(this),
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            depositToLendingPool(
                address(underlyingAsset),
                _amount,
                address(this),
                lendingPoolSeamless
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Withdraw functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Withdraws the specified amount of assets and burns the corresponding shares from the owner.
     * @param assets The amount of assets to withdraw.
     * @param receiver The address receiving the assets.
     * @param owner The address of the owner of the shares.
     * @return The amount of shares burned.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        public
        virtual
        override
        nonZero(assets)
        canWithdraw(owner)
        returns (uint256)
    {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        uint256 aTokenBalance = IERC20(getCurrentProtocolAtoken()).balanceOf(
            address(this)
        );
        uint256 aTokensToWithdraw = (shares * aTokenBalance) / totalSupply();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        uint256 amountWithdrawn = withdrawFromLendingPool(
            aTokensToWithdraw,
            receiver
        );
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);
        return shares;
    }

    /**
     * @dev Redeems the specified amount of shares and transfers the corresponding assets to the receiver.
     * @param shares The amount of shares to redeem.
     * @param receiver The address receiving the assets.
     * @param owner The address of the owner of the shares.
     * @return The amount of assets redeemed.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        public
        virtual
        override
        nonZero(shares)
        canWithdraw(owner)
        returns (uint256)
    {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        uint256 assets = previewRedeem(shares);
        uint256 aTokenBalance = IERC20(getCurrentProtocolAtoken()).balanceOf(
            address(this)
        );
        uint256 aTokensToWithdraw = (shares * aTokenBalance) / totalSupply();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        uint256 amountWithdrawn = withdrawFromLendingPool(
            aTokensToWithdraw,
            receiver
        );
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);

        return assets;
    }

    /**
     * @dev Internal function to handle withdrawal from the lending pool.
     * @param _amount The amount to withdraw.
     * @param _receiver The address receiving the withdrawn assets.
     * @return The amount withdrawn.
     */
    function withdrawFromLendingPool(
        uint256 _amount,
        address _receiver
    ) internal virtual nonZero(_amount) returns (uint256) {
        uint256 amountWithdrawn;
        if (currentProtocol == Protocol.Aave) {
            amountWithdrawn = withdrawFromLendingPool(
                address(underlyingAsset),
                _amount,
                _receiver,
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            amountWithdrawn = withdrawFromLendingPool(
                address(underlyingAsset),
                _amount,
                _receiver,
                lendingPoolSeamless
            );
        }
        return amountWithdrawn;
    }

    /**
     * @dev Gets the address of the aToken for the current protocol.
     * @return The address of the aToken.
     */
    function getCurrentProtocolAtoken() public view returns (address) {
        address aToken;
        if (currentProtocol == Protocol.Aave) {
            // aToken = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;
            aToken = getATokenAddress(
                address(underlyingAsset),
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            aToken = getATokenAddress(
                address(underlyingAsset),
                lendingPoolSeamless
            );
        }
        return aToken;
    }
}
