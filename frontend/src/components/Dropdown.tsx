import { faChevronDown, faChevronUp } from "@fortawesome/free-solid-svg-icons";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { useState } from "react";

export default function Dropdown({
  options,
  setOption,
  selectedOption,
}: {
  options: string[];
  setOption: (option: string) => void;
  selectedOption: string;
}) {
  const [isOpen, setIsOpen] = useState(false);

  const toggleDropdown = () => {
    setIsOpen(!isOpen);
  };
  return (
    <div className="relative inline-block text-left">
      <div>
        <button
          type="button"
          onClick={toggleDropdown}
          className="inline-flex justify-center w-full rounded-md border border-[#9E9E9E] shadow-sm px-4 py-2 bg-[#E8E8E8] text-black text-sm font-medium text-[#FAFAFA] focus:outline-none "
          id="options-menu"
          aria-haspopup="true"
          aria-expanded="true"
        >
          <p>{selectedOption}</p>
          <FontAwesomeIcon
            icon={isOpen ? faChevronUp : faChevronDown}
            className="ml-28 my-auto"
          />
        </button>
      </div>

      {isOpen && (
        <div
          className="origin-top-left absolute left-0  w-full rounded-md shadow-lg bg-[#1E1A20] ring-1 ring-black ring-opacity-5"
          role="menu"
          aria-orientation="vertical"
          aria-labelledby="options-menu"
        >
          <div className="py-1" role="none">
            {options.map((option) => (
              <a
                key={option}
                href="#"
                onClick={() => {
                  setIsOpen(false);
                  setOption(option);
                }}
                className="block px-4 py-2 text-sm text-white hover:bg-[#F8049C] hover:to-[#] "
                role="menuitem"
              >
                {option}
              </a>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}