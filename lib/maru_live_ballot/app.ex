defmodule MaruLiveBallot.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    [worker(MaruLiveBallot.Database, [])
    ] |> supervise strategy: :one_for_one
  end
  
end

defmodule MaruLiveBallot.Database do
  use RethinkDB.Connection
end

defmodule MaruLiveBallot.QueryWrapper do
    import RethinkDB.Query
    alias MaruLiveBallot.Database

    require RethinkDB.Lambda
    import RethinkDB.Lambda

  def get_all_ballots do
    posts = table("posts")
      |> IO.inspect
      |> Database.run
  end

  def get_ballot_by_id(id_to_get) do
    ballot = table("posts")
      |> filter(%{id: id_to_get})
      |> Database.run
    # ballot
  end

  def update_tally(id, choice) do
    ballot = table("posts")
          |> get(id)
          |> update(lambda fn (doc) -> %{tallies: %{grizzly_bear: doc["tallies"]["grizzly_bear"] +1}} end)
          |> Database.run
          |> IO.inspect
  end
end

defmodule MaruLiveBallot.Router.Endpoint do
  use Maru.Router
  alias MaruLiveBallot.Database

  import RethinkDB.Query, only: [table_create: 1, table: 2, table: 1, insert: 2, filter: 2]


  namespace :ballots do

    get do
      posts = MaruLiveBallot.QueryWrapper.get_all_ballots
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

      # initializes tallies map based on options list
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
    end

    route_param :id do
      get do
        ballot = MaruLiveBallot.QueryWrapper.get_ballot_by_id(params[:id])
        json(conn, hd(ballot.data))
      end

      get "/options" do
        ballot = MaruLiveBallot.QueryWrapper.get_ballot_by_id(params[:id])
        options = hd(ballot.data)["options"]
          # ^^ should be a way to use atom keys here?
        json(conn, options)
      end

      params do
        requires :vote
      end

      patch "/tallies" do
        # curl -H "Content-Type: application/json" -X PATCH -d '{"vote": "grizzly_bear"}' http://localhost:8880/ballots/e5632783-d472-48af-8e82-f271bceb4f8d/tallies | less
        vote = params[:vote] |> IO.inspect


        MaruLiveBallot.QueryWrapper.update_tally(params[:id], vote) |> IO.inspect

        # tallies = hd(ballot.data)["tallies"] |> IO.inspect

        json(conn, %{hello: :dude})

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
