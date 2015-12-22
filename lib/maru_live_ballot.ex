defmodule MaruLiveBallot do
  use Application

  def start(_type, _args) do
    IO.puts("HELLO")
    MaruLiveBallot.Supervisor.start_link
  end

end