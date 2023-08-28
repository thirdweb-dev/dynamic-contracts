// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouterWithDefaults.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */

contract RouterImmutable is BaseRouterWithDefaults {
    
    constructor(FunctionWithMetadata[] memory _functions) BaseRouterWithDefaults(_functions) {}

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a new function can be added in the given execution context.
    function _canAddFunction(FunctionWithMetadata memory) internal view virtual override returns (bool) {
        return false;
    }
    
    /// @dev Returns whether a function can be updated in the given execution context.
    function _canUpdateFunction(FunctionWithMetadata memory) internal view virtual override returns (bool) {
        return false;
    }
    
    /// @dev Returns whether a function can be deleted in the given execution context.
    function _canDeleteFunction(bytes4) internal view virtual override returns (bool) {
        return false;
    }
}
