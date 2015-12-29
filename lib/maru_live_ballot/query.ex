defmodule MaruLiveBallot.QueryWrapper do
    import RethinkDB.Query
    alias MaruLiveBallot.Database

    require RethinkDB.Lambda
    import RethinkDB.Lambda

  def get_all_ballots do
    posts = table("posts")
      # |> IO.inspect
      |> Database.run
  end

  def create_ballot(new_ballot) do
    post = table("posts")
      |> insert(new_ballot)
      # |> IO.inspect
      |> Database.run
  end

  def get_ballot_by_id(id_to_get) do
    ballot = table("posts")
      |> filter(%{id: id_to_get})
      |> Database.run
    # ballot
  end

  def update_tally(id, choice) do
    # ballot = table("posts")
    #   |> get(id)
    #   |> update(lambda fn (doc) -> %{tallies: %{grizzly_bear: doc["tallies"]["grizzly_bear"] +1}} end)
    #   |> Database.run
    #   |> IO.inspect

    ballot = hd(get_ballot_by_id(id).data) |> IO.inspect

    updated_count = ballot["tallies"]
      |> Map.update!(choice, fn(val) -> val+1 end)

    inserted_ballot = table("posts")
      |> get(id)
      |> update(%{"tallies" => updated_count})
      |> Database.run

  end
end