defmodule Loupgarou.GameLogic.PlayerProcess do


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

      {:dead} -> IO.puts("#{name} is dead")
                 Process.exit(self(), :normal)

    end
  end
end
