defmodule MaruLiveBallot do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: true
    children = [
      supervisor(MaruLiveBallot.API, []),
      worker(MaruLiveBallot.Database, [])
    ]
    opts = [strategy: :one_for_one, name: MaruLiveBallot.Supervisor]
    # opts = []
    IO.puts("starting")
    Supervisor.start_link(children, opts)
    IO.inspect(Supervisor)
  end
end

defmodule MaruLiveBallot.Database do
  use RethinkDB.Connection
end

defmodule MaruLiveBallot.Router.Endpoint do
  use Maru.Router
  alias MaruLiveBallot.Database

  import RethinkDB.Query, only: [table_create: 1, table: 2, table: 1, insert: 2]

  get "/" do
    Database.start_link
    table("posts")
      |> IO.inspect
      |> Database.run
      |> IO.inspect
    # IO.inspect(MaruLiveBallot.Database)
    text(conn, "live reload")
  end

  post "/ballots" do
    # Database.start_link
    # body = fetch_req_body |> body_params
    body = conn.params
    # receive ballot: title/question, options, initial subscription URL
    # validate input and create autoincremented ID
    table("posts")
      |> insert(body)
      |> IO.inspect
      |> Database.run
      |> IO.inspect
    json(conn, %{hello: :world})
  end


end


defmodule MaruLiveBallot.API do
  use Maru.Router

  mount MaruLiveBallot.Router.Endpoint

  rescue_from :all, as: e do
    IO.inspect(e)
    put_status(conn, 500)
    text(conn, "Server Error")
  end
end
