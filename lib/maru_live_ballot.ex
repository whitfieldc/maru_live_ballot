defmodule MaruLiveBallot do
  use Application

  def start(_type, _args) do
    MaruLiveBallot.Supervisor.start_link
  end

end