import {
  CheckIcon,
  ChevronDownIcon,
  ChevronUpIcon,
} from "@radix-ui/react-icons";
import * as Select from "@radix-ui/react-select";
import React, { ChangeEvent } from "react";

import { cn } from "@/library/utils";

interface selectProps {
  type?: string;
  label?: string;
  input: boolean;
  value: string;
  onChange: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
}

const ProjectSelect = (prop: selectProps) => (
  <div className=" flex flex-col gap-2 w-full">
    {prop.label && <p className=" text-sm font-medium">{prop.label}</p>}
    <Select.Root>
      <Select.Trigger
        className="inline-flex items-center justify-between rounded w-full p-6 px-[15px] leading-none h-[35px] bg-white shadow-[0_0_0_2px] shadow-[#DEE6E5] outline-none"
        aria-label="Project"
      >
        <Select.Value placeholder="Select a project..." />
        <Select.Icon>
          <ChevronDownIcon />
        </Select.Icon>
      </Select.Trigger>

      <Select.Portal>
        <Select.Content className="overflow-hidden bg-white rounded-md shadow-[0px_10px_38px_-10px_rgba(22,_23,_24,_0.35),0px_10px_20px_-15px_rgba(22,_23,_24,_0.2)]">
          <Select.ScrollUpButton className="flex items-center justify-center h-[25px] bg-white cursor-default">
            <ChevronUpIcon />
          </Select.ScrollUpButton>
          <Select.Viewport className="p-[5px]">
            <Select.Group>
              <SelectItem value="rejected">Rejected</SelectItem>
              <SelectItem value="accepted">Accepted</SelectItem>
            </Select.Group>
          </Select.Viewport>
          <Select.ScrollDownButton className="flex items-center justify-center h-[25px] bg-white cursor-default">
            <ChevronDownIcon />
          </Select.ScrollDownButton>
        </Select.Content>
      </Select.Portal>
    </Select.Root>
  </div>
);

const SelectItem = React.forwardRef<
  HTMLDivElement,
  {
    value: string;
    disabled?: boolean;
    className?: string;
    children: React.ReactNode;
  }
>(({ children, className, ...props }, forwardedRef) => {
  // Existing code
  return (
    <Select.Item
      className={cn(
        "leading-none rounded-[3px] flex items-center h-[25px] p-5 pr-[35px] pl-[25px] relative select-none data-[disabled]:text-mauve8 data-[disabled]:pointer-events-none data-[highlighted]:outline-none data-[highlighted]:bg-[#DEE6E5] data-[highlighted]:text-violet1",
        className
      )}
      {...props}
      ref={forwardedRef}
    >
      <Select.ItemText>{children}</Select.ItemText>
      <Select.ItemIndicator className="absolute left-0 w-[25px] inline-flex items-center justify-center">
        <CheckIcon />
      </Select.ItemIndicator>
    </Select.Item>
  );
});

export default ProjectSelect;
