"use client";
import { useEffect, useReducer } from "react";

import { createEcosystem } from "@/library/backendAPI";
import Button from "@/library/components/atoms/Button";
import Input from "@/library/components/atoms/Input";
import Toggle from "@/library/components/atoms/Toggle";
import TextHead from "@/library/components/molecules/TextHead";
import ProgressModal from "@/library/components/organisms/ProgressModal";
import {
  deployGovernor,
  deployTimeLock,
  deployVotingToken,
  setupGovernance,
} from "@/library/deploymentFlow";
import { useStore } from "@/library/store/useStore";
import { useRouter } from "next/navigation";
import { Address, parseEther } from "viem";

interface NewEcosystem {
  name: string;
  logoURL: string;
  description: string;
  governanceReady: boolean;
  governanceTokenName: string;
  governanceTokenSymbol: string;
  maxSupply: number;
  mintTo: string;
  votingDelay: number;
  votingPeriod: number;
  quorum: number;
  minDelay: number;
}

const initialState = {
  name: "",
  logoURL: "",
  description: "",
  governanceReady: true,
  governanceTokenName: "",
  governanceTokenSymbol: "",
  maxSupply: 0,
  mintTo: "",
  votingDelay: 0,
  votingPeriod: 0,
  quorum: 0,
  minDelay: 0,
};

const stateReducer = (
  current: NewEcosystem,
  update: Partial<NewEcosystem>
): NewEcosystem => {
  return {
    ...current,
    ...update,
    maxSupply:
      update.maxSupply === undefined
        ? current.maxSupply
        : isNaN(current.maxSupply)
        ? 0
        : update.maxSupply || 0,
    votingDelay:
      update.votingDelay === undefined
        ? current.votingDelay
        : isNaN(current.votingDelay)
        ? 0
        : update.votingDelay || 0,
    votingPeriod:
      update.votingPeriod === undefined
        ? current.votingPeriod
        : isNaN(current.votingPeriod)
        ? 0
        : update.votingPeriod || 0,
    quorum:
      update.quorum === undefined
        ? current.quorum
        : isNaN(current.quorum)
        ? 0
        : update.quorum || 0,
    minDelay:
      update.minDelay === undefined
        ? current.minDelay
        : isNaN(current.minDelay)
        ? 0
        : update.minDelay || 0,
  };
};

const page = () => {
  const router = useRouter();
  const [values, updateValues] = useReducer(stateReducer, initialState);
  const setModalStep = useStore((state) => state.setModalStep);
  const setTransactionHashes = useStore((state) => state.setTransactionHashes);
  const setModalStepIndex = useStore((state) => state.setModalStepIndex);

  useEffect(() => {
    setModalStep([
      { status: "loading" },
      { status: "none" },
      { status: "none" },
      { status: "none" },
    ]);
  }, []);

  const handleCreateNewEcosystem = async () => {
    let txHashes = {};
    let governanceTokenAddress: Address = "0x";
    let timeLockAddress: Address = "0x";
    let governorAddress: Address = "0x";

    await deployVotingToken({
      name: values.governanceTokenName,
      symbol: values.governanceTokenSymbol,
      maxSupply: parseEther(values.maxSupply.toString()),
      callback: (txHash: { [key: string]: Address }, address: Address) => {
        txHashes = { ...txHashes, ...txHash };
        governanceTokenAddress = address;
      },
    });

    setModalStepIndex(0, { status: "done" });
    setModalStepIndex(1, { status: "loading" });

    await deployTimeLock({
      minDelaySec: BigInt(values.minDelay),
      proposers: [],
      executors: [],
      callback: (txHash: { [key: string]: Address }, address: Address) => {
        txHashes = { ...txHashes, ...txHash };
        timeLockAddress = address;
      },
    });

    await deployGovernor({
      token: governanceTokenAddress,
      timeLock: timeLockAddress,
      votingDelayBlocks: values.votingDelay,
      votingPeriodBlocks: values.votingPeriod,
      quorumPercentage: BigInt(values.quorum),
      callback: (txHash: { [key: string]: Address }, address: Address) => {
        txHashes = { ...txHashes, ...txHash };
        governorAddress = address;
      },
    });

    await setupGovernance({
      timeLockAddress: timeLockAddress,
      governorAddress: governorAddress,
      callback: (txHash: { [key: string]: Address }) => {
        txHashes = { ...txHashes, ...txHash };
      },
    });

    setTransactionHashes(txHashes);

    setModalStepIndex(1, { status: "done" });
    setModalStepIndex(2, { status: "loading" });

    setModalStepIndex(2, { status: "done" });
    setModalStepIndex(3, { status: "loading" });

    createEcosystem(
      {
        ...values,
        governanceTokenAddress,
        timeLockAddress,
        governorAddress,
        createdAt: Date.now(),
      },
      (ecosystem: string) => {
        setModalStepIndex(3, { status: "done" });
        setTimeout(() => {
          router.push("/ecosystems/" + ecosystem);
        }, 10_000);
      }
    );
  };

  return (
    <main
      className="flex-1 p-8 overflow-y-scroll flex flex-col gap-8"
      id="newEcosystemModal1"
    >
      <TextHead
        title="Create New Ecosystem"
        description="A community to host all its funding pools"
      />
      <div className=" w-[480px] flex flex-col gap-4">
        <Input
          label="Name"
          input={true}
          value={values.name}
          onChange={(e) => updateValues({ name: e.target.value })}
        />
        <Input
          label="Logo Url"
          input={true}
          value={values.logoURL}
          onChange={(e) => updateValues({ logoURL: e.target.value })}
        />
        <Input
          label="Description"
          input={false}
          value={values.description}
          onChange={(e) => updateValues({ description: e.target.value })}
        />
        <Toggle
          description={"Enable DAO governance for ecosystem"}
          value={values.governanceReady as unknown as string} // TODO:
          onChange={(e) => updateValues({ governanceReady: e.target.value })}
        />
      </div>
      <hr className="bg-[#F2F2F2] w-[480px] outline-none"></hr>
      <div className=" w-[480px] flex flex-col gap-4">
        <h2 className="font-bold text-xl">Voting Token</h2>
        <div className="flex gap-4">
          <Input
            label="Token Name"
            input={true}
            value={values.governanceTokenName}
            onChange={(e) =>
              updateValues({ governanceTokenName: e.target.value })
            }
          />
          <Input
            label="Token Symbol"
            input={true}
            value={values.governanceTokenSymbol}
            onChange={(e) =>
              updateValues({ governanceTokenSymbol: e.target.value })
            }
          />
        </div>
        <Input
          label="Token Max Supply"
          input={true}
          value={values.maxSupply.toString()}
          onChange={(e) =>
            updateValues({ maxSupply: parseFloat(e.target.value) })
          }
        />
        <Input
          label="Mint all to"
          input={true}
          value={values.mintTo}
          onChange={(e) => updateValues({ mintTo: e.target.value })}
        />
      </div>
      <hr className="bg-[#F2F2F2] w-[480px] outline-none"></hr>
      <div className=" w-[480px] flex flex-col gap-4">
        <h2 className="font-bold text-xl">DAO Governance</h2>
        <div className="flex gap-4">
          <Input
            label="Voting Delay (in blocks)"
            input={true}
            value={values.votingDelay.toString()}
            onChange={(e) =>
              updateValues({ votingDelay: parseFloat(e.target.value) })
            }
          />
          <Input
            label="Voting Period (in blocks)"
            input={true}
            value={values.votingPeriod.toString()}
            onChange={(e) =>
              updateValues({ votingPeriod: parseFloat(e.target.value) })
            }
          />
        </div>
        <Input
          label="Quorum % (votes needed for a proposal to pass)"
          input={true}
          value={values.quorum.toString()}
          onChange={(e) => updateValues({ quorum: parseFloat(e.target.value) })}
        />
        <Input
          label="Min Delay (seconds to wait before proposal goes live)"
          input={true}
          value={values.minDelay.toString()}
          onChange={(e) =>
            updateValues({ minDelay: parseFloat(e.target.value) })
          }
        />
      </div>
      <ProgressModal modalItem={"newEcosystem"}>
        <Button
          text={"Create Ecosystem"}
          handleClick={handleCreateNewEcosystem}
        />
      </ProgressModal>
    </main>
  );
};

export default page;
