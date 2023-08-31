// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../interface/IRouterState.sol";
import "../interface/IRouterStateGetters.sol";
import "../lib/ExtensionManagerStorage.sol";
import "../lib/StringSet.sol";

contract DefaultExtensionSet is IRouterState, IRouterStateGetters {

    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(Extension[] memory _extensions) {
        uint256 len = _extensions.length;
        for (uint256 i = 0; i < len; i += 1) {
            _addExtension(_extensions[i]);
        }
    } 

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns all extensions of the Router.
    function getAllExtensions() external view override returns (Extension[] memory allExtensions) {

        string[] memory names = _extensionManagerStorage().extensionNames.values();
        uint256 len = names.length;
        
        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = _getExtension(names[i]);
        }
    }

    /// @dev Returns the extension metadata for a given function.
    function getMetadataForFunction(bytes4 functionSelector) public view returns (ExtensionMetadata memory) {
        return _extensionManagerStorage().extensionMetadata[functionSelector];
    }

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) public view returns (Extension memory) {
        return _getExtension(extensionName);
    }


    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the Extension for a given name.
    function _getExtension(string memory _extensionName) internal view returns (Extension memory) {
        return _extensionManagerStorage().extensions[_extensionName];
    }

    /// @dev Adds a new extension to the Router.
    function _addExtension(Extension memory _extension) internal {    
        // Check: extension namespace must not already exist.
        // Check: provided extension namespace must not be empty.
        // Check: provided extension implementation must be non-zero.
        // Store: new extension name.
        require(_canAddExtension(_extension), "ExtensionManager: cannot add extension.");

        // 1. Store: metadata for extension.
        _setMetadataForExtension(_extension.metadata.name, _extension.metadata);

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            // 2. Store: function for extension.
            _enableFunctionInExtension(_extension.metadata.name, _extension.functions[i]);
            // 3. Store: metadata for function.
            _setMetadataForFunction(_extension.functions[i].functionSelector, _extension.metadata);
        }
    }

    /// @dev Returns whether a new extension can be added in the given execution context.
    function _canAddExtension(Extension memory _extension) internal virtual returns (bool) {
        // Check: provided extension namespace must not be empty.
        require(bytes(_extension.metadata.name).length > 0, "ExtensionManager: empty name.");
        
        // Check: extension namespace must not already exist.
        // Store: new extension name.
        require(_extensionManagerStorage().extensionNames.add(_extension.metadata.name), "ExtensionManager: extension already exists.");

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");

        return true;
    }

    /// @dev Sets the ExtensionMetadata for a given extension.
    function _setMetadataForExtension(string memory _extensionName, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensions[_extensionName].metadata = _metadata;
    }

    /// @dev Sets the ExtensionMetadata for a given function.
    function _setMetadataForFunction(bytes4 _functionSelector, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensionMetadata[_functionSelector] = _metadata;
    }

    /// @dev Enables a function in an Extension.
    function _enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _extFunction) internal {
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
        require(
            _extensionManagerStorage().extensionMetadata[_extFunction.functionSelector].implementation == address(0),
            "ExtensionManager: function impl already exists."
        );

        // Store: name -> extension.functions map
        _extensionManagerStorage().extensions[_extensionName].functions.push(_extFunction);
    }

    /// @dev Returns the ExtensionManager storage.
    function _extensionManagerStorage() internal pure returns (ExtensionManagerStorage.Data storage data) {
        data = ExtensionManagerStorage.data();
    }
}