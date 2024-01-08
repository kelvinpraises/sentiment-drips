import Button from "../atoms/Button";

const VoteSection = ({ ecoFundId }: { ecoFundId: any }) => {
  return (
    <div className="flex flex-col gap-4">
      <div className=" flex justify-between">
        <p className=" text-sm">
          Vote on if the collective averaged sentiment is fit for the ecosystem
        </p>
        <Button text={"Vote on Proposal"} handleClick={undefined} />
      </div>
      <div className="flex flex-col gap-8">
        <div className="w-[520px]">{}</div>
      </div>
    </div>
  );
};

export default VoteSection;
