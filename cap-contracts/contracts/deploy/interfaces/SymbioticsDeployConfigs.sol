// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

struct SymbioticNetworkAdapterImplementationsConfig {
    address network;
    address networkMiddleware;
    address agentManager;
}

struct SymbioticNetworkAdapterConfig {
    address network;
    address networkMiddleware;
    address agentManager;
    uint256 feeAllowed;
    address vaultFactory;
    address decreaseHook;
}

struct SymbioticNetworkRewardsConfig {
    address stakerRewarder;
}

struct SymbioticNetworkAdapterParams {
    uint48 vaultEpochDuration;
    uint256 feeAllowed;
}

struct SymbioticUsersConfig {
    address vault_admin;
}

struct SymbioticVaultParams {
    address vault_admin;
    address collateral;
    uint48 vaultEpochDuration;
    uint48 burnerRouterDelay;
    address agent;
    address network;
}

struct SymbioticVaultConfig {
    address vault;
    address collateral;
    address burnerRouter;
    address globalReceiver;
    address delegator;
    address slasher;
    uint48 vaultEpochDuration;
}
