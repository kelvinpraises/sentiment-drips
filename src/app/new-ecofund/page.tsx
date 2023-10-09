"use client";
import { useRouter } from "next/navigation";
import { useReducer } from "react";

import Button from "@/components/atoms/Button";
import Input from "@/components/atoms/Input";
import TextHead from "@/components/molecules/TextHead";
import EmojiPicker from "@/components/organisms/EmojiPicker";
import useBackendAPI from "@/hooks/backendAPI";

export interface NewDocFund {
  emoji: string;
  title: string;
  tokenAmount: number;
  description: string;
  registrationEnd: number;
  allocationEnd: number;
  createdAt: number;
}

const NewEcoFundScreen = () => {
  const router = useRouter();
  const { createDocFund } = useBackendAPI();

  // TODO: Ensure the dates passed should be a time in the future.
  const [values, updateValues] = useReducer(
    (current: NewDocFund, update: Partial<NewDocFund>): NewDocFund => {
      return {
        ...current,
        ...update,
        tokenAmount:
          update.tokenAmount === undefined
            ? current.tokenAmount
            : isNaN(current.tokenAmount)
            ? 0
            : update.tokenAmount || 0,
        registrationEnd:
          update.registrationEnd === undefined
            ? current.registrationEnd
            : update.registrationEnd || Math.floor(new Date().getTime() / 1000),
        allocationEnd:
          update.allocationEnd === undefined
            ? current.allocationEnd
            : update.allocationEnd || Math.floor(new Date().getTime() / 1000),
      };
    },
    {
      emoji: "",
      title: "",
      tokenAmount: 0,
      description: "",
      registrationEnd: Math.floor(new Date().getTime() / 1000), // Convert to Unix timestamp already in UTC
      allocationEnd: Math.floor(new Date().getTime() / 1000), // Convert to Unix timestamp already in UTC
      createdAt: Math.floor(new Date().getTime() / 1000),
    }
  );

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 items-start">
      <TextHead
        title="Create New DocFund"
        description="Create pooled funds to support LX Devs in your community."
      />
      <div className=" w-[480px] flex flex-col gap-8">
        <div className=" flex flex-col gap-2 w-full">
          <p className=" text-sm font-medium">Title</p>
          <div className=" flex bg-[#DEE6E5] items-center pl-2 rounded-md">
            <EmojiPicker setSelectedEmoji={updateValues} />
            <Input
              input={true}
              value={values.title}
              onChange={(e) => updateValues({ title: e.target.value })}
            />
          </div>
        </div>
        <Input
          type="number"
          label={"Token Amount"}
          input={true}
          value={values.tokenAmount.toString()}
          onChange={(e) =>
            updateValues({ tokenAmount: parseFloat(e.target.value) })
          }
        />
        <Input
          label={"Proposal Description"}
          input={false}
          value={values.description}
          onChange={(e) => updateValues({ description: e.target.value })}
        />
        <Input
          type="datetime-local"
          label={"Registration End Date"}
          input={true}
          value={
            isNaN(values.registrationEnd)
              ? ""
              : new Date(
                  values.registrationEnd * 1000 -
                    new Date().getTimezoneOffset() * 60000 // Convert Unix timestamp already in UTC to milliseconds and factor in timezone
                )
                  .toISOString()
                  .substring(0, 16)
          }
          onChange={
            (e) =>
              updateValues({
                registrationEnd: Math.floor(
                  new Date(e.target.value).getTime() / 1000
                ),
              }) // Convert to Unix timestamp
          }
        />
        <Input
          type="datetime-local"
          label={"Allocation End Date"}
          input={true}
          value={
            isNaN(values.allocationEnd)
              ? ""
              : new Date(
                  values.allocationEnd * 1000 -
                    new Date().getTimezoneOffset() * 60000 // Convert Unix timestamp already in UTC to milliseconds and factor in timezone
                )
                  .toISOString()
                  .substring(0, 16)
          }
          onChange={
            (e) =>
              updateValues({
                allocationEnd: Math.floor(
                  new Date(e.target.value).getTime() / 1000
                ),
              }) // Convert to Unix timestamp
          }
        />
      </div>
      <Button
        text={"Submit"}
        handleClick={() =>
          createDocFund(values, (d: string) => {
            router.push("/grants/docfunds/" + d);
          })
        }
      />
    </div>
  );
};

export default NewEcoFundScreen;
