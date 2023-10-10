interface IHead {
  title?: string;
  description?: string;
  tag?: string;
}

const TextHead = (prop: IHead) => {
  return (
    <div className=" flex flex-col gap-2">
      <div className=" flex gap-4 items-center">
        <p className=" text-[40px] font-semibold">{prop.title}</p>
        <p className=" text-sm font-semibold">{prop.tag}</p>
      </div>
      <p>{prop.description}</p>
    </div>
  );
};

export default TextHead;
