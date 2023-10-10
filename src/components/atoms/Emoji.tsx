interface IEmoji {
  className?: string;
  emoji: string;
}

const Emoji = ({ className, emoji }: IEmoji) => {
  let unicode = emoji
    .split("-")
    .map((val) => {
      return String.fromCodePoint(parseInt(val, 16));
    })
    .join("");

  return (
    <p className={"aspect-square grid place-items-center" + className}>
      {unicode}
    </p>
  );
};

export default Emoji;
