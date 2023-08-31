// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StringSet.sol";
import "../interface/IExtension.sol";

/// @title IExtensionManagerStorage
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage for managing a router's extensions.

library ExtensionManagerStorage {

    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant EXTENSION_MANAGER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("extension.manager.storage")) - 1));

    struct Data {
        /// @dev Set of names of all extensions of the router.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        /// @dev Mapping from function selector => metadata of the extension the function belongs to.
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
    }

    /// @dev Returns access to the extension manager's storage.
    function data() internal pure returns (Data storage data_) {
        bytes32 position = EXTENSION_MANAGER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}