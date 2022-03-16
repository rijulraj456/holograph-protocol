// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.11;

contract OpenSeaOwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
    mapping(address => OpenSeaOwnableDelegateProxy) public proxies;
}
