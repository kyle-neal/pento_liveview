defmodule PentoWeb.WrongLive do
  alias PentoWeb.WrongLive
  use Phoenix.LiveView, layout: {PentoWeb.LayoutView, "live.html"}

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket, score: 0, message: "Make a guess:", time: time(), guessed_correctly: false)}
  end

  def render(assigns) do
    ~H"""
    <h1>Your score: <%= @score %></h1>
    <h2><%= @message %></h2>
    <h2>
      <%= for n <- 1..10 do %>
        <a href="#" phx-click="guess" phx-value-number={n}><%= n %></a>
      <% end %>
      <%= if @won_game do %>
        <%= live_patch("Retry?", to: Routes.live_path(@socket, WrongLive)) %>
      <% end %>
    </h2>
    <footer>
      <h4>It's now <%= @time %></h4>
    </footer>
    """
  end

  def handle_event("guess", %{"number" => guess} = data, socket) do
    {message, score, guessed_correctly} =
      case guessed_correct?(guess) do
        true ->
          {"You guessed correct!", socket.assigns.score + 1, true}

        false ->
          {"You guessed wrong :(", socket.assigns.score - 1, socket.assigns.guessed_correctly}
      end

    {:noreply,
     assign(socket,
       message: message,
       score: score,
       time: time(),
       guessed_correctly: guessed_correctly
     )}
  end

  defp guessed_correct?(guess) do
    randnum = :rand.uniform(10)
    is_correct = :erlang.binary_to_integer(guess) == randnum
    IO.puts("Generated #{randnum} guess is #{guess} -> #{is_correct}")
    is_correct
  end

  def time() do
    DateTime.utc_now() |> to_string
  end
end
