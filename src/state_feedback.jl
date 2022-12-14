using Sockets

# errormonitor(@async begin
#     @info "Waiting for connection"
#     server = listen(ip"192.168.144.1",42422)

#     while true
#         sock = accept(server)
#         @info "Connection accepted"
#         @async while isopen(sock)
#             str = readline(sock, keep=false)
#             @info "Data received: " * str
#         end
#     end
# end)

function test()
    @info "Waiting for connection"
    server = listen(IPv4(0),42422)

    while true
        sock = accept(server)
        @info "Connection accepted"
        while isopen(sock)
            str = readline(sock, keep=false)
            @info "Data received: " * str
        end
    end
end
test()