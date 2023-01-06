mutable struct RobotConnection
    task::Task
    channel::Channel{Any}

    function RobotConnection(ip::String, port::Integer)
        channel = Channel(1)
        @info "Connecting to robot at $(ip):$(port) ..."
        socket = Sockets.connect(ip, port)
        task = errormonitor(Threads.@spawn robot_connection_task(channel, socket))
        robot_connection = new(task, channel)
        return robot_connection
    end
end

"""
    open_robot_connection(ip::String, port::Integer=42421)

Open a connection to the ROS node and return the `RobotConnection`.

The `ip` must be a string formated as `"123.123.123.123"`
"""
function open_robot_connection(ip::String, port::Integer)
    robot_connection = RobotConnection(ip, port)
    return robot_connection
end

function robot_connection_task(channel, socket)
    @info "Robot connection task spawned"
    while true
        controls = take!(channel)
        if controls === :close
            @info "Closing robot connection ..."
            break
        end
        msg = """{ "controls": $(controls) }\n"""
        write(socket, msg)
    end
    close(socket)
    @info "Robot connection task completed"
end

"""
    send_control_commands(robot_connection, controls)

Send a sequence of control commands to the ROS node.

# Arguments
- `robot_connection`: the `RobotConnection` obtained from `open_robot_connection`.
- `controls`: a collection of vectors; each vector is a pair of linear and angular velocities. 
"""
function send_control_commands(robot_connection, controls)
    put!(robot_connection.channel, controls)
end

"""
    close_robot_connection(robot_connection; stop_robot=true)

Close the connection with the ROS node.

# Arguments
- `robot_connection`: the `RobotConnection` obtained from `open_robot_connection`.
- `stop_robot`: issues a zero-velocity command to the ROS node to stop the robot before shutdown.
"""
function close_robot_connection(robot_connection; stop_robot=true)
    if stop_robot
        @info "Stopping robot"
        send_control_commands(robot_connection, [[0.0,0.0]])
    end
    put!(robot_connection.channel, :close)
    wait(robot_connection.task)
    close(robot_connection.channel)
    @info "Robot connection closed"
end