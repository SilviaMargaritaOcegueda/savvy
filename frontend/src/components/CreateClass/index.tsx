import React, { useState } from "react";
import Dropdown from "../Dropdown";
import { useAccount } from "wagmi";


export default function CreateClass()
{
    const {address}=useAccount()
    const [classes,setClasses]=useState(['1A','1B','2B'])
    const [selectedClass,setSeletedClass]=useState('1A')
    const [weeklyAmonut,setWeeklyAmount]=useState(0)
    const [initialDeposit,setInitialDeposit]=useState({day:"",month:"",year:""})
    const [finalDeposit,setFinalDeposit]=useState({day:"",month:"",year:""})
    return <div className="flex flex-col justify-center items-center">
    <div className="mt-8 text-center">
        <p className="text-black font-bold text-3xl">Register Class</p>
        <p className="text-black font-normal mt-2 text-lg">School</p>
    </div>
    <div className="text-[#595B70] w-[500px]">
    <p className="mt-8">Class</p>
    <Dropdown options={classes} setOption={(option:string)=>{setSeletedClass(option)}} selectedOption={selectedClass}/>
<p className="mt-8">Teacher</p>
    <input
type="text"
placeholder="Autofilled"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-md placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
value={address?address:"0x5A6B842891032d702517a4E52ec38eE561063539"}
onChange={(e) => {
}}
></input>
<p className="mt-8">Weekly amount in dollars per student</p>
  <div className="flex justify-between"><input
type="text"
placeholder="Increment value"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[90%] flex-shrink-0 mr-2  "
value={weeklyAmonut}

></input><button className="px-3 py-2 font-semibold rounded-md text-white bg-black" onClick={()=>{
setWeeklyAmount(weeklyAmonut+5)
}}>+</button></div>  
     <p className="mt-8">Date of students' initial deposit</p>
    <div className="flex space-x-4">
    <input
type="text"
placeholder="Day"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={initialDeposit.day}
onChange={(e) => {
  setInitialDeposit({...initialDeposit,day:e.target.value})
}}
></input>
<input
type="text"
placeholder="Month"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={initialDeposit.month}
onChange={(e) => {
  setInitialDeposit({...initialDeposit,month:e.target.value})
}}
></input>
<input
type="text"
placeholder="Year"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={initialDeposit.year}
onChange={(e) => {
  setInitialDeposit({...initialDeposit,year:e.target.value})
}}
></input>
    </div>
    <p className="mt-8">Date of students' final deposit</p>
    <div className="flex space-x-4">
    <input
type="text"
placeholder="Day"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={finalDeposit.day}
onChange={(e) => {
  setFinalDeposit({...finalDeposit,day:e.target.value})
}}
></input>
<input
type="text"
placeholder="Month"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={finalDeposit.month}
onChange={(e) => {
  setFinalDeposit({...finalDeposit,month:e.target.value})
}}
></input>
<input
type="text"
placeholder="Year"
className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-[30%] flex-shrink-0 mr-2  "
value={finalDeposit.year}
onChange={(e) => {
  setFinalDeposit({...finalDeposit,year:e.target.value})
}}
></input>
    </div>
    </div>
    <button className="bg-[#FA378A] text-white px-3 py-2 rounded-lg font-semibold text-xl my-8">Create</button>
</div>
}