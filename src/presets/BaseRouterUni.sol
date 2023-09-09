// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Router } from "../core/Router.sol";
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

    /*///////////////////////////////////////////////////////////////
                        View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions of the Router.
     *  @return allExtensions An array of all extensions.
     */
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

        // Traverse defaults and non defaults in same loop.
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

    /**
     *  @notice Returns the extension metadata for a given function.
     *  @param _functionSelector The function selector to get the extension metadata for.
     *  @return metadata The extension metadata for a given function.
     */
    function getMetadataForFunction(bytes4 _functionSelector) public view override returns (ExtensionMetadata memory) {
        ExtensionMetadata memory defaultMetadata = IRouterStateGetters(defaultExtensions).getMetadataForFunction(_functionSelector);
        ExtensionMetadata memory nonDefaultMetadata = _extensionManagerStorage().extensionMetadata[_functionSelector];
        
        return nonDefaultMetadata.implementation != address(0) ? nonDefaultMetadata : defaultMetadata;
    }

    /**
     *  @notice Returns the extension metadata and functions for a given extension.
     *  @param extensionName The name of the extension to get the metadata and functions for.
     *  @return extension The extension metadata and functions for a given extension.
     */
    function getExtension(string memory extensionName) public view override returns (Extension memory) {
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(extensionName);
        Extension memory nonDefaultExt = _extensionManagerStorage().extensions[extensionName];
        
        return bytes(nonDefaultExt.metadata.name).length > 0 ? nonDefaultExt : defaultExt;
    }

    /// @notice Returns the implementation contract address for a given function signature.
    function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getMetadataForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     *  @param _extension The extension to add.
     */
    function addExtension(Extension memory _extension) public override onlyAuthorizedCall {
            
        // If the extension is a default extension and not yet tracked as removed or replaced, revert.
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(_extension.metadata.name);
        if(defaultExt.metadata.implementation != address(0) && !_baseRouterStorage().isRemovedOrReplaced[_extension.metadata.name]) {
            revert("BaseRouter: extension already exists.");
        }
    
        _addExtension(_extension);
    }

    /**
     *  @notice Fully replace an existing extension of the router.
     *  @dev The extension with name `extension.name` is the extension being replaced.
     *  @param _extension The extension to replace or overwrite.
     */
    function replaceExtension(Extension memory _extension) public override onlyAuthorizedCall {

        // If the extension is a default extension and not yet tracked as removed or replaced, track it as replaced for the first time.
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(_extension.metadata.name);
        if(defaultExt.metadata.implementation != address(0) && !_baseRouterStorage().isRemovedOrReplaced[_extension.metadata.name]) {
            _baseRouterStorage().isRemovedOrReplaced[_extension.metadata.name] = true;

            _addExtension(_extension);
        } else {
            _replaceExtension(_extension);
        }
    }

    /**
     *  @notice Remove an existing extension from the router.
     *  @param _extensionName The name of the extension to remove.
     */
    function removeExtension(string memory _extensionName) public override onlyAuthorizedCall {
            
        // If the extension is a default extension and not yet tracked as removed or replaced, track it as removed for the first time.
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(_extensionName);
        if(defaultExt.metadata.implementation != address(0) && !_baseRouterStorage().isRemovedOrReplaced[_extensionName]) {
            _baseRouterStorage().isRemovedOrReplaced[_extensionName] = true;
        }
    
        _removeExtension(_extensionName);
    }

    /**
     *  @notice Enables a single function in an existing extension.
     *  @dev Makes the given function callable on the router.
     *
     *  @param _extensionName The name of the extension to which `extFunction` belongs.
     *  @param _function The function to enable.
     */
    function enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) public override onlyAuthorizedCall {
        // If the extension is a default extension and not yet tracked as removed or replaced, track it as replaced for the first time.
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(_extensionName);

        if(defaultExt.metadata.implementation != address(0) && !_baseRouterStorage().isRemovedOrReplaced[_extensionName]) {
            _baseRouterStorage().isRemovedOrReplaced[_extensionName] = true;

            Extension memory newExt = Extension({
                metadata: defaultExt.metadata,
                functions: new ExtensionFunction[](defaultExt.functions.length + 1)
            });
            for(uint256 i = 0; i < defaultExt.functions.length; i += 1) {
                newExt.functions[i] = defaultExt.functions[i];
            }
            newExt.functions[defaultExt.functions.length] = _function;

            _addExtension(defaultExt);
        } else {
            _enableFunctionInExtension(_extensionName, _function);
        }
    }

    /**
     *  @notice Disables a single function in an Extension.
     *
     *  @param _extensionName The name of the extension to which the function of `functionSelector` belongs.
     *  @param _functionSelector The function to disable.
     */
    function disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) public override onlyAuthorizedCall {
        // If the extension is a default extension and not yet tracked as removed or replaced, track it as replaced for the first time.
        Extension memory defaultExt = IRouterStateGetters(defaultExtensions).getExtension(_extensionName);

        if(defaultExt.metadata.implementation != address(0) && !_baseRouterStorage().isRemovedOrReplaced[_extensionName]) {
            _baseRouterStorage().isRemovedOrReplaced[_extensionName] = true;

            uint256 len = defaultExt.functions.length > 0 ? defaultExt.functions.length - 1 : 0;
            Extension memory newExt = Extension({
                metadata: defaultExt.metadata,
                functions: new ExtensionFunction[](len)
            });

            uint256 idx = 0;
            for(uint256 i = 0; i < defaultExt.functions.length; i += 1) {

                if(defaultExt.functions[i].functionSelector == _functionSelector) {
                    continue;
                }
                newExt.functions[idx] = defaultExt.functions[i];
                idx += 1;
            }

            _addExtension(defaultExt);
        } else {
            _disableFunctionInExtension(_extensionName, _functionSelector);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the BaseRouter storage.
    function _baseRouterStorage() internal pure returns (BaseRouterStorage.Data storage data) {
        data = BaseRouterStorage.data();
    }
}