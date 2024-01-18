import Image from "next/image";
import React from "react";

export default function Home() {
  return <div className="flex flex-col justify-center items-center">
    <div className="bg-gradient-to-r from-[#F8049C] to-[#FDD54F] w-full h-[500px] rounded-b-full flex flex-col justify-center items-center">
    <Image src={'/logo.png'} width={200} height={100} alt="logo" />
    <p className="text-white text-lg">DeFi for Teens</p>
    <p className="text-white  text-3xl font-semibold mt-14">Hi Welcome</p>
  </div>
  <button>Connect Family Wallet</button>

  </div> 
}
