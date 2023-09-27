// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouter.sol";
/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */
contract RouterUpgradeable is BaseRouter {
    
    address public admin;

    constructor() BaseRouter(new Extension[](0)) {
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

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return msg.sender == admin;
    }
}
