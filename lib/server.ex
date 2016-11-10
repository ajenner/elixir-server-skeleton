defmodule Server do
  use Application
  require Logger
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
  	{:ok, socket} = :gen_tcp.connect(address, port, [:binary, active: false])
  	socket
  end

  defp send_get(line,socket) do
    case :gen_tcp.send(socket, line) do
      :ok ->
        read(socket)
      {:error, reason} ->
        IO.puts "Error sending data: #{reason}"
    end  
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