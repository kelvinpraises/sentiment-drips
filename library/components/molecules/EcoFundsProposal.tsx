import { EcoFund, getEcoFunds } from "@/library/backendAPI";
import { isEmpty } from "@/library/utils";
import { useEffect, useState } from "react";
import LargeCard from "./LargeCard";

interface EcoFundWithId extends EcoFund {
  ecoFundId: number;
  proposalPassed: number;
}

interface EcoFundsData {
  typeIsLink: boolean;
  href: string;
  title: string;
  description: string;
  buttonText: string;
  buttonImg: string;
}

const EcoFundsProposal = ({ ecoFundId }: { ecoFundId: any }) => {
  const [data, setData] = useState<EcoFundsData[]>();

  useEffect(() => {
    (async () => {
      const ecoFunds: EcoFundWithId[] = await getEcoFunds(ecoFundId); // TODO:

      console.log("ecoFunds ", ecoFunds);

      const newEcoFunds = ecoFunds
        .filter((ecoFund) => ecoFund.proposalPassed === 0)
        .map((ecoFund) => {
          return {
            typeIsLink: true,
            href: `/ecoFund/${ecoFund.ecoFundId}`, // TODO:
            title: ecoFund.title,
            description: ecoFund.description,
            buttonText: "Open Proposal",
            buttonImg: "enter.svg",
          };
        });

      setData(newEcoFunds);
    })();
  }, []);

  return (
    <>
      <div className=" grid grid-cols-2 gap-8">
        {data?.map((card, index) => (
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

      {isEmpty(data) && (
        <div className="flex items-center justify-center h-full">
          <div className="flex flex-col gap-4 mt-[-10rem]">
            <p>No proposals available</p>
          </div>
        </div>
      )}
    </>
  );
};

export default EcoFundsProposal;
