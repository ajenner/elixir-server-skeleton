defmodule Echo do

  def main(address_str, port_str, message) do
    address = address_str 
              |> String.split(".") # form a list of strings
              |> Enum.map(fn (str) -> String.to_integer(str) end) #retrieve each string and convert them to ints
              |> List.to_tuple # create our tuple
    port = String.to_integer port_str
    msg = URI.encode message

    connect(address, port)
    |> send_request(msg)
  end

  def connect(address, port) do
  	{:ok, socket} = :gen_tcp.connect(address, port, [:binary, packet: :raw, active: false])
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