// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouterWithDefaults.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */
contract ExtensionRegistry {

    address public immutable admin;
    mapping (address => bool) public isRegistered;

    constructor() {
        admin = msg.sender;
    }

    function setExtensionRegistered(address _extension, bool _isRegistered) external {
        require(msg.sender == admin, "ExtensionRegistry: Only admin can alter extension registry");
        isRegistered[_extension] = _isRegistered;
    }
}

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */
contract RouterRegistryConstrained is BaseRouterWithDefaults {

    address public admin;
    ExtensionRegistry public registry;

    // @dev Cannot initialize with extensions before registry is set, so we pass empty array to base constructor.
    constructor(address _registry) BaseRouterWithDefaults(new Extension[](0)) {
        admin = msg.sender;
        registry = ExtensionRegistry(_registry);
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
        return super._canAddExtension(_extension) && msg.sender == admin && registry.isRegistered(_extension.metadata.implementation);
    }

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory _extension) internal virtual override returns (bool) {
        return super._canReplaceExtension(_extension) && msg.sender == admin && registry.isRegistered(_extension.metadata.implementation);
    }

    /// @dev Returns whether an extension can be removed in the given execution context.
    function _canRemoveExtension(string memory _extensionName) internal virtual override returns (bool) {
        return super._canRemoveExtension(_extensionName) && msg.sender == admin;
    }

    /// @dev Returns whether a function can be enabled in an extension in the given execution context.
    function _canEnableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function) internal view virtual override returns (bool) {
        return super._canEnableFunctionInExtension(_extensionName, _function) && msg.sender == admin;
    }

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _canDisableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) internal view virtual override returns (bool) {
        return super._canDisableFunctionInExtension(_extensionName, _functionSelector) && msg.sender == admin;
    }
}