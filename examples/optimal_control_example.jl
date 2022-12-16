using JuMP, Ipopt, Plots, LinearAlgebra, Rotations

using RosSockets

# Uncomment this if developing within RosSockets.jl environment
# include("../src/RosSockets.jl")
# using .RosSockets

include("utils/nlp.jl")

# set the goal state
x_f = 3.0
y_f = 3.0
v_f = 0.0
θ_f = deg2rad(270)
goal_state = [x_f,y_f,v_f,θ_f]

# initialize the solver
model = initialize_model(goal_state)

# initialize a plotter to display trajectory solution real-time
display(plot(xlims=(-1,4),ylims=(-1,4),size=(600,600)))

# Open listener for feedback data from the ROS node
feedback_port = 42422   # port to listen for ROS data on
timeout = 10.0          # maximum seconds to wait for data with receive_feedback_data
feedback_connection = open_feedback_connection(feedback_port)

# open a connection to the ROS velocity control node
ip = "192.168.1.135"    # ip address of the host of the ROS node
control_port = 42421    # port to connect on
timestep = 0.1          # duration of each timestep (sec)
robot_connection = open_robot_connection(ip, control_port)

# obtain initial state of the robot
feedback_state = receive_feedback_data(feedback_connection, timeout);

# loop while robot is sufficiently far from goal
while dist_from_goal(feedback_state,goal_state) > 0.5
    
    # obtain robot state
    global feedback_state = receive_feedback_data(feedback_connection, timeout) 
    
    # compute control commands and send them
    commands, trajectory = solve!(model,feedback_state)
    send_control_commands(robot_connection, commands)

    # plot solution trajectory
    display(plot(trajectory[:,1],trajectory[:,2],
            xlims=(-1,4),ylims=(-1,4),
            size=(600,600)))
end

# when complete, close connections
close_robot_connection(robot_connection, stop_robot=false)
close_feedback_connection(feedback_connection)
