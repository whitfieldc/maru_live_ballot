defmodule MaruLiveBallot.Database do
  use RethinkDB.Connection
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
        requires :vote
      end

      patch "/tallies" do
        # curl -H "Content-Type: application/json" -X PATCH -d '{"vote": "grizzly_bear"}' http://localhost:8880/ballots/8f657c73-87f8-4e85-9a75-fac4a2b90c0b/tallies | less
        vote = params[:vote] |> IO.inspect

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
