module RosSockets

using Sockets

include("velocity_control.jl")
export open_robot_connection, 
    send_control_commands,
    close_robot_connection

end # module RosSockets
