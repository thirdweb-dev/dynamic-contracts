// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IRouter.sol";

/// @dev See {IRouter}.
interface IRouterPayable is IRouter {
    receive() external payable;
}