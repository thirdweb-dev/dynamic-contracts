// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "../presets/BaseRouterWithDefaults.sol";

/**
 *  This smart contract is an EXAMPLE, and is not meant for use in production.
 */

contract RouterImmutable is BaseRouterWithDefaults {
    
    constructor(Extension[] memory _extensions) BaseRouterWithDefaults(_extensions) {}

    /*///////////////////////////////////////////////////////////////
                            Overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a new extension can be added in the given execution context.
    function _canAddExtension(Extension memory) internal virtual override returns (bool) {
        return false;
    }

    /// @dev Returns whether an extension can be replaced in the given execution context.
    function _canReplaceExtension(Extension memory) internal view virtual override returns (bool) {
        return false;
    }

    /// @dev Returns whether an extension can be removed in the given execution context.
    function _canRemoveExtension(string memory) internal virtual override returns (bool) {
        return false;
    }

    /// @dev Returns whether a function can be enabled in an extension in the given execution context.
    function _canEnableFunctionInExtension(string memory, ExtensionFunction memory) internal view virtual override returns (bool) {
        return false;
    }

    /// @dev Returns whether a function can be disabled in an extension in the given execution context.
    function _canDisableFunctionInExtension(string memory, bytes4) internal view virtual override returns (bool) {
        return false;
    }
    
}
