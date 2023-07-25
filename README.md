# Dynamic Contracts Standard

### Architectural pattern for writing dynamic smart contracts in Solidity

This repository provides core interfaces and preset implementations that:

- Provide guardrails for writing dynamic contracts that can have functionality added, updated or removed over time
- Enables scaling up contracts by eliminating the restriction of contract size limit altogether

> This architecture builds upon the diamond pattern ([EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)). We've taken inspiration from it, and boiled it down to its leanest, simplest form.

## Installation

#### Forge

```bash
forge install https://github.com/thirdweb-dev/dynamic-contracts
```

#### Hardhat

```bash
npm install @thirdweb-dev/dynamic-contracts
```

## Core concepts

- A `Router` contract can route function calls to any number of destination contracts
- We call these destination contracts `Extensions`.
- `Extensions` can be added/updated/removed at any time, according to a predefined set of rules.

![router-pattern](/docs/img/router-diagram.png)

## Getting started

### 1. `Router` - the entrypoint contract

The simplest way to write a `Router` contract is to extend the preset [`BaseRouter`](/src/presets/BaseRouter.sol) available in this repository.

```solidity
import "lib/dynamic-contracts/src/presets/BaseRouter.sol";
```

The `BaseRouter` contract comes with an API to add/update/remove extensions from the contract. It is an abstract contract, and expects its consumer to implement the `_canSetExtension(...)` function, which specifies the conditions under which `Extensions` can be added, updated or removed. The rest of the implementation is generic and usable for all purposes.

```solidity
function _canSetExtension(Extension memory _extension) internal view virtual returns (bool);
```

Here's a very simple example that allows only the original contract deployer to add/update/remove `Extensions`.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/dynamic-contracts/src/presets/BaseRouter.sol";

/// Example usage of `BaseRouter`, for demonstration only

contract SimpleRouter is BaseRouter {

    address public deployer;

    constructor(Extension[] memory _extensions) BaseRouter(_extensions) {
        deployer = msg.sender;
    }

    /// @dev Returns whether extensions can be set in the given execution context.
    function _canSetExtension(Extension memory _extension) internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
}
```

#### Choosing a permission model:

The main decision as a `Router` contract author is to decide the permission model to add/update/remove extensions. This repository offers some presets for a few possible permission models:

- #### [`RouterUpgradeable`](/src/presets/example/RouterUpgradeable.sol)

This a is a preset that **allows the contract owner to add / upgrade / remove extensions**. The contract owner can be changed. This is a very basic permission model, but enough for some use cases. You can expand on this and use a permission based model instead for example.

- #### [`RouterImmutable`](/src/presets/example/RouterImmutable.sol)

This is a preset you can use to **create static contracts that cannot be updated or get new functionality**. This still allows you to create modular contracts that go beyond the contract size limit, but guarantees that the original functionality cannot be altered. With this model, you would pass all the `Extensions` for this contract at construction time, and guarantee that the functionality is immutable.

Other permissions models might include an explicit list of extensions that can be added or removed for example. The implementation is up to the Router author.

- #### [`RouterRegistryConstrained`](/src/presets/example/RouterRegistryConstrained.sol)

This is a preset that **allows the owner to change extensions if they are defined on a given registry contract**. This is meant to demonstrate how a protocol ecosystem could constrain extensions to known, audited contracts, for instance. The registry and router upgrade models are of course too basic for production as written.

### 2. `Extensions` - implementing routeable contracts

An `Extension` contract is written like any other smart contract, except that its state must be defined using a `struct` within a `library` and at a well defined storage location. This storage technique is known as [storage structs](https://mirror.xyz/horsefacts.eth/EPB4o-eyDl0N8gu0gEz1uw7BTITheaZUqIAOEK1m-jE). This is important to ensure that state defined in an `Extension` doesn't conflict with the state of another `Extension` of the same `Router` at the same storage location.

Here's an example of a simple contract written as an `Extension` contract:

```solidity

/// library defining the data structure of our contract
library NumberStorage {
    /// specify the storage location, needs to be unique
    bytes32 public constant NUMBER_STORAGE_POSITION = keccak256("number.storage");

    /// the state data struct
    struct Data {
        uint256 number;
    }

    /// state accessor, always use this to access the state data
    function numberStorage() internal pure returns (Data storage numberData) {
        bytes32 position = NUMBER_STORAGE_POSITION;
        assembly {
            numberData.slot := position
        }
    }
}

/// implementation of our contract's logic, notice the lack of local state
/// state is always accessed via the storage library defined above
contract Number {

    function setNumber(uint256 _newNumber) external {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        data.number = _newNumber;
    }

    function getNumber() external view returns (uint256) {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        return data.number;
    }
}
```

To compare, here is the same contract written in a regular way:

```solidity
contract Number {

    uint256 private number;

    function setNumber(uint256 _newNumber) external {
        number = _newNumber;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
```

The main difference is how the state is defined. While an `Extension` written this way requires a bit more boilerplate to setup, it is a one time cost that ensures full modularity when using multiple `Extension` contracts with a single `Router`.

### 3. Deploying a `Router`

Deploying a contract in the router pattern looks a little different from deploying a regular contract.

1. Deploy all your `Extension` contracts first. You only need to do this once per `Extension`. Deployed `Extensions` can be re-used by many different `Router` contracts.

2. Deploy your `Router` contract that implements `BaseRouter`.

3. Optionally, you pass your default `Extensions` in the constructor of your `BaseRouter` at deploy time. This is a convenient way to bootstrap an `Router` with a set of default `Extension` in one transaction.

### 4. Adding, removing or upgrading `Extensions` post deployment

The preset `BaseRouter` comes with an API to add/update/remove `Extensions` at any time after deployment:

- `addExtension()`: function to add completely new `Extension` to your `Router`.
- `updateExtension()`: function to update the address, metadata, or functions of an existing `Extension` in your `Router`.
- `removeExtension()`: remove an existing `Extension` from your `Router`.

The permission to modify `Extensions` is encoded in your `Router` and can have different conditions.

With this pattern, your contract is now dynamically updeatable, with granular control.

- Add entire new functionality to your contract post deployment
- Remove functionality when it's not longer needed
- Deploy security and bug fixes for a single function of your contract

---

## Going deeper - background and technical details

In the standard proxy pattern for smart contracts, a proxy smart contract calls a _logic contract_ using `delegateCall`. This allows proxies to keep a persistent state (storage and balance) while the code is delegated to the logic contract. ([EIP-1967](https://eips.ethereum.org/EIPS/eip-1967))

The pattern aims to solve for the following two limitations of this standard proxy pattern:

1. The proxy contract points to a single smart contract as its _logic contract_, at a time.
2. The _logic contract_ is subject to the smart contract size limit of ~24kb ([EIP-170](https://eips.ethereum.org/EIPS/eip-170)). This prevents a single smart contract from having all of the features one may want it to have.

> **Note:** The diamond pattern ([EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)) anticipates these same problems and more. We've taken inspiration from it, and boiled it down to its leanest, simplest form.

The router pattern eliminates these limitations performing a lookup for the implementation smart contract address associated with every incoming function call, and make a `delegateCall` to that particular implementation.

This is different from the standard proxy pattern, where the proxy stores a single implementation smart contract address, and calls via `delegateCall` this same implementation for every incoming function call.

**Standard proxy pattern**

```solidity
contract StandardProxy {

  address public constant implementation = 0xabc...;

  fallback() external payable virtual {
    _delegateCall(implementation);
  }
}
```

**Router pattern**

```solidity
abstract contract Router {

  fallback() external payable virtual {
    address implementation = getImplementationForFunction(msg.sig);
    _delegateCall(implementation);
  }

  function getImplementationForFunction(bytes4 _functionSelector) public view virtual returns (address);
}
```

This setup in the `Router` contract allows for different functions of the smart contract to be implemented in different logic contracts.

### `Extensions` - Grouping logical functionality together

By itself, the core `Router` contract does not specify _how to store or fetch_ appropriate implementation addresses for incoming function calls.

While the Router pattern allows to point to a different contract for each function, in practice functions are usually groupped by functionality related to a shared state (a read and a set function for example).

To make the pattern more practical, we created a generic `BaseRouter` contract that makes it easy to have logical group of functions plugged in and out of it, each group of functions being implemented in a separate implementation contract. We refer to each such implementation contract as an **_extension_**.

`BaseRouter` maintains a `function_signature` → `implementation` mapping, and provides an API for updating that mapping. By updating the values stored in this map, functionality can be added to, removed from or updated in the smart contract.

![updating-extensions](/docs/img/update-diagram.png)

### `Extension` to `Extension` communication

When splitting logic between multiple `Extensions` in a `Router`, one might want to access data from one `Extension` to another.

A simple way to do this is by casting the current contract address as the `Extension` (ideally its interface) we're trying to call. This works from both a `Router` or any of its `Extensions`.

Here's an example of accessing a IPermission `Extension` from another one:

```solidity
/// in MyExtension.sol
modifier onlyAdmin(address _asset) {
  /// we access our IPermission extension by casting our own address
  IPermissions(address(this)).hasAdminRole(msg.sender);
}
```

Note that if we don't have a IPermission `Extension` added to our `Router`, this method will revert.

### Upgrading `Extensions`

Just like any upgradeable contract, there are limitations on how the data structure of the updated contract is modified. While the logic of a function can be updated safely, changing the data structure of a contract requires careful consideration.

A good rule of thumb to follow is:

- It is safe to append new fields to an existing data structure
- It is _not_ safe to update the type or order of existing structs, deprecate and add new ones instead

Refer to [this article](https://mirror.xyz/horsefacts.eth/EPB4o-eyDl0N8gu0gEz1uw7BTITheaZUqIAOEK1m-jE) for more information.

## Feedback

The best, most open way to give feedback/suggestions for the router pattern is to open a github issue.

Additionally, since [thirdweb](https://thirdweb.com/) will be maintaining this repository, you can reach out to us at support@thirdweb.com or join our [discord](https://discord.gg/thirdweb).

## Authors

- [thirdweb](https://github.com/thirdweb-dev)
