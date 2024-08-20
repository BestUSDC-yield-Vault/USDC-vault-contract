// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./LendingManager.sol";

/**
 * @title Vault
 * @author Bhumi Sadariya
 * @notice A vault contract that optimizes yield by interacting with multiple lending protocols.
 * @dev This contract supports deposits of USDC and rebalances between Aave, Seamless, ExtraFi, and Moonwell protocols to maximize yield.
 */
contract Vault is ERC4626, LendingManager, Ownable, ReentrancyGuard, Pausable {
    using Math for uint256;

    // Enum to represent different protocols
    enum Protocol {
        Aave,
        ExtraFi, // reserveID 25
        ExtraFi2, // reserveId 24
        Moonwell,
        Seamless
    }
    Protocol public currentProtocol = Protocol.Seamless;

    // Lending pool addresses for various protocols
    address public lendingPoolAave;
    address public lendingPoolSeamless;
    address public lendingPoolExtraFi;
    address public lendingPoolMoonwell;

    // Underlying asset and other configuration parameters
    IERC20 public immutable underlyingAsset;
    uint16 public referralCode;
    uint256 public constant MAX_USDC_CAP = 5_000_000 * 1e6; // 5 million USDC

    // Mapping to keep track of staking times
    mapping(address lender => uint32 epoch) public stakeTimeEpochMapping;

    event check(uint256 amount, uint256 user, uint256 vault);
    event Rebalance(Protocol _protocol, uint256 depositedAssets);

    /**
     * @param _asset The underlying asset of the vault (USDC).
     * @param _lendingPoolAave The address of the Aave lending pool.
     * @param _lendingPoolSeamless The address of the Seamless lending pool.
     * @param _lendingPoolExtraFi The address of the ExtraFi lending pool.
     * @param _lendingPoolMoonwell The address of the Moonwell lending pool.
     */
    constructor(
        IERC20 _asset,
        address _lendingPoolAave,
        address _lendingPoolSeamless,
        address _lendingPoolExtraFi,
        address _lendingPoolMoonwell
    )
        Ownable(msg.sender)
        ReentrancyGuard()
        Pausable()
        ERC4626(_asset)
        ERC20("BESTUSDC Yield Vault", "vFFI")
        LendingManager(address(_asset))
    {
        underlyingAsset = IERC20(_asset);
        lendingPoolAave = _lendingPoolAave;
        lendingPoolSeamless = _lendingPoolSeamless;
        lendingPoolExtraFi = _lendingPoolExtraFi;
        lendingPoolMoonwell = _lendingPoolMoonwell;
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
                balanceOfUSDC() + 1,
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
                balanceOfUSDC() + 1,
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
    )
        public
        virtual
        override
        nonZero(assets)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        // require(
        //     usdcBalance + assets <= MAX_USDC_CAP,
        //     "Vault: Deposit exceeds maximum USDC cap"
        // );
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxDeposit(receiver, assets, maxAssets);
        }

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        _afterDeposit(assets);

        // stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
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
    )
        public
        virtual
        override
        nonZero(shares)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        uint256 assets = previewMint(shares);
        // require(
        //     usdcBalance + assets <= MAX_USDC_CAP,
        //     "Vault: Mint exceeds maximum USDC cap"
        // );

        uint256 maxShares = maxMint(receiver);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxMint(receiver, shares, maxShares);
        }

        _deposit(_msgSender(), receiver, assets, shares);
        // usdcBalance += assets;

        _afterDeposit(assets);
        // stakeTimeEpochMapping[msg.sender] = uint32(block.timestamp);
        return assets;
    }

    /**
     * @dev Internal function to handle post-deposit actions.
     * @param _amount The amount deposited.
     */
    function _afterDeposit(uint256 _amount) internal nonZero(_amount) {
        if (currentProtocol == Protocol.Aave) {
            depositToLendingPool(_amount, address(this), lendingPoolAave);
        } else if (currentProtocol == Protocol.Seamless) {
            depositToLendingPool(_amount, address(this), lendingPoolSeamless);
        } else if (currentProtocol == Protocol.Moonwell) {
            depositToMoonWell(_amount, lendingPoolMoonwell);
        } else if (currentProtocol == Protocol.ExtraFi) {
            depositToExtraFi(25, _amount, address(this), lendingPoolExtraFi);
        } else if (currentProtocol == Protocol.ExtraFi2) {
            depositToExtraFi(24, _amount, address(this), lendingPoolExtraFi);
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
    ) public virtual override nonZero(assets) returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }

        uint256 shares = previewWithdraw(assets);
        uint256 aTokenBalance = getCurrentAtokenBalance();

        uint256 aTokensToWithdraw = (shares * aTokenBalance) / totalSupply();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);

        uint256 amountWithdrawn = _withdrawFromLendingPool(
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
    ) public virtual override nonZero(shares) returns (uint256) {
        uint256 maxShares = maxRedeem(owner);
        if (shares > maxShares) {
            revert ERC4626ExceededMaxRedeem(owner, shares, maxShares);
        }

        // uint256 assets = previewRedeem(shares);
        uint256 aTokenBalance = getCurrentAtokenBalance();

        uint256 aTokensToWithdraw = (shares * aTokenBalance) / totalSupply();

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // usdcBalance -= assets;

        uint256 amountWithdrawn = _withdrawFromLendingPool(
            aTokensToWithdraw,
            receiver
        );
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, amountWithdrawn, shares);

        return amountWithdrawn;
    }

    /**
     * @dev Internal function to handle withdrawal from the lending pool.
     * @param _amount The amount to withdraw.
     * @param _receiver The address receiving the withdrawn assets.
     * @return amountWithdrawn The amount withdrawn.
     */
    function _withdrawFromLendingPool(
        uint256 _amount,
        address _receiver
    ) internal nonZero(_amount) returns (uint256 amountWithdrawn) {
        if (currentProtocol == Protocol.Aave) {
            amountWithdrawn = withdrawFromLendingPool(
                _amount,
                _receiver,
                lendingPoolAave
            );
        } else if (currentProtocol == Protocol.Seamless) {
            amountWithdrawn = withdrawFromLendingPool(
                _amount,
                _receiver,
                lendingPoolSeamless
            );
        } else if (currentProtocol == Protocol.ExtraFi) {
            amountWithdrawn = withdrawFromExtraFi(
                _amount,
                _receiver,
                25,
                lendingPoolExtraFi
            );
        } else if (currentProtocol == Protocol.ExtraFi2) {
            amountWithdrawn = withdrawFromExtraFi(
                _amount,
                _receiver,
                24,
                lendingPoolExtraFi
            );
        } else if (currentProtocol == Protocol.Moonwell) {
            withdrawFromMoonWell(
                _amount,
                // _receiver,
                lendingPoolMoonwell
            );
            amountWithdrawn = IERC20(underlyingAsset).balanceOf(address(this));
            if (_receiver != address(this)) {
                IERC20(underlyingAsset).transfer(
                    _receiver,
                    IERC20(underlyingAsset).balanceOf(address(this))
                );
            }
            emit check(
                amountWithdrawn,
                IERC20(underlyingAsset).balanceOf(_receiver),
                IERC20(underlyingAsset).balanceOf(address(this))
            );
        }
        return amountWithdrawn;
    }

    /**
     * @dev Gets the address of the aToken for the current protocol.
     * @return The address of the aToken.
     */
    function getCurrentAtokenBalance() public view returns (uint256) {
        if (currentProtocol == Protocol.Aave) {
            return
                IERC20(getATokenAddress(lendingPoolAave)).balanceOf(
                    address(this)
                );
        } else if (currentProtocol == Protocol.Seamless) {
            return
                IERC20(getATokenAddress(lendingPoolSeamless)).balanceOf(
                    address(this)
                );
        } else if (currentProtocol == Protocol.Moonwell) {
            return IERC20(lendingPoolMoonwell).balanceOf(address(this));
        }
        // else if (currentProtocol == Protocol.ExtraFi) {
        //     return
        //         IERC20(getATokenAddressOfExtraFi(25, lendingPoolExtraFi))
        //             .balanceOf(address(this));
        // } else if (currentProtocol == Protocol.ExtraFi2) {
        //     return
        //         IERC20(getATokenAddressOfExtraFi(24, lendingPoolExtraFi))
        //             .balanceOf(address(this));
        // }
        revert("Invalid protocol");
    }

    function setProtocol(Protocol _protocol) public {
        currentProtocol = _protocol;
    }

    /*//////////////////////////////////////////////////////////////
                            REBALANCE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Rebalances the vault to a different protocol.
     * @param _protocol The protocol to which funds should be rebalanced.
     */
    function rebalance(Protocol _protocol) external onlyOwner whenNotPaused {
        require(
            _protocol != currentProtocol,
            "Vault: Already using the selected protocol"
        );

        // Get the address of the aToken or equivalent token for the current protocol
        uint256 balanceToRebalance = getCurrentAtokenBalance();

        require(balanceToRebalance > 0, "Vault: No assets to rebalance");

        // Withdraw all assets from the current protocol
        _withdrawFromLendingPool(balanceToRebalance, address(this));

        uint256 assetsToDeposit = IERC20(address(underlyingAsset)).balanceOf(
            address(this)
        );

        require(assetsToDeposit > 0, "Vault: No assets to deposit");

        // Set the current protocol to the new protocol before depositing
        currentProtocol = _protocol;

        // Use the afterDeposit function to deposit the assets into the new protocol
        _afterDeposit(assetsToDeposit);

        // Emit an event for transparency (optional)
        emit Rebalance(_protocol, assetsToDeposit);
    }

    function balanceOfUSDC() public view returns (uint256) {
        uint256 usdcAmount;
        if (currentProtocol == Protocol.Aave) {
            usdcAmount = IERC20(getATokenAddress(lendingPoolAave)).balanceOf(
                address(this)
            );
        } else if (currentProtocol == Protocol.Seamless) {
            usdcAmount = IERC20(getATokenAddress(lendingPoolSeamless))
                .balanceOf(address(this));
        } else if (currentProtocol == Protocol.Moonwell) {
            usdcAmount =
                (IERC20(lendingPoolMoonwell).balanceOf(address(this)) *
                    exchangeRateOfMoonWell(lendingPoolMoonwell)) /
                1e18;
        }
        return usdcAmount;
    }

    /*//////////////////////////////////////////////////////////////
                              ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the referral code for the Aave protocol.
     * @param _referralCode The new referral code.
     */
    function updateReferralCode(uint16 _referralCode) external onlyOwner {
        referralCode = _referralCode;
    }

    /// @notice Pauses deposits and withdraws all funds from the underlying platform
    function panic() public onlyOwner {
        pause();
        _withdrawFromLendingPool(getCurrentAtokenBalance(), address(this));
    }

    /// @notice Pauses deposits but leaves funds still invested
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Unpauses deposits and reinvests any idle funds
    function unpause() external onlyOwner {
        _unpause();

        _afterDeposit(getCurrentAtokenBalance());
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        require(_token != address(underlyingAsset), "!token");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                              FALLBACK FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Fallback function to handle unexpected ether sent to the contract.
     */
    receive() external payable {
        revert("Vault: Cannot accept Ether");
    }

    // TO-DO
    // add whenNotPaused for harvest function
}
