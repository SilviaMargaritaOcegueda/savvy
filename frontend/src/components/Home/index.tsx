import Image from 'next/image'
import React, { useEffect } from 'react'
import { ConnectKitButton } from 'connectkit'
import { useAccount } from 'wagmi'
import { Router, useRouter } from 'next/router'

export default function Home()
{ 
  const {address}=useAccount()
  const router=useRouter()

  useEffect(()=>{
    if(address!=undefined)
    {
      // make a smart contract call to check if the user has already logged in
      // if user already logged in go to /dashboard
      // if not go to /onboarding
      router.push('/dashboard')
    }else{
      // Connect wallet to go
      // Fix for NOW!
      router.push('/dashboard')
    }
  },[address])
  

    return <div className="flex flex-col justify-center items-center">
    <div className="bg-gradient-to-r from-[#F8049C] to-[#FDD54F] w-full h-[500px] rounded-b-full flex flex-col justify-center items-center">
    <Image src={'/logo.png'} width={200} height={100} alt="logo" />
    <p className="text-white text-lg">DeFi for Teens</p>
    <p className="text-white  text-3xl font-semibold mt-14">Hi Welcome</p>
  </div>
  <div className='mt-8'>
  <ConnectKitButton  />

  </div>

  </div> 
}