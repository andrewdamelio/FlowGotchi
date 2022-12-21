"use client";

import Image from "next/image";
import flowagotchi from "../public/Avatar of a tamagotchi.png";
import { mockPetInfo } from "./mock";
import { TPetInfo } from "./types";

export const StatusArea = ({
  pet = mockPetInfo,
}: {
  pet?: TPetInfo;
}): JSX.Element => {
  return (
    <section className="flex flex-col mx-auto w-96 items-center justify-center bg-gradient-to-b from-lime-900 to-violet-400 p-2 rounded-xl relative">
      <h1 className="text-2xl font-serif py-2 text-cyan-500">{pet?.name}</h1>
      <p className="text-n font-sans">{pet?.description}</p>
      <div className="overflow-clip rounded-lg p-1 bg-gradient-to-tl from-cyan-600 to-rose-400">
        <Image
          alt={`${pet?.name}'s profile image`}
          src={flowagotchi}
          width={200}
          height={200}
          priority
          style={{ borderRadius: "0.5rem" }}
        />
      </div>
      <ul className='absolute bottom-2 left-2 right-2 flex flex-row justify-between h-6'>
        <li>Age: {pet.traits.age}</li>
        <li>Mood: {pet.traits.mood}</li>
        <li>Hunger: {pet.traits.hunger}</li>
      </ul>
      <div className="w-56 justify-between flex flex-row py-2 h-20 items-start mb-6">
        <button
          onClick={() => console.log("fire off feed transaction here")}
          className="cursor-pointer rounded-full w-12 h-12 bg-emerald-400"
        >
          Feed
        </button>
        <button
          onClick={() => console.log("fire off Gift transaction here")}
          className="self-end cursor-pointer rounded-full w-12 h-12 bg-emerald-400"
        >
          Gift
        </button>
        <button
          onClick={() => console.log("fire off Pet transaction here")}
          className="cursor-pointer rounded-full w-12 h-12 bg-emerald-400"
        >
          Pet
        </button>
      </div>
    </section>
  );
};
