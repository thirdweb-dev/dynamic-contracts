// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

// Interface
import "../../interface/IExtension.sol";

// Extensions
import "./StringSet.sol";

library ExtensionStateStorage {
    bytes32 public constant EXTENSION_STATE_STORAGE_POSITION = keccak256("extension.state.storage");

    struct Data {
        /// @dev Set of names of all extensions stored.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        /// @dev Mapping from function selector => extension metadata of the extension the function belongs to.
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
    }

    function data() internal pure returns (Data storage extensionStateData) {
        bytes32 position = EXTENSION_STATE_STORAGE_POSITION;
        assembly {
            extensionStateData.slot := position
        }
    }
}

contract ExtensionState is IExtension {
    using StringSet for StringSet.Set;

    /*///////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Stores a new extension in the contract.
    function _addExtension(Extension memory _extension) internal {

        string memory name = _extension.metadata.name;

        require(_extensionStateStorage().extensionNames.add(name), "ExtensionState: extension already exists.");
        _extensionStateStorage().extensions[name].metadata = _extension.metadata;

        require(_extension.metadata.implementation != address(0), "ExtensionState: adding extension without implementation.");

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {

            /**
             *  Note: `bytes4(0)` is the function selector for the `receive` function.
             *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
             */
            bool mismatch = false;
            if(_extension.functions[i].functionSelector == bytes4(0)) {
                mismatch = keccak256(abi.encode(_extension.functions[i].functionSignature)) != keccak256(abi.encode("receive()"));
            } else {
                mismatch = _extension.functions[i].functionSelector !=
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature)));
            }
            require(
                !mismatch,
                "ExtensionState: fn selector and signature mismatch."
            );
            require(
                _extensionStateStorage().extensionMetadata[_extension.functions[i].functionSelector].implementation == address(0),
                "ExtensionState: extension already exists for function."
            );

            _extensionStateStorage().extensionMetadata[_extension.functions[i].functionSelector] = _extension.metadata;
            _extensionStateStorage().extensions[name].functions.push(_extension.functions[i]);

            emit ExtensionAdded(
                _extension.metadata.implementation,
                _extension.functions[i].functionSelector,
                _extension.functions[i].functionSignature
            );
        }
    }

    /// @dev Updates / overrides an existing extension in the contract.
    function _updateExtension(Extension memory _extension) internal {
        string memory name = _extension.metadata.name;
        require(_extensionStateStorage().extensionNames.contains(name), "ExtensionState: extension does not exist.");

        address oldImplementation = _extensionStateStorage().extensions[name].metadata.implementation;
        require(_extension.metadata.implementation != oldImplementation, "ExtensionState: re-adding same extension.");

        _extensionStateStorage().extensions[name].metadata = _extension.metadata;

        ExtensionFunction[] memory oldFunctions = _extensionStateStorage().extensions[name].functions;
        uint256 oldFunctionsLen = oldFunctions.length;

        delete _extensionStateStorage().extensions[name].functions;

        for (uint256 i = 0; i < oldFunctionsLen; i += 1) {
            delete _extensionStateStorage().extensionMetadata[oldFunctions[i].functionSelector];
        }

        uint256 len = _extension.functions.length;
        for (uint256 i = 0; i < len; i += 1) {
            /**
             *  Note: `bytes4(0)` is the function selector for the `receive` function.
             *        So, we maintain a special fn selector-signature mismatch check for the `receive` function.
             */
            bool mismatch = false;
            if(_extension.functions[i].functionSelector == bytes4(0)) {
                mismatch = keccak256(abi.encode(_extension.functions[i].functionSignature)) != keccak256(abi.encode("receive()"));
            } else {
                mismatch = _extension.functions[i].functionSelector !=
                    bytes4(keccak256(abi.encodePacked(_extension.functions[i].functionSignature)));
            }
            require(
                !mismatch,
                "ExtensionState: fn selector and signature mismatch."
            );
            require(
                _extensionStateStorage().extensionMetadata[_extension.functions[i].functionSelector].implementation == address(0),
                "ExtensionState: extension already exists for function."
            );

            _extensionStateStorage().extensionMetadata[_extension.functions[i].functionSelector] = _extension.metadata;
            _extensionStateStorage().extensions[name].functions.push(_extension.functions[i]);

            emit ExtensionUpdated(
                oldImplementation,
                _extension.metadata.implementation,
                _extension.functions[i].functionSelector,
                _extension.functions[i].functionSignature
            );
        }
    }

    /// @dev Removes an existing extension from the contract.
    function _removeExtension(string memory _extensionName) internal {
        require(_extensionStateStorage().extensionNames.remove(_extensionName), "ExtensionState: extension does not exist.");

        address implementation = _extensionStateStorage().extensions[_extensionName].metadata.implementation;
        ExtensionFunction[] memory extensionFunctions = _extensionStateStorage().extensions[_extensionName].functions;
        delete _extensionStateStorage().extensions[_extensionName];

        uint256 len = extensionFunctions.length;
        for (uint256 i = 0; i < len; i += 1) {
            emit ExtensionRemoved(
                implementation,
                extensionFunctions[i].functionSelector,
                extensionFunctions[i].functionSignature
            );
            delete _extensionStateStorage().extensionMetadata[extensionFunctions[i].functionSelector];
        }
    }

    function _extensionStateStorage() internal pure returns (ExtensionStateStorage.Data storage data) {
        data = ExtensionStateStorage.data();
    }
}