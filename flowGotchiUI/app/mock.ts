import { TPetInfo, TTask, TUser, TASK_STATUS } from "./types";
import trophy1 from "../public/trophy_1.png";
import trophy2 from "../public/trophy_2.png";

export const mockPetInfo: TPetInfo = {
  name: "Tony",
  description: "I'm walkin' here!",
  thumbnail: "someimage",
  owner: "0xdeadbeef",
  traits: {
    age: 50,
    friendshipLevel: 90,
    mood: 90,
    hunger: 10,
  },
  items: [
    {
      itemId: '1',
      description: "50 FLOW tokens",
      thumbnail: trophy1,
    },
    {
      itemId: '2',
      description: "10 FLOW tokens",
      thumbnail: trophy2,
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
