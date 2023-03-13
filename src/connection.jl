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

function send(connection::Connection, command::String)
    put!(connection.command_channel, (:send, command))
end

function send_receive(connection::Connection, command::String, timeout::Real = 10.0)
    t = Timer(_ -> timeout_callback(connection), timeout)
    payload = nothing
    try
        put!(connection.command_channel, (:send_receive, command))
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

function close_connection(connection::Connection)
    @info "Stopping server ..."
    put!(connection.command_channel, (:close, ""))
    wait(connection.task)
    close(connection.data_channel)
    close(connection.command_channel)
    @info "Server stopped"
end