// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title BaseRouterStorage
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage for the base router preset.

library BaseRouterStorage {

    /// @custom:storage-location erc7201:base.router.storage
    bytes32 public constant BASE_ROUTER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("base.router.storage")) - 1));

    struct Data {
        /// @dev Mapping from default extension name -> whether the extension has been removed or replaced at least once.
        mapping(string => bool) isRemovedOrReplaced;
    }

    /// @dev Returns access to the extension manager's storage.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = BASE_ROUTER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}