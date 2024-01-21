import Image from "next/image";
import React, { useEffect } from "react";
import { ConnectKitButton } from "connectkit";
import { useAccount } from "wagmi";
import { Router, useRouter } from "next/router";

export default function Home() {
  const { address } = useAccount();
  const router = useRouter();

  useEffect(() => {
    if (address != undefined) {
      // CHANGE: make a smart contract call to check if the user has already logged in
      // if user already logged in go to /dashboard
      // if not go to /onboarding
      // router.push('/onboarding')
    } else {
      // Connect wallet to go
      // Fix for NOW!
      // router.push('/dashboard')
    }
  }, [address]);

  return (
    <div className="flex flex-col justify-center items-center">
      <div
        className="bg-gradient-to-r from-[#F8049C] to-[#FDD54F] w-full h-[500px] rounded-b-full flex flex-col justify-center items-center"
        // style={{
        //   backgroundImage:
        //     "url('https://drive.google.com/file/d/1IXq2cmIgeHrNSjK0W_oaMl_uskloRgsn/view?usp=drive_link')",
        //   backgroundSize: "",
        // }}
      >
        <Image src={"/logo.png"} width={200} height={100} alt="logo" />

        <p className="text-white  text-3xl font-semibold mt-14">Hi, welcome!</p>
      </div>
      <div className="mt-8">
        <ConnectKitButton />
      </div>
    </div>
  );
}
