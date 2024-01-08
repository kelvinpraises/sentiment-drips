import React from "react";
import Button from "../atoms/Button";
import ReviewCard from "../molecules/ReviewCard";

const ReviewSection = ({ ecoFundId }: { ecoFundId: any }) => {
  return (
    <div className="flex flex-col gap-8">
      <div className=" flex justify-between">
        <p className=" text-sm">
          Review showcased projects by accepting or rejecting applications
        </p>
        <Button text={"Upload Revision"} handleClick={undefined} />
      </div>
      <div className="flex flex-col gap-8">
        {[1].map(() => {
          return <ReviewCard name={"fgfgfg"} address={"0xB754369b3a7C430d7E94c14f33c097C398a0caa5"} />;
        })}
      </div>
    </div>
  );
};

export default ReviewSection;
