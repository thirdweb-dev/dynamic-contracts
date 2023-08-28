// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

import "./IRouter.sol";

pragma solidity ^0.8.0;

interface IRouterPayable is IRouter {
    
    /// @dev Lets a router receive native token by default; adds `receive` as a fixed function.
    receive() external payable;
}