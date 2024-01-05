"use client";
import { useEffect, useReducer } from "react";

import {
  allocateFunds,
  getAllocators,
  getDocFundProjects,
} from "@/lib/backendAPI";
import { useStore } from "@/lib/store/useStore";
import Button from "../atoms/Button";
import AllocationCard from "./AllocationCard";

interface DocFundProjects {
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

const AllocateSection = ({ docFundId }: { docFundId: any }) => {
  // TODO: take into consideration the previous allocations made by user, basically when user edits their prev choice
  useEffect(() => {
    (async () => {
      const allocators = await getAllocators(docFundId);
      const docFundProjects: DocFundProjects[] = await getDocFundProjects(
        docFundId
      );

      console.log(allocators);

      const personalAllocations = docFundProjects.map((docFund) => {
        return {
          projectId: docFund.projectId,
          amount: 0,
          title: docFund.title,
          createdBy: docFund.createdBy,
        };
      });

      updateValues({ allocators, personalAllocations });
    })();
  }, [docFundId]);

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
            docFundId={docFundId}
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
              docFundId={docFundId}
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
