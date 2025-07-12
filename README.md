# Cap contest details

- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the **Issues** page in your private contest repo (label issues as **Medium** or **High**)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
Ethereum
___

### Q: If you are integrating tokens, are you allowing only whitelisted tokens to work with the codebase or any complying with the standard? Are they assumed to have certain properties, e.g. be non-reentrant? Are there any types of [weird tokens](https://github.com/d-xo/weird-erc20) you want to integrate?
We are integrating stablecoins like USDC, USDT, pyUSD. All ERC20, no weird tokens. 
___

### Q: Are there any limitations on values set by admins (or other roles) in the codebase, including restrictions on array lengths?
Owner and admin is trusted, and will correctly adjust settings. 
___

### Q: Are there any limitations on values set by admins (or other roles) in protocols you integrate with, including restrictions on array lengths?
No
___

### Q: Is the codebase expected to comply with any specific EIPs?
stcUSD is ERC4626, cUSD is ERC20.
___

### Q: Are there any off-chain mechanisms involved in the protocol (e.g., keeper bots, arbitrage bots, etc.)? We assume these mechanisms will not misbehave, delay, or go offline unless otherwise specified.
We expect MEV to handle the liquidations and feeAuction distributions in a timely manner, we will have automation to backstop this
___

### Q: What properties/invariants do you want to hold even if breaking them has a low/unknown impact?
No
___

### Q: Please discuss any design choices you made.
In stcUSD we have a 24 hour linear release of rewards, I know that this is not 100% fair for all parties but we see this a more fair distribution then other options. 

We have a fractional reserve which allows the unused funds to still earn via an underlying strategy. There is a known issue that the last withdraw can revert since we can get 1 wei less funds back. We will seed the vault with 1 wei to offset this. Also this fractional reserve will be a yVault that has 1 depositor which is our vault. This is locked to just our vault as depositor and is completely owned and run by the cap team. 

We will have a symbiotic vault factory that will be used to remove some features from the symbiotic vaults to add risk to the system. This includes having the burner router admin be address(0). It also will require instant slashing. Each vault gets added by the admin and will be expected to have the correct config. 

The epoch in the delegation contract is not the same as the epoch on the symbiotic contracts. The delegation epoch will be shorter than the symbiotic epoch as its purpose is to find us a slashable timestamp in which delegations were backing the borrow. 

The mint fees are to counter the possibility of sandwiching a chainlink price update, so it will be set 2x the deviation of the largest asset update deviation from chainlink. We would trust parties that are whitelist for 0 mint fee. The fees are use to repay an system bad debt. 

We have the ability to use funds in the vault to realize interest for both the stcUSD token and restakers. These are in two different functions, realizeRestakerInterest and realizeInterest. We also know that the interest rate can differ when realizeRestakerInterest is called by adding to the vault debt. This is because the restaker interest is a fixed rate and the underlying rate is variable.

There is an edge case where the added debt tokens of all parties are greater than the total supply of the debt token by 1 wei. This is a known issue in using the index to calc balances. It doesnt cause a systemic issue. 
___

### Q: Please provide links to previous audits (if any) and all the known issues or acceptable risks.
- [CAP Security Cartel](https://sherlock-files.ams3.digitaloceanspaces.com/contest-qa/cap-audit-sec-cal-12.pdf)
- https://docs.cap.app/resources/audits
___

### Q: Please list any relevant protocol resources.
https://docs.cap.app/
https://docs.google.com/document/d/1cm1q4JOjvcuDQwnFNuIpL1DVfbYa2uSSqiyUYVxkLXI/edit?tab=t.0
___

### Q: Additional audit information.
A deep look at the symbiotic integration, and the open functions of Mint, Burn, Redeem, Liquidate, Repay, RealizeInterest and RealizeRestakerInterest. 
Changed severity definitions that will apply to this contest:
High severity:

Direct loss of protocol TVL without (extensive) limitations of external conditions. The loss of the protocol TVL must exceed >1%. This can include >1% of the individual user cUSD collateral that is uniform at any size of user deposit (min $10 requirement still applies).

That means if the issue leads to loss of yield or fees, then it's not sufficient for High severity.

Medium severity:

Causes a loss of funds but requires certain external conditions or specific states, or a loss is highly constrained. The loss must be relevant to the affected party.

Breaks core contract functionality, rendering the contract useless or leading to loss of funds that's relevant to the affected party.

Any yield or fees losses >0.01% are considered Medium. Hence, if the issue leads to a 50% loss of yield or fees, then it's still Medium severity.


# Audit scope

[cap-contracts @ 0a57fbfdba7f54e516b5ed412548b7e415f3739d](https://github.com/cap-labs-dev/cap-contracts/tree/0a57fbfdba7f54e516b5ed412548b7e415f3739d)
- [cap-contracts/contracts/access/Access.sol](cap-contracts/contracts/access/Access.sol)
- [cap-contracts/contracts/access/AccessControl.sol](cap-contracts/contracts/access/AccessControl.sol)
- [cap-contracts/contracts/delegation/Delegation.sol](cap-contracts/contracts/delegation/Delegation.sol)
- [cap-contracts/contracts/delegation/providers/symbiotic/SymbioticNetwork.sol](cap-contracts/contracts/delegation/providers/symbiotic/SymbioticNetwork.sol)
- [cap-contracts/contracts/delegation/providers/symbiotic/SymbioticNetworkMiddleware.sol](cap-contracts/contracts/delegation/providers/symbiotic/SymbioticNetworkMiddleware.sol)
- [cap-contracts/contracts/feeAuction/FeeAuction.sol](cap-contracts/contracts/feeAuction/FeeAuction.sol)
- [cap-contracts/contracts/lendingPool/Lender.sol](cap-contracts/contracts/lendingPool/Lender.sol)
- [cap-contracts/contracts/lendingPool/libraries/BorrowLogic.sol](cap-contracts/contracts/lendingPool/libraries/BorrowLogic.sol)
- [cap-contracts/contracts/lendingPool/libraries/LiquidationLogic.sol](cap-contracts/contracts/lendingPool/libraries/LiquidationLogic.sol)
- [cap-contracts/contracts/lendingPool/libraries/ReserveLogic.sol](cap-contracts/contracts/lendingPool/libraries/ReserveLogic.sol)
- [cap-contracts/contracts/lendingPool/libraries/ValidationLogic.sol](cap-contracts/contracts/lendingPool/libraries/ValidationLogic.sol)
- [cap-contracts/contracts/lendingPool/libraries/ViewLogic.sol](cap-contracts/contracts/lendingPool/libraries/ViewLogic.sol)
- [cap-contracts/contracts/lendingPool/libraries/configuration/AgentConfiguration.sol](cap-contracts/contracts/lendingPool/libraries/configuration/AgentConfiguration.sol)
- [cap-contracts/contracts/lendingPool/libraries/math/MathUtils.sol](cap-contracts/contracts/lendingPool/libraries/math/MathUtils.sol)
- [cap-contracts/contracts/lendingPool/libraries/math/PercentageMath.sol](cap-contracts/contracts/lendingPool/libraries/math/PercentageMath.sol)
- [cap-contracts/contracts/lendingPool/libraries/math/WadRayMath.sol](cap-contracts/contracts/lendingPool/libraries/math/WadRayMath.sol)
- [cap-contracts/contracts/lendingPool/tokens/DebtToken.sol](cap-contracts/contracts/lendingPool/tokens/DebtToken.sol)
- [cap-contracts/contracts/lendingPool/tokens/base/MintableERC20.sol](cap-contracts/contracts/lendingPool/tokens/base/MintableERC20.sol)
- [cap-contracts/contracts/lendingPool/tokens/base/ScaledToken.sol](cap-contracts/contracts/lendingPool/tokens/base/ScaledToken.sol)
- [cap-contracts/contracts/oracle/Oracle.sol](cap-contracts/contracts/oracle/Oracle.sol)
- [cap-contracts/contracts/oracle/PriceOracle.sol](cap-contracts/contracts/oracle/PriceOracle.sol)
- [cap-contracts/contracts/oracle/RateOracle.sol](cap-contracts/contracts/oracle/RateOracle.sol)
- [cap-contracts/contracts/oracle/libraries/AaveAdapter.sol](cap-contracts/contracts/oracle/libraries/AaveAdapter.sol)
- [cap-contracts/contracts/oracle/libraries/CapTokenAdapter.sol](cap-contracts/contracts/oracle/libraries/CapTokenAdapter.sol)
- [cap-contracts/contracts/oracle/libraries/ChainlinkAdapter.sol](cap-contracts/contracts/oracle/libraries/ChainlinkAdapter.sol)
- [cap-contracts/contracts/oracle/libraries/VaultAdapter.sol](cap-contracts/contracts/oracle/libraries/VaultAdapter.sol)
- [cap-contracts/contracts/storage/AccessStorageUtils.sol](cap-contracts/contracts/storage/AccessStorageUtils.sol)
- [cap-contracts/contracts/storage/DebtTokenStorageUtils.sol](cap-contracts/contracts/storage/DebtTokenStorageUtils.sol)
- [cap-contracts/contracts/storage/DelegationStorageUtils.sol](cap-contracts/contracts/storage/DelegationStorageUtils.sol)
- [cap-contracts/contracts/storage/FeeAuctionStorageUtils.sol](cap-contracts/contracts/storage/FeeAuctionStorageUtils.sol)
- [cap-contracts/contracts/storage/FractionalReserveStorageUtils.sol](cap-contracts/contracts/storage/FractionalReserveStorageUtils.sol)
- [cap-contracts/contracts/storage/LenderStorageUtils.sol](cap-contracts/contracts/storage/LenderStorageUtils.sol)
- [cap-contracts/contracts/storage/MintableERC20StorageUtils.sol](cap-contracts/contracts/storage/MintableERC20StorageUtils.sol)
- [cap-contracts/contracts/storage/MinterStorageUtils.sol](cap-contracts/contracts/storage/MinterStorageUtils.sol)
- [cap-contracts/contracts/storage/PriceOracleStorageUtils.sol](cap-contracts/contracts/storage/PriceOracleStorageUtils.sol)
- [cap-contracts/contracts/storage/RateOracleStorageUtils.sol](cap-contracts/contracts/storage/RateOracleStorageUtils.sol)
- [cap-contracts/contracts/storage/ScaledTokenStorageUtils.sol](cap-contracts/contracts/storage/ScaledTokenStorageUtils.sol)
- [cap-contracts/contracts/storage/StakedCapStorageUtils.sol](cap-contracts/contracts/storage/StakedCapStorageUtils.sol)
- [cap-contracts/contracts/storage/SymbioticNetworkMiddlewareStorageUtils.sol](cap-contracts/contracts/storage/SymbioticNetworkMiddlewareStorageUtils.sol)
- [cap-contracts/contracts/storage/SymbioticNetworkStorageUtils.sol](cap-contracts/contracts/storage/SymbioticNetworkStorageUtils.sol)
- [cap-contracts/contracts/storage/VaultAdapterStorageUtils.sol](cap-contracts/contracts/storage/VaultAdapterStorageUtils.sol)
- [cap-contracts/contracts/storage/VaultStorageUtils.sol](cap-contracts/contracts/storage/VaultStorageUtils.sol)
- [cap-contracts/contracts/token/CapToken.sol](cap-contracts/contracts/token/CapToken.sol)
- [cap-contracts/contracts/token/StakedCap.sol](cap-contracts/contracts/token/StakedCap.sol)
- [cap-contracts/contracts/vault/FractionalReserve.sol](cap-contracts/contracts/vault/FractionalReserve.sol)
- [cap-contracts/contracts/vault/Minter.sol](cap-contracts/contracts/vault/Minter.sol)
- [cap-contracts/contracts/vault/Vault.sol](cap-contracts/contracts/vault/Vault.sol)
- [cap-contracts/contracts/vault/libraries/FractionalReserveLogic.sol](cap-contracts/contracts/vault/libraries/FractionalReserveLogic.sol)
- [cap-contracts/contracts/vault/libraries/MinterLogic.sol](cap-contracts/contracts/vault/libraries/MinterLogic.sol)
- [cap-contracts/contracts/vault/libraries/VaultLogic.sol](cap-contracts/contracts/vault/libraries/VaultLogic.sol)


