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
    errormonitor(@async begin
        sock = accept(server)
        payload = readline(sock)
        put!(channel, payload)
        close(sock)
    end)

    # connect to localhost, send data, then close the connection
    robot_connection = open_robot_connection(ip, port)
    send_control_commands(robot_connection, commands)
    close_robot_connection(robot_connection, stop_robot=false)

    # take the data from the channel and compare it to the sent data
    received_payload = take!(channel)
    data = JSON.parse(received_payload)
    @test data["controls"] == commands
end

function test_state_feedback()
    data = Dict()
    data["position"] = [1.,2.,3.]
    data["orientation"] = [.1,.2,.3,.4]
    data["linear_vel"] = [4.,5.,6.]
    data["angular_vel"] = [.4,.5,.6]
    feedback_data = FeedbackData(data)
    
    ip = ip"127.0.0.1"
    port = 42450
    timeout = 10.0
    channel = Channel(1)

    # create a task that opens a feedback connection, recieves data, and then
    # closes the connection
    feedback_connection = open_feedback_connection(port)
    task = errormonitor(@async begin
        received_feedback_data = receive_feedback_data(feedback_connection, timeout)
        put!(channel, received_feedback_data)
        close_feedback_connection(feedback_connection)
    end)

    # send data to the feedback connection and compare the received data to the
    # sent data
    sleep(1.0)
    sock = UDPSocket()
    send(sock, ip, port, JSON.json(data))
    received_feedback_data = take!(channel)
    wait(task)
    @test received_feedback_data == feedback_data
end

function Base.:(==)(x::FeedbackData, y::FeedbackData) 
    return x.position == y.position &&
            x.orientation == y.orientation &&
            x.linear_vel == y.linear_vel &&
            x.angular_vel == y.angular_vel
end

@testset "RosSockets.jl" begin
    test_velocity_control()
    test_state_feedback()
end
