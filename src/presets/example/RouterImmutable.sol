// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/plugin-pattern)

pragma solidity ^0.8.0;

import "../BaseRouter.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */

contract RouterImmutable is BaseRouter {
    
    constructor(Plugin[] memory _plugins) BaseRouter(_plugins) {}

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal pure override returns (bool) {
        return false;
    }
}
