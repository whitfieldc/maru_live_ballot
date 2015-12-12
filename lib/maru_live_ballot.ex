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


  namespace :ballots do
    params do
      optional :ballot, type: Map do
        requires :title
        requires :subscribe
        requires :option_one
        requires :option_two
      end
    end

    get do
      Database.start_link
      posts = table("posts")
        |> IO.inspect
        |> Database.run
      # IO.inspect(MaruLiveBallot.Database)
      json(conn, posts)
    end

    post do
      # curl -H "Content-Type: application/json" -X POST -d '{"title":"what type of bear is best?", "1":"black bear", "2":"grizzly bear", "subscribe":"this is definitely a url"}' http://localhost:8880/ballots | less
      # Database.start_link
      # body = fetch_req_body |> body_params
      body = conn.params
      # receive ballot: title/question, options, initial subscription URL
      # validate input and create autoincremented ID
      post = table("posts")
        |> insert(body)
        |> IO.inspect
        |> Database.run
      json(conn, post.data)
    end
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
