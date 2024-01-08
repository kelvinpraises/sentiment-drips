import React from "react";
import Button from "../atoms/Button";

const ReviewSection = ({ ecoFundId }: { ecoFundId: any }) => {
  return (
    <div className="flex flex-col gap-4">
      <div className=" flex justify-between">
        <p className=" text-sm">
          Review showcased projects by accepting or rejecting applications
        </p>
        <Button text={"Upload Revision"} handleClick={undefined} />
      </div>
      <div className="flex flex-col gap-8">
        <div className="w-[520px]">{}</div>
      </div>
    </div>
  );
};

export default ReviewSection;
