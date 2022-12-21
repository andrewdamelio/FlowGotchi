"use client";
import { TUser } from "./types";

export const UserInfo = ({ user }: { user: TUser }) => {
  return (
    <section className="flex flex-row mx-auto w-96 items-center my-2">
      <ol className="flex flex-row justify-between w-full px-2">
        <li className="flex flex-row">
          <span className="font-serif mr-2">Flow:</span>
          {user.flow}
        </li>
        <li className="flex flex-row flex-nowrap">
          <span className="font-serif mr-2">NBATS:</span>
          {user.topShotMoments}
        </li>
        <li className="flex flex-row flex-nowrap">
          <span className="font-serif mr-2">NFLAD:</span>
          {user.allDayMoments}
        </li>
      </ol>
    </section>
  );
};
