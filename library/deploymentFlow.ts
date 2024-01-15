import {
  Address,
  createPublicClient,
  createWalletClient,
  custom,
  http,
  zeroAddress,
} from "viem";
import { sepolia } from "viem/chains";
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

const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
});

const hasWindow = typeof window !== "undefined";

const walletClient = async () => {
  const walletClient = createWalletClient({
    chain: sepolia,
    transport: custom(hasWindow ? (window as any).ethereum : null),
  });

  const chainId = await (window as any).ethereum.request({
    method: "eth_chainId",
  });

  if (walletClient.chain.id !== parseInt(chainId, 16)) {
    await walletClient.switchChain({ id: sepolia.id });
  }

  return walletClient;
};

export const deployVotingToken = async ({
  name,
  symbol,
  maxSupply,
  callback,
}: {
  name: string;
  symbol: string;
  maxSupply: bigint;
  callback: (
    txHash: { [key: string]: Address },
    contractAddress: Address
  ) => void;
}) => {
  const wallet = await walletClient();
  const [account] = await wallet.getAddresses();

  const txHash = await wallet.deployContract({
    abi: votingTokenABI,
    account,
    args: [name, symbol, maxSupply],
    bytecode: `0x${votingTokenBytecode}`,
    gas: BigInt(5_000_000),
  });
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  await wallet.watchAsset({
    type: "ERC20",
    options: {
      address: receipt.contractAddress!,
      decimals: 18,
      symbol,
    },
  });

  callback({ "Token creation hash": txHash }, receipt.contractAddress!);
};

export const deployTimeLock = async ({
  minDelaySec,
  proposers,
  executors,
  callback,
}: {
  minDelaySec: bigint;
  proposers: Address[];
  executors: Address[];
  callback: (
    txHash: { [key: string]: Address },
    contractAddress: Address
  ) => void;
}) => {
  const wallet = await walletClient();
  const [account] = await wallet.getAddresses();
  const txHash = await wallet.deployContract({
    abi: timeLockABI,
    account,
    args: [account, minDelaySec, proposers, executors],
    bytecode: `0x${timeLockBytecode}`,
    gas: BigInt(5_000_000),
  });
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  callback({ "TimeLock deployment hash": txHash }, receipt.contractAddress!);
};

export const deployGovernor = async ({
  token,
  timeLock,
  votingDelayBlocks,
  votingPeriodBlocks,
  quorumPercentage,
  callback,
}: {
  token: Address;
  timeLock: Address;
  votingDelayBlocks: number;
  votingPeriodBlocks: number;
  quorumPercentage: bigint;
  callback: (
    txHash: { [key: string]: Address },
    contractAddress: Address
  ) => void;
}) => {
  const wallet = await walletClient();
  const [account] = await wallet.getAddresses();
  const txHash = await wallet.deployContract({
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
    gas: BigInt(5_000_000),
  });
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  callback({ "Governor deployment hash": txHash }, receipt.contractAddress!);
};

export const setupGovernance = async ({
  timeLockAddress,
  governorAddress,
  callback,
}: {
  timeLockAddress: Address;
  governorAddress: Address;
  callback: (txHash: { [key: string]: Address }) => void;
}) => {
  const wallet = await walletClient();
  const [account] = await wallet.getAddresses();

  const timeLockCOntract = { address: timeLockAddress, abi: timeLockABI };

  const [proposeRole, executorRole, adminRole] = await publicClient.multicall({
    contracts: [
      {
        ...timeLockCOntract,
        functionName: "PROPOSER_ROLE",
      },
      {
        ...timeLockCOntract,
        functionName: "EXECUTOR_ROLE",
      },
      {
        ...timeLockCOntract,
        functionName: "DEFAULT_ADMIN_ROLE",
      },
    ],
  });

  const { request: req1 } = await publicClient.simulateContract({
    ...timeLockCOntract,
    functionName: "grantRole",
    args: [proposeRole.result!, governorAddress],
    account,
  });

  const { request: req2 } = await publicClient.simulateContract({
    ...timeLockCOntract,
    functionName: "grantRole",
    args: [executorRole.result!, zeroAddress],
    account,
  });

  const { request: req3 } = await publicClient.simulateContract({
    ...timeLockCOntract,
    functionName: "revokeRole",
    args: [adminRole.result!, account],
    account,
  });

  const req1TxHash = await wallet.writeContract(req1);
  const req2TxHash = await wallet.writeContract(req2);
  const req3TxHash = await wallet.writeContract(req3);

  callback({
    "Governor granted proposer role hash": req1TxHash,
    "Everyone granted executor role hash": req2TxHash,
    "TimeLock admin revoked role hash": req3TxHash,
  });
};

export const deployStrategy = async ({
  alloAddress,
  strategyName,
  callback,
}: {
  alloAddress: Address;
  strategyName: string;
  callback: (
    txHash: { [key: string]: Address },
    contractAddress: Address
  ) => void;
}) => {
  const wallet = await walletClient();
  const [account] = await wallet.getAddresses();
  const txHash = await (
    await walletClient()
  ).deployContract({
    abi: donationVotingMerkleDripABI,
    account,
    args: [alloAddress, strategyName],
    bytecode: `0x${donationVotingMerkleDripBytecode}`,
    gas: BigInt(5_000_000),
  });
  const receipt = await publicClient.waitForTransactionReceipt({
    hash: txHash,
  });

  callback({ "Strategy deployment hash": txHash }, receipt.contractAddress!);
};
