mutable struct FeedbackConnection
    socket::Sockets.UDPSocket
    task::Task
    data_channel::Channel{Any}
    ready_channel::Channel{Bool}

    function FeedbackConnection(port::Integer)
        @info "Starting feedback server on port $(port) ..."
        socket = UDPSocket()
        bind(socket,IPv4(0),42422)
        data_channel = Channel(1)
        ready_channel = Channel{Bool}(1)
        put!(ready_channel, false)
        task = errormonitor(Threads.@spawn feedback_connection_task(socket, 
                data_channel, ready_channel))
        feedback_connection = new(socket, task, data_channel, ready_channel)
        @info "Feedback server started"
        return feedback_connection
    end
end

mutable struct TimeoutError <: Exception
end

"""
    open_feedback_connection(port::Integer)

Open listener for feedback data from the ROS node on the specified port and
return the `FeedbackConnection`.

"""
function open_feedback_connection(port::Integer)
    return FeedbackConnection(port)
end

# This task continuously reads from the UDP port in order to keep the buffer
# clear. That way, when receive_feedback_data is called, stale data will not be
# returned. 
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
            _ = take!(ready_channel)
            put!(ready_channel, false)
            put!(data_channel, payload)
        else
            @debug "Feedback data discarded"
        end
    end
end

"""
    receive_feedback_data(feedback_connection::FeedbackConnection, 
        timeout::Real = 10.0)

Waits for data to arrive from the ROS node and returns a tuple of the data:
position, orientation, linear_vel, angular_vel. This function blocks execution
while waiting, up to the timout duration provided. If the timeout duration
elapses without the arrival of data, throws a TimeoutError exception.

# Arguments
- `feedback_connection`: the `FeedbackConnection` obtained from
  `open_feedback_connection`.
- `timeout`: maximum time in seconds to wait for data. 
"""
function receive_feedback_data(feedback_connection::FeedbackConnection,
                                timeout::Real = 10.0)
    _ = take!(feedback_connection.ready_channel)
    put!(feedback_connection.ready_channel, true)
    t = Timer(_ -> timeout_callback(feedback_connection), timeout)
    position = nothing
    orientation = nothing
    linear_vel = nothing
    angular_vel = nothing
    try
        payload = take!(feedback_connection.data_channel)
        data = JSON.parse(String(payload))
        position = data["position"]
        orientation = data["orientation"]
        linear_vel = data["linear_vel"]
        angular_vel = data["angular_vel"]
    catch e
        if typeof(e) != InvalidStateException
            close_feedback_connection(feedback_connection)
            rethrow(e)
        end
    finally
        close(t)
    end
    return position, orientation, linear_vel, angular_vel
end

function timeout_callback(feedback_connection::FeedbackConnection)
    close_feedback_connection(feedback_connection)
    @error "Feedback server timed out waiting for data."
    throw(TimeoutError())
end

"""
close_feedback_connection(feedback_connection::FeedbackConnection)

Close the listener.
"""
function close_feedback_connection(feedback_connection::FeedbackConnection)
    @info "Stopping feedback server ..."
    close(feedback_connection.socket)
    wait(feedback_connection.task)
    close(feedback_connection.data_channel)
    close(feedback_connection.ready_channel)
    @info "Feedback server stopped"
end
