// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IRouter {
    fallback() external payable;

    function getImplementationForFunction(bytes4 _functionSelector) external view returns (address);
}