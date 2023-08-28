// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouter.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */
contract RouterUpgradeable is BaseRouter {
    
    address public admin;

    constructor() {
        admin = msg.sender;
    }

    // @dev Sets the admin address.
    function setAdmin(address _admin) external {
        require(msg.sender == admin, "RouterUpgradeable: Only admin can set a new admin");
        admin = _admin;
    }

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a new extension can be added in the given execution context.
    function _canAddExtension(Extension memory _extension) internal virtual override returns (bool) {
        return super._canAddExtension(_extension) && msg.sender == admin;
    }

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory _extension) internal view virtual override returns (bool) {
        return super._canReplaceExtension(_extension) && msg.sender == admin;
    }

    /// @dev Returns whether an extension can be removed in the given execution context.
    function _canRemoveExtension(string memory _extensionName) internal virtual override returns (bool) {
        return super._canRemoveExtension(_extensionName) && msg.sender == admin;
    }

    /// @dev Returns whether a function can be added to an extension in the given execution context.
    function _canAddFunctionToExtension(string memory _extensionName, ExtensionFunction memory _function) internal view virtual override returns (bool) {
        return super._canAddFunctionToExtension(_extensionName, _function) && msg.sender == admin;
    }

    /// @dev Returns whether an extension can be removed from an extension in the given execution context.
    function _canRemoveFunctionFromExtension(string memory _extensionName, bytes4 _functionSelector) internal view virtual override returns (bool) {
        return super._canRemoveFunctionFromExtension(_extensionName, _functionSelector) && msg.sender == admin;
    }
}
