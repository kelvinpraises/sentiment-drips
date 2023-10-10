"use client";
import { Allocation } from "@/hooks/backendAPI";
import { produce } from "immer";
import { useRouter } from "next/navigation";
import { Dispatch, useState } from "react";
import { AllocateSectionState } from "../organisms/FundsScreen";

interface cardProps {
  docFundId: string;
  updateValues?: Dispatch<Partial<AllocateSectionState>>;
  name: string;
  address: string;
  allocateFunds?: (
    docFundId: string,
    allocations: Allocation[],
    callback: () => void
  ) => Promise<void>;
  allocated: {
    projectId: number;
    amount: number;
    title: string;
    createdBy: string;
  }[];
  readonly?: boolean;
  open?: boolean;
}

const AllocationCard = (card: cardProps) => {
  const [showMore, setShowMore] = useState(false);
  const router = useRouter();

  return (
    <div className=" p-8 flex flex-col gap-4 w-full bg-[#DEE6E5] rounded-[20px]">
      <p className=" text-xl font-medium">{card.name}</p>
      <div className=" flex justify-between items-center">
        <div className=" p-4 flex items-center gap-2.5  rounded-[10px] bg-[#313B3D] text-white">
          <p className=" max-w-[480px] overflow-hidden">{card.address}</p>
          <img src="/export.svg" alt="" />
        </div>
        <div className=" w-[125px] p-4 rounded-[10px] bg-[#313B3D] grid place-items-center">
          <p className=" text-white">{0 /* totalToken */}</p>
        </div>

        <button className={`${!card.readonly && "invisible"}`}>
          <img src="/down.svg" alt="" onClick={() => setShowMore(!showMore)} />
        </button>
      </div>
      {(showMore || card.open) && (
        <div className=" flex flex-col gap-8 pt-4 items-start">
          <div className=" flex flex-col gap-4">
            {card.allocated.map((allocated, i) => (
              <div
                key={allocated.projectId}
                className=" flex gap-8  items-center"
              >
                <div className=" flex gap-8 w-[450px]">
                  <div className=" p-4 w-full gap-4 bg-white rounded-[10px] flex">
                    <p className="">
                      {allocated.title} | {allocated.title}
                    </p>
                    <img src="/export-d.svg" alt="" />
                  </div>
                  <input
                    className={`p-4 w-[125px] bg-white rounded-[10px] ${
                      card.readonly && "cursor-not-allowed"
                    }`}
                    readOnly={card.readonly}
                    value={allocated.amount}
                    onChange={(e) => {
                      card.updateValues!({
                        personalAllocations: produce(
                          card.allocated,
                          (draft) => {
                            draft[i].amount = parseFloat(e.target.value) || 0;
                          }
                        ),
                      });
                    }}
                  />
                </div>
                <p className=" ">RDT</p>
              </div>
            ))}
          </div>

          {!card.readonly && (
            <button
              onClick={() =>
                card.allocateFunds!(card.docFundId, card.allocated, () =>
                  router.refresh()
                )
              }
              className=" py-4 px-8 rounded-[5px] text-sm font-semibold bg-green-600 text-white flex items-center"
            >
              Submit Allocation
            </button>
          )}
        </div>
      )}
    </div>
  );
};

export default AllocationCard;
