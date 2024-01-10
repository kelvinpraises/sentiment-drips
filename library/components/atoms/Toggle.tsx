interface ToggleProps {
  label?: string;
  description: string;
  optional?: boolean;
  disabled?: boolean;
  value: string;
  onChange: (e: any) => void;
}

const Toggle = (prop: ToggleProps) => {
  return (
    <div>
      <span className="flex gap-2">
        {prop.label && <p className=" text-sm font-bold">{prop.label}</p>}
        {prop.optional && <p className=" text-sm font-normal">(Optional)</p>}
      </span>
      <div className="flex gap-5">
        <p className=" text-sm font-normal">{prop.description}</p>
      </div>
    </div>
  );
};

export default Toggle;
