const Footer = ({ className }: { className?: string }) => {
  const date = new Date();

  return (
    <div className={` flex pb-8 justify-center ${className}`}>
      <p className=" text-sm font-bold">
        © {date.getFullYear()} Sentiment Drips
      </p>
    </div>
  );
};

export default Footer;
