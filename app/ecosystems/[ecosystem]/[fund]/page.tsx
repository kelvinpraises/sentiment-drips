"use client";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";

import { getEcoFundById } from "@/library/backendAPI";
import EcoFundPassed from "@/library/components/molecules/EcoFundPassed";
import EcoFundProposal from "@/library/components/molecules/EcoFundProposal";

export interface EcoFundState {
  id: string;
  title: string;
  description: string;
  tokenAmount: string;
  createdBy: string;
  strategyAddress: string;
  proposalPassed: number;
  createdAt: Date;
}

const page = () => {
  const pathname = usePathname();
  const id = pathname.split("/")[3];

  const [data, setData] = useState<Partial<EcoFundState>>();

  useEffect(() => {
    (async () => {
      const data = await getEcoFundById(id);

      if (data) {
        setData({
          proposalPassed: data.proposalPassed,
        });
      }
    })();
  }, [id]);

  return (
    <div className="flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 shadow-[0px_4px_15px_5px_rgba(226,229,239,0.25)]">
      {(() => {
        switch (data?.proposalPassed) {
          case 0:
          return <EcoFundProposal  id={id} />; // TODO:
          case 1:
            return <EcoFundPassed id={id} />;
          default:
            return null;
        }
      })()}
    </div>
  );
};

export default page;
