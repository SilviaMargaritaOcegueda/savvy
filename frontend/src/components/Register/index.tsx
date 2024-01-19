import React, { useState } from "react";


export default function Register()
{
    const [teacherName,setTeacherName]=useState('')
    const [teacherAddress,setTeacherAddress]=useState('')
    const [schoolClass,setSchoolClass]=useState('')
    const [classAddress,setClassAddress]=useState('')
    return  <div className="flex flex-col justify-center items-center">
            <div className="mt-8 text-center">
                <p className="text-black font-bold text-3xl">Register Class</p>
                <p className="text-black font-normal mt-2 text-lg">School</p>
            </div>
            <div className="text-[#595B70] w-[500px]">
            <p className="mt-8">Teacher</p>
            <input
        type="text"
        placeholder="Name"
        className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
        value={teacherName}
        onChange={(e) => {
          setTeacherName(e.target.value);
        }}
      ></input>
       <p className="mt-8">Teacher Ethereum Address</p>
            <input
        type="text"
        placeholder="Given by the teacher"
        className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
        value={teacherAddress}
        onChange={(e) => {
          setTeacherAddress(e.target.value);
        }}
      ></input>
       <p className="mt-8">Class</p>
            <input
        type="text"
        placeholder="Class Name ie. 1B"
        className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
        value={schoolClass}
        onChange={(e) => {
            setSchoolClass(e.target.value);
        }}
      ></input>
             <p className="mt-8">Class Ethereum Address</p>
            <input
        type="text"
        placeholder="Assigned by the schoool"
        className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
        value={classAddress}
        onChange={(e) => {
          setClassAddress(e.target.value);
        }}
      ></input>
            </div>
            <button className="bg-[#FA378A] text-white px-3 py-2 rounded-lg font-semibold text-xl my-8">Create</button>
        </div>
}