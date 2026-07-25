import { RuntimeAgentConsole } from "../components/runtime-agent-console";
import { loadViewOptions } from "../lib/views";

export default async function Page() {
  const views = await loadViewOptions();

  return <RuntimeAgentConsole views={views} />;
}
