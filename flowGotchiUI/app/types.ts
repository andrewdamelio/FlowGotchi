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
    health: number;
    hunger: number;
  };
  items: { itemId: number; description: string; thumbnail: string }[];
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
