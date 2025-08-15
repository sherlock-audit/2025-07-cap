// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IFractionalReserve } from "../../interfaces/IFractionalReserve.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Fractional Reserve Logic
/// @author kexley, @capLabs
/// @notice Idle capital is put to work in fractional reserve vaults and can be recalled when
/// withdrawing, redeeming or borrowing.
library FractionalReserveLogic {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Loss not allowed from fractional reserve
    error LossFromFractionalReserve(address asset, address vault, uint256 loss);

    /// @dev Fractional reserve vault already set
    error FractionalReserveVaultAlreadySet(address vault);

    /// @dev Fractional reserve invested event
    event FractionalReserveInvested(address indexed asset, uint256 amount);

    /// @dev Fractional reserve divested event
    event FractionalReserveDivested(address indexed asset, uint256 amount);

    /// @dev Fractional reserve vault updated event
    event FractionalReserveVaultUpdated(address indexed asset, address vault);

    /// @dev Fractional reserve reserve updated event
    event FractionalReserveReserveUpdated(address indexed asset, uint256 reserve);

    /// @dev Fractional reserve interest realized event
    event FractionalReserveInterestRealized(address indexed asset);

    /// @notice Invest unborrowed capital in a fractional reserve vault
    /// @param $ Storage pointer
    /// @param _asset Asset address
    function invest(IFractionalReserve.FractionalReserveStorage storage $, address _asset) external {
        uint256 assetBalance = IERC20(_asset).balanceOf(address(this));
        uint256 reserveBalance = $.reserve[_asset];

        if (assetBalance > reserveBalance && $.vault[_asset] != address(0)) {
            uint256 investAmount = assetBalance - reserveBalance;
            $.loaned[_asset] += investAmount;
            IERC20(_asset).forceApprove($.vault[_asset], investAmount);
            IERC4626($.vault[_asset]).deposit(investAmount, address(this));

            emit FractionalReserveInvested(_asset, investAmount);
        }
    }

    /// @notice Divest all from a fractional reserve vault
    /// @param $ Storage pointer
    /// @param _asset Asset address
    function divest(IFractionalReserve.FractionalReserveStorage storage $, address _asset) external {
        if ($.vault[_asset] != address(0)) {
            uint256 loanedAssets = $.loaned[_asset];
            $.loaned[_asset] = 0;

            uint256 vaultBalance = IERC20($.vault[_asset]).balanceOf(address(this));
            if (vaultBalance > 0) {
                uint256 redeemedAssets = IERC4626($.vault[_asset]).redeem(vaultBalance, address(this), address(this));
                if (redeemedAssets > loanedAssets) {
                    IERC20(_asset).safeTransfer($.interestReceiver, redeemedAssets - loanedAssets);
                } else if (redeemedAssets < loanedAssets) {
                    revert LossFromFractionalReserve(_asset, $.vault[_asset], loanedAssets - redeemedAssets);
                }

                emit FractionalReserveDivested(_asset, loanedAssets);
            }
        }
    }

    /// @notice Divest capital from a fractional reserve vault when not enough funds are held in reserve
    /// @param $ Storage pointer
    /// @param _asset Asset address
    /// @param _withdrawAmount Amount to withdraw to fulfil
    function divest(IFractionalReserve.FractionalReserveStorage storage $, address _asset, uint256 _withdrawAmount)
        external
    {
        if ($.vault[_asset] != address(0)) {
            uint256 assetBalance = IERC20(_asset).balanceOf(address(this));

            if (_withdrawAmount > assetBalance) {
                /// Divest both the withdrawal amount and the buffer reserve for later withdrawals
                uint256 divestAmount = _withdrawAmount + $.reserve[_asset] - assetBalance;
                if (divestAmount > $.loaned[_asset]) divestAmount = $.loaned[_asset];
                if (divestAmount > 0) {
                    $.loaned[_asset] -= divestAmount;

                    IERC4626($.vault[_asset]).withdraw(divestAmount, address(this), address(this));

                    if (IERC20(_asset).balanceOf(address(this)) < divestAmount + assetBalance) {
                        uint256 loss = divestAmount + assetBalance - IERC20(_asset).balanceOf(address(this));
                        revert LossFromFractionalReserve(_asset, $.vault[_asset], loss);
                    }
                }

                emit FractionalReserveDivested(_asset, divestAmount);
            }
        }
    }

    /// @notice Set the fractional reserve vault for an asset
    /// @param $ Storage pointer
    /// @param _asset Asset address
    /// @param _vault Fractional reserve vault
    function setFractionalReserveVault(
        IFractionalReserve.FractionalReserveStorage storage $,
        address _asset,
        address _vault
    ) external {
        if ($.vault[_asset] != address(0)) $.vaults.remove($.vault[_asset]);
        if (!$.vaults.add(_vault)) revert FractionalReserveVaultAlreadySet(_vault);
        $.vault[_asset] = _vault;

        emit FractionalReserveVaultUpdated(_asset, _vault);
    }

    /// @notice Set the reserve level for an asset
    /// @param $ Storage pointer
    /// @param _asset Asset address
    /// @param _reserve Reserve level in asset decimals
    function setReserve(IFractionalReserve.FractionalReserveStorage storage $, address _asset, uint256 _reserve)
        external
    {
        $.reserve[_asset] = _reserve;

        emit FractionalReserveReserveUpdated(_asset, _reserve);
    }

    /// @notice Realize interest from a fractional reserve vault
    /// @param $ Storage pointer
    /// @param _asset Asset address
    function realizeInterest(IFractionalReserve.FractionalReserveStorage storage $, address _asset) external {
        IERC4626($.vault[_asset]).withdraw(claimableInterest($, _asset), $.interestReceiver, address(this));

        emit FractionalReserveInterestRealized(_asset);
    }

    /// @notice Interest from a fractional reserve vault
    /// @param $ Storage pointer
    /// @param _asset Asset address
    /// @return interest Claimable amount of asset
    function claimableInterest(IFractionalReserve.FractionalReserveStorage storage $, address _asset)
        public
        view
        returns (uint256 interest)
    {
        uint256 vaultShares = IERC4626($.vault[_asset]).balanceOf(address(this));
        uint256 vaultAssets = IERC4626($.vault[_asset]).convertToAssets(vaultShares);
        interest = vaultAssets > $.loaned[_asset] ? vaultAssets - $.loaned[_asset] : 0;
    }
}
