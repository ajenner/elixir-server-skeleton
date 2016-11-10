defmodule Server do
  use Application
  import Supervisor.Spec

  @port Application.get_env(:server, :port)

  def start(_type, _args) do
    IO.puts "Server Started\n"
    children = [
      worker(Task, [Server, :listen, [@port]])
      supervisor(Task.Supervisor, [[name: Server.TaskSupervisor]])
      ]
    options = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, options)
  end

  def listen(port) do
    IO.puts "Server listening on: #{port}"
    open_conn(port)
  end

  def open_conn(port) do
    case :gen_tcp.listen(port,[:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, socket} ->
        IO.puts "Accepting connections on port #{port}"
        receive_conn(socket)
      _ ->
        IO.puts "error opening socket connection"
        System.halt
    end
  end

  defp receive_conn(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    receive_conn(socket)
  end

  defp read(socket) do
  	case :gen_tcp.recv(socket, 0) do
  	  {:ok, data} ->
  		IO.puts data
      {:error, reason} ->
      	IO.puts "Error receiving data: #{reason}"
  	end
  	:gen_tcp.close socket
  end

  defp send_request(socket, message) do
  	IO.puts message
  	get_request_body = "GET /echo.php?message=#{message} HTTP/1.0\r\n\r\n"
  	send_get(get_request_body, socket)
    socket
  end

end