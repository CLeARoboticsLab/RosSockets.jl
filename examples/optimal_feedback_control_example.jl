# In this example, an optimal sequence of controls is computed and sent to the
# robot. The program then waits for state feedback. When the feedback data
# arrives, the new information is used to recompute and optimal sequence of
# controls which is then sent to the robot. This loop is repeated until the
# robot is sufficiently close to a goal location.

using JuMP, Ipopt, Plots, LinearAlgebra, Rotations
using RosSockets

include("utils/common.jl")
include("utils/nlp.jl")

function run_example()
   # set the goal state
    x_f = 3.0
    y_f = 3.0
    v_f = 0.0
    θ_f = deg2rad(270)
    goal_state = [x_f,y_f,v_f,θ_f]

    # initialize the solver
    timestep = 0.1          # duration of each timestep (sec)
    model = initialize_model(goal_state, timestep)

    # begin without warm start so that first solve is cold
    warm_start = false

    # initialize a plotter to display trajectory solution real-time
    display(plot(xlims=(-1,4),ylims=(-1,4),size=(600,600)))

    # Open a connection to the ROS feedback node
    ip = "192.168.1.135"    # ip address of the host of the ROS node
    feedback_port = 42422   # port to connect on
    timeout = 10.0          # maximum seconds to wait for data with receive_feedback_data
    feedback_connection = open_feedback_connection(ip, feedback_port)

    # open a connection to the ROS velocity control node
    control_port = 42421    # port to connect on
    robot_connection = open_robot_connection(ip, control_port)

    # obtain initial state of the robot
    feedback_state = receive_feedback_data(feedback_connection, timeout);

    # loop while robot is sufficiently far from goal
    while dist_from_goal(feedback_state,goal_state) > 0.5
        
        # obtain robot state
        feedback_state = receive_feedback_data(feedback_connection, timeout) 
        
        # compute control commands and send them
        commands, trajectory = solve!(model,feedback_state,warm_start)
        send_control_commands(robot_connection, commands)
        
        # future calls to solve! will be warm started
        warm_start = true

        # plot solution trajectory
        display(plot(trajectory[:,1],trajectory[:,2],
                xlims=(-1,4),ylims=(-1,4),
                size=(600,600)))
    end

    # when complete, close connections
    close_robot_connection(robot_connection, stop_robot=false)
    close_feedback_connection(feedback_connection) 
end

run_example()
