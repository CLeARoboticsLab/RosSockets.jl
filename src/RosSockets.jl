module RosSockets

using Sockets
import JSON

include("connection.jl")
export Connection, open_connection, close_connection,
    send, send_receive

include("velocity_control.jl")
export open_robot_connection, 
    send_control_commands,
    close_robot_connection

include("state_feedback.jl")
export FeedbackData,
    open_feedback_connection,
    receive_feedback_data,
    close_feedback_connection
    
include("rollout_data.jl")
export rollout_data

end # module RosSockets
