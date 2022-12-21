import { StatusArea } from "./statusArea";
import { UserInfo } from './userInfo';
import { mockTasks, mockPetInfo, mockUser } from "./mock";
import { TaskList } from "./tasks";

export default function Home() {
  return (
    <main className="container flex flex-col mx-auto py-12">
      <h1 className="text-4xl text-lime-500 font-serif text-center my-2">FlowGotchi</h1>
      <StatusArea pet={mockPetInfo} />
      <UserInfo user={mockUser} />
      <TaskList tasks={mockTasks} />
    </main>
  );
}
