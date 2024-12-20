defmodule Loupgarou.GameLogic.PlayerProcess do

@doc """
updates the information of the player thoughout the game by communicating with messages from and to the game process
"""
  def loop(name, role, status) do
    receive do
      {:setRole, newRole, from} -> IO.inspect("#{name} has received new Role #{newRole}")
                                   send(from, {:replySetRole})
                                  loop(name, newRole, status)


      {:getRole, from} -> send(from, {:replyRole, role})
                          loop(name, role, status)

      {:setStatus, newStatus} -> IO.inspect("#{name} hast received new State: #{newStatus}" )
                                 loop(name, role, newStatus)

      {:getStatus, from} -> send(from, {:replyStatus, status})
                            loop(name, role, status)

      {:dead, from} -> IO.puts("#{name} is dead")
                 send(from, {:replyDead, :ok})
                 Process.exit(self(), :normal)

    end
  end
end
