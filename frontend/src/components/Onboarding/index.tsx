import React from "react";
import OnboardingElement from "./OnboardingElement";


export default function Onboarding()
{
    return <div className="flex flex-col justify-center items-center mx-[200px] my-12">
    <div className="grid grid-cols-2 w-full h-full gap-4 ">
    <OnboardingElement name="Student" buttonContent="Join your class" iconSvg="/rocket.svg" bgImage="/student.png" route="/student" />
    <OnboardingElement name="Teacher" buttonContent="Set the crew" iconSvg="/space.svg" bgImage="/teacher.png" route="/teacher" />
    <OnboardingElement name="Parent" buttonContent="Get Started" iconSvg="/meme.svg" bgImage="/teacher.png" route="/parent" />
    <OnboardingElement name="School" buttonContent="Get Started" iconSvg="/earth.svg" bgImage="/school.png" route="/school/register" />
    </div>
    </div>
}