using RosSockets, Sockets
using Test

function test_velocity_control()
    # create a server on localhost that listens for a connection and reads data
    ip = "127.0.0.1"
    port = 42450
    channel = Channel(1)
    server = listen(port)
    @async begin
        sock = accept(server)
        payload = readline(sock)
        put!(channel, payload)
        close(sock)
    end

    # connect to localhost, send data, then close the connection
    robot_connection = open_robot_connection(ip, port)
    send_control_commands(robot_connection, [[1.2,3.4]])
    close_robot_connection(robot_connection, stop_robot=false)
    received_payload = take!(channel)
    println(received_payload)
    @test 3 == 3 # TODO
end

@testset "RosSockets.jl" begin
    test_velocity_control()
end
