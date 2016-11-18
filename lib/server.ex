defmodule Server do
  use Application
  import Supervisor.Spec

  @port Application.get_env(:server, :port)
  @max_clients 32
  #@system_ip "89.100.7.32"
  @system_ip "134.226.214.253"

  def start(_type, _args) do
    IO.puts "Server Started\n"
    children = [
      worker(Task, [Server, :listen, [String.to_integer(@port)]]),
      supervisor(Task.Supervisor, [[name: Server.TaskSupervisor]])
      ]
    options = [strategy: :one_for_one, name: Server.Supervisor]
    Supervisor.start_link(children, options)
  end

  # Listen for connections

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
        IO.puts "ERROR: opening socket connection"
        System.halt
    end
  end

  # Receviving connections below

  defp receive_conn(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client} ->
        serve_client(socket,client)
       _ ->
        IO.puts "ERROR: Server socket is closed"
        System.halt
    end
  end
  
  # Thread pooling handled below - with workers serving as threads.

  defp serve_client(socket, client_socket) do
    %{:workers => count} = Supervisor.count_children(Server.TaskSupervisor) #count the number of active workers
    if count <= @max_clients do
      case Task.Supervisor.start_child(Server.TaskSupervisor, fn -> serve_request(socket,client_socket) end) do
        {:ok, pid} ->
              :gen_tcp.controlling_process(client_socket, pid)
              socket |> receive_conn
         _ ->
          IO.puts "ERROR: spawning new worker"
          System.halt
      end
    else
      :gen_tcp.close(client_socket)
      socket |> receive_conn
    end
  end

  defp serve_request(server_socket,client_socket) do
    case :gen_tcp.recv(client_socket, 0) do
      { _ , data} ->
          IO.puts "Request : #{data}"
          read(server_socket,client_socket,data)
      _ ->
          IO.puts "ERROR: Reading from socket"
    end
  end

  #pattern match responses

  defp read( _ ,socket, "HELO" <> " " <> text ) do
    message = "HELO #{text}IP:#{get_ip_addr}\nPort:#{@port}\nStudentID:12301154\n"
    :gen_tcp.send(socket,message)
    :gen_tcp.close(socket)
  end

  defp read( server_socket , _ , "KILL_SERVICE" <> _ ) do
    :gen_tcp.close(server_socket)
  end

  defp read( _ ,socket, _ ) do
    :gen_tcp.close(socket)
  end

  defp get_ip_addr() do
    {:ok, ifs} = :inet.getif()
    Enum.map(ifs, fn {ip, _broadaddr, _mask} -> ip end)
    |> hd()
    |> Tuple.to_list
    |> Enum.join(".")
  end

end