// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Router.sol";

/// @title IRouterPayable.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice A Router with `receive` as a fixed function.

abstract contract RouterPayable is Router {
    
    /// @notice Lets a contract receive native tokens.
    receive() external payable virtual {}
}