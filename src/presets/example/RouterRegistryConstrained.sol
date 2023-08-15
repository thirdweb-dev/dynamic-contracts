// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../BaseRouterWithDefaults.sol";

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

    /// @dev Returns whether extensions can be set in the given execution context.
    function _canSetExtension(Extension memory _extension) internal view virtual override returns (bool) {
        return msg.sender == admin && registry.isRegistered(_extension.metadata.implementation);
    }
}