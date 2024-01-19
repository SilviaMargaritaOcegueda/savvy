import { useAccount } from "wagmi";
import { useRouter } from "next/router";
import React, { useEffect, useState } from "react";
import Link from "next/link";
import { ConnectKitButton } from "connectkit";
import Image from "next/image";

export default function Layout({ children }: { children: React.ReactNode }) {
  const { address } = useAccount();
  useEffect(() => {
    if(address==undefined){
        // CHANGE: go to home page
    }
    console.log("address", address);
  }, [address]);
  return   <div>
     
      <div className="flex justify-between bg-gradient-to-r from-[#F8049C] to-[#FDD54F] py-4 rounded-b-3xl">
        <div className="ml-4">
        <Link
          href={"/"}
          className="font-bold font-logo  text-3xl italic text-[#FAFB63]"
        >
          <Image src={'/logo.png'} height={100} width={100} alt="logo" className="my-auto" />
        </Link>
        </div>
    
        <div className="mr-4">
        <ConnectKitButton/>

        </div>
      </div>
      {children}
    </div>

}