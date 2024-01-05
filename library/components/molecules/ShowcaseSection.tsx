"use client";
import { useEffect, useReducer } from "react";

import {
  Project,
  addProjectToEcoFund,
  getEcoFundProjects,
  getProjects,
} from "@/library/backendAPI";
import { useStore } from "@/library/store/useStore";
import Button from "../atoms/Button";
import SelectProject from "../atoms/SelectProject";
import LargeCard from "./LargeCard";

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
        <Button
          text={"Showcase Project"}
          handleClick={() => updateValues({ showPersonalProjects: true })}
        />
      </div>

      <div className="flex flex-col gap-8">
        <p className="font-bold text-xl">Projects</p>

        <div
          className="flex-1 bg-white rounded-[10px] p-8 overflow-x-scroll flex gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]"
          style={{ display: values.showPersonalProjects ? "flex" : "none" }}
        >
          {values.personalProjects.map((project) => {
            return (
              <SelectProject
                props={{
                  addProjectToEcoFund,
                  updateValues,
                  project,
                  ecoFundId,
                }}
              />
            );
          })}
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
    </div>
  );
};

export default ShowcaseSection;
