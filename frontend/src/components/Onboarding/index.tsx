import React from "react";
import OnboardingElement from "./OnboardingElement";

export default function Onboarding() {
  return (
    <div className="flex flex-col justify-center items-center mx-[200px] my-12">
      <div className="grid grid-cols-2 w-full h-full gap-4 ">
        <OnboardingElement
          name="Student"
          buttonContent="Join class"
          iconSvg="/rocket.svg"
          bgImage="/student.png"
          route="/student/vote"
        />
        <OnboardingElement
          name="Teacher"
          buttonContent="Set students"
          iconSvg="/space.svg"
          bgImage="/teacher.png"
          route="/class/create"
        />
        <OnboardingElement
          name="Parent"
          buttonContent="Create wallet"
          iconSvg="/meme.svg"
          bgImage="/teacher.png"
          route="/parent"
        />
        <OnboardingElement
          name="School"
          buttonContent="Set classes"
          iconSvg="/earth.svg"
          bgImage="/school.png"
          route="/school/register"
        />
      </div>
    </div>
  );
}
