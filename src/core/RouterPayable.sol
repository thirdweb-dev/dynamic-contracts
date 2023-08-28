// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./Router.sol";

abstract contract RouterPayable is Router {
    receive() external payable virtual {}
}