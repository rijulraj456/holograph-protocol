// SPDX-License-Identifier: UNLICENSED
/*

  ,,,,,,,,,,,
 [ HOLOGRAPH ]
  '''''''''''
  _____________________________________________________________
 |                                                             |
 |                            / ^ \                            |
 |                            ~~*~~            .               |
 |                         [ '<>:<>' ]         |=>             |
 |               __           _/"\_           _|               |
 |             .:[]:.          """          .:[]:.             |
 |           .'  []  '.        \_/        .'  []  '.           |
 |         .'|   []   |'.               .'|   []   |'.         |
 |       .'  |   []   |  '.           .'  |   []   |  '.       |
 |     .'|   |   []   |   |'.       .'|   |   []   |   |'.     |
 |   .'  |   |   []   |   |  '.   .'  |   |   []   |   |  '.   |
 |.:'|   |   |   []   |   |   |':'|   |   |   []   |   |   |':.|
 |___|___|___|___[]___|___|___|___|___|___|___[]___|___|___|___|
 |XxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxXxXxXxXxXxXxX[]XxXxXxXxXxXxXxX|
 |^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^^^^^^^^^^^^^[]^^^^^^^^^^^^^^^|
 |               []                           []               |
 |               []                           []               |
 |    ,          []     ,        ,'      *    []               |
 |~~~~~^~~~~~~~~/##\~~~^~~~~~~~~^^~~~~~~~~^~~/##\~~~~~~~^~~~~~~|
 |_____________________________________________________________|

             - one bridge, infinite possibilities -


 ***************************************************************

 DISCLAIMER: U.S Patent Pending

 LICENSE: Holograph Limited Public License (H-LPL)

 https://holograph.xyz/licenses/h-lpl/1.0.0

 This license governs use of the accompanying software. If you
 use the software, you accept this license. If you do not accept
 the license, you are not permitted to use the software.

 1. Definitions

 The terms "reproduce," "reproduction," "derivative works," and
 "distribution" have the same meaning here as under U.S.
 copyright law. A "contribution" is the original software, or
 any additions or changes to the software. A "contributor" is
 any person that distributes its contribution under this
 license. "Licensed patents" are a contributor’s patent claims
 that read directly on its contribution.

 2. Grant of Rights

 A) Copyright Grant- Subject to the terms of this license,
 including the license conditions and limitations in sections 3
 and 4, each contributor grants you a non-exclusive, worldwide,
 royalty-free copyright license to reproduce its contribution,
 prepare derivative works of its contribution, and distribute
 its contribution or any derivative works that you create.
 B) Patent Grant- Subject to the terms of this license,
 including the license conditions and limitations in section 3,
 each contributor grants you a non-exclusive, worldwide,
 royalty-free license under its licensed patents to make, have
 made, use, sell, offer for sale, import, and/or otherwise
 dispose of its contribution in the software or derivative works
 of the contribution in the software.

 3. Conditions and Limitations

 A) No Trademark License- This license does not grant you rights
 to use any contributors’ name, logo, or trademarks.
 B) If you bring a patent claim against any contributor over
 patents that you claim are infringed by the software, your
 patent license from such contributor is terminated with
 immediate effect.
 C) If you distribute any portion of the software, you must
 retain all copyright, patent, trademark, and attribution
 notices that are present in the software.
 D) If you distribute any portion of the software in source code
 form, you may do so only under this license by including a
 complete copy of this license with your distribution. If you
 distribute any portion of the software in compiled or object
 code form, you may only do so under a license that complies
 with this license.
 E) The software is licensed “as-is.” You bear all risks of
 using it. The contributors give no express warranties,
 guarantees, or conditions. You may have additional consumer
 rights under your local laws which this license cannot change.
 To the extent permitted under your local laws, the contributors
 exclude all implied warranties, including those of
 merchantability, fitness for a particular purpose and
 non-infringement.

 4. (F) Platform Limitation- The licenses granted in sections
 2.A & 2.B extend only to the software or derivative works that
 you create that run on a Holograph system product.

 ***************************************************************

*/

pragma solidity 0.8.11;

import "./interface/ERC721Holograph.sol";
import "./interface/HolographedERC721.sol";
import "./interface/IInitializable.sol";

/**
 * @title Sample ERC-721 Collection that is bridgeable via Holograph
 * @author CXIP-Labs
 * @notice A smart contract for minting and managing Holograph Bridgeable ERC721 NFTs.
 * @dev The entire logic and functionality of the smart contract is self-contained.
 */
contract SampleERC721 is IInitializable, HolographedERC721  {

    /*
     * @dev Address of initial creator/owner of the collection.
     */
    address private _owner;

    /*
     * @dev Address of Holograph ERC721 standards enforcer smart contract.
     */
    address private _holographer;

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bool private _success;

    /*
     * @dev Dummy variable to prevent empty functions from making "switch to pure" warnings.
     */
    bytes private _data;

    mapping(uint256 => string) private _tokenURIs;

    modifier onlyHolographer() {
        require(msg.sender == _holographer, "holographer only function");
        _;
    }

    /**
     * @notice Constructor is empty and not utilised.
     * @dev To make exact CREATE2 deployment possible, constructor is left empty. We utilize the "init" function instead.
     */
    constructor() {}

    /**
     * @notice Initializes the collection.
     * @dev Special function to allow a one time initialisation on deployment. Also configures and deploys royalties.
     */
    function init(bytes memory data) external returns (bytes4) {
        _holographer = msg.sender;
        (address owner) = abi.decode(data, (address));
        _owner = owner;
        return IInitializable.init.selector;
    }

    /**
     * @notice Get's the URI of the token.
     * @dev Defaults the the Arweave URI
     * @return string The URI.
     */
    function tokenURI(uint256 tokenId) external view onlyHolographer returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function test() external pure returns (string memory) {
        return "it works!";
    }

    function bridgeIn(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external onlyHolographer returns (bool success) {
        // dummy input to prevent "switch to view" warnings
        _success = true;
        return _success;
    }

    function bridgeOut(address/* _from*/, address/* _to*/, uint256/* _tokenId*/) external onlyHolographer returns (bytes memory/* _data*/) {
        // dummy input to prevent "switch to view" warnings
        _success = true;
        return _data;
    }

    function afterApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeApprove(address/* _owner*/, address/* _to*/, uint256/* _tokenId*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function afterApprovalAll(address/* _to*/, bool/* _approved*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeApprovalAll(address/* _to*/, bool/* _approved*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function afterBurn(address/* _owner*/, uint256/* _tokenId*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeBurn(address/* _owner*/, uint256/* _tokenId*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function afterMint() external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeMint() external view onlyHolographer returns (bool success) {
        return _success;
    }

    function afterSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeSafeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function afterTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

    function beforeTransfer(address/* _from*/, address/* _to*/, uint256/* _tokenId*/, bytes calldata/* _data*/) external view onlyHolographer returns (bool success) {
        return _success;
    }

}