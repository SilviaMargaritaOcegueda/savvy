import Layout from "@/components/Layout";
import Image from "next/image";
import React from "react";


export default function OnboardingPage()
{
    return <Layout>
          <div className="grid grid-cols-2 w-full h-full">
            <Image src='/student.png' width={500} height={500} alt="student" />
            <Image src='/teacher.png' width={500} height={500} alt="teacher" />
            <Image src='/teacher.png' width={500} height={500} alt="parent" />
            <Image src='/school.png' width={500} height={500} alt="school" />
        </div>
    </Layout>
  
}