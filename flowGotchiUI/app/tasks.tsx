"use client";
import { mockTasks } from "./mock";
import { TTask, TASK_STATUS } from "./types";

export const TaskList = ({ tasks = mockTasks }: { tasks?: TTask[] }) => {
  return (
    <section className="items-center flex flex-col my-2">
      <h2 className="text-2xl">Tasks</h2>
      <ul>
        {tasks.map((t) => (
          <TaskItem key={t.questName} task={t} />
        ))}
      </ul>
    </section>
  );
};

const TaskItem = ({ task }: { task: TTask }) => {
  let CustomButton = (
    <button
      className="col-span-4 justify-self-end font-serif cursor-pointer p-2 rounded-md h-10 w-max bg-emerald-400 disabled:bg-amber-300"
      onClick={() => console.log("No Action")}
      disabled={true}
    >
      Incomplete
    </button>
  );

  switch (task?.status) {
    case TASK_STATUS.Claimable: {
      CustomButton = (
        <button
          className="col-span-4 justify-self-end font-serif cursor-pointer p-2 rounded-md h-10 w-max bg-emerald-400 disabled:bg-amber-300"
          onClick={() => console.log("Claim Action")}
          disabled={false}
        >
          Claimable
        </button>
      );
      break;
    }
    case TASK_STATUS.Claimed: {
      CustomButton = (
        <button
          className="col-span-4 justify-self-end font-serif cursor-pointer p-2 rounded-md h-10 w-max bg-emerald-400 disabled:bg-emerald-600"
          onClick={() => console.log("No Action")}
          disabled={true}
        >
          Claimed
        </button>
      );
      break;
    }
    default:
      break;
  }
  return (
    <li className="p-2 my-1 grid grid-cols-12 rounded-xl bg-gradient-to-tr from-violet-300 to-cyan-500">
      <h4 className="font-serif col-span-full">{task.questName}</h4>
      <p className="font-sans col-span-full">{task.questDescription}</p>
      <div className="flex flex-row whitespace-nowrap my-1 col-span-8">
        <span className="text-m font-sans mr-2">Progress: </span>
        <span className="text-m font-sans">
          {task.progress}%
        </span>
      </div>
      {CustomButton}
    </li>
  );
};
