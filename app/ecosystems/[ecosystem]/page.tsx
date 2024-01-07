"use client";
import { useEffect, useState } from "react";

import {
  EcoFund,
  Ecosystem,
  getEcoFunds,
  getEcosystemById,
} from "@/library/backendAPI";
import Button from "@/library/components/atoms/Button";
import EcoFundsPassed from "@/library/components/molecules/EcoFundsPassed";
import EcoFundsProposal from "@/library/components/molecules/EcoFundsProposal";
import { useParams } from "next/navigation";

interface EcosystemWithId extends Ecosystem {
  ecosystemId: number;
}

interface EcosystemData {
  id: string;
  title: string;
  description: string;
  tokenAmount: string;
  createdBy: string;
  createdAt: Date;
  cardArray: EcoFundsData[];
}

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

const page = () => {
  const { ecosystem: blocId } = useParams();

  const [data, setData] = useState<Partial<EcosystemData>>();
  const [activeScreen, setActiveScreen] = useState("ecoFunds");

  useEffect(() => {
    (async () => {
      const ecosystem: EcosystemWithId = await getEcosystemById("1"); // TODO:
      const ecoFunds: EcoFundWithId[] = await getEcoFunds(""); // TODO:

      const newEcosystem = {
        title: ecosystem.name,
        description: ecosystem.description,
        cardArray: ecoFunds.map((ecoFund) => {
          return {
            typeIsLink: true,
            href: `/ecoFund/${ecoFund.ecoFundId}`, // TODO:
            title: ecoFund.title,
            description: ecoFund.description,
            buttonText: "Open EcoFund",
            buttonImg: "enter.svg",
          };
        }),
      };

      setData(newEcosystem);
    })();
  }, []);

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      <div className="flex flex-col gap-2">
        <div className="flex gap-4 items-center">
          <p className="text-[40px] font-semibold">{data?.title}</p>
          <p className="text-sm font-semibold">Ecosystem</p>
        </div>
        <p>{data?.description}</p>
      </div>

      <div className="flex flex-col gap-4 h-full">
        <div className="flex gap-4 items-center text-[#B1BAC1]">
          <button
            className={`font-medium text-xl ${
              activeScreen === "ecoFunds" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("ecoFunds")}
          >
            EcoFunds
          </button>
          <button
            className={`font-medium text-xl ${
              activeScreen === "proposals" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("proposals")}
          >
            Proposals
          </button>
        </div>

        <div className=" flex justify-between">
          <p className="text-sm">
            Start funding projects by proposing an EcoFund for the community
          </p>
          <Button
            text={"Propose EcoFund"}
            link={true}
            href={"/"}
            handleClick={undefined}
          />
        </div>

        <div className="flex flex-col pt-4 pb-8 gap-8 h-full">
          {(() => {
            switch (activeScreen) {
              case "ecoFunds":
                return <EcoFundsPassed ecoFundId={"1"} />; // TODO:
              case "proposals":
                return <EcoFundsProposal ecoFundId={"1"} />; // TODO:
              default:
                return null;
            }
          })()}
        </div>
      </div>
    </div>
  );
};

export default page;
