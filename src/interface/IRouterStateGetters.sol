// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title IRouterStateGetters.
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Helper view functions to inspect a router's state.

interface IRouterStateGetters is IExtension {

    /*///////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the extension metadata for a given function.
     *  @param functionSelector The function selector to get the extension metadata for.
     *  @return metadata The extension metadata for a given function.
     */
    function getMetadataForFunction(bytes4 functionSelector) external view returns (ExtensionMetadata memory metadata);

    /**
     *  @notice Returns the extension metadata and functions for a given extension.
     *  @param extensionName The name of the extension to get the metadata and functions for.
     *  @return extension The extension metadata and functions for a given extension.
     */
    function getExtension(string memory extensionName) external view returns (Extension memory);
}