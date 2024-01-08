import { useEffect, useState } from "react";

import { EcoFundState } from "@/app/ecosystems/[ecosystem]/[fund]/page";
import { getEcoFundById } from "@/library/backendAPI";
import AllocateSection from "./AllocateSection";
import ShowcaseSection from "./ShowcaseSection";
import VoteSection from "./VoteSection";

const EcoFundPassed = ({ id }: { id: string }) => {
  const [activeScreen, setActiveScreen] = useState("showcase");
  const [data, setData] = useState<Partial<EcoFundState>>();

  useEffect(() => {
    (async () => {
      const data = await getEcoFundById(id);

      if (data) {
        setData({
          id,
          title: data.title,
          description: data.description,
          createdBy: data.createdBy,
          tokenAmount: data.tokenAmount,
          strategyAddress: data.strategyAddress,
          createdAt: new Date(data.createdAt * 1000),
        });
      }
    })();
  }, [id]);

  return (
    <>
      <div className="flex flex-col gap-2">
        <div className="flex gap-4 items-center">
          <p className="text-[40px] font-semibold">{data?.title}</p>
          <p className="text-sm font-semibold">EcoFund</p>
        </div>
        <p>{data?.description}</p>
      </div>
      <div className="flex gap-4 flex-col">
        <div className="flex items-center gap-4">
          <div className="flex flex-col gap-1">
            <p className="text-xs font-bold">Strategy</p>
            <p className="text-sm">{data?.strategyAddress}</p>
          </div>
          <div className="flex flex-col gap-1">
            <p className="text-xs font-bold">Pool</p>
            <p className="text-sm">{data?.tokenAmount}5000 RDT</p> {/* TODO: */}
          </div>
          <div className="flex flex-col gap-1">
            <p className="text-xs font-bold">Created</p>
            <p className="text-sm">{data?.createdAt?.toDateString()}</p>
          </div>
        </div>
      </div>
      <div className="flex flex-col gap-4">
        <div className="flex gap-4 items-center text-[#B1BAC1]">
          <button
            className={`font-medium text-xl ${
              activeScreen === "showcase" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("showcase")}
          >
            Showcase
          </button>
          <button
            className={`font-medium text-xl ${
              activeScreen === "review" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("review")}
          >
            Review
          </button>
          <button
            className={`font-medium text-xl ${
              activeScreen === "allocate" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("allocate")}
          >
            Allocate
          </button>
          <button
            className={`font-medium text-xl ${
              activeScreen === "vote" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("vote")}
          >
            Vote
          </button>
          <button
            className={`font-medium text-xl ${
              activeScreen === "distribute" && "text-[#647684]"
            }`}
            onClick={() => setActiveScreen("distribute")}
          >
            Distribute
          </button>
        </div>

        <div className="flex flex-col pt-4 pb-8 gap-8">
          {(() => {
            switch (activeScreen) {
              case "showcase":
                return <ShowcaseSection ecoFundId={id} />;
              case "allocate":
                return <AllocateSection ecoFundId={id} />;
              case "vote":
                return <VoteSection ecoFundId={id} />;
              default:
                return null;
            }
          })()}
        </div>
      </div>
    </>
  );
};

export default EcoFundPassed;
