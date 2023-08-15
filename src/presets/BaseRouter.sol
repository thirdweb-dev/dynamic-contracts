// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "../interface/IBaseRouter.sol";

// Core
import "../core/Router.sol";

// Utils
import "./utils/StringSet.sol";
import "./utils/ExtensionState.sol";

abstract contract BaseRouter is IBaseRouter, Router, ExtensionState {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                            ERC 165 logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBaseRouter).interfaceId || super.supportsInterface(interfaceId);
    }

    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(Extension memory _extension) external {
        require(_canSetExtension(_extension), "BaseRouter: not authorized.");

        _addExtension(_extension);
    }

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(Extension memory _extension) external {
        require(_canSetExtension(_extension), "BaseRouter: not authorized.");

        _updateExtension(_extension);
    }

    /// @dev Removes an existing extension from the router.
    function removeExtension(Extension memory _extension) external {
        require(_canSetExtension(_extension), "BaseRouter: not authorized.");

        _removeExtension(_extension.metadata.name);
    }

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns all extensions stored. Override default lugins stored in router are
     *          given precedence over default extensions in DefaultExtensionSet.
     */
    function getAllExtensions() external view returns (Extension[] memory allExtensions) {
        string[] memory names = _extensionStateStorage().extensionNames.values();
        uint256 namesLen = names.length;

        allExtensions = new Extension[](namesLen);
        uint256 idx = 0;

        for (uint256 i = 0; i < namesLen; i += 1) {
            allExtensions[i] = _extensionStateStorage().extensions[names[i]];
            idx += 1;
        }
    }

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory _extensionName) public view returns (Extension memory) {
        return _extensionStateStorage().extensions[_extensionName];
    }

    /// @dev Returns the extension's implementation smart contract address.
    function getExtensionImplementation(string memory _extensionName) external view returns (address) {
        return getExtension(_extensionName).metadata.implementation;
    }

    /// @dev Returns all functions that belong to the given extension contract.
    function getAllFunctionsOfExtension(string memory _extensionName) external view returns (ExtensionFunction[] memory) {
        return getExtension(_extensionName).functions;
    }

    /// @dev Returns the extension metadata for a given function.
    function getExtensionForFunction(bytes4 _functionSelector) public view returns (ExtensionMetadata memory) {
        return _extensionStateStorage().extensionMetadata[_functionSelector];
    }

    /// @dev Returns the extension implementation address stored in router, for the given function.
    function getImplementationForFunction(bytes4 _functionSelector)
        public
        view
        override
        returns (address extensionAddress)
    {
        return getExtensionForFunction(_functionSelector).implementation;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a extension can be set in the given execution context.
    function _canSetExtension(Extension memory _extension) internal view virtual returns (bool);
}