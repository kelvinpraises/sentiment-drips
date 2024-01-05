"use client";
import { getEcoFunds, getProjects } from "@/library/backendAPI";
import { useStore } from "@/library/store/useStore";
import { useEffect, useReducer, useState } from "react";
import ConnectWallet from "../molecules/ConnectWallet";
import GrantCard from "../molecules/GrantCard";

interface GrantCarouselState {
  projects: {
    title: string;
    projectId: number;
    emoji: string;
  }[];
  ecoFunds: {
    title: string;
    ecoFundId: number;
    emoji: string;
  }[];
}

const ProjectEcoFundNav = () => {
  const appActive = useStore((store) => store.appActive);
  const userAddress = useStore((state) => state.userAddress);

  useEffect(() => {
    (async () => {
      const projects = await getProjects(userAddress);
      const ecoFunds = await getEcoFunds(userAddress);

      console.log({
        projects,
        ecoFunds,
      });

      updateValues({ projects, ecoFunds });
    })();
  }, []);

  const [values, updateValues] = useReducer(
    (
      current: GrantCarouselState,
      update: Partial<GrantCarouselState>
    ): GrantCarouselState => {
      return {
        ...current,
        ...update,
      };
    },
    {
      projects: [],
      ecoFunds: [],
    }
  );

  const [activeButton, setActiveButton] = useState("projects");
  return (
    <div className=" max-w-[420px] w-full flex flex-col  bg-white rounded-[10px] h-full">
      <div className=" flex  items-center">
        <button
          className={` px-8 grid place-items-center text-xl font-medium flex-1 h-[70px] ${
            activeButton == "projects" &&
            " bg-[#DEE6E5] text-[#647684] rounded-tl-[10px]"
          }`}
          onClick={() => setActiveButton("projects")}
        >
          Projects
        </button>
        <button
          className={` px-8 grid place-items-center text-xl font-medium flex-1 h-[70px] ${
            activeButton == "ecofunds" &&
            " bg-[#DEE6E5] text-[#647684] rounded-tr-[10px]"
          }`}
          onClick={() => setActiveButton("ecofunds")}
        >
          EocFunds
        </button>
      </div>
      {appActive ? (
        <div className="flex flex-col gap-8 p-8 overflow-y-scroll">
          {activeButton == "projects" ? (
            <>
              {values.projects.map((item, index) => (
                <GrantCard
                  key={index}
                  title={item.title}
                  href={`/grants/projects/${item.projectId}`}
                  emoji={item.emoji}
                />
              ))}
            </>
          ) : (
            <>
              {values.ecoFunds.map((item, index) => (
                <GrantCard
                  key={index}
                  title={item.title}
                  href={`/grants/ecofunds/${item.ecoFundId}`}
                  emoji={item.emoji}
                />
              ))}
            </>
          )}
        </div>
      ) : (
        <div className=" flex-1 grid place-items-center">
          <ConnectWallet />
        </div>
      )}
    </div>
  );
};

export default ProjectEcoFundNav;
