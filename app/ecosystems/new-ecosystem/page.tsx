"use client";
import { useReducer } from "react";

import Button from "@/library/components/atoms/Button";
import Input from "@/library/components/atoms/Input";
import Toggle from "@/library/components/atoms/Toggle";
import TextHead from "@/library/components/molecules/TextHead";
import ProgressModal from "@/library/components/organisms/ProgressModal";

interface NewEcosystem {
  name: string;
  logoURL: string;
  description: string;
  governanceReady: boolean;
  tokenName: string;
  tokenSymbol: string;
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
  tokenName: "",
  tokenSymbol: "",
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
  const [values, updateValues] = useReducer(stateReducer, initialState);

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
            value={values.tokenName}
            onChange={(e) => updateValues({ tokenName: e.target.value })}
          />
          <Input
            label="Token Symbol"
            input={true}
            value={values.tokenSymbol}
            onChange={(e) => updateValues({ tokenSymbol: e.target.value })}
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
            label="Voting Delay"
            input={true}
            value={values.votingDelay.toString()}
            onChange={(e) =>
              updateValues({ votingDelay: parseFloat(e.target.value) })
            }
          />
          <Input
            label="Voting Period"
            input={true}
            value={values.votingPeriod.toString()}
            onChange={(e) =>
              updateValues({ votingPeriod: parseFloat(e.target.value) })
            }
          />
        </div>
        <Input
          label="Quorum %"
          input={true}
          value={values.quorum.toString()}
          onChange={(e) => updateValues({ quorum: parseFloat(e.target.value) })}
        />
        <Input
          label="Min Delay (how long to waits before TimeLock passes)"
          input={true}
          value={values.minDelay.toString()}
          onChange={(e) =>
            updateValues({ minDelay: parseFloat(e.target.value) })
          }
        />
      </div>
      <ProgressModal step={0}>
        <Button
          text={"Create Ecosystem"}
          handleClick={
            () => {}
            // createProject(values, (d: string) => {
            //   router.push("/projects/" + d);
            // })
          }
        />
      </ProgressModal>
    </main>
  );
};

export default page;
