// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseRouter.sol";

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
