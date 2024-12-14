defmodule Loupgarou.GameLogic.PlayerProcess do


  def loop(name, role, status) do
    receive do
      {:setRole, newRole} -> loop(name, newRole, status)

      #{:getRole, from} -> send()

      {:sleep} -> IO.puts("sleeping")

      {:wolfWakeUp} when role == :wolf -> IO.puts("wake up")

      {:wakeUp} -> IO.puts("waking up")

      {:vote} -> IO.puts("voting")
      # send to GameProcess my vote

      {:dead} -> IO.puts("#{name} is dead")
                 Process.exit(self(), :normal)

    end
  end
end
