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

    /// @dev Mapping used only for checking default extension validity in constructor.
    mapping(bytes4 => bool) functionMap;
    /// @dev Mapping used only for checking default extension validity in constructor.
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

        bool isValid = true;

        for (uint256 i = 0; i < len; i += 1) {
            isValid = _isValidExtension(_extensions[i]);
            if(!isValid) {
                break;
            }
        }
        require(isValid, "BaseRouter: invalid extension.");
    }

    function _isValidExtension(Extension memory _extension) internal returns (bool isValid) {
        isValid  = bytes(_extension.metadata.name).length > 0 // non-empty name
            && !extensionMap[_extension.metadata.name] // unused name
            && _extension.metadata.implementation != address(0); // non-empty implementation
        
        extensionMap[_extension.metadata.name] = true;

        if(!isValid) {
            return false;
        }
        
        uint256 len = _extension.functions.length;

        for(uint256 i = 0; i < len; i += 1) {

            if(!isValid) {
                break;
            }

            ExtensionFunction memory _extFunction = _extension.functions[i];

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

            // No fn signature-selector mismatch and no duplicate function.
            isValid = !mismatch && !functionMap[_extFunction.functionSelector];
            
            functionMap[_extFunction.functionSelector] = true;
        }
    }
}