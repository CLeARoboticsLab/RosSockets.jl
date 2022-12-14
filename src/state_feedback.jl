using Sockets

# @async begin
#     udpsock = UDPSocket()
#     bind(udpsock,ip"127.0.0.1",2000)
#     while true
#       println(bytestring(recv(udpsock)))
#     end
# end

function read_udp_once()
    udpsock = UDPSocket()
    bind(udpsock,IPv4(0),42422)
    @info "UDP socket opened"
    data = recv(udpsock)
    io = IOBuffer(data)
    str = read(io, String)
    @info "Data received: " * str
    close(udpsock)
end
read_udp_once()
