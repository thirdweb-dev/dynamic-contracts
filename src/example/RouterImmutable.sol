// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouter.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */

abstract contract MyRouter is BaseRouter {

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {
        // Initialize the router with a set of default extensions.
        __BaseRouter_init();
    }
}

contract RouterImmutable is MyRouter {
    
    constructor(Extension[] memory _extensions) MyRouter(_extensions) {}

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether all relevant permission and other checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return false;
    }
    
}
