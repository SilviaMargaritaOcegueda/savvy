import Layout from "@/components/Layout";
import OnboardingElement from "@/components/Onboarding/OnboardingElement";
import React from "react";


export default function OnboardingPage()
{
    return <Layout>
        <div className="flex flex-col justify-center items-center mx-[200px] my-12">
        <div className="grid grid-cols-2 w-full h-full gap-4 ">
        <OnboardingElement name="Student" buttonContent="Join your class" iconSvg="/rocket.svg" bgImage="/student.png" route="/student" />
        <OnboardingElement name="Teacher" buttonContent="Set the crew" iconSvg="/space.svg" bgImage="/teacher.png" route="/teacher" />
        <OnboardingElement name="Parent" buttonContent="Get Started" iconSvg="/meme.svg" bgImage="/teacher.png" route="/parent" />
        <OnboardingElement name="School" buttonContent="Get Started" iconSvg="/earth.svg" bgImage="/student.png" route="/school" />
        </div>
        </div>
        
    </Layout>
  
}