// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseRouter.sol";

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
