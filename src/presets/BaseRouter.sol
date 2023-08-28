// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../core/Router.sol";
import "./FunctionManager.sol";

abstract contract BaseRouter is Router, FunctionManager {

    /// @dev Returns the implementation address to delegateCall for the given function selector.
    function getImplementationForFunction(bytes4 _functionSelector) public view override returns (address) {
        return _getFunctionData(_functionSelector).implementation;
    }
}