/*HOLOGRAPH_LICENSE_HEADER*/

/*SOLIDITY_COMPILER_VERSION*/

import "./abstract/Admin.sol";
import "./abstract/Initializable.sol";

import "./interface/HolographInterface.sol";
import "./interface/HolographRegistryInterface.sol";
import "./interface/InitializableInterface.sol";

/**
 * @title Holograph Registry
 * @author https://github.com/holographxyz
 * @notice View and validate all deployed holographable contracts
 * @dev Use this to: validate that contracts are Holograph Protocol compliant, get source code for supported standards, and interact with hTokens
 */
contract HolographRegistry is Admin, Initializable, HolographRegistryInterface {
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.holograph')) - 1)
   */
  bytes32 constant _holographSlot = precomputeslot("eip1967.Holograph.holograph");
  /**
   * @dev bytes32(uint256(keccak256('eip1967.Holograph.utilityToken')) - 1)
   */
  bytes32 constant _utilityTokenSlot = precomputeslot("eip1967.Holograph.utilityToken");

  /**
   * @dev Array of all Holographable contracts that were ever deployed on this chain
   */
  address[] private _holographableContracts;

  /**
   * @dev A mapping of hashes to contract addresses
   */
  mapping(bytes32 => address) private _holographedContractsHashMap;

  /**
   * @dev Storage slot for saving contract type to contract address references
   */
  mapping(bytes32 => address) private _contractTypeAddresses;

  /**
   * @dev Reserved type addresses for Admin
   *  Note: this is used for defining default contracts
   */
  mapping(bytes32 => bool) private _reservedTypes;

  /**
   * @dev A list of smart contracts that are guaranteed secure and holographable
   */
  mapping(address => bool) private _holographedContracts;

  /**
   * @dev Mapping of all hTokens available for the different EVM chains
   */
  mapping(uint32 => address) private _hTokens;

  /**
   * @dev Constructor is left empty and init is used instead
   */
  constructor() {}

  /**
   * @notice Used internally to initialize the contract instead of through a constructor
   * @dev This function is called by the deployer/factory when creating a contract
   * @param initPayload abi encoded payload to use for contract initilaization
   */
  function init(bytes memory initPayload) external override returns (bytes4) {
    require(!_isInitialized(), "HOLOGRAPH: already initialized");
    (address holograph, bytes32[] memory reservedTypes) = abi.decode(initPayload, (address, bytes32[]));
    assembly {
      sstore(_adminSlot, origin())
      sstore(_holographSlot, holograph)
    }
    for (uint256 i = 0; i < reservedTypes.length; i++) {
      _reservedTypes[reservedTypes[i]] = true;
    }
    _setInitialized();
    return InitializableInterface.init.selector;
  }

  function isHolographedContract(address smartContract) external view returns (bool) {
    return _holographedContracts[smartContract];
  }

  function isHolographedHashDeployed(bytes32 hash) external view returns (bool) {
    return _holographedContractsHashMap[hash] != address(0);
  }

  function holographableEvent(bytes calldata payload) external {
    require(_holographedContracts[msg.sender], "HOLOGRAPH: not holographed");
    emit HolographableContractEvent(msg.sender, payload);
  }

  /**
   * @dev Allows to reference a deployed smart contract, and use it's code as reference inside of Holographers
   */
  function referenceContractTypeAddress(address contractAddress) external returns (bytes32) {
    bytes32 contractType;
    assembly {
      contractType := extcodehash(contractAddress)
    }
    require((contractType != 0x0 && contractType != precomputekeccak256("")), "HOLOGRAPH: empty contract");
    require(_contractTypeAddresses[contractType] == address(0), "HOLOGRAPH: contract already set");
    require(!_reservedTypes[contractType], "HOLOGRAPH: reserved address type");
    _contractTypeAddresses[contractType] = contractAddress;
    return contractType;
  }

  /**
   * @dev Returns the contract address for a contract type
   */
  function getContractTypeAddress(bytes32 contractType) external view returns (address) {
    return _contractTypeAddresses[contractType];
  }

  /**
   * @dev Sets the contract address for a contract type
   */
  function setContractTypeAddress(bytes32 contractType, address contractAddress) external onlyAdmin {
    require(_reservedTypes[contractType], "HOLOGRAPH: not reserved type");
    _contractTypeAddresses[contractType] = contractAddress;
  }

  /**
   * @notice Get the Holograph Protocol contract
   * @dev This contract stores a reference to all the primary modules and variables of the protocol
   */
  function getHolograph() external view returns (address holograph) {
    assembly {
      holograph := sload(_holographSlot)
    }
  }

  /**
   * @notice Update the Holograph Protocol contract address
   * @param holograph address of the Holograph Protocol smart contract to use
   */
  function setHolograph(address holograph) external onlyAdmin {
    assembly {
      sstore(_holographSlot, holograph)
    }
  }

  /**
   * @notice Get set length list, starting from index, for all holographable contracts
   * @param index The index to start enumeration from
   * @param length The length of returned results
   * @return contracts address[] Returns a set length array of holographable contracts deployed
   */
  function getHolographableContracts(uint256 index, uint256 length) external view returns (address[] memory contracts) {
    uint256 supply = _holographableContracts.length;
    if (index + length > supply) {
      length = supply - index;
    }
    contracts = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      contracts[i] = _holographableContracts[index + i];
    }
  }

  /**
   * @notice Get total number of deployed holographable contracts
   */
  function getHolographableContractsLength() external view returns (uint256) {
    return _holographableContracts.length;
  }

  /**
   * @dev Returns the address for a holographed hash
   */
  function getHolographedHashAddress(bytes32 hash) external view returns (address) {
    return _holographedContractsHashMap[hash];
  }

  /**
   * @dev Allows Holograph Factory to register a deployed contract, referenced with deployment hash
   */
  function setHolographedHashAddress(bytes32 hash, address contractAddress) external {
    address holograph;
    assembly {
      holograph := sload(_holographSlot)
    }
    require(msg.sender == HolographInterface(holograph).getFactory(), "HOLOGRAPH: factory only function");
    _holographedContractsHashMap[hash] = contractAddress;
    _holographedContracts[contractAddress] = true;
    _holographableContracts.push(contractAddress);
  }

  /**
   * @dev Returns the hToken address for a given chain id
   */
  function getHToken(uint32 chainId) external view returns (address) {
    return _hTokens[chainId];
  }

  /**
   * @dev Sets the hToken address for a specific chain id
   */
  function setHToken(uint32 chainId, address hToken) external onlyAdmin {
    _hTokens[chainId] = hToken;
  }

  /**
   * @dev Returns the reserved contract address for a contract type
   */
  function getReservedContractTypeAddress(bytes32 contractType) external view returns (address contractTypeAddress) {
    if (_reservedTypes[contractType]) {
      contractTypeAddress = _contractTypeAddresses[contractType];
    }
  }

  /**
   * @dev Allows admin to update or toggle reserved type
   */
  function setReservedContractTypeAddress(bytes32 hash, bool reserved) external onlyAdmin {
    _reservedTypes[hash] = reserved;
  }

  /**
   * @dev Allows admin to update or toggle reserved types
   */
  function setReservedContractTypeAddresses(bytes32[] calldata hashes, bool[] calldata reserved) external onlyAdmin {
    for (uint256 i = 0; i < hashes.length; i++) {
      _reservedTypes[hashes[i]] = reserved[i];
    }
  }

  /**
   * @notice Get the Holograph Utility Token address
   * @dev This is the official utility token of the Holograph Protocol
   */
  function getUtilityToken() external view returns (address utilityToken) {
    assembly {
      utilityToken := sload(_utilityTokenSlot)
    }
  }

  /**
   * @notice Update the Holograph Utility Token address
   * @param utilityToken address of the Holograph Utility Token smart contract to use
   */
  function setUtilityToken(address utilityToken) external onlyAdmin {
    assembly {
      sstore(_utilityTokenSlot, utilityToken)
    }
  }

  /**
   * @dev Purposefully reverts to prevent having any type of ether transfered into the contract
   */
  receive() external payable {
    revert();
  }

  /**
   * @dev Purposefully reverts to prevent any calls to undefined functions
   */
  fallback() external payable {
    revert();
  }
}
