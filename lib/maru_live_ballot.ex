defmodule MaruLiveBallot do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [ worker(MaruLiveBallot.Database, []) ]
    opts = [strategy: :one_for_one, name: MaruTodo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule MaruLiveBallot.Database do
  use RethinkDB.Connection
end

defmodule MaruLiveBallot.API do
  use Maru.Router
  alias MaruLiveBallot.Database

  import RethinkDB.Query

  get do
    table("posts")
      |> IO.inspect
      |> Database.run
      # |> IO.inspect
    # IO.inspect(MaruLiveBallot.Database)
    text(conn, "hi")
  end

  rescue_from :all, as: e do
    IO.inspect(e)
    put_status(conn, 500)
    text(conn, "Server Error")
  end
end
