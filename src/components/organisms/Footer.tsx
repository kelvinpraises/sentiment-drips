import React from "react";

const Footer = ({ className }: { className?: string }) => {
  return (
    <div className={` flex pb-8 justify-center ${className}`}>
      <p className=" text-sm font-bold">© 2023 RizzDocs</p>
    </div>
  );
};

export default Footer;
