"use client";
import { useParams } from "next/navigation";
import { useEffect, useState } from "react";

import { Project, getProjectById } from "@/library/backendAPI";
import TextHead from "@/library/components/molecules/TextHead";

const page = () => {
  const { project: projectId } = useParams();

  const [data, setData] = useState<Project>();

  useEffect(() => {
    (async () => {
      const project = await getProjectById(projectId as string);

      setData(project);
    })();
  }, []);

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      <TextHead
        title={data?.title}
        description={data?.description}
        tag={"EcoFund Project"}
      />
      <div className=" flex flex-col gap-8">
        <p className=" font-bold text-xl">EcoFunds Applied</p>
        {/* <div className=" grid grid-cols-2 gap-8">
          {data?.cardArray.map((card, index) => (
            <Card1
              key={index}
              title={card.title}
              description={card.text}
              buttonText={card.buttonText}
              buttonOnclick={function (): {} {
                throw new Error("Function not implemented.");
              }}
              buttonImg="enter.svg"
            />
          ))}
        </div> */}
      </div>
    </div>
  );
};

export default page;
