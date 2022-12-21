import { TPetInfo, TTask, TUser, TASK_STATUS } from "./types";

export const mockPetInfo: TPetInfo = {
  name: "Tony",
  description: "I'm walkin' here!",
  thumbnail: "someimage",
  owner: "0xdeadbeef",
  traits: {
    age: 50,
    friendshipLevel: 90,
    mood: 90,
    health: 100,
    hunger: 10,
  },
  items: [
    {
      itemId: 1,
      description: "Number One Foam Finger",
      thumbnail: "some image of afinger",
    },
  ],
};

export const mockTasks: TTask[] = [
  {
    questName: "NBA Top Shot Debut",
    questDescription: "Own one NBA Top Shot Moment",
    status: TASK_STATUS.Incomplete,
    progress: 0,
  },
  {
    questName: "NFL All Day Debut",
    questDescription: "Own one NFL All Day Moment",
    status: TASK_STATUS.Incomplete,
    progress: 0,
  },
  {
    questName: "Flow Rookie",
    questDescription: "Have at least 10 FLOW tokens in your Dapper Wallet",
    status: TASK_STATUS.Claimed,
    progress: 100,
  },
  {
    questName: "Flow Veteran",
    questDescription: "Have at least 50 FLOW tokens in your Dapper Wallet",
    status: TASK_STATUS.Claimable,
    progress: 100,
  },
  {
    questName: "Flow All Star",
    questDescription: "Have at least 1,000 FLOW tokens in your Dapper Wallet",
    status: TASK_STATUS.Incomplete,
    progress: 5,
  },
];

export const mockUser: TUser = {
  flow: "50.23",
  contracts: 0,
  topShotMoments: 1,
  allDayMoments: 2,
};
