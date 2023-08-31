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
     *  @notice Fully replace an existing extension of the router.
     */
    function replaceExtension(Extension memory extension) external;

    /**
     *  @notice Remove an existing extension from the router.
     */
    function removeExtension(string memory extensionName) external;

    /**
     *  @notice Enables a single function in an existing extension.
     */
    function enableFunctionInExtension(string memory extensionName, ExtensionFunction memory extFunction) external;
    
    /**
     *  @notice Disables a single function in an Extension.
     */
    function disableFunctionInExtension(string memory extensionName, bytes4 functionSelector) external;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is added.
    event ExtensionReplaced(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is added.
    event ExtensionRemoved(string indexed name, Extension extension);

    /// @dev Emitted when a function is updated.
    event FunctionAdded(string indexed name, bytes4 indexed functionSelector, ExtensionFunction extFunction, ExtensionMetadata extMetadata);

    /// @dev Emitted when a function is removed.
    event FunctionRemoved(string indexed name, bytes4 indexed functionSelector, ExtensionMetadata extMetadata);
}