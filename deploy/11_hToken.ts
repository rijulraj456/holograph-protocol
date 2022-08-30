declare var global: any;
import fs from 'fs';
import { BigNumberish, BytesLike, ContractFactory, Contract } from 'ethers';
import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy-holographed/types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import {
  LeanHardhatRuntimeEnvironment,
  Signature,
  hreSplit,
  zeroAddress,
  StrictECDSA,
  generateErc20Config,
  generateInitCode,
} from '../scripts/utils/helpers';
import { HolographERC20Event, ConfigureEvents } from '../scripts/utils/events';
import networks from '../config/networks';

const func: DeployFunction = async function (hre1: HardhatRuntimeEnvironment) {
  let { hre, hre2 } = await hreSplit(hre1, global.__companionNetwork);
  const accounts = await hre.ethers.getSigners();
  const deployer: SignerWithAddress = accounts[0];

  const salt = hre.deploymentSalt;

  const network = networks[hre.networkName];

  const error = function (err: string) {
    hre.deployments.log(err);
    process.exit();
  };

  const holographFactoryProxy = await hre.ethers.getContract('HolographFactoryProxy');
  const holographFactory = ((await hre.ethers.getContract('HolographFactory')) as Contract).attach(
    holographFactoryProxy.address
  );

  const holographRegistryProxy = await hre.ethers.getContract('HolographRegistryProxy');
  const holographRegistry = ((await hre.ethers.getContract('HolographRegistry')) as Contract).attach(
    holographRegistryProxy.address
  );

  const chainId = '0x' + network.holographId.toString(16).padStart(8, '0');

  let hTokenAddress = await holographRegistry.getHToken(chainId);

  if (hTokenAddress == zeroAddress()) {
    hre.deployments.log('need to deploy "hToken" for chain:', chainId);

    let { erc20Config, erc20ConfigHash, erc20ConfigHashBytes } = await generateErc20Config(
      network,
      deployer.address,
      'hToken',
      network.tokenName + ' (Holographed)',
      'h' + network.tokenSymbol,
      network.tokenName + ' (Holographed)',
      '1',
      18,
      ConfigureEvents([]),
      generateInitCode(['address', 'uint16'], [deployer.address, 0]),
      salt
    );

    const sig = await deployer.signMessage(erc20ConfigHashBytes);
    const signature: Signature = StrictECDSA({
      r: '0x' + sig.substring(2, 66),
      s: '0x' + sig.substring(66, 130),
      v: '0x' + sig.substring(130, 132),
    } as Signature);

    const depoyTx = await holographFactory.deployHolographableContract(erc20Config, signature, deployer.address, {
      nonce: await hre.ethers.provider.getTransactionCount(deployer.address),
    });
    const deployResult = await depoyTx.wait();
    if (deployResult.events.length < 1 || deployResult.events[0].event != 'BridgeableContractDeployed') {
      throw new Error('BridgeableContractDeployed event not fired');
    }
    hTokenAddress = deployResult.events[0].args[0];
    const setHTokenTx = await holographRegistry.setHToken(chainId, hTokenAddress);
    await setHTokenTx.wait();

    hre.deployments.log('deployed "hToken" at:', await holographRegistry.getHToken(chainId));
  } else {
    hre.deployments.log('reusing "hToken" at:', hTokenAddress);
  }
};

export default func;
func.tags = ['hToken'];
func.dependencies = ['HolographGenesis', 'DeploySources', 'DeployERC20', 'RegisterTemplates'];