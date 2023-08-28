// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../core/Router.sol";
import "./ExtensionManager.sol";
import "./DefaultExtensionSet.sol";

contract BaseRouterWithDefaults is Router, ExtensionManager {

    using StringSet for StringSet.Set;

    address public immutable defaultExtensions;

    constructor(Extension[] memory _extensions) {
        defaultExtensions = address(new DefaultExtensionSet(_extensions));
    }

    /*///////////////////////////////////////////////////////////////
                        Overriden view functions
    //////////////////////////////////////////////////////////////*/


    /// @notice Returns all extensions of the Router.
    function getAllExtensions() external view override returns (Extension[] memory allExtensions) {

        Extension[] memory defaults = IRouterState(defaultExtensions).getAllExtensions();
        string[] memory names = _extensionManagerStorage().extensionNames.values();

        uint256 total = defaults.length + names.length;
        uint256 overrides = 0;

        // Count number of overrides.
        for(uint256 i = 0; i < defaults.length; i += 1) {
            if (_extensionManagerStorage().extensionNames.contains(defaults[i].metadata.name)) {
                overrides += 1;
            }
        }
        
        allExtensions = new Extension[](total - overrides);
        uint256 idx = 0;

        // Travers defaults and non defaults in same loop.
        for(uint256 j = 0; j < total; j += 1) {
            if(j < defaults.length) {
                if (!_extensionManagerStorage().extensionNames.contains(defaults[j].metadata.name)) {
                    allExtensions[idx] = defaults[j];
                    idx += 1;
                }
            } else {
                allExtensions[idx] = _getExtension(names[j - defaults.length]);
                idx += 1;
            }
        }
    }

    /// @notice Returns the extension metadata for a given function.
    function getMetadataForFunction(bytes4 _functionSelector) public view override returns (ExtensionMetadata memory) {
        ExtensionMetadata memory defaultMetadata = IRouterStateGetters(defaultExtensions).getMetadataForFunction(_functionSelector);
        ExtensionMetadata memory nonDefaultMetadata = _extensionManagerStorage().extensionMetadata[_functionSelector];
        
        return nonDefaultMetadata.implementation != address(0) ? nonDefaultMetadata : defaultMetadata;
    }

    /// @notice Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) public view override returns (Extension memory) {
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(extensionName);
        Extension memory nonDefaultExt = _extensionManagerStorage().extensions[extensionName];
        
        return bytes(nonDefaultExt.metadata.name).length > 0 ? nonDefaultExt : defaultExt;
    }

    /// @notice Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        
        address defaultImpl = IRouterStateGetters(defaultExtensions).getMetadataForFunction(_functionSelector).implementation;
        address nonDefaultImpl = _extensionManagerStorage().extensionMetadata[_functionSelector].implementation;
        
        return nonDefaultImpl != address(0) ? nonDefaultImpl : defaultImpl;
    }

    /*///////////////////////////////////////////////////////////////
                        Overriden internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a given function to an Extension.
    function _addFunctionToExtension(string memory _extensionName, ExtensionFunction memory _extFunction) internal virtual override {

        string memory name = IRouterStateGetters(defaultExtensions).getMetadataForFunction(_extFunction.functionSelector).name;
        bytes32 fnHash = keccak256(abi.encode(name));
        require(
            bytes(name).length == 0 || fnHash == keccak256(abi.encode(_extensionName)),
            "ExtensionManager: fn implemented under different default extension."
        );

        super._addFunctionToExtension(_extensionName, _extFunction);
    }

    /// @dev Returns whether a new extension can be added in the given execution context.
    function _canAddExtension(Extension memory _extension) internal virtual override returns (bool) {

        // Check: extension namespace is not already in use as a default.
        string memory name = _extension.metadata.name;
        require(
            bytes(IRouterStateGetters(defaultExtensions).getExtension(name).metadata.name).length == 0,
            "BaseRouterWithDefaults: re-adding a default extension."
        );

        return super._canAddExtension(_extension);
    }

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory _extension) internal view virtual override returns (bool) {
        // Check: extension namespace must already exist -- as default, or in router.
        string memory name = _extension.metadata.name;
        bool isDefault = bytes(IRouterStateGetters(defaultExtensions).getExtension(name).metadata.name).length > 0;
        bool isAddedAsNonDefault = _extensionManagerStorage().extensionNames.contains(name);

        require(isDefault || isAddedAsNonDefault, "ExtensionManager: extension does not exist.");

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");

        return true;
    }
}