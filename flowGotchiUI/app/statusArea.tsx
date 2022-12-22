"use client";

import Image from "next/image";
import { useState } from "react";
import { petFlowGotchi, feedFlowGotchi } from "./fclCalls";
import { TPetInfo, TItem, FRIENDSHIP_LEVEL } from "./types";

export const StatusArea = ({ pet }: { pet: TPetInfo }): JSX.Element => {
  const [showItems, setShowItems] = useState(false);
  return (
    <section className="mx-auto w-96 rounded-xl p-1 bg-gradient-to-tl from-amber-600 to-lime-400">
      <div className="flex flex-col w-full items-center justify-center bg-gradient-to-b from-lime-900 to-violet-400 p-2 rounded-xl relative">
        <h1 className="text-2xl font-serif py-2 text-cyan-500">{pet?.name}</h1>
        {showItems ? (
          <>
            <div className="absolute top-2 left-2 overflow-clip rounded-lg p-1 bg-gradient-to-tl from-cyan-600 to-rose-400">
              <Image
                alt={`${pet?.name}'s profile image`}
                src={pet?.thumbnail}
                width={50}
                height={50}
                priority
                style={{ borderRadius: "0.5rem" }}
              />
            </div>
            <button
              onClick={() => setShowItems(false)}
              className="absolute top-2 right-2 cursor-pointer rounded-full w-14 h-14 bg-emerald-400"
            >
              Back
            </button>
            <ItemsList items={pet.items} name={pet.name} />
          </>
        ) : (
          <>
            <p className="text-n font-sans p-2 text-slate-50">
              {pet?.description}
            </p>
            <ul className="absolute bottom-2 left-2 right-2 flex flex-row justify-between h-6">
              <li>{`Age: ${Math.floor(parseInt(pet.traits.age))}`}</li>
              <li>{`Mood: ${pet.traits.mood}`}</li>
              <li>{`Hunger: ${pet.traits.hunger}`}</li>
            </ul>
            <div className="overflow-clip rounded-lg p-1 bg-gradient-to-tl from-cyan-600 to-rose-400">
              <Image
                alt={`${pet?.name}'s profile image`}
                src={pet?.thumbnail}
                width={200}
                height={200}
                priority
                style={{ borderRadius: "0.5rem" }}
              />
            </div>
            <span className=" text-slate-50">{`Relationship Status: ${
              FRIENDSHIP_LEVEL[parseInt(pet.traits.friendship)]
            }`}</span>
            <div className="w-56 justify-between flex flex-row py-2 h-20 items-start mb-6">
              <button
                onClick={() => feedFlowGotchi()}
                disabled={!pet.actions.canFeed}
                className="cursor-pointer rounded-full w-14 h-14 bg-emerald-400 disabled:opacity-50"
              >
                Feed
              </button>
              <button
                onClick={() => setShowItems(true)}
                className="self-end cursor-pointer rounded-full w-14 h-14 bg-emerald-400"
              >
                Items
              </button>
              <button
                onClick={() => petFlowGotchi()}
                disabled={!pet.actions.canPet}
                className="cursor-pointer rounded-full w-14 h-14 bg-emerald-400 disabled:opacity-50"
              >
                Pet
              </button>
            </div>
          </>
        )}
      </div>
    </section>
  );
};

const ItemsList = ({ items = [], name }: { items: TItem[]; name: string }) => (
  <ul className="min-h-4 w-56 m-w-56">
    {items?.length === 0 && (
      <li key="noItems" className="text-center">
        <p className="font-sans ml-2 text-slate-50">{`${name} doesn't have items.`}</p>
      </li>
    )}
    {items?.map((i) => (
      <li key={i.itemId} className="flex flex-row my-1 bg-cyan-900 rounded-lg p-1">
        <div className="overflow-clip rounded-lg p-[2px] bg-gradient-to-tl from-cyan-600 to-rose-400">
          <Image
            alt=""
            src={i.thumbnail}
            width={50}
            height={50}
            style={{ borderRadius: "0.5rem" }}
          />
        </div>
        <p className="font-sans ml-2 text-slate-50">{i.description}</p>
      </li>
    ))}
  </ul>
);
