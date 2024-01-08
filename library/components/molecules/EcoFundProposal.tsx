import { useEffect, useState } from "react";

import { EcoFundState } from "@/app/ecosystems/[ecosystem]/[fund]/page";
import { getEcoFundById } from "@/library/backendAPI";
import Button from "../atoms/Button";

const EcoFundProposal = ({ id }: { id: string }) => {
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
          <p className="text-sm font-semibold">EcoFund Proposal</p>
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
            <p className="text-xs font-bold">Created</p>
            <p className="text-sm">{data?.createdAt?.toDateString()}</p>
          </div>
        </div>
      </div>
      <div className="flex flex-col gap-4">
        <div className="flex gap-4 items-center text-[#B1BAC1]">
          <p className="font-medium text-xl text-[#647684]">Proposal Details</p>
        </div>

        <div className=" flex justify-between">
          <p className=" text-sm">
            Vote on whether the proposal fits into the ecosystem
          </p>
          <Button text={"Vote on Proposal"} handleClick={undefined} />
        </div>

        <div className="flex flex-col pt-4 pb-8 gap-8">todo</div>
      </div>
    </>
  );
};

export default EcoFundProposal;
