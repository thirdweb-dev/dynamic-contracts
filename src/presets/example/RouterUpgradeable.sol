// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "../BaseRouter.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */

contract RouterUpgradeable is BaseRouter {
    
    address public deployer;

    constructor(Plugin[] memory _plugins) BaseRouter(_plugins) {
        deployer = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
}
