"use client";
import { useRouter } from "next/navigation";
import { useReducer } from "react";

import Button from "@/components/atoms/Button";
import Input from "@/components/atoms/Input";
import TextHead from "@/components/molecules/TextHead";
import EmojiPicker from "@/components/organisms/EmojiPicker";
import { createProject } from "@/lib/backendAPI";

interface NewShowcaseProject {
  tokensRequested: number;
  emoji: string;
  title: string;
  description: string;
}

const page = () => {
  const router = useRouter();

  const [values, updateValues] = useReducer(
    (
      current: NewShowcaseProject,
      update: Partial<NewShowcaseProject>
    ): NewShowcaseProject => {
      console.log(update.tokensRequested);
      return {
        ...current,
        ...update,
        tokensRequested:
          update.tokensRequested === undefined
            ? current.tokensRequested
            : isNaN(current.tokensRequested)
            ? 0
            : update.tokensRequested || 0,
      };
    },
    {
      emoji: "",
      title: "",
      tokensRequested: 0,
      description: "",
    }
  );

  console.log(values);

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 items-start">
      <TextHead
        title="Showcase Project"
        description="Showcase a project to qualify for an ecosystem funding round."
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
          label={"Token Request Amount"}
          input={true}
          value={values.tokensRequested.toString()}
          onChange={(e) =>
            updateValues({ tokensRequested: parseFloat(e.target.value) })
          }
        />
        <Input
          label={"Project Description"}
          input={false}
          value={values.description}
          onChange={(e) => updateValues({ description: e.target.value })}
        />
      </div>
      <Button
        text={"Submit"}
        handleClick={() =>
          createProject(values, (d: string) => {
            router.push("/grants/projects/" + d);
          })
        }
      />
    </div>
  );
};

export default page;
