import {
  Address,
  createPublicClient,
  createWalletClient,
  custom,
  http,
  zeroAddress,
} from "viem";
import { goerli } from "viem/chains";
import {
  donationVotingMerkleDripABI,
  governorABI,
  timeLockABI,
  votingTokenABI,
} from "./contract/abi-data";
import {
  donationVotingMerkleDripBytecode,
  governorBytecode,
  timeLockBytecode,
  votingTokenBytecode,
} from "./contract/bytecode-data";

const walletClient = createWalletClient({
  chain: goerli,
  transport: custom(
    typeof window !== "undefined" ? (window as any).ethereum : null
  ),
});

const publicClient = createPublicClient({
  chain: goerli,
  transport: http(),
});

export const deployVotingToken = async ({
  name,
  symbol,
  maxSupply,
}: {
  name: string;
  symbol: string;
  maxSupply: bigint;
}) => {
  const [account] = await walletClient.getAddresses();
  const txHash = await walletClient.deployContract({
    abi: votingTokenABI,
    account,
    args: [name, symbol, maxSupply],
    bytecode: `0x${votingTokenBytecode}`,
  });
  return txHash;
};

export const deployTimeLock = async ({
  minDelaySec,
  proposers,
  executors,
}: {
  minDelaySec: bigint;
  proposers: Address[];
  executors: Address[];
}) => {
  const [account] = await walletClient.getAddresses();
  const txHash = await walletClient.deployContract({
    abi: timeLockABI,
    account,
    args: [minDelaySec, proposers, executors],
    bytecode: `0x${timeLockBytecode}`,
  });
  return txHash;
};

export const deployGovernor = async ({
  token,
  timeLock,
  votingDelayBlocks,
  votingPeriodBlocks,
  quorumPercentage,
}: {
  token: Address;
  timeLock: Address;
  votingDelayBlocks: number;
  votingPeriodBlocks: number;
  quorumPercentage: bigint;
}) => {
  const [account] = await walletClient.getAddresses();
  const txHash = await walletClient.deployContract({
    abi: governorABI,
    account,
    args: [
      token,
      timeLock,
      votingDelayBlocks,
      votingPeriodBlocks,
      quorumPercentage,
    ],
    bytecode: `0x${governorBytecode}`,
  });
  return txHash;
};

export const setupGovernance = async ({
  timeLockAddress,
  governorAddress,
}: {
  timeLockAddress: Address;
  governorAddress: Address;
}) => {
  const [account] = await walletClient.getAddresses();

  const proposeRole = await publicClient.readContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "PROPOSER_ROLE",
  });

  const executorRole = await publicClient.readContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "EXECUTOR_ROLE",
  });

  const adminRole = await publicClient.readContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "DEFAULT_ADMIN_ROLE",
  });

  const { request: req1 } = await publicClient.simulateContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "grantRole",
    args: [proposeRole, governorAddress],
    account,
  });

  const { request: req2 } = await publicClient.simulateContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "grantRole",
    args: [executorRole, zeroAddress],
    account,
  });

  const { request: req3 } = await publicClient.simulateContract({
    address: timeLockAddress,
    abi: timeLockABI,
    functionName: "revokeRole",
    args: [adminRole, account],
    account,
  });

  const req1TxHash = await walletClient.writeContract(req1);
  const req2TxHash = await walletClient.writeContract(req2);
  const req3TxHash = await walletClient.writeContract(req3);

  return [req1TxHash, req2TxHash, req3TxHash];
};

export const deployStrategy = async ({
  alloAddress,
  strategyName,
}: {
  alloAddress: Address;
  strategyName: string;
}) => {
  const [account] = await walletClient.getAddresses();
  const txHash = await walletClient.deployContract({
    abi: donationVotingMerkleDripABI,
    account,
    args: [alloAddress, strategyName],
    bytecode: `0x${donationVotingMerkleDripBytecode}`,
  });
  return txHash;
};
