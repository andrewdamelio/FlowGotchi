"use client";

import Image from "next/image";
import { useState } from "react";
import { petFlowGotchi } from "./fclCalls";
import { TPetInfo, TItem, FRIENDSHIP_LEVEL } from "./types";

export const StatusArea = ({ pet }: { pet: TPetInfo }): JSX.Element => {
  const [showItems, setShowItems] = useState(false);

  return (
    <section className="flex flex-col mx-auto w-96 items-center justify-center bg-gradient-to-b from-lime-900 to-violet-400 p-2 rounded-xl relative">
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
          <p className="text-n font-sans p-2">{pet?.description}</p>
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
          <span className="">{`Relationship Status: ${
            FRIENDSHIP_LEVEL[parseInt(pet.traits.friendship)]
          }`}</span>
          <div className="w-56 justify-between flex flex-row py-2 h-20 items-start mb-6">
            <button
              onClick={() =>
                console.log("@TODO: fire off feed transaction here")
              }
              disabled={pet.actions.canFeed}
              className="cursor-pointer rounded-full w-14 h-14 bg-emerald-400"
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
              className={!pet.actions.canPet ?
                "opacity-20 rounded-full w-14 h-14 bg-emerald-400" :
                "cursor-pointer rounded-full w-14 h-14 bg-emerald-400"}
            >
              Pet
            </button>
          </div>
        </>
      )}
    </section>
  );
};

const ItemsList = ({ items = [], name }: { items: TItem[]; name: string }) => (
  <ul className="min-h-4 w-56 m-w-56">
    {items?.length === 0 && (
      <li key="noItems" className="text-center">
        <p className="font-sans ml-2">{`${name} doesn't have items.`}</p>
      </li>
    )}
    {items?.map((i) => (
      <li key={i.itemId} className="flex flex-row my-1">
        <div className="overflow-clip rounded-lg p-[2px] bg-gradient-to-tl from-cyan-600 to-rose-400">
          <Image
            alt=""
            src={i.thumbnail}
            width={50}
            height={50}
            style={{ borderRadius: "0.5rem" }}
          />
        </div>
        <p className="font-sans ml-2">{i.description}</p>
      </li>
    ))}
  </ul>
);
