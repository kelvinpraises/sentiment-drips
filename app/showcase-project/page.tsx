"use client";
import { useRouter } from "next/navigation";
import { useReducer } from "react";

import { createProject } from "@/library/backendAPI";
import Button from "@/library/components/atoms/Button";
import Input from "@/library/components/atoms/Input";
import TextHead from "@/library/components/molecules/TextHead";
import EmojiPicker from "@/library/components/organisms/EmojiPicker";

interface NewProject {
  tokensRequested: number;
  emoji: string;
  title: string;
  description: string;
}

const initialState = {
  emoji: "",
  title: "",
  tokensRequested: 0,
  description: "",
};

const stateReducer = (
  current: NewProject,
  update: Partial<NewProject>
): NewProject => {
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
};

const page = () => {
  const router = useRouter();

  const [values, updateValues] = useReducer(stateReducer, initialState);

  return (
    <div className=" flex-1 bg-white rounded-[10px] p-8 overflow-y-scroll flex flex-col gap-8 items-start">
      <TextHead
        title="Create Project"
        description="Create a project to showcase in an ecosystem funding round."
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
            router.push("/projects/" + d);
          })
        }
      />
    </div>
  );
};

export default page;
