"use client";
import { useState } from "react";
import { StatusArea } from "./statusArea";
import { UserInfo } from "./userInfo";
import { mockUser } from "./mock";
import { TaskList } from "./tasks";
import { TPetInfo, TUser, TTask } from "./types";
import { getMetaData, hasFlowGotchi, setupFlowGotchi, mintFlowGotchi } from "./fclCalls";
import * as fcl from "@onflow/fcl"

export default function Home() {
  const [isLogged, setIsLogged] = useState(false);
  const [user, setUser] = useState<null | TUser>(null);
  const [pet, setPet] = useState<null | TPetInfo>(null);
  const [tasks, setTasks] = useState<TTask[]>([]);
  const isLoggedIn = isLogged && pet && user;

  const loadMetaData = async(addr: string) => await getMetaData(addr);

  const logout = async () => {
    await fcl.currentUser.unauthenticate();

    setUser(null);
    setPet(null);
    setTasks([]);
    setIsLogged(false);
  };

  const login = async () => {
    // await fcl.unauthenticate();
    fcl.config({
      "accessNode.api": "https://rest-testnet.onflow.org",
      // "discovery.wallet": "https://fcl-discovery.onflow.org/testnet/authn"
      "discovery.wallet": "https://staging.accounts.meetdapper.com/fcl/authn-restricted",
      "discovery.wallet.method": "POP/RPC"
    });

    await fcl.logIn()
    let flowUser =  await fcl.currentUser.authenticate();
    const address = flowUser?.addr;

    if (address) {
      const isFlowGotchiSetup = await hasFlowGotchi(address);
      let metaData = null;

      if (!isFlowGotchiSetup) {
        await setupFlowGotchi();
        await mintFlowGotchi();
      }

      metaData = await loadMetaData(address);
      setUser(mockUser);   // TODO
      setPet(metaData);
      setTasks(metaData?.quests || []);
      setIsLogged(true);
    }
  };

  return (
    <main className="container flex flex-col mx-auto py-12 relative">
      <h1 className="text-4xl text-lime-500 font-serif text-center my-2">
        FlowGotchi
      </h1>
      {isLoggedIn && (
        <>
         <button
            className="font-serif cursor-pointer h-8 px-4 my-2 rounded-full bg-emerald-500 w-max absolute top-2 right-2"
            onClick={logout}
          >
            Disconnect Wallet
          </button>
          <StatusArea pet={pet} />
          <UserInfo user={user} />
          <TaskList tasks={tasks} />
        </>
      )}
      {!isLoggedIn && (
        <section className="flex flex-col mx-auto w-96 items-center justify-center">
          <p className="font-sans text-m">
            Please connect a dapper wallet to get your FlowGotchi
          </p>
          <button
            className="font-serif cursor-pointer h-8 px-4 my-2 rounded-full bg-emerald-500"
            onClick={login}
          >
            Connect Wallet
          </button>
        </section>
      )}
    </main>
  );
}
