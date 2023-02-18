// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "../BaseRouter.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */
contract RouterUpgradeable is BaseRouter {
    
    address public admin;

    constructor(Plugin[] memory _plugins) BaseRouter(_plugins) {
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

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual override returns (bool) {
        return msg.sender == admin;
    }
}
