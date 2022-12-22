import { StaticImageData } from "next/image";

export enum TASK_STATUS {
  Incomplete,
  Completed,
  Claimable,
}

export enum FRIENDSHIP_LEVEL {
  'Acquaintance',
  'Friend',
  'Good Friend',
  'Great Friend',
  'Best Friend',
  'Soul Mate',
}

export type TPetActions = {
  canFeed: boolean;
  canPet: boolean;
  lastFed: string;
  lastPet: string;
  nextFeedingTime: string;
  nextPettingTime: string;
};

export type TPetInfo = {
  name: string;
  description: string;
  thumbnail: string;
  owner: string;
  traits: {
    age: string;
    friendship: string;
    mood: string;
    hunger: string;
  };
  items: TItem[];
  actions: TPetActions;
};

export type TItem = {
  itemId: string;
  description: string;
  thumbnail: string | StaticImageData;
};

export type TTask = {
  name: string;
  description: string;
  status: {
    rawValue: TASK_STATUS;
  };
  // status: TASK_STATUS;
  // progress: number;
};


export type TUser = {
  flow: string;
  contracts: number;
  topShotMoments: number;
  allDayMoments: number;
};
