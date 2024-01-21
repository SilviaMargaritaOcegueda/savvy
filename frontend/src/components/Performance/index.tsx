import React, { useState } from "react";
import { useAccount } from "wagmi";
import Image from "next/image";

export default function Performance() {
  return (
    <div className="flex flex-col justify-center items-center">
      <div className="mt-8 text-center">
        <p className="text-black font-bold text-3xl">Performance Dashboard</p>
        <p className="text-black font-normal mt-2 text-lg">Strategic Hodling</p>
      </div>
      <div className="w-full h-[500px] rounded-b-full flex flex-col justify-center items-center">
        <Image
          src={"/investProfit.png"}
          width={600}
          height={600}
          alt="investProfit"
        />
      </div>
    </div>
  );
}
