// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "./LendingManager.sol";

contract Vault is ERC4626, LendingManager {
    using Math for uint256;

    enum Protocol {
        Aave,
        Extrafi,
        Moonwell,
        Seamless
    }
    Protocol public currentProtocol = Protocol.Aave;

    address public lendingPoolAave;
    address public lendingPoolSeamless;

    IERC20 public underlyingAsset;
    uint32 public stakeDuration;
    uint16 public referralCode;

    // LendingManager public lendingManager;

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

    event Check(uint256);
    /*//////////////////////////////////////////////////////////////
                          MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address lender => uint32 epoch) public stakeTimeEpochMapping;

    /*//////////////////////////////////////////////////////////////
                          MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier nonZero(uint256 _value) {
        require(
            _value != 0,
            "Value must be greater than zero. Please enter a valid amount"
        );
        _;
    }

    modifier canWithdraw(address _owner) {
        require(
            getWithdrawEpoch(_owner) <= _blockTimestamp(),
            "Not eligible right now, funds can be redeemed after locking period"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getWithdrawEpoch(address _owner) public view returns (uint32) {
        return stakeTimeEpochMapping[_owner] + stakeDuration;
    }

    // for gas efficiency
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    /*//////////////////////////////////////////////////////////////
                          ERC4626 overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Preview taking an entry fee on deposit. See {IERC4626-previewDeposit}.
    function previewDeposit(
        uint256 assets
    ) public view virtual override returns (uint256) {
        return _convertToShares(assets, Math.Rounding.Floor);
    }

    /// @dev Preview adding an entry fee on mint. See {IERC4626-previewMint}.
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
                          (3) DEPOSIT functions
                          - deposit
                          - mint
    //////////////////////////////////////////////////////////////*/

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
        // overridden
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return shares;
    }

    function mint(
        uint256 shares,
        address receiver
    ) public virtual override nonZero(shares) returns (uint256 assets) {
        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        afterDeposit(assets);
        stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return assets;
    }

    function afterDeposit(uint256 _amount) internal virtual nonZero(_amount) {
        if (currentProtocol == Protocol.Aave) {
            depositAave(
                address(underlyingAsset),
                _amount,
                address(this),
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            depositAave(
                address(underlyingAsset),
                _amount,
                address(this),
                lendingPoolSeamless
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          (2) Withdraw functions
                          - withdraw
                          - redeem
    //////////////////////////////////////////////////////////////*/

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
        uint256 totalSupplyShares = totalSupply();
        uint256 aTokensToWithdraw = (shares * aTokenBalance) /
            totalSupplyShares;

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        uint256 amountWithdrawn = withdrawPool(aTokensToWithdraw, receiver);
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);
        return shares;
    }

    function withdrawPool(
        uint256 _amount,
        address _receiver
    ) internal virtual nonZero(_amount) returns (uint256 amountWithdrawn) {
        if (currentProtocol == Protocol.Aave) {
            amountWithdrawn = withdrawAave(
                address(underlyingAsset),
                _amount,
                _receiver,
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            amountWithdrawn = withdrawAave(
                address(underlyingAsset),
                _amount,
                _receiver,
                lendingPoolSeamless
            );
        }
    }

    function getCurrentProtocolAtoken() public view returns (address aToken) {
        // aToken = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;
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
    }
}
