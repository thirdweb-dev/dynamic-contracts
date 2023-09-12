// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Router, IRouter } from "../core/Router.sol";
import { IRouterState } from "../interface/IRouterState.sol";
import { IRouterStateGetters } from "../interface/IRouterStateGetters.sol";
import { ExtensionManager } from "./ExtensionManager.sol";
import { DefaultExtensionSet } from "./DefaultExtensionSet.sol";
import { BaseRouterStorage } from "../lib/BaseRouterStorage.sol";
import { StringSet } from "../lib/StringSet.sol";

/// @title BaseRouter
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice A router with an API to manage its extensions.

abstract contract BaseRouterUni is Router, ExtensionManager {

    using StringSet for StringSet.Set;

    /// @notice The address where the router's default extension set is stored.
    address public immutable defaultExtensions;
    
    /// @notice Initialize the Router with a set of default extensions.
    constructor(Extension[] memory _extensions) {
        address defaultExtensionsAddr = _extensions.length > 0 ? address(new DefaultExtensionSet(_extensions)) : address(0);
        defaultExtensions = defaultExtensionsAddr;
    }

    /// @notice Initialize the Router with a set of default extensions.
    function __BaseRouter_init() internal {
        Extension[] memory defaults = IRouterState(defaultExtensions).getAllExtensions();

        for(uint256 i = 0; i < defaults.length; i += 1) {

            Extension memory extension = defaults[i];
            // Store: new extension name.
        require(_extensionManagerStorage().extensionNames.add(extension.metadata.name), "ExtensionManager: extension already exists.");

            // 1. Store: metadata for extension.
            _setMetadataForExtension(extension.metadata.name, extension.metadata);
            uint256 len = extension.functions.length;
            for (uint256 j = 0; j < len; j += 1) {
                // 2. Store: function for extension.
                _addToFunctionMap(extension.metadata.name, extension.functions[j]);
                // 3. Store: metadata for function.
                _setMetadataForFunction(extension.functions[j].functionSelector, extension.metadata);
            }

            emit ExtensionAdded(extension.metadata.name, extension.metadata.implementation, extension);
        }
    }

    /// @notice Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getMetadataForFunction(_functionSelector).implementation;
    }
}