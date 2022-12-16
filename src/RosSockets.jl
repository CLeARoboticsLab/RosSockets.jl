module RosSockets

using Sockets
import JSON

include("velocity_control.jl")
export open_robot_connection, 
    send_control_commands,
    close_robot_connection

include("state_feedback.jl")
export open_feedback_connection,
    receive_feedback_data,
    close_feedback_connection

end # module RosSockets
