using Sockets
import JSON

mutable struct FeedbackConnection
    socket::Sockets.UDPSocket
    task::Task
    data_channel::Channel{Any}
    ready_channel::Channel{Bool}
    io::IOBuffer

    function FeedbackConnection(port::Integer)
        @info "Starting feedback server on port $(port) ..."
        socket = UDPSocket()
        bind(socket,IPv4(0),42422)
        data_channel = Channel(1)
        ready_channel = Channel{Bool}(1)
        put!(ready_channel, false)
        task = errormonitor(Threads.@spawn feedback_connection_task(socket, data_channel, ready_channel))
        feedback_connection = new(socket, task, data_channel, ready_channel, IOBuffer())
        @info "Feedback server started"
        return feedback_connection
    end
end

mutable struct TimeoutError <: Exception
end

function open_feedback_connection(port::Integer)
    return FeedbackConnection(port)
end

function feedback_connection_task(socket, data_channel, ready_channel)
    while true
        payload = nothing
        try
            payload = recv(socket)
        catch e
            # socket was closed, end the task
            break
        end
        
        if fetch(ready_channel)
            _ = take!(feedback_connection.ready_channel)
            put!(feedback_connection.ready_channel, false)
            put!(data_channel, payload)
        else
            @info "Feedback data discarded"
        end
    end
end

function receive_feedback_data(feedback_connection::FeedbackConnection,
                                timeout::Real = 10.0)
    
    _ = take!(feedback_connection.ready_channel)
    put!(feedback_connection.ready_channel, true)
    t = Timer(_ -> timeout_callback(feedback_connection), timeout)
    payload = nothing
    try
        payload = take!(feedback_connection.data_channel)
        @warn "Feedback data received"
    catch e
    finally
        close(t)
    end
end

function timeout_callback(feedback_connection::FeedbackConnection)
    close(feedback_connection.socket)
    wait(feedback_connection.task)
    close(feedback_connection.data_channel)
    @error "Feedback server timed out waiting for data."
    throw(TimeoutError())
end


function close_feedback_connection(feedback_connection::FeedbackConnection)
    @info "Stopping feedback server ..."
    close(feedback_connection.socket)
    wait(feedback_connection.task)
    close(feedback_connection.data_channel)
    close(feedback_connection.ready_channel)
    @info "Feedback server stopped"
end


feedback_connection = open_feedback_connection(42422)
receive_feedback_data(feedback_connection, 10.0)
close_feedback_connection(feedback_connection)


# function read_udp()
#     udpsock = UDPSocket()
#     bind(udpsock,IPv4(0),42422)
#     @info "UDP socket opened"

#     while true
#         t =Timer(_ -> close(udpsock),1.0)
#         try
#             data = recv(udpsock)
#             io = IOBuffer(data)
#             str = read(io, String)
#             @info "State data received"

#             d = JSON.parse(str)
#             display(d["position"])
#             display(d["orientation"])
#             display(d["linear_vel"])
#             display(d["angular_vel"])




