"use client";
import { useEffect, useReducer } from "react";

import {
  allocateFunds,
  getAllocators,
  getEcoFundProjects,
} from "@/library/backendAPI";
import { useStore } from "@/library/store/useStore";
import Button from "../atoms/Button";
import AllocationCard from "./AllocationCard";

interface ecoFundProjects {
  projectId: number;
  createdBy: string;
  tokensRequested: number;
  emoji: string;
  title: string;
  description: string;
}

export interface AllocateSectionState {
  showAllocateSentiment: boolean;
  allocators: Allocation[];
  personalAllocations: Allocation["allocated"];
}

interface Allocation {
  name: string;
  address: string;
  allocated: {
    projectId: number;
    amount: number;
    title: string;
    createdBy: string;
  }[];
}

const AllocateSection = ({ ecoFundId }: { ecoFundId: any }) => {
  // TODO: take into consideration the previous allocations made by user, basically when user edits their prev choice
  useEffect(() => {
    (async () => {
      const allocators = await getAllocators(ecoFundId);
      const ecoFundProjects: ecoFundProjects[] = await getEcoFundProjects(
        ecoFundId
      );

      console.log(allocators);

      const personalAllocations = ecoFundProjects.map((ecoFund) => {
        return {
          projectId: ecoFund.projectId,
          amount: 0,
          title: ecoFund.title,
          createdBy: ecoFund.createdBy,
        };
      });

      updateValues({ allocators, personalAllocations });
    })();
  }, [ecoFundId]);

  const [values, updateValues] = useReducer(
    (
      current: AllocateSectionState,
      update: Partial<AllocateSectionState>
    ): AllocateSectionState => {
      return {
        ...current,
        ...update,
      };
    },
    {
      showAllocateSentiment: false,
      allocators: [],
      personalAllocations: [],
    }
  );

  const userAddress = useStore((state) => state.userAddress);
  const userName = useStore((state) => state.userName);

  return (
    <div className="flex flex-col gap-4">
      <div className=" flex justify-between">
        <p className="text-sm">
          Sentiments determine what projects are worth, and are averaged for
          final voting
        </p>
        <Button
          text={"Allocate Sentiment"}
          handleClick={() => updateValues({ showAllocateSentiment: true })}
        />
      </div>

      <div className="flex flex-col gap-8">
        <p className="font-bold text-xl">Allocators</p>
        {values.showAllocateSentiment && (
          <AllocationCard
            ecoFundId={ecoFundId}
            name={userName}
            address={userAddress}
            open
            allocated={values.personalAllocations}
            updateValues={updateValues}
            allocateFunds={allocateFunds}
          />
        )}
        {values.allocators.map(({ name, address, allocated }) => {
          return (
            <AllocationCard
              ecoFundId={ecoFundId}
              name={name}
              address={address}
              allocated={allocated}
              readonly
            />
          );
        })}
      </div>
    </div>
  );
};

export default AllocateSection;
