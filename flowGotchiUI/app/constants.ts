import { TUser } from "./types";

export const TASKS = [
  {
    name: "Flow Rookie",
    description: "Have at least 10 FLOW tokens in your Dapper Wallet",
    status: { rawValue: "0" },
    getProgress: (user: TUser) => handleProgress(parseInt(user.flow), 10),
  },
  {
    name: "Flow Veteran",
    description: "Have at least 50 FLOW tokens in your Dapper Wallet",
    status: { rawValue: "0" },
    getProgress: (user: TUser) => handleProgress(parseInt(user.flow), 50),
  },
  {
    name: "Flow All Star",
    description: "Have at least 1,000 FLOW tokens in your Dapper Wallet",
    status: { rawValue: "0" },
    getProgress: (user: TUser) => handleProgress(parseInt(user.flow), 1000),
  },
  {
    name: "NBA Top Shot Debut",
    description: "Own one NBA Top Shot Moment",
    status: { rawValue: "0" },
    getProgress: (user: TUser) => handleProgress(user.topShotMoments, 1),
  },
  {
    name: "NFL All Day Debut",
    description: "Own one NFL All Day Moment",
    status: { rawValue: "0" },
    getProgress: (user: TUser) => handleProgress(user.allDayMoments, 1),
  },
];

const handleProgress = (val = 0, max = 1) => {
  const curValPercent = Math.round((val / max) * 100);
  return curValPercent > 100 ? 100 : curValPercent;
}