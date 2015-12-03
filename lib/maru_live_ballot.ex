defmodule MaruLiveBallot.API do
  use Maru.Router

  get do
    json(conn, %{ hello: :world })
  end

  rescue_from :all, as: e do
    IO.inspect(e)
    put_status(conn, 500)
    text(conn, "Server Error")
  end
end
