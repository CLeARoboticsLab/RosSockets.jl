"""
    open_robot_connection(ip::String, port::Integer=42421)

Open a connection to the ROS node and return the `RobotConnection`.

The `ip` must be a string formatted as `"123.123.123.123"`
"""
function open_robot_connection(ip::String, port::Integer)
    return open_connection(ip, port)
end

"""
    send_control_commands(robot_connection, controls)

Send a sequence of control commands to the ROS node.

# Arguments
- `robot_connection`: the `RobotConnection` obtained from `open_robot_connection`.
- `controls`: a collection of vectors; each vector is a pair of linear and angular velocities. 
"""
function send_control_commands(robot_connection::Connection, controls::AbstractVector{<:AbstractVector{<:Real}})
    msg = """{ "controls": $(controls) }\n"""
    send(robot_connection, msg)
end

"""
    close_robot_connection(robot_connection; stop_robot=true)

Close the connection with the ROS node.

# Arguments
- `robot_connection`: the `RobotConnection` obtained from `open_robot_connection`.
- `stop_robot`: issues a zero-velocity command to the ROS node to stop the robot before shutdown.
"""
function close_robot_connection(robot_connection::Connection; stop_robot::Bool=true)
    if stop_robot
        @info "Stopping robot"
        send_control_commands(robot_connection, [[0.0,0.0]])
    end
    close_connection(robot_connection)
end