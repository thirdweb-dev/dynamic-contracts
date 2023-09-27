// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IExtensionManager.sol";
import "../interface/IRouterState.sol";
import "../interface/IRouterStateGetters.sol";
import "../lib/ExtensionManagerStorage.sol";

/// @title ExtensionManager
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage and API for managing a router's extensions.

abstract contract ExtensionManager is IExtensionManager, IRouterState, IRouterStateGetters {

    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            Modifier
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks that a call to any external function is authorized.
    modifier onlyAuthorizedCall() {
        require(_isAuthorizedCallToUpgrade(), "ExtensionManager: unauthorized.");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions of the Router.
     *  @return allExtensions An array of all extensions.
     */
    function getAllExtensions() external view virtual override returns (Extension[] memory allExtensions) {

        string[] memory names = _extensionManagerStorage().extensionNames.values();
        uint256 len = names.length;
        
        allExtensions = new Extension[](len);

        for (uint256 i = 0; i < len; i += 1) {
            allExtensions[i] = _getExtension(names[i]);
        }
    }

    /**
     *  @notice Returns the extension metadata for a given function.
     *  @param functionSelector The function selector to get the extension metadata for.
     *  @return metadata The extension metadata for a given function.
     */
    function getMetadataForFunction(bytes4 functionSelector) public view virtual returns (ExtensionMetadata memory) {
        return _extensionManagerStorage().extensionMetadata[functionSelector];
    }

    /**
     *  @notice Returns the extension metadata and functions for a given extension.
     *  @param extensionName The name of the extension to get the metadata and functions for.
     *  @return extension The extension metadata and functions for a given extension.
     */
    function getExtension(string memory extensionName) public view virtual returns (Extension memory) {
        return _getExtension(extensionName);
    }

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     *  @param _extension The extension to add.
     */
    function addExtension(Extension memory _extension) public virtual onlyAuthorizedCall {    
        _addExtension(_extension);
    }

    /**
     *  @notice Fully replace an existing extension of the router.
     *  @dev The extension with name `extension.name` is the extension being replaced.
     *  @param _extension The extension to replace or overwrite.
     */
    function replaceExtension(Extension memory _extension) public virtual onlyAuthorizedCall {
        _replaceExtension(_extension);
    }

    /**
     *  @notice Remove an existing extension from the router.
     *  @param _extensionName The name of the extension to remove.
     */
    function removeExtension(string memory _extensionName) public virtual onlyAuthorizedCall {
        _removeExtension(_extensionName);
    }

    /**
     *  @notice Enables a single function in an existing extension.
     *  @dev Makes the given function callable on the router.
     *
     *  @param _extensionName The name of the extension to which `extFunction` belongs.
     *  @param _function The function to enable.
     */
    function enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) public virtual onlyAuthorizedCall {
        _enableFunctionInExtension(_extensionName, _function);
    }

    /**
     *  @notice Disables a single function in an Extension.
     *
     *  @param _extensionName The name of the extension to which the function of `functionSelector` belongs.
     *  @param _functionSelector The function to disable.
     */
    function disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) public virtual onlyAuthorizedCall {
        _disableFunctionInExtension(_extensionName, _functionSelector);
    }
    
    /*///////////////////////////////////////////////////////////////
                            Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Add a new extension to the router.
    function _addExtension(Extension memory _extension) internal virtual {    
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
            _addToFunctionMap(_extension.metadata.name, _extension.functions[i]);
            // 3. Store: metadata for function.
            _setMetadataForFunction(_extension.functions[i].functionSelector, _extension.metadata);
        }

        emit ExtensionAdded(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @dev Fully replace an existing extension of the router.
    function _replaceExtension(Extension memory _extension) internal virtual {
        // Check: extension namespace must already exist.
        // Check: provided extension implementation must be non-zero.
        require(_canReplaceExtension(_extension), "ExtensionManager: cannot replace extension.");
        
        // 1. Store: metadata for extension.
        _setMetadataForExtension(_extension.metadata.name, _extension.metadata);
        // 2. Delete: existing extension.functions and metadata for each function.
        _removeAllFunctionsFromExtension(_extension.metadata.name);
        
        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            // 2. Store: function for extension.
            _addToFunctionMap(_extension.metadata.name, _extension.functions[i]);
            // 3. Store: metadata for function.
            _setMetadataForFunction(_extension.functions[i].functionSelector, _extension.metadata);
        }

        emit ExtensionReplaced(_extension.metadata.name, _extension.metadata.implementation, _extension);
    }

    /// @dev Remove an existing extension from the router.
    function _removeExtension(string memory _extensionName) internal virtual {
        // Check: extension namespace must already exist.
        // Delete: extension namespace.
        require(_canRemoveExtension(_extensionName), "ExtensionManager: cannot remove extension.");

        Extension memory extension = _extensionManagerStorage().extensions[_extensionName];

        // 1. Delete: metadata for extension.
        _deleteMetadataForExtension(_extensionName);
        // 2. Delete: existing extension.functions and metadata for each function.
        _removeAllFunctionsFromExtension(_extensionName);

        emit ExtensionRemoved(_extensionName, extension);
    }

    /// @dev Makes the given function callable on the router.
    function _enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) internal virtual {
        // Check: extension namespace must already exist.
        require(_canEnableFunctionInExtension(_extensionName, _function), "ExtensionManager: cannot Store: function for extension.");
        
        // 1. Store: function for extension.
        _addToFunctionMap(_extensionName, _function);

        ExtensionMetadata memory metadata = _extensionManagerStorage().extensions[_extensionName].metadata;
        // 2. Store: metadata for function.
        _setMetadataForFunction(_function.functionSelector, metadata);

        emit FunctionEnabled(_extensionName, _function.functionSelector, _function, metadata);
    }

    /// @dev Disables a single function in an Extension.
    function _disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) public virtual onlyAuthorizedCall {
        // Check: extension namespace must already exist.
        // Check: function must be mapped to provided extension.
        require(_canDisableFunctionInExtension(_extensionName, _functionSelector), "ExtensionManager: cannot remove function from extension.");
    
        ExtensionMetadata memory extMetadata = _extensionManagerStorage().extensionMetadata[_functionSelector];

        // 1. Delete: function from extension.
        _deleteFromFunctionMap(_extensionName, _functionSelector);
        // 2. Delete: metadata for function.
        _deleteMetadataForFunction(_functionSelector);

        emit FunctionDisabled(_extensionName, _functionSelector, extMetadata);
    }

    /// @dev Returns the Extension for a given name.
    function _getExtension(string memory _extensionName) internal view returns (Extension memory) {
        return _extensionManagerStorage().extensions[_extensionName];
    }

    /// @dev Sets the ExtensionMetadata for a given extension.
    function _setMetadataForExtension(string memory _extensionName, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensions[_extensionName].metadata = _metadata;
    }

    /// @dev Deletes the ExtensionMetadata for a given extension.
    function _deleteMetadataForExtension(string memory _extensionName) internal {
        delete _extensionManagerStorage().extensions[_extensionName].metadata;
    }

    /// @dev Sets the ExtensionMetadata for a given function.
    function _setMetadataForFunction(bytes4 _functionSelector, ExtensionMetadata memory _metadata) internal {
        _extensionManagerStorage().extensionMetadata[_functionSelector] = _metadata;
    }

    /// @dev Deletes the ExtensionMetadata for a given function.
    function _deleteMetadataForFunction(bytes4 _functionSelector) internal {
        delete _extensionManagerStorage().extensionMetadata[_functionSelector];
    }

    /// @dev Adds a function to the function map of an extension.
    function _addToFunctionMap(string memory _extensionName, ExtensionFunction memory _extFunction) internal virtual {
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

    /// @dev Deletes a function from an extension's function map.
    function _deleteFromFunctionMap(string memory _extensionName, bytes4 _functionSelector) internal {
        ExtensionFunction[] memory extensionFunctions = _extensionManagerStorage().extensions[_extensionName].functions;

        uint256 len = extensionFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            if(extensionFunctions[i].functionSelector == _functionSelector) {

                // Delete: particular function from name -> extension.functions map
                _extensionManagerStorage().extensions[_extensionName].functions[i] = _extensionManagerStorage().extensions[_extensionName].functions[len - 1];
                _extensionManagerStorage().extensions[_extensionName].functions.pop();
                break;
            }
        }
    }

    /// @dev Removes all functions from an Extension.
    function _removeAllFunctionsFromExtension(string memory _extensionName) internal {        
        ExtensionFunction[] memory functions = _extensionManagerStorage().extensions[_extensionName].functions;
        
        // Delete: existing name -> extension.functions map
        delete _extensionManagerStorage().extensions[_extensionName].functions;

        for(uint256 i = 0; i < functions.length; i += 1) {
            // Delete: metadata for function.
            _deleteMetadataForFunction(functions[i].functionSelector);
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

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory _extension) internal virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extension.metadata.name), "ExtensionManager: extension does not exist.");

        // Check: extension implementation must be non-zero.
        require(_extension.metadata.implementation != address(0), "ExtensionManager: adding extension without implementation.");

        return true;
    }

    /// @dev Returns whether an extension can be removed in the given execution context.
    function _canRemoveExtension(string memory _extensionName) internal virtual returns (bool) {
        // Check: extension namespace must already exist.
        // Delete: extension namespace.
        require(_extensionManagerStorage().extensionNames.remove(_extensionName), "ExtensionManager: extension does not exist.");

        return true;
    }

    /// @dev Returns whether a function can be enabled in an extension in the given execution context.
    function _canEnableFunctionInExtension(string memory _extensionName, ExtensionFunction memory) internal view virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extensionName), "ExtensionManager: extension does not exist.");

        return true;
    }

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _canDisableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) internal view virtual returns (bool) {
        // Check: extension namespace must already exist.
        require(_extensionManagerStorage().extensionNames.contains(_extensionName), "ExtensionManager: extension does not exist.");
        // Check: function must be mapped to provided extension.
        require(keccak256(abi.encode(_extensionManagerStorage().extensionMetadata[_functionSelector].name)) == keccak256(abi.encode(_extensionName)), "ExtensionManager: incorrect extension.");

        return true;
    }

    
    /// @dev Returns the ExtensionManager storage.
    function _extensionManagerStorage() internal pure returns (ExtensionManagerStorage.Data storage data) {
        data = ExtensionManagerStorage.data();
    }

    /// @dev To override; returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual returns (bool);
}