"use client";
import { useEffect, useState } from "react";

import TextHead from "../../components/molecules/TextHead";
import LargeCard from "../../components/molecules/LargeCard";
import useBackendAPI, { EcoFund } from "../../lib/hooks/backendAPI";

interface EcoFundWithId extends EcoFund {
  ecoFundId: number;
}

interface EcoFundsData {
  typeIsLink: boolean;
  href: string;
  title: string;
  description: string;
  buttonText: string;
  buttonImg: string;
}

const initData = {
  title: "Ecosystems",
  subtitle:
    "Supporting impactful retroactive project funding for stakeholders and builders",
  tag: "Home | Ecosystems",
  cardArray: [] as EcoFundsData[],
};

const page = () => {
  const { getEcoFunds } = useBackendAPI();
  const [data, setData] = useState(initData);

  useEffect(() => {
    (async () => {
      const ecoFunds: EcoFundWithId[] = await getEcoFunds("");

      const newEcoFunds = ecoFunds.map((ecoFund) => {
        return {
          typeIsLink: true,
          href: `/ecofunds/${ecoFund.ecoFundId}`,
          title: ecoFund.title,
          description: ecoFund.description,
          buttonText: "Open Fund",
          buttonImg: "enter.svg",
        };
      });

      setData((prev) => {
        prev.cardArray = newEcoFunds;
        return prev;
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
    </div>
  );
};

export default page;
