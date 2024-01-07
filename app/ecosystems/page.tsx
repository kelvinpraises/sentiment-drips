"use client";
import { useEffect, useState } from "react";

import { Ecosystem, getEcosystems } from "@/library/backendAPI";
import LargeCard from "@/library/components/molecules/LargeCard";
import TextHead from "@/library/components/molecules/TextHead";

interface EcosystemWithId extends Ecosystem {
  ecosystemId: number;
}

interface EcosystemData {
  typeIsLink: boolean;
  href: string;
  title: string;
  description: string;
  buttonText: string;
  buttonImg: string;
}

const initData = {
  title: "Ecosystems",
  subtitle: "Communities funding impactful projects",
  tag: "Home | Ecosystems",
  cardArray: [] as EcosystemData[],
};

const page = () => {
  const [data, setData] = useState(initData);

  useEffect(() => {
    (async () => {
      const ecosystem: EcosystemWithId[] = await getEcosystems("");

      const newEcosystem = ecosystem.map((ecosystem) => {
        return {
          typeIsLink: true,
          href: `/ecosystems/${ecosystem.ecosystemId}`,
          title: ecosystem.name,
          description: ecosystem.description,
          buttonText: "Open Ecosystem",
          buttonImg: "enter.svg",
        };
      });

      setData((prev) => {
        prev.cardArray = newEcosystem;
        return { ...prev };
      });
    })();
  }, []);

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      <TextHead title={data.title} description={data.subtitle} tag={data.tag} />

      <div className=" grid grid-cols-2 gap-8">
        {data.cardArray?.map((card, index) => (
          <LargeCard
            typeIsLink={card.typeIsLink}
            href={card.href}
            key={index}
            title={card.title}
            description={card.description}
            buttonText={card.buttonText}
          />
        ))}
      </div>

      {data.cardArray.length === 0 && (
        <div className="flex items-center justify-center h-full">
          <div className="flex flex-col gap-4 mt-[-10rem]">
            <p>No ecosystems available</p>
          </div>
        </div>
      )}
    </div>
  );
};

export default page;
