import Image from "next/image";
import { useRouter } from "next/router";
import React from "react";


export default function OnboardingElement({
    name,iconSvg,buttonContent,bgImage,route
}:{
    name: string;
    iconSvg: string;
    buttonContent: string;
    bgImage: string;
    route: string;
})
{   const router=useRouter()
    return     <div className="relative w-full h-full">
        <Image src={bgImage} width={500} height={500} alt="background" className="w-full h-full rounded-lg "/>
        <Image src={iconSvg} width={100} height={100} alt="icon" className="absolute left-[40%] top-[30%] "/>
        <div className="absolute left-[15%] top-[45%]">
            <p className="text-white font-bold text-3xl">{name}</p>
            <button className="text-black font-semibold bg-white px-3 py-2 rounded-md mt-2 " onClick={
                ()=>{
                    router.push(route)
                }
            }>{buttonContent}</button>
        </div>

    </div>
}