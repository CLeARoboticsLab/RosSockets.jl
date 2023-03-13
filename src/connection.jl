struct Connection
    task::Task
    command_channel::Channel{Any}
    data_channel::Channel{Any}

    function Connection(ip::String, port::Integer)
        command_channel = Channel(1)
        data_channel = Channel(1)
        @info "Connecting to server at $(ip):$(port) ..."
        socket = Sockets.connect(ip, port)
        task = errormonitor(Threads.@spawn connection_task(socket, 
            command_channel, data_channel))
        connection = new(task, command_channel, data_channel)
        return connection
    end
end

struct TimeoutError <: Exception end

"""
    open_connection(ip::String, port::Integer)

Open a connection to a TCP server and return the `Connection`.

The `ip` must be a string formatted as `"123.123.123.123"`
"""
function open_connection(ip::String, port::Integer)
    return Connection(ip, port)
end

function connection_task(socket, command_channel, data_channel)
    @info "Connection task spawned"
    while true
        command, msg = take!(command_channel)
        if command === :close
            @info "Closing connection ..."
            break
        elseif command === :send
            write(socket, msg)
        elseif command === :send_receive
            write(socket, msg)
            data = readline(socket)
            put!(data_channel, data)
        end
    end
    close(socket)
    @info "Connection task completed"
end

"""
    send(connection::Connection, msg::String)

Send a message.

# Arguments
- `connection`: the `Connection` obtained from `open_connection`.
- `msg`: the message to be sent. Note: some TCP servers may be require the
    message be formatted a certain way (such as JSON), and may also require an
    end of line character, such as `\\n`, to terminate the message.
"""
function send(connection::Connection, msg::String)
    put!(connection.command_channel, (:send, msg))
end

"""
    send_receive(connection::Connection, msg::String, timeout::Real = 10.0)

Sends a message and waits for a response, which is then returned. This function
blocks execution while waiting, up to the timeout duration provided. If the
timeout duration elapses without the arrival of data, throws a TimeoutError
exception. Note: the payload which is returned will be in a raw format. To
convert to a string, use `String(payload)`. This string may further converted to
other formats such as JSON.

# Arguments
- `connection`: the `Connection` obtained from `open_connection`.
- `msg`: the message to be sent. Note: some TCP servers may be require the
    message be formatted a certain way (such as JSON), and may also require an
    end of line character, such as `\\n`, to terminate the message.
- `timeout`: maximum time in seconds to wait for data. 
"""
function send_receive(connection::Connection, msg::String, timeout::Real = 10.0)
    t = Timer(_ -> timeout_callback(connection), timeout)
    payload = nothing
    try
        put!(connection.command_channel, (:send_receive, msg))
        payload = take!(connection.data_channel)
    catch e
        if typeof(e) != InvalidStateException
            close_connection(connection)
            rethrow(e)
        end
    finally
        close(t)
    end
    return payload
end

function timeout_callback(connection::Connection)
    close_connection(connection)
    @error "Server timed out waiting for data."
    throw(TimeoutError())
end

"""
    close_connection(connection::Connection)

Close the connection to the TCP server.
"""
function close_connection(connection::Connection)
    @info "Stopping server ..."
    put!(connection.command_channel, (:close, ""))
    wait(connection.task)
    close(connection.data_channel)
    close(connection.command_channel)
    @info "Server stopped"
end