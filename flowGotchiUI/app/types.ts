import { StaticImageData } from "next/image";

export enum TASK_STATUS {
  Claimable,
  Claimed,
  Incomplete,
}

export type TPetInfo = {
  name: string;
  description: string;
  thumbnail: string;
  owner: string;
  traits: {
    age: number;
    friendshipLevel: number;
    mood: number;
    hunger: number;
  };
  items: TItem[];
};

export type TItem = {
  itemId: string;
  description: string;
  thumbnail: string | StaticImageData;
};

export type TTask = {
  questName: string;
  questDescription: string;
  status: TASK_STATUS;
  progress: number;
};

export type TUser = {
  flow: string;
  contracts: number;
  topShotMoments: number;
  allDayMoments: number;
};
