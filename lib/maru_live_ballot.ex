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

  import RethinkDB.Query, only: [table_create: 1, table: 2, table: 1, insert: 2, filter: 2]


  namespace :ballots do

    get do
      Database.start_link
      posts = table("posts")
        |> IO.inspect
        |> Database.run
      json(conn, posts)
    end

    params do
      group :ballot, type: Map do
        requires :title
        requires :subscriptions
        requires :options, type: List
      end
    end

    post do
      # curl -H "Content-Type: application/json" -X POST -d '{"ballot": {"title":"what type of bear is best?", "options":["black_bear","grizzly_bear"], "subscriptions":["this is definitely a url"]}}' http://localhost:8880/ballots | less
      params_ballot = params[:ballot]

      tallies = params_ballot.options
        |> Enum.reduce(%{},
          fn(option, new_map) ->
            Map.put(new_map, option, 0)
          end
        )

      formatted_ballot = Map.put(params_ballot, :tallies, tallies)

      post = table("posts")
        |> insert(formatted_ballot)
        |> IO.inspect
        |> Database.run
      json(conn, post.data)
      # json(conn, %{hello: :world})
    end

    route_param :id do
      get do
        ballot = table("posts")
          |> filter(%{id: params[:id]})
          |> Database.run
          |> IO.inspect
        json(conn, hd(ballot.data))
      end


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
