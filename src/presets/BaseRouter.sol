// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Router, IRouter } from "../core/Router.sol";
import { IRouterState } from "../interface/IRouterState.sol";
import { IRouterStateGetters } from "../interface/IRouterStateGetters.sol";
import { ExtensionManager } from "./ExtensionManager.sol";
import { StringSet } from "../lib/StringSet.sol";
import "lib/sstore2/contracts/SSTORE2.sol";

/// @title BaseRouter
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice A router with an API to manage its extensions.

abstract contract BaseRouter is Router, ExtensionManager {

    using StringSet for StringSet.Set;
    mapping(bytes4 => bool) functionMap;
    mapping(string => bool) extensionMap;

    /// @notice The address where the router's default extension set is stored.
    address public immutable defaultExtensions;
    
    /// @notice Initialize the Router with a set of default extensions.
    constructor(Extension[] memory _extensions) {
        address pointer;
        if(_extensions.length > 0) {
            _validateExtensions(_extensions);
            pointer = SSTORE2.write(abi.encode(_extensions));
        }

        defaultExtensions = pointer;
    }

    /// @notice Initialize the Router with a set of default extensions.
    function __BaseRouter_init() internal {
        if(defaultExtensions == address(0)) {
            return;
        }
        
        bytes memory data = SSTORE2.read(defaultExtensions);
        Extension[] memory defaults = abi.decode(data, (Extension[]));

        for(uint256 i = 0; i < defaults.length; i += 1) {

            Extension memory extension = defaults[i];
            // Store: new extension name.
            _extensionManagerStorage().extensionNames.add(extension.metadata.name);

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

    /// @dev Validates default extensions.
    function _validateExtensions(Extension[] memory _extensions) internal {  
        uint256 len = _extensions.length;
        for (uint256 i = 0; i < len; i += 1) {
            // Check: extension namespace must not already exist.
            // Check: provided extension namespace must not be empty.
            // Check: provided extension implementation must be non-zero.
            _checkExtensionValidity(_extensions[i]);

            uint256 len = _extensions[i].functions.length;
            for (uint256 j = 0; j < len; j += 1) {
                _checkFunctionValidity(_extensions[i].functions[j]);
            }
        }
    }

    /// @dev Checks whether a new extension can be added in the given execution context.
    function _checkExtensionValidity(Extension memory _extension) internal virtual {
        // Check: provided extension namespace must not be empty.
        require(bytes(_extension.metadata.name).length > 0, "ExtensionManager: empty name.");

        require(!extensionMap[_extension.metadata.name], "ExtensionManager: extension exists.");
        extensionMap[_extension.metadata.name] = true;

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");
    }

    /// @dev Validates a function in an Extension.
    function _checkFunctionValidity(ExtensionFunction memory _extFunction) internal {
        /**
         *  Note: `bytes4(0)` is the function selector for the `receive` function.
         *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
        **/
        bool mismatch = false;
        if(_extFunction.functionSelector == bytes4(0)) {
            mismatch = keccak256(abi.encode(_extFunction.functionSignature)) != keccak256(abi.encode("receive()"));
        } else {
            mismatch = _extFunction.functionSelector !=
                bytes4(keccak256(abi.encodePacked(_extFunction.functionSignature)));
        }
            
        // Check: function selector and signature must match.
        require(
            !mismatch,
            "ExtensionManager: fn selector and signature mismatch."
        );
        // Check: function must not already be mapped to an implementation.
        require(!functionMap[_extFunction.functionSelector], "ExtensionManager: function exists.");
        functionMap[_extFunction.functionSelector] = true;
    }
}