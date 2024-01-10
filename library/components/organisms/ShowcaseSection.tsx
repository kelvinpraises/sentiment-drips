"use client";
import { useEffect, useReducer } from "react";

import { Project, getEcoFundProjects, getProjects } from "@/library/backendAPI";
import { useStore } from "@/library/store/useStore";
import Button from "../atoms/Button";
import LargeCard from "../molecules/LargeCard";
import ShowcaseModal from "../molecules/ShowcaseModal";

interface ProjectWithId extends Project {
  projectId: number;
}

interface ecoFundProjects {
  projectId: number;
  createdBy: string;
  tokensRequested: number;
  emoji: string;
  title: string;
  description: string;
}

interface ShowcaseSectionState {
  ecoFundProjects: ecoFundProjects[];
  showPersonalProjects: boolean;
  projectId: number | undefined;
  personalProjects: ProjectWithId[];
}

const ShowcaseSection = ({ ecoFundId }: { ecoFundId: any }) => {
  const userAddress = useStore((state) => state.userAddress);

  useEffect(() => {
    (async () => {
      const ecoFundProjects = await getEcoFundProjects(ecoFundId);
      const personalProjects = await getProjects(userAddress);

      console.log(ecoFundProjects);

      updateValues({ ecoFundProjects, personalProjects });
    })();
  }, []);

  const [values, updateValues] = useReducer(
    (
      current: ShowcaseSectionState,
      update: Partial<ShowcaseSectionState>
    ): ShowcaseSectionState => {
      return {
        ...current,
        ...update,
      };
    },
    {
      ecoFundProjects: [],
      showPersonalProjects: false,
      projectId: undefined,
      personalProjects: [],
    }
  );

  return (
    <div className="flex flex-col gap-4">
      <div className=" flex justify-between">
        <p className=" text-sm">
          Submit a project to this showcase for a possible funded drip
        </p>

        <ShowcaseModal >
          <Button text={"Showcase Project"} handleClick={() => {}} />
        </ShowcaseModal>
      </div>

      <div className="w-[520px] flex flex-col gap-4">
        {values.ecoFundProjects?.map((x) => {
          return (
            <LargeCard
              title={x.title}
              description={x.description}
              buttonText={"Open Fund"}
              buttonImg={"enter.svg"}
              buttonOnclick={() => {
                throw new Error("Function not implemented.");
              }}
            />
          );
        })}
      </div>
    </div>
  );
};

export default ShowcaseSection;
