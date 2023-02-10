# Plugin Pattern: an open standard for dynamic smart contracts.

Plugin pattern is a code / architectural pattern for writing dynamic smart contracts.

## Background

In the standard proxy pattern for smart contracts, a proxy smart contract calls a _logic contract_ using `delegateCall`. This allows proxies to keep a persistent state (storage and balance) while the code is delegated to the logic contract. ([EIP-1967](https://eips.ethereum.org/EIPS/eip-1967))

The pattern aims to solve for the following two limitations of this standard proxy pattern:

1. The proxy contract points to a single smart contract as its _logic contract_, at a time.
2. The _logic contract_ is subject to the smart contract size limit of ~24kb ([EIP-170](https://eips.ethereum.org/EIPS/eip-170)). This prevents a single smart contract from having all of the features one may want it to have.

> **Note:**  The diamond pattern ([EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)) anticipates these same problems and more. We've taken inspiration from it, and boiled it down to its leanest, simplest form.

The plugin pattern eliminates these limitations by making a proxy contract perform a lookup for the implementation smart contract address associated with any given incoming function call, and make a `delegateCall` to that particular implementation. 

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

**Plugin pattern**
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

### Smart contract _plugins_

By itself, the `Router` contract does not specify _how to store or fetch_ appropriate implementation addresses for incoming function calls.

To complement `Router`'s core functionality, the `BaseRouter` contract comes with an opinionated API to manage what functions should be mapped to what implementations.

The `BaseRouter` contract prepares `Router` to have implementation smart contracts plugged in and out of it. We refer to each such implementation smart contract as a **_plugin_**.

**Standard proxy pattern**
![standard-proxy](https://blog.thirdweb.com/content/images/size/w1600/2023/02/plugin-pattern-diag-1.png)
**Plugin pattern**
![plugin-pattern](https://blog.thirdweb.com/content/images/size/w1600/2023/02/plugin-pattern-diag2.png)

Essentially, `BaseRouter` maintains a `function_signature` → `implementation` mapping, and provides an API for updating that mapping. By updating the values stored in this map, functionality can be added to, removed from or updated in the smart contract!

![updating-plugins](https://blog.thirdweb.com/content/images/size/w1600/2023/02/plugin-pattern-diag3.png)

At construction time, the `BaseRouter` contract accepts a default set of plugins that belong to the contract; these can only be overriden, not entirely removed. Other plugins can be added to the contract, updated and removed from the contract over time.

The `BaseRouter` contract is an abstract contract, and expects its consumer to implement the `_canSetPlugin()` function, which specifies the conditions under which plugins can be added, updated or removed.

```solidity
function _canSetPlugin() internal view virtual returns (bool);
```

## Usage

Install the contents of this repo in your `forge` repository.
```bash
forge install https://github.com/thirdweb-dev/plugin-pattern
```

### Router.sol
The core `Router` smart contract is available as an import. 
```solidity
import "lib/plugin-pattern/src/core/Router.sol";
```

To use the abstract contract `Router`, you must implement the `getImplementationForFunction` function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/plugin-pattern/src/core/Router.sol";

contract SimpleRouter is Router {

    mapping(bytes4 => address) public fnToImpl; 

    fallback() external payable virtual {
        address implementation = getImplementationForFunction(msg.sig);
        delegateCall(implementation);
    }

    function getImplementationForFunction(bytes4 _functionSelector) 
      public 
      view 
      virtual 
      override
      returns (address) 
    {
        return fnToImpl[_functionSelector];
    }
  
    function setImplementationForFunction(bytes4 _functionSelector, address _impl) external {
        fnToImpl[_functionSelector] = _impl;
    }
}
```

### BaseRouter.sol

The `BaseRouter` smart contract builds on top of the core `Router` smart contract, and is available as an import.

```solidity
import "lib/plugin-pattern/src/presets/BaseRouter.sol";
```
The `BaseRouter` contract comes with an API to add/update/remove plugins from the contract. To use the abstract contract `BaseRouter`, you must specifcy the conditions under which plugins can be updated:

```solidity
import "lib/plugin-pattern/src/presets/BaseRouter.sol";

contract RouterUpgradeable is BaseRouter {
    
    address public deployer;

    constructor(Plugin[] memory _plugins) BaseRouter(_plugins) {
        deployer = msg.sender;
    }

    /// @dev Returns whether plug-in can be set in the given execution context.
    function _canSetPlugin() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }
}
```
### Writing a smart contract plugin.

A plugin smart contract is written like any other smart contract, expect that its state must be defined in a library and at a well defined storage location.

This is to ensure that state defined in different plugins of the same `Router` don't affect the same storage locations by accident.

**Regular smart contract**
```solidity
contract Number {

    uint256 private number;

    function setNumber(uitn256 _newNumber) external {
        number = _newNumber;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
```

**Plugin smart contract**
```solidity

library NumberStorage {

    bytes32 public constant NUMBER_STORAGE_POSITION = keccak256("number.storage");

    struct Data {
        uint256 number;
    }

    function numberStorage() internal pure returns (Data storage numberData) {
        bytes32 position = NUMBER_STORAGE_POSITION;
        assembly {
            numberData.slot := position
        }
    }
}

contract Number {

    uint256 private number;

    function setNumber(uitn256 _newNumber) external {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        data.number = _newNumber;
    }

    function getNumber() external view returns (uint256) {
        NumberStorage.Data storage data = NumberStorage.numberStorage();
        return data.number;
    }
}
```

## Feedback

The best, most open way to give feedback/suggestions for the plugin pattern is to open a github issue. 

Additionally, since [thirdweb](https://thirdweb.com/) will be maintaining this repository, you can reach out to us at support@thirdweb.com.

## Authors
* [thirdweb](https://github.com/thirdweb-dev)