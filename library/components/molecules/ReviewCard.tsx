"use client";
import { ChangeEvent, Dispatch, useState } from "react";

import {
  ChevronDownIcon,
  ChevronUpIcon,
  ExternalLinkIcon,
} from "@radix-ui/react-icons";
import Input from "../atoms/Input";
import { AllocateSectionState } from "../organisms/AllocateSection";
import ReviewSelect from "./ReviewSelect";

interface cardProps {
  updateValues?: Dispatch<Partial<AllocateSectionState>>;
  name: string;
  address: string;
}

const ReviewCard = (card: cardProps) => {
  const [showMore, setShowMore] = useState(false);

  return (
    <div className=" p-8 flex flex-col gap-4 w-full bg-[#DEE6E5] rounded-[20px]">
      <p className=" text-xl font-medium">{card.name}</p>
      {/* TODO: show status here */}
      <div className="flex justify-between items-center gap-8">
        <div className=" p-4 flex items-center gap-2 rounded-[10px] bg-[#313B3D] text-white">
          <p className=" w-[42ch] max-w-[480px] overflow-hidden">
            {card.address}
          </p>
          <ExternalLinkIcon />
        </div>

        {showMore ? (
          <button
            className="flex justify-center items-center p-4 rounded-[10px] bg-[#313B3D] text-white h-full"
            onClick={() => setShowMore(!showMore)}
          >
            <p className="w-[12ch]">Hide Details</p>
            <ChevronUpIcon />
          </button>
        ) : (
          <button
            className="flex justify-center items-center p-4 rounded-[10px] bg-[#313B3D] text-white h-full"
            onClick={() => setShowMore(!showMore)}
          >
            <p className="w-[12ch]">Show Details</p>
            <ChevronDownIcon />
          </button>
        )}
      </div>
      {showMore && (
        <div className=" flex flex-col gap-8 pt-4 items-start">
          <div className=" flex flex-col gap-4 w-[450px]">
            <ReviewSelect
              input={false}
              label="Status"
              value={""}
              onChange={function (
                e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
              ): void {
                throw new Error("Function not implemented.");
              }}
            />

            <Input
              label={"Description"}
              input={false}
              disabled
              value={
                "Lorem ipsum dolor sit amet consectetur adipisicing elit. Praesentium laboriosam deleniti delectus similique odio sunt reiciendis. Doloribus optio fugit ea?"
              }
              onChange={(e) => {}}
            />

            <Input
              label={"Token Request Amount"}
              input={true}
              disabled
              value={"Yeah hello there"}
              onChange={(e) => {}}
            />
          </div>
        </div>
      )}
    </div>
  );
};

export default ReviewCard;
