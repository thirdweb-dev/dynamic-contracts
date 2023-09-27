# ERC-7504: Dynamic Contracts standard.

**Architectural pattern for writing client-friendly one-to-many proxy contracts (aka 'dynamic contracts') in Solidity.**

This repository implements ERC-7504: Dynamic Contracts [[DRAFT](https://ethereum-magicians.org/t/erc-7504-dynamic-contracts/15551)]. This repository provides core interfaces and preset implementations that:

- Provide guardrails for writing dynamic contracts that can have functionality added, updated or removed over time.
- Enables scaling up contracts by eliminating the restriction of contract size limit altogether.

> ⚠️ **ERC-7504** [DRAFT] is now published and open for feedback! You can read the EIP and provide your feedback at its [ethereum-magicians discussion link](https://ethereum-magicians.org/t/erc-7504-dynamic-contracts/15551).

# Installation

### Forge projects:

```bash
forge install https://github.com/thirdweb-dev/dynamic-contracts
```

### Hardhat / JS based projects:

```bash
npm install @thirdweb-dev/dynamic-contracts
```

### Project structure

```shell
src
|
|-- core
|   |- Router: "Minmal abstract contract implementation of EIP-7504 Router."
|   |- RouterPayable: "A Router with `receive` as a fixed function."
|
|-- presets
|   |-- ExtensionManager: "Defined storage layout and API for managing a router's extensions."
|   |-- DefaultExtensionSet: "A static store of a set of extensions, initialized on deployment."
|   |-- BaseRouter: "A Router with an ExtensionManager."
|   |-- BaseRouterWithDefaults: "A BaseRouter initialized with extensions on deployment."
|
|-- interface: "Interfaces for core and preset contracts."
|-- example: "Example dynamic contracts built with presets."
|-- lib: "Storage layouts and helper libraries."
```

# Running locally

This repository is a forge project. ([forge handbook](https://book.getfoundry.sh/))

**Clone the repository:**

```bash
git clone https://github.com/thirdweb-dev/dynamic-contracts.git
```

**Install dependencies:**

```bash
forge install
```

**Compile contracts:**

```bash
forge build
```

**Run tests:**

```bash
forge test
```

**Generate documentation**

```bash
forge doc --serve --port 4000
```

# Core concepts

An “upgradeable smart contract” is actually two kinds of smart contracts considered together as one system:

1. **Proxy** smart contract: The smart contract whose state/storage we’re concerned with.
2. **Implementation** smart contract: A stateless smart contract that defines the logic for how the proxy smart contract’s state can be mutated.

![A proxy contract that forwards all calls to a single implementation contract](https://ipfs.io/ipfs/QmdzTiw5YuaMa1rjBtoyDuGHHRLdi9Afmh2Tu9Rjj1XuoA/proxy-with-single-impl.png)

The job of a proxy contract is to forward any calls it receives to the implementation contract via `delegateCall`. As a shorthand — a proxy contract stores state, and always asks an implementation contract how to mutate its state (upon receiving a call).

ERC-7504 introduces a `Router` smart contract.

![A router contract that forwards calls to one of many implementation contracts based on the incoming calldata](https://ipfs.io/ipfs/Qmasd6DHrqMnkhifoapWAeWSs8eEJoFbzKJUpeEBacPAM7/router-many-impls.png)

Instead of always delegateCall-ing the same implementation contract, a `Router` delegateCalls a particular implementation contract (i.e. “Extension”) for the particular function call it receives.

A router stores a map from function selectors → to the implementation contract where the given function is implemented. “Upgrading a contract” now simply means updating what implementation contract a given function, or functions are mapped to.

![Upgrading a contract means updating what implementation a given function, or functions are mapped to](https://ipfs.io/ipfs/QmUWk4VrFsAQ8gSMvTKwPXptJiMjZdihzUNhRXky7VmgGz/router-upgrades.png)

# Getting started

The simplest way to write a `Router` contract is to extend the preset [`BaseRouter`](/src/presets/BaseRouter.sol) available in this repository.

```solidity
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";
```

The `BaseRouter` contract comes with an API to add/replace/remove extensions from the contract. It is an abstract contract, and expects its consumer to implement the `_isAuthorizedCallToUpgrade` function, which specifies the conditions under which `Extensions` can be added, replaced or removed. The rest of the implementation is generic and usable for all purposes.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter.sol";

/// Example usage of `BaseRouter`, for demonstration only

contract SimpleRouter is BaseRouter {

    address public deployer;

    constructor() {
        deployer = msg.sender;
    }

    /// @dev Returns whether all relevant permission checks are met before any upgrade.
    function _isAuthorizedCallToUpgrade() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
}
```

## Choosing a permission model

The main decision as a `Router` contract author is to decide the permission model to add/replace/remove extensions. This repository offers some examples of a few possible permission models:

- [**RouterImmutable**](https://github.com/thirdweb-dev/dynamic-contracts/blob/main/src/example/RouterImmutable.sol)

  This is a preset you can use to create static contracts that cannot be updated or get new functionality. This still allows you to create modular contracts that go beyond the contract size limit, but guarantees that the original functionality cannot be altered. With this model, you would pass all the Extensions for this contract at construction time, and guarantee that the functionality is immutable.

- [**RouterUpgradeable**](https://github.com/thirdweb-dev/dynamic-contracts/blob/main/src/example/RouterUpgradeable.sol)

  This a is a preset that allows the contract owner to add / replace / remove extensions. The contract owner can be changed. This is a very basic permission model, but enough for some use cases. You can expand on this and use a permission based model instead for example.

- [**RouterRegistryContrained**](https://github.com/thirdweb-dev/dynamic-contracts/blob/main/src/example/RouterRegistryConstrained.sol)

  This is a preset that allows the owner to change extensions if they are defined on a given registry contract. This is meant to demonstrate how a protocol ecosystem could constrain extensions to known, audited contracts, for instance. The registry and router upgrade models are of course too basic for production as written.

## Writing extension smart contracts

An `Extension` contract is written like any other smart contract, except that its state must be defined using a `struct` within a `library` and at a well defined storage location. This storage technique is known as [storage structs](https://mirror.xyz/horsefacts.eth/EPB4o-eyDl0N8gu0gEz1uw7BTITheaZUqIAOEK1m-jE).

**Example:** `ExtensionManagerStorage` defines the storage layout for the `ExtensionManager` contract.

```solidity
// SPDX-License-Identifier: MIT
// @author: thirdweb (https://github.com/thirdweb-dev/dynamic-contracts)

pragma solidity ^0.8.0;

import "./StringSet.sol";
import "../interface/IExtension.sol";

library ExtensionManagerStorage {

    /// @custom:storage-location erc7201:extension.manager.storage
    bytes32 public constant EXTENSION_MANAGER_STORAGE_POSITION = keccak256(abi.encode(uint256(keccak256("extension.manager.storage")) - 1));

    struct Data {
        /// @dev Set of names of all extensions stored.
        StringSet.Set extensionNames;
        /// @dev Mapping from extension name => `Extension` i.e. extension metadata and functions.
        mapping(string => IExtension.Extension) extensions;
        /// @dev Mapping from function selector => metadata of the extension the function belongs to.
        mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
    }

    function data() internal pure returns (Data storage data_) {
        bytes32 position = EXTENSION_MANAGER_STORAGE_POSITION;
        assembly {
            data_.slot := position
        }
    }
}
```

Each `Extension` of a router must occupy a unique, unused storage location. This is important to ensure that state updates defined in one `Extension` doesn't conflict with the state updates defined in another `Extension`, leading to corrupted state.

## Extensions: logical grouping of functionality

By itself, the core `Router` contract does not specify _how to store or fetch_ appropriate implementation addresses for incoming function calls.

While the Router pattern allows to point to a different contract for each function, in practice functions are usually groupped by functionality related to a shared state (a read and a set function for example).

To make the pattern more practical, we created a generic `BaseRouter` contract that makes it easy to have logical group of functions plugged in and out of it, each group of functions being implemented in a separate implementation contract. We refer to each such implementation contract as an **_extension_**.

`BaseRouter` maintains a `function_signature` → `implementation` mapping, and provides an API for updating that mapping. By updating the values stored in this map, functionality can be added to, removed from or updated in the smart contract.

![Upgrading a contract means updating what implementation a given function, or functions are mapped to](https://ipfs.io/ipfs/QmUWk4VrFsAQ8gSMvTKwPXptJiMjZdihzUNhRXky7VmgGz/router-upgrades.png)

## Deploying a Router

Deploying a contract in the router pattern looks a little different from deploying a regular contract.

1. Deploy all your `Extension` contracts first. You only need to do this once per `Extension`. Deployed `Extensions` can be re-used by many different `Router` contracts.

2. Deploy your `Router` contract that implements `BaseRouter`.
3. Add extensions to youe router via the API available in `BaseRouter`. (Alternatively, you can use `BaseRouterDefaults` which can be initialized with a set of extensions on deployment.)

### `Extensions` - Grouping logical functionality together

By itself, the core `Router` contract does not specify _how to store or fetch_ appropriate implementation addresses for incoming function calls.

While the Router pattern allows to point to a different contract for each function, in practice functions are usually groupped by functionality related to a shared state (a read and a set function for example).

To make the pattern more practical, we created a generic `BaseRouter` contract that makes it easy to have logical group of functions plugged in and out of it, each group of functions being implemented in a separate implementation contract. We refer to each such implementation contract as an **_extension_**.

`BaseRouter` maintains a `function_signature` → `implementation` mapping, and provides an API for updating that mapping. By updating the values stored in this map, functionality can be added to, removed from or updated in the smart contract.

## Extension to Extension communication

When splitting logic between multiple extensions in a `Router`, one might want to access data from one `Extension` to another.

A simple way to do this is by casting the current contract address as the `Extension` (ideally its interface) we're trying to call. This works from both a `Router` or any of its extensions.

Here's an example of accessing a `IPermission` extension from another one:

```solidity
modifier onlyAdmin(address _asset) {
  /// we access our IPermission extension by casting our own address
  IPermissions(address(this)).hasAdminRole(msg.sender);
}
```

Note that if we don't have an `IPermission` extension added to our `Router`, this method will revert.

## Upgrading Extensions

Just like any upgradeable contract, there are limitations on how the data structure of the updated contract is modified. While the logic of a function can be updated safely, changing the data structure of a contract requires careful consideration.

A good rule of thumb to follow is:

- It is safe to append new fields to an existing data structure
- It is _not_ safe to update the type or order of existing structs; deprecate and add new ones instead.

Refer to [this article](https://mirror.xyz/horsefacts.eth/EPB4o-eyDl0N8gu0gEz1uw7BTITheaZUqIAOEK1m-jE) for more information.

# API reference

You can generate and view the full API reference for all contracts, interfaces and libraries in the repository by running the repository locally and running:

```bash
forge doc --serve --port 4000
```

## Router

```solidity
import "@thirdweb-dev/dynamic-contracts/src/core/Router.sol";
```

The `Router` smart contract implements the ERC-7504 [`Router` interface](https://github.com/thirdweb-dev/dynamic-contracts/blob/main/src/interface/IRouter.sol).

For any given function call made to the Router contract that reaches the fallback function, the contract performs a delegateCall on the address returned by `getImplementationForFunction(msg.sig)`.

This is an abstract contract that expects you to override and implement the following functions:

- `getImplementationForFunction`
  ```solidity
  function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address implementation);
  ```

### fallback

delegateCalls the appropriate implementation address for the given incoming function call.

_The implementation address to delegateCall MUST be retrieved from calling `getImplementationForFunction` with the
incoming call's function selector._

```solidity
fallback() external payable virtual;
```

#### Revert conditions:

- `getImplementationForFunction(msg.sig) == address(0)`

### \_delegate

_delegateCalls an `implementation` smart contract._

```solidity
function _delegate(address implementation) internal virtual;
```

### getImplementationForFunction

Returns the implementation address to delegateCall for the given function selector.

```solidity
function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address implementation);
```

**Parameters**

| Name                | Type     | Description                                                  |
| ------------------- | -------- | ------------------------------------------------------------ |
| `_functionSelector` | `bytes4` | The function selector to get the implementation address for. |

**Returns**

| Name             | Type      | Description                                                                 |
| ---------------- | --------- | --------------------------------------------------------------------------- |
| `implementation` | `address` | The implementation address to delegateCall for the given function selector. |

## ExtensionManager

```solidity
import "@thirdweb-dev/dynamic-contracts/src/presets/ExtensionManager.sol";
```

The `ExtensionManager` contract provides a defined storage layout and API for managing and fetching a router's extensions. This contract implements the ERC-7504 [`RouterState` interface](https://github.com/thirdweb-dev/dynamic-contracts/blob/main/src/interface/IRouterState.sol).

The contract's storage layout is defined in `src/lib/ExtensionManagerStorage`:

```solidity
struct Data {
    StringSet.Set extensionNames;
    mapping(string => IExtension.Extension) extensions;
    mapping(bytes4 => IExtension.ExtensionMetadata) extensionMetadata;
}
```

The following are some helpful **invariant properties** of `ExtensionManager`:

- Each extension has a non-empty, unique name which is stored in `extensionNames`.
- Each extension's metadata specifies a _non_-zero-address implementation.
- A function `fn` has a non-empty metadata i.e. `extensionMetadata[fn]` value _if and only if_ it is a part of some extension `Ext` such that:

  - `extensionNames` contains `Ext.metadata.name`
  - `extensions[Ext.metadata.name].functions` includes `fn`.

This contract is meant to be used along with a Router contract, where an upgrade to the Router means updating the storage of `ExtensionManager`. For example, the preset contract `BaseRouter` inherits `Router` and `ExtensionManager` and overrides the `getImplementationForFunction` function as follows:

```solidity
function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address) {
        return getMetadataForFunction(_functionSelector).implementation;
    }
```

This contract is an abstract contract that expects you to override and implement the following functions:

- `isAuthorizedCallToUpgrade`
  ```solidity
  function _isAuthorizedCallToUpgrade() internal view virtual returns (bool);
  ```

### onlyAuthorizedCall

Checks that a call to any external function is authorized.

```solidity
modifier onlyAuthorizedCall();
```

#### Revert conditions:

- `!_isAuthorizedCallToUpgrade()`

### getAllExtensions

Returns all extensions of the Router.

```solidity
function getAllExtensions() external view virtual override returns (Extension[] memory allExtensions);
```

**Returns**

| Name            | Type          | Description                 |
| --------------- | ------------- | --------------------------- |
| `allExtensions` | `Extension[]` | An array of all extensions. |

### getMetadataForFunction

Returns the extension metadata for a given function.

```solidity
function getMetadataForFunction(bytes4 functionSelector) public view virtual returns (ExtensionMetadata memory);
```

**Parameters**

| Name               | Type     | Description                                              |
| ------------------ | -------- | -------------------------------------------------------- |
| `functionSelector` | `bytes4` | The function selector to get the extension metadata for. |

**Returns**

| Name     | Type                | Description                                           |
| -------- | ------------------- | ----------------------------------------------------- |
| `<none>` | `ExtensionMetadata` | metadata The extension metadata for a given function. |

### getExtension

Returns the extension metadata and functions for a given extension.

```solidity
function getExtension(string memory extensionName) public view virtual returns (Extension memory);
```

**Parameters**

| Name            | Type     | Description                                                      |
| --------------- | -------- | ---------------------------------------------------------------- |
| `extensionName` | `string` | The name of the extension to get the metadata and functions for. |

**Returns**

| Name     | Type        | Description                                                 |
| -------- | ----------- | ----------------------------------------------------------- |
| `<none>` | `Extension` | The extension metadata and functions for a given extension. |

### addExtension

Add a new extension to the router.

```solidity
function addExtension(Extension memory _extension) external onlyAuthorizedCall;
```

**Parameters**

| Name         | Type        | Description           |
| ------------ | ----------- | --------------------- |
| `_extension` | `Extension` | The extension to add. |

#### Revert conditions:

- Extension name is empty.
- Extension name is already used.
- Extension implementation is zero address.
- Selector and signature mismatch for some function in the extension.
- Some function in the extension is already a part of another extension.

### replaceExtension

Fully replace an existing extension of the router.

_The extension with name `extension.name` is the extension being replaced._

```solidity
function replaceExtension(Extension memory _extension) external onlyAuthorizedCall;
```

**Parameters**

| Name         | Type        | Description                            |
| ------------ | ----------- | -------------------------------------- |
| `_extension` | `Extension` | The extension to replace or overwrite. |

#### Revert conditions:

- Extension being replaced does not exist.
- Provided extension's implementation is zero address.
- Selector and signature mismatch for some function in the provided extension.
- Some function in the provided extension is already a part of another extension.

### removeExtension

Remove an existing extension from the router.

```solidity
function removeExtension(string memory _extensionName) external onlyAuthorizedCall;
```

**Parameters**

| Name             | Type     | Description                          |
| ---------------- | -------- | ------------------------------------ |
| `_extensionName` | `string` | The name of the extension to remove. |

#### Revert conditions:

- Extension being removed does not exist.

### enableFunctionInExtension

Enables a single function in an existing extension.

_Makes the given function callable on the router._

```solidity
function enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _function)
    external
    onlyAuthorizedCall;
```

**Parameters**

| Name             | Type                | Description                                               |
| ---------------- | ------------------- | --------------------------------------------------------- |
| `_extensionName` | `string`            | The name of the extension to which `extFunction` belongs. |
| `_function`      | `ExtensionFunction` | The function to enable.                                   |

#### Revert conditions:

- Provided extension does not exist.
- Selector and signature mismatch for some function in the provided extension.
- Provided function is already a part of another extension.

### disableFunctionInExtension

Disables a single function in an Extension.

```solidity
function disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector)
    external
    onlyAuthorizedCall;
```

**Parameters**

| Name                | Type     | Description                                                                    |
| ------------------- | -------- | ------------------------------------------------------------------------------ |
| `_extensionName`    | `string` | The name of the extension to which the function of `functionSelector` belongs. |
| `_functionSelector` | `bytes4` | The function to disable.                                                       |

#### Revert conditions:

- Provided extension does not exist.
- Provided function is not part of provided extension.

### \_getExtension

_Returns the Extension for a given name._

```solidity
function _getExtension(string memory _extensionName) internal view returns (Extension memory);
```

### \_setMetadataForExtension

_Sets the ExtensionMetadata for a given extension._

```solidity
function _setMetadataForExtension(string memory _extensionName, ExtensionMetadata memory _metadata) internal;
```

### \_deleteMetadataForExtension

_Deletes the ExtensionMetadata for a given extension._

```solidity
function _deleteMetadataForExtension(string memory _extensionName) internal;
```

### \_setMetadataForFunction

_Sets the ExtensionMetadata for a given function._

```solidity
function _setMetadataForFunction(bytes4 _functionSelector, ExtensionMetadata memory _metadata) internal;
```

### \_deleteMetadataForFunction

_Deletes the ExtensionMetadata for a given function._

```solidity
function _deleteMetadataForFunction(bytes4 _functionSelector) internal;
```

### \_enableFunctionInExtension

_Enables a function in an Extension._

```solidity
function _enableFunctionInExtension(string memory _extensionName, ExtensionFunction memory _extFunction)
    internal
    virtual;
```

### \_disableFunctionInExtension

Note: `bytes4(0)` is the function selector for the `receive` function.
So, we maintain a special fn selector-signature mismatch check for the `receive` function.

_Disables a given function in an Extension._

```solidity
function _disableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector) internal;
```

### \_removeAllFunctionsFromExtension

_Removes all functions from an Extension._

```solidity
function _removeAllFunctionsFromExtension(string memory _extensionName) internal;
```

### \_canAddExtension

_Returns whether a new extension can be added in the given execution context._

```solidity
function _canAddExtension(Extension memory _extension) internal virtual returns (bool);
```

### \_canReplaceExtension

_Returns whether an extension can be replaced in the given execution context._

```solidity
function _canReplaceExtension(Extension memory _extension) internal virtual returns (bool);
```

### \_canRemoveExtension

_Returns whether an extension can be removed in the given execution context._

```solidity
function _canRemoveExtension(string memory _extensionName) internal virtual returns (bool);
```

### \_canEnableFunctionInExtension

_Returns whether a function can be enabled in an extension in the given execution context._

```solidity
function _canEnableFunctionInExtension(string memory _extensionName, ExtensionFunction memory)
    internal
    view
    virtual
    returns (bool);
```

### \_canDisableFunctionInExtension

_Returns whether a function can be disabled in an extension in the given execution context._

```solidity
function _canDisableFunctionInExtension(string memory _extensionName, bytes4 _functionSelector)
    internal
    view
    virtual
    returns (bool);
```

### \_extensionManagerStorage

_Returns the ExtensionManager storage._

```solidity
function _extensionManagerStorage() internal pure returns (ExtensionManagerStorage.Data storage data);
```

### isAuthorizedCallToUpgrade

_To override; returns whether all relevant permission and other checks are met before any upgrade._

```solidity
function _isAuthorizedCallToUpgrade() internal view virtual returns (bool);
```

## BaseRouter

```solidity
import "@thirdweb-dev/dynamic-contracts/src/presets/BaseRouter"
```

`BaseRouter` inherits `Router` and `ExtensionManager`. It overrides the `Router.getImplementationForFunction` function to use the extensions stored in the `ExtensionManager` contract's storage system.

This contract is an abstract contract that expects you to override and implement the following functions:

- `isAuthorizedCallToUpgrade`
  ```solidity
  function _isAuthorizedCallToUpgrade() internal view virtual returns (bool);
  ```

### getImplementationForFunction

Returns the implementation address to delegateCall for the given function selector.

```solidity
function getImplementationForFunction(bytes4 _functionSelector) public view virtual override returns (address);
```

**Parameters**

| Name                | Type     | Description                                                  |
| ------------------- | -------- | ------------------------------------------------------------ |
| `_functionSelector` | `bytes4` | The function selector to get the implementation address for. |

**Returns**

| Name     | Type      | Description                                                                                |
| -------- | --------- | ------------------------------------------------------------------------------------------ |
| `<none>` | `address` | implementation The implementation address to delegateCall for the given function selector. |

# Feedback

The best, most open way to give feedback/suggestions for the router pattern is to open a github issue, or comment in the ERC-7504 [ethereum-magicians discussion](https://ethereum-magicians.org/t/erc-7504-dynamic-contracts/15551).

Additionally, since [thirdweb](https://thirdweb.com/) will be maintaining this repository, you can reach out to us at support@thirdweb.com or join our [discord](https://discord.gg/thirdweb).

# Authors

- [thirdweb](https://github.com/thirdweb-dev)
