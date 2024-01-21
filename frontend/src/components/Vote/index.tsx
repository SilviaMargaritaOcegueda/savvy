import React, { useState } from "react";
import Dropdown from "../Dropdown";
import { useAccount } from "wagmi";

export default function Vote() {
  const [classWallet, setClassWallet] = useState("");
  const [strategyOption, setStrategyOption] = useState("");
  const [strategies, setStrategies] = useState([
    "CONSERVATIVE",
    "MODERATE",
    "AGGRESSIVE",
  ]);
  const [selectedStrategy, setSeletedStrategy] = useState("CONSERVATIVE");
  return (
    <div className="flex flex-col justify-center items-center">
      <div className="mt-8 text-center">
        <p className="text-black font-bold text-3xl">Vote</p>
        <p className="text-black font-normal mt-2 text-lg">
          Choose Strategy Option
        </p>
      </div>
      <div className="text-[#595B70] w-[500px]">
        <p className="mt-8">Class</p>
        <input
          type="text"
          placeholder="1A"
          className="font-theme  font-semibold placeholder:text-[#9A9A9A] text-xl placeholder:text-base bg-[#E8E8E8] border  border-white focus:border-[#25272b] my-1 pl-6 text-black p-2 rounded-xl focus:outline-none  w-full flex-shrink-0 mr-2  "
          value={classWallet}
          onChange={(e) => {
            setClassWallet(e.target.value);
          }}
        ></input>
      </div>
      <div className="text-[#595B70] w-[500px]">
        <p className="mt-8">Strategy Option</p>
        <Dropdown
          options={strategies}
          setOption={(option: string) => {
            setSeletedStrategy(option);
          }}
          selectedOption={selectedStrategy}
        />
      </div>
      <div className="text-[#595B70] w-[500px]">
        <p className="mt-8"></p>
        <p className="mt-8"></p>
      </div>
      <button className="bg-[#FA378A] text-white px-3 py-2 rounded-lg font-semibold text-xl my-8">
        Vote
      </button>
    </div>
  );
}
