// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IDefaultExtensionSet.sol";

interface IBaseRouter is IDefaultExtensionSet {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(Extension memory extension) external;

    /// @dev Updates an existing extension in the router, or overrides a default extension.
    function updateExtension(Extension memory extension) external;

    /// @dev Removes an existing extension from the router.
    function removeExtension(Extension memory extension) external;

    /// @dev Returns all extensions stored.
    function getAllExtensions() external view returns (Extension[] memory allExtensions);
}
