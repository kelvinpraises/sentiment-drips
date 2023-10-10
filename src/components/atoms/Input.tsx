import { ChangeEvent } from "react";

interface inputProps {
  type?: string;
  label?: string;
  input: boolean;
  value: string;
  onChange: (e: ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
}

const Input = (prop: inputProps) => {
  return (
    <div className=" flex flex-col gap-2 w-full">
      {prop.label && <p className=" text-sm font-medium">{prop.label}</p>}
      {prop.input ? (
        <input
          type={prop.type ? prop.type : "text"}
          className=" bg-[#DEE6E5] p-4 rounded-md outline-none w-full"
          value={prop.value}
          onChange={prop.onChange}
        />
      ) : (
        <textarea
          className=" bg-[#DEE6E5] p-4 rounded-md h-[113px] outline-none"
          value={prop.value}
          onChange={prop.onChange}
        />
      )}
    </div>
  );
};

export default Input;
