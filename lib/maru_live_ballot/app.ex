defmodule MaruLiveBallot.Database do
  use RethinkDB.Connection
end

defmodule MaruLiveBallot.Changefeed do
  use RethinkDB.Changefeed

  import RethinkDB.Query

  def start_link(opts, gen_server_opts \\[]) do
    RethinkDB.Changefeed.start_link(__MODULE__, opts, gen_server_opts)
  end

  def init(db) do
    q = table("posts")
      # |> limit(10)
      |> changes()
    {:subscribe, q, db, nil}
  end

  def handle_update(data, nil) do
    IO.puts('hello change')
    IO.inspect(data)
    {:next, data}
  end

  def handle_update(updates, list) do
    IO.puts('HELLO change')
    IO.inspect(updates)
    old_tallies = hd(updates)["old_val"]["tallies"] |> IO.inspect
    case hd(updates)["new_val"]["tallies"] do
      old_tallies ->
        IO.puts('broadcast the update')
        IO.inspect(hd(updates)["new_val"]["tallies"])
        {:next, list}
      _ ->
        IO.puts('no new votes')
        {:next, list}
    end
    # {:next, list}
  end

end

defmodule MaruLiveBallot.Router.Endpoint do
  use Maru.Router
  alias MaruLiveBallot.QueryWrapper

  namespace :ballots do

    get do
      posts = QueryWrapper.get_all_ballots
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

      post = QueryWrapper.create_ballot(formatted_ballot)
      json(conn, post.data)
    end

    route_param :id do
      get do
        ballot = QueryWrapper.get_ballot_by_id(params[:id])
        json(conn, hd(ballot.data))
      end

      get "/options" do
        ballot = QueryWrapper.get_ballot_by_id(params[:id])
        options = hd(ballot.data)["options"]
          # ^^ should be a way to use atom keys here?
        json(conn, options)
      end

      params do
        requires :subscriber
      end

      post "/subscriptions" do
        # curl -H "Content-Type: application/json" -X POST -d '{"subscriber": "grizzly_bear"}' http://localhost:8880/ballots/8f657c73-87f8-4e85-9a75-fac4a2b90c0b/subscriptions | less
        ballot = QueryWrapper.add_subscriber(params[:id], params[:subscriber])

        json(conn, %{hello: :new_subscriber})

      end

      params do
        requires :vote
      end

      patch "/tallies" do
        # curl -H "Content-Type: application/json" -X PATCH -d '{"vote": "grizzly_bear"}' http://localhost:8880/ballots/8f657c73-87f8-4e85-9a75-fac4a2b90c0b/tallies | less
        vote = params[:vote] #|> IO.inspect

        QueryWrapper.update_tally(params[:id], vote) # |> IO.inspect

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
