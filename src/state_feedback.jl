mutable struct FeedbackData
    position::Vector{Float64}
    orientation::Vector{Float64}
    linear_vel::Vector{Float64}
    angular_vel::Vector{Float64}

    function FeedbackData(data::Dict)
        position = data["position"]
        orientation = data["orientation"]
        linear_vel = data["linear_vel"]
        angular_vel = data["angular_vel"]
        return new(position,
                    orientation,
                    linear_vel,
                    angular_vel)
    end
end

mutable struct FeedbackConnection
    task::Task
    command_channel::Channel{Any}
    data_channel::Channel{Any}

    function FeedbackConnection(ip::String, port::Integer)
        command_channel = Channel(1)
        data_channel = Channel(1)
        @info "Connecting to feedback server at $(ip):$(port) ..."
        socket = Sockets.connect(ip, port)
        task = errormonitor(Threads.@spawn feedback_connection_task(socket, 
            command_channel, data_channel))
        feedback_connection = new(task, command_channel, data_channel)
        return feedback_connection
    end
end

struct TimeoutError <: Exception
end

"""
    open_feedback_connection(ip::String, port::Integer)

Open a connection to the ROS node and return the `FeedbackConnection`.

The `ip` must be a string formated as `"123.123.123.123"`
"""
function open_feedback_connection(ip::String, port::Integer)
    return FeedbackConnection(ip, port)
end

function feedback_connection_task(socket, command_channel, data_channel)
    @info "Feedback connection task spawned"
    while true
        command = take!(command_channel)
        if command === :close
            @info "Closing feedback connection ..."
            break
        end
        msg = """{ "action": "get_feedback_data" }\n"""
        write(socket, msg)
        data = readline(socket)
        put!(data_channel, data)
    end
    close(socket)
    @info "Feedback connection task completed"
end

"""
    receive_feedback_data(feedback_connection::FeedbackConnection, 
        timeout::Real = 10.0)

Waits for data to arrive from the ROS node and returns a struct of the data with
the following fields: position, orientation, linear_vel, angular_vel. This
function blocks execution while waiting, up to the timout duration provided. If
the timeout duration elapses without the arrival of data, throws a TimeoutError
exception.

# Arguments
- `feedback_connection`: the `FeedbackConnection` obtained from
  `open_feedback_connection`.
- `timeout`: maximum time in seconds to wait for data. 
"""
function receive_feedback_data(feedback_connection::FeedbackConnection,
                                timeout::Real = 10.0)
    t = Timer(_ -> timeout_callback(feedback_connection), timeout)
    feedback_data = nothing
    try
        put!(feedback_connection.command_channel, :read)
        payload = take!(feedback_connection.data_channel)
        data = JSON.parse(String(payload))
        feedback_data = FeedbackData(data)
    catch e
        if typeof(e) != InvalidStateException
            close_feedback_connection(feedback_connection)
            rethrow(e)
        end
    finally
        close(t)
    end
    return feedback_data
end

function timeout_callback(feedback_connection::FeedbackConnection)
    close_feedback_connection(feedback_connection)
    @error "Feedback server timed out waiting for data."
    throw(TimeoutError())
end

"""
    close_feedback_connection(feedback_connection::FeedbackConnection)

Close the connection with the ROS node.
"""
function close_feedback_connection(feedback_connection::FeedbackConnection)
    @info "Stopping feedback server ..."
    put!(feedback_connection.command_channel, :close)
    wait(feedback_connection.task)
    close(feedback_connection.data_channel)
    close(feedback_connection.command_channel)
    @info "Feedback server stopped"
end
