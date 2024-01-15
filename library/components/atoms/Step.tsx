import { cn } from "@/library/utils";
import { Status, progressStepGap } from "../organisms/ProgressModal";
import { CheckIcon } from "@radix-ui/react-icons";

interface ProgressStepProp {
  index: number;
  name: string;
  status: Status;
  last: boolean;
}

const ProgressStep = (prop: ProgressStepProp) => {
  return (
    <div className={cn("flex items-center min-h-fit gap-2")}>
      <div
        className={cn(
          "flex items-center justify-center relative h-8 w-8 rounded-full bg-white shadow-[0_0_0_2.5px] shadow-[#DEE6E5] outline-none",
          "after:absolute after:top-[100%] after:content-[''] after:w-1 after:bg-[#DEE6E5] after:left-[50%] after:translate-x-[-50%]",
          progressStepGap,
          // prop.status === "loading" && "shadow-[#313B3D]",
          prop.status === "errored" && "after:bg-[#FF5353]  shadow-[#FF5353]",
          prop.status === "done" &&
            "after:bg-[#313B3D] bg-[#313B3D] shadow-[#313B3D]",
          prop.last && "after:w-0"
        )}
      >
        {(() => {
          switch (prop.status) {
            case "none":
              return prop.index + 1;
            case "loading":
              return <img className=" w-3/4 h-3/4" src={"/circles.svg"} />;
            case "errored":
              return <></>;
            case "done":
              return <CheckIcon className="text-white"/>;
            default:
              return <></>;
          }
        })()}
      </div>
      <div>
        <p className="text-sm text-gray-600">{prop.name}</p>
      </div>
    </div>
  );
};

export default ProgressStep;
