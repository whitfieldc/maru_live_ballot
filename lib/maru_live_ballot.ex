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
  use Rethinkdb.Connection
end

defmodule MaruLiveBallot.API do
  use Maru.Router

  import Rethinkdb.Query

  get do
    table("posts") |> (MaruLiveBallot.Database).run |> IO.inspect
    json(conn, %{ hello: :world })
  end

  rescue_from :all, as: e do
    IO.inspect(e)
    put_status(conn, 500)
    text(conn, "Server Error")
  end
end
