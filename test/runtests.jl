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
    t = errormonitor(@async begin
        sock = accept(server)
        payload = readline(sock)
        put!(channel, payload)
        close(sock)
    end)
    @test !istaskfailed(t)

    # connect to localhost, send data, then close the connection
    robot_connection = open_robot_connection(ip, port)
    @test !istaskfailed(robot_connection.task)
    @test !istaskdone(robot_connection.task)

    send_control_commands(robot_connection, commands)

    close_robot_connection(robot_connection, stop_robot=false)
    @test istaskdone(robot_connection.task)

    # take the data from the channel and compare it to the sent data
    received_payload = take!(channel)
    data = JSON.parse(received_payload)
    @test haskey(data, "controls")
    @test data["controls"] == commands

    close(server)
end

function test_state_feedback()
    data = Dict()
    data["position"] = [1.,2.,3.]
    data["orientation"] = [.1,.2,.3,.4]
    data["linear_vel"] = [4.,5.,6.]
    data["angular_vel"] = [.4,.5,.6]
    feedback_data = FeedbackData(data)
    
    # create a server on localhost that listens for a connection, reads a
    # command, writes feedback data, and puts the received command on a channel
    ip = "127.0.0.1"
    port = 42450
    timeout = 5.0

    channel = Channel(1)
    server = listen(port)
    t = errormonitor(@async begin
        sock = accept(server)
        payload = readline(sock)
        put!(channel, payload)
        write(sock,JSON.json(data)*"\n")
        close(sock)
    end)
    @test !istaskfailed(t)

    # open a feedback connection, receive data, and then close the connection
    feedback_connection = open_feedback_connection(ip, port)
    @test !istaskfailed(feedback_connection.task)
    @test !istaskdone(feedback_connection.task)

    received_feedback_data = receive_feedback_data(feedback_connection, timeout)
    @test received_feedback_data == feedback_data

    close_feedback_connection(feedback_connection)
    @test istaskdone(feedback_connection.task)

    # check that the command sent to the feedback server is correct
    received_payload = take!(channel)
    json_cmd = JSON.parse(received_payload)
    @test haskey(json_cmd, "action")
    @test json_cmd["action"] == "get_feedback_data"

    close(server)
end

function Base.:(==)(x::FeedbackData, y::FeedbackData) 
    return x.position == y.position &&
            x.orientation == y.orientation &&
            x.linear_vel == y.linear_vel &&
            x.angular_vel == y.angular_vel
end

@testset verbose = true "RosSockets.jl" begin
    @testset "Velocity Control" begin
        test_velocity_control()
    end

    @testset "State Feedback" begin
        test_state_feedback()
    end
end