"use client";
import { TTask, TASK_STATUS } from "./types";

export const TaskList = ({ tasks }: { tasks?: TTask[] }) => (
  <section className="items-center flex flex-col my-2">
    <h2 className="text-2xl">Tasks</h2>
    <ul>
      {tasks?.map((t) => (
        <TaskItem key={t.name} task={t} />
      ))}
    </ul>
  </section>
);

const TaskItem = ({ task }: { task: TTask }) => {
  let CustomButton = null;

  switch (task?.status?.rawValue) {
    case TASK_STATUS.Claimable: {
      CustomButton = (
        <button
          className="col-span-4 justify-self-end font-serif cursor-pointer p-2 rounded-md h-10 w-max bg-emerald-400 disabled:bg-amber-300"
          onClick={() => console.log("@TODO: Claim Action")}
        >
          Claimable
        </button>
      );
      break;
    }
    case TASK_STATUS.Completed: {
      CustomButton = (
        <button
          className="col-span-4 justify-self-end font-serif cursor-pointer p-2 rounded-md h-10 w-max bg-emerald-400 disabled:bg-emerald-600"
          onClick={() => null}
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
    <li className="p-2 my-1 grid grid-cols-12 rounded-xl bg-gradient-to-tr from-violet-400 to-cyan-500 dark:from-violet-200 dark:to-cyan-300">
      <h4 className="font-serif col-span-full text-stone-100 dark:text-violet-800 text-lg">
        {task.name}
      </h4>
      <p className="font-sans col-span-full text-m text-slate-50 dark:text-emerald-700">
        {task.description}
      </p>
      <div className="flex flex-row whitespace-nowrap my-1 col-span-8">
        <span className="text-m font-sans mr-2 text-slate-50 dark:text-emerald-700">Progress: </span>
        <span className="text-m font-sans text-slate-50 dark:text-emerald-700">
          {task.progress}%
        </span>
      </div>
      {CustomButton}
    </li>
  );
};
