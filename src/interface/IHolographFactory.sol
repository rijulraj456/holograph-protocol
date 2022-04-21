HOLOGRAPH_LICENSE_HEADER

pragma solidity 0.8.11;

import "../struct/DeploymentConfig.sol";
import "../struct/Verification.sol";

interface IHolographFactory {

    event BridgeableContractDeployed(address indexed contractAddress, bytes32 indexed hash);

    function getBridgeRegistry() external view returns (address bridgeRegistry);

    function getSecureStorage() external view returns (address secureStorage);

    function deployHolographableContract(DeploymentConfig calldata config, Verification calldata signature, address signer) external;

}