// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IExtension.sol";

interface IExtensionManager is IExtension {

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     */
    function addExtension(Extension memory extension) external;

    /**
     *  @notice Overwrite an existing extension of the router.
     */
    function overwriteExtension(Extension memory extension) external;

    /**
     *  @notice Remove an existing extension from the router.
     */
    function removeExtension(string memory extName) external;

    /**
     *  @notice Update a single, existing function of the router.
     */
    function updateFunction(ExtensionFunction memory extFunction, ExtensionMetadata memory extMetadata) external;

    /**
     *  @notice Remove a single, existing function from the router.
     */
    function removeFunction(bytes4 functionSelector) external;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added.
    event ExtensionAdded(address indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is added.
    event ExtensionUpdated(address indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is added.
    event ExtensionRemoved(address indexed name, address indexed implementation, Extension extension);
}