// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExtension.sol";

/// @title IExtensionManager
/// @author thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)
/// @notice Defined storage and API for managing a router's extensions.

interface IExtensionManager is IExtension {

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when a extension is added.
    event ExtensionAdded(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is replaced.
    event ExtensionReplaced(string indexed name, address indexed implementation, Extension extension);

    /// @dev Emitted when a extension is removed.
    event ExtensionRemoved(string indexed name, Extension extension);

    /// @dev Emitted when a function is enabled i.e. made callable.
    event FunctionEnabled(string indexed name, bytes4 indexed functionSelector, ExtensionFunction extFunction, ExtensionMetadata extMetadata);

    /// @dev Emitted when a function is disabled i.e. made un-callable.
    event FunctionDisabled(string indexed name, bytes4 indexed functionSelector, ExtensionMetadata extMetadata);

    /*///////////////////////////////////////////////////////////////
                            External functions
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Add a new extension to the router.
     *  @param extension The extension to add.
     */
    function addExtension(Extension memory extension) external;

    /**
     *  @notice Fully replace an existing extension of the router.
     *  @dev The extension with name `extension.name` is the extension being replaced.
     *  @param extension The extension to replace or overwrite.
     */
    function replaceExtension(Extension memory extension) external;

    /**
     *  @notice Remove an existing extension from the router.
     *  @param extensionName The name of the extension to remove.
     */
    function removeExtension(string memory extensionName) external;

    /**
     *  @notice Enables a single function in an existing extension.
     *  @dev Makes the given function callable on the router.
     *
     *  @param extensionName The name of the extension to which `extFunction` belongs.
     *  @param extFunction The function to enable.
     */
    function enableFunctionInExtension(string memory extensionName, ExtensionFunction memory extFunction) external;
    
    /**
     *  @notice Disables a single function in an Extension.
     *
     *  @param extensionName The name of the extension to which the function of `functionSelector` belongs.
     *  @param functionSelector The function to disable.
     */
    function disableFunctionInExtension(string memory extensionName, bytes4 functionSelector) external;
}