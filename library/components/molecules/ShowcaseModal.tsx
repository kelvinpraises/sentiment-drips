import React from "react";
import * as Dialog from "@radix-ui/react-dialog";
import { Cross2Icon } from "@radix-ui/react-icons";
import ProjectSelect from "./ProjectSelect";
import Input from "../atoms/Input";

interface ModalProps {
  children: React.ReactNode;
  modalElementId: string;
}

const ShowcaseModal: React.FC<ModalProps> = ({
  children,
  modalElementId,
}: ModalProps) => {
  return (
    <Dialog.Root>
      <Dialog.Trigger>{children}</Dialog.Trigger>

      <Dialog.Portal container={document.getElementById(modalElementId)}>
        <Dialog.Overlay className="backdrop-blur-xl data-[state=open]:animate-overlayShow absolute inset-0" />
        <Dialog.Content className="data-[state=open]:animate-contentShow overflow-scroll absolute max-h-[80%] top-[50%] left-[50%] w-[90vw] max-w-[500px] translate-x-[-50%] translate-y-[-50%] rounded-xl bg-white p-[25px] shadow-[hsl(206_22%_7%_/_35%)_0px_10px_38px_-10px,_hsl(206_22%_7%_/_20%)_0px_10px_20px_-15px] focus:outline-none">
          <div className="sticky top-[0] flex flex-row-reverse translate-x-[12px] translate-y-[-12px] w-full">
            <Dialog.Close asChild>
              <button
                className=" hover:bg-black/60 text-white bg-black/40 inline-flex flex-row-reverse h-[25px] w-[25px] appearance-none items-center justify-center rounded-full focus:shadow-[0_0_0_2px] focus:outline-none"
                aria-label="Close"
              >
                <Cross2Icon />
              </button>
            </Dialog.Close>
          </div>

          <div className="mt-[-25px] flex flex-col gap-4">
            <div>
              <Dialog.Title className="font-bold text-xl">
                Showcase
              </Dialog.Title>
              <Dialog.Description>
                Select a project. Fill your details. Apply for a funded drip!
              </Dialog.Description>
            </div>

            <ProjectSelect
              label="Select a Project"
              input={false}
              value={""}
              onChange={function (
                e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
              ): void {
                throw new Error("Function not implemented.");
              }}
            />


            <div className="mt-[25px] flex justify-end">
              <Dialog.Close asChild>
                <button className="bg-green4 text-green11 hover:bg-green5 focus:shadow-green7 inline-flex h-[35px] items-center justify-center rounded-[4px] px-[15px] font-medium leading-none focus:shadow-[0_0_0_2px] focus:outline-none">
                  Showcase Project
                </button>
              </Dialog.Close>
            </div>
          </div>
        </Dialog.Content>
      </Dialog.Portal>
    </Dialog.Root>
  );
};

export default ShowcaseModal;
