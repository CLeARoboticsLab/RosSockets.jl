using Test, RosSockets, Sockets
import JSON

function test_velocity_control()
    commands = [[1.2,3.4], [5.6,7.8]]
    
    # create a server on localhost that listens for a connection, reads data,
    # and puts the data on a channel
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
    send_control_commands(robot_connection, commands)
    close_robot_connection(robot_connection, stop_robot=false)

    # take the data from the channel and compare it to the sent data
    received_payload = take!(channel)
    data = JSON.parse(received_payload)
    @test data["controls"] == commands
end

@testset "RosSockets.jl" begin
    test_velocity_control()
end
