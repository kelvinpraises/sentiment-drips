"use client";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

import AllocateSection from "@/components/molecules/AllocateSection";
import ShowcaseSection from "@/components/molecules/ShowcaseSection";
import VoteSection from "@/components/molecules/VoteSection";
import { getDocFundById } from "@/lib/backendAPI";

const page = () => {
  const pathname = usePathname();
  const id = pathname.split("/")[3];

  const [activeScreen, setActiveScreen] = useState("showcase");
  const [data, setData] = useState<{
    id: string;
    title: string;
    description: string;
    tokenAmount: string;
    createdBy: string;
    createdAt: Date;
  }>();

  useEffect(() => {
    (async () => {
      const data = await getDocFundById(id);

      if (data) {
        setData({
          id,
          title: data.title,
          description: data.description,
          createdBy: data.createdBy,
          tokenAmount: data.tokenAmount,
          createdAt: new Date(data.createdAt * 1000),
        });
      }
    })();
  }, [id]);

  return (
    <div className="flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      <div className="flex gap-4 items-center">
        <p className="text-[40px] font-semibold">{data?.title}</p>
        <p className="text-sm font-semibold">DocFund</p>
      </div>
      <div className="flex gap-4 flex-col">
        <div className="flex items-center gap-4">
          <p className="text-sm">{data?.createdBy}</p>
          <p className="text-sm">{data?.tokenAmount} RDT</p>
          <p className="text-sm">{data?.createdAt.toDateString()}</p>
        </div>
        <p>{data?.description}</p>
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
        </div>

        <div className="flex flex-col pt-4 pb-8 gap-8">
          {(() => {
            switch (activeScreen) {
              case "showcase":
                return <ShowcaseSection docFundId={id} />;
              case "allocate":
                return <AllocateSection docFundId={id} />;
              case "vote":
                return <VoteSection docFundId={id} />;
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
