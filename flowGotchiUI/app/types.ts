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

export type TRawMetaData = {
  name: string;
  description: string;
  owner: string;
  thumbnail: string;
  actions: TPetActions;
  traits: TPetTraits;
  items?: TItem[];
  quests: TQuest[];
}

export type TPetActions = {
  canFeed: boolean;
  canPet: boolean;
  lastFed: string;
  lastPet: string;
  nextFeedingTime: string;
  nextPettingTime: string;
};
export type TPetTraits = 
  {
    age: string;
    friendship: string;
    mood: string;
    hunger: string;
  }

export type TPetInfo = {
  name: string;
  description: string;
  thumbnail: string;
  owner: string;
  traits: TPetTraits;
  items: TItem[];
  actions: TPetActions;
};

export type TItem = {
  itemId: string;
  description: string;
  thumbnail: string | StaticImageData;
};

export type TQuest = {
  name: string;
  description: string;
  status: {
    rawValue: TASK_STATUS;
  };
};

export type TTask = {
  name: string;
  description: string;
  status: {
    rawValue: TASK_STATUS;
  }
  progress: number;
  getProgress?: (arg0: TUser) => number;
}

export type TUser = {
  flow: string;
  contracts: number;
  topShotMoments: number;
  allDayMoments: number;
};
