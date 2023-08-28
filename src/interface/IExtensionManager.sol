// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IExtension.sol";

interface IExtensionManager is IExtension {
    /*///////////////////////////////////////////////////////////////
                        External functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Adds a new extension to the router.
    function addExtension(Extension memory extension) external;

    /// @dev Overwrites an existing extension in the router.
    function overwriteExtension(Extension memory extension) external;

    /// @dev Removes an entire existing extension from the router.
    function deleteExtension(string memory extensionName) external;

    /// @dev Updates the extension for a specific function.
    function updateFunction(ExtensionFunction memory extFunction, ExtensionMetadata memory metadata) external;

    /// @dev Removes an existing extension from the router.
    function deleteFunction(bytes4 functionSelector) external;
}
