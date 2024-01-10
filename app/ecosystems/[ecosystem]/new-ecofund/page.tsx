"use client";
import { useRouter } from "next/navigation";
import { ChangeEvent, useReducer } from "react";

import Button from "@/library/components/atoms/Button";
import Input from "@/library/components/atoms/Input";
import TextHead from "@/library/components/molecules/TextHead";
import EmojiPicker from "@/library/components/organisms/EmojiPicker";
import { createEcoFund } from "@/library/backendAPI";
import Toggle from "@/library/components/atoms/Toggle";
import ProjectSelect from "@/library/components/molecules/ProjectSelect";

export interface NewEcoFund {
  emoji: string;
  title: string;
  tokenAmount: number; // TODO: remove this
  description: string;
  registrationEnd: number;
  allocationEnd: number;
  createdAt: number;
}

const NewEcoFundScreen = () => {
  const router = useRouter();

  // TODO: Ensure the dates passed should be a time in the future.
  const [values, updateValues] = useReducer(
    (current: NewEcoFund, update: Partial<NewEcoFund>): NewEcoFund => {
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
        title="Propose An EcoFund"
        description="Pool funds to support projects in this community."
      />
      <div className=" w-[480px] flex flex-col gap-4">
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
          label={"Proposal Description"}
          input={false}
          value={values.description}
          onChange={(e) => updateValues({ description: e.target.value })}
        />
      </div>

      <hr className="bg-[#F2F2F2] w-[480px] outline-none"></hr>

      <div className="flex flex-col gap-4">
        <h2 className="font-bold text-xl">Allocation Strategy</h2>

        <div className=" w-[480px] flex flex-col gap-8">
          <div className=" w-[480px] flex flex-col gap-4">
            <Toggle
              label="Stream Donation"
              optional
              description={"After donation is over stream tokens to recipients"}
              value={""}
              onChange={function (e: any): void {
                throw new Error("Function not implemented.");
              }}
            />
            <Toggle
              label="Registry Anchor Required"
              optional
              description={"Recipients must have an registry anchor address "}
              value={""}
              onChange={function (e: any): void {
                throw new Error("Function not implemented.");
              }}
            />
          </div>
          <ProjectSelect
            input={false}
            value={""}
            onChange={function (
              e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
            ): void {
              throw new Error("Function not implemented.");
            }}
          />
          <div className=" w-[480px] flex flex-col gap-4">
            <div className="flex gap-4">
              <Input
                type="datetime-local"
                label={"Registration Start Date"}
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
                label={"Registration End Date"}
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
            <div className="flex gap-4">
              <Input
                type="datetime-local"
                label={"Allocation Start Date"}
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
          </div>

          <Input
            label={"Allowed Allocation Tokens"}
            input={false}
            value={values.description}
            onChange={(e) => updateValues({ description: e.target.value })}
          />

          <Input
            label={"Pool Managers"}
            input={false}
            value={values.description}
            onChange={(e) => updateValues({ description: e.target.value })}
          />

          <Input
            label="Registration Questions (Optional)"
            input={true}
            value={values.title}
            onChange={(e) => updateValues({ title: e.target.value })}
          />
        </div>
      </div>
      <Button
        text={"Propose"}
        handleClick={
          () => {}
          // () =>
          // createEcoFund(values, (d: string) => { TODO: add correct values
          //   router.push("/ecoFunds/" + d); TODO: push to correct route
          // })
        }
      />
    </div>
  );
};

export default NewEcoFundScreen;
