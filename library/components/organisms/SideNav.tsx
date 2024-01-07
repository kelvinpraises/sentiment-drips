"use client";
import { useEffect, useReducer, useState } from "react";

import { getEcosystems, getProjects } from "@/library/backendAPI";
import { useStore } from "@/library/store/useStore";
import ConnectWallet from "../molecules/ConnectWallet";
import NavCard from "../molecules/NavCard";

interface SideNavState {
  projects: {
    title: string;
    projectId: number;
    emoji: string;
  }[];
  ecosystems: {
    name: string;
    ecosystemId: number;
    logoURL: string;
  }[];
}

const SideNav = () => {
  const appActive = useStore((store) => store.appActive);
  const userAddress = useStore((state) => state.userAddress);

  useEffect(() => {
    if (!appActive) return;
    (async () => {
      const projects = await getProjects(userAddress);
      const ecosystems = await getEcosystems(userAddress);

      console.log({
        projects,
        ecosystems,
      });

      updateValues({ projects, ecosystems });
    })();
  }, [appActive, userAddress]);

  const [values, updateValues] = useReducer(
    (current: SideNavState, update: Partial<SideNavState>): SideNavState => {
      return {
        ...current,
        ...update,
      };
    },
    {
      projects: [],
      ecosystems: [],
    }
  );

  const [activeSelection, setActiveSelection] = useState("projects");
  return (
    <div className=" max-w-[420px] w-full flex flex-col  bg-white rounded-[10px] h-full">
      <div className=" flex  items-center">
        <button
          className={` px-8 grid place-items-center text-xl font-medium flex-1 h-[70px] ${
            activeSelection == "projects" &&
            " bg-[#DEE6E5] text-[#647684] rounded-tl-[10px]"
          }`}
          onClick={() => setActiveSelection("projects")}
        >
          Projects
        </button>
        <button
          className={` px-8 grid place-items-center text-xl font-medium flex-1 h-[70px] ${
            activeSelection == "ecosystems" &&
            " bg-[#DEE6E5] text-[#647684] rounded-tr-[10px]"
          }`}
          onClick={() => setActiveSelection("ecosystems")}
        >
          Ecosystems
        </button>
      </div>
      {appActive ? (
        <div className="flex h-full flex-col gap-8 p-8 overflow-y-scroll">
          {activeSelection === "projects" ? (
            <>
              {values.projects.length > 0 ? (
                values.projects.map((item, index) => (
                  <NavCard
                    key={index}
                    title={item.title}
                    href={`/projects/${item.projectId}`}
                    emoji={item.emoji}
                  />
                ))
              ) : (
                <div className="flex items-center justify-center h-full">
                  <div className="flex flex-col gap-4 mt-[-5rem]">
                    <p>No projects available</p>
                  </div>
                </div>
              )}
            </>
          ) : (
            <>
              {values.ecosystems.length > 0 ? (
                values.ecosystems.map((item, index) => (
                  <NavCard
                    key={index}
                    title={item.name}
                    href={`/ecosystems/${item.ecosystemId}`}
                    logo={item.logoURL}
                  />
                ))
              ) : (
                <div className="flex items-center justify-center h-full">
                  <div className="flex flex-col gap-4 mt-[-5rem]">
                    <p>No ecosystems available</p>
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      ) : (
        <div className="flex-1 grid place-items-center">
          <ConnectWallet />
        </div>
      )}
    </div>
  );
};

export default SideNav;
