// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./IExtension.sol";

interface IRouterStateGetters is IExtension {
    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the extension metadata for a given function.
    function getMetadataForFunction(bytes4 functionSelector) external view returns (ExtensionMetadata memory);

    /// @dev Returns the extension metadata and functions for a given extension.
    function getExtension(string memory extensionName) external view returns (Extension memory);
}