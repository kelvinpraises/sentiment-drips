import { cn } from "@/library/utils";
import { ChangeEvent } from "react";

interface inputProps {
  type?: string;
  label?: string;
  disabled?: boolean;
  input: boolean;
  value: string;
  onChange: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
}

const Input = (prop: inputProps) => {
  return (
    <div className="flex flex-col gap-2 w-full">
      {prop.label && <p className=" text-sm font-normal">{prop.label}</p>}
      {prop.input ? (
        <input
          type={prop.type ? prop.type : "text"}
          className={cn(
            "bg-[#DEE6E5] p-4 rounded-md outline-none w-full",
            prop.disabled &&
              "bg-white shadow-[0_0_0_2px] shadow-[#DEE6E5] outline-none"
          )}
          value={prop.value}
          onChange={prop.onChange}
          disabled={prop.disabled}
        />
      ) : (
        <textarea
          className={cn(
            "bg-[#DEE6E5] p-4 rounded-md h-[113px] outline-none",
            prop.disabled &&
              "bg-white shadow-[0_0_0_2px] shadow-[#DEE6E5] outline-none"
          )}
          value={prop.value}
          onChange={prop.onChange}
          disabled={prop.disabled}
        />
      )}
    </div>
  );
};

export default Input;
