# In this example, 3 robots are controlled. Each robot is eqiupped with state
# feedback and is commanded to move forward until that robot reaches its goal
# location.

using LinearAlgebra, Rotations
using RosSockets

include("utils/common.jl")

# constants applicable to all agents
global const IP = "192.168.1.135"   # ip address of the host of the ROS node
global const TIMESTEP = 0.1         # duration of each timestep (sec)
global const TIMEOUT = 10.0         # maximum seconds to wait for data with receive_feedback_data
global const GOAL_TOL = 0.1         # each agent must end within this distance from their goal
global const LENGTH = 10            # length of the control sequence

# struct to hold data for each agent
mutable struct Robot
    goal_location::Vector{Float64}
    feedback_port::Integer
    control_port::Integer
    feedback_connection
    robot_connection
    feedback_state

    function Robot(;goal_location::Vector{Float64},
                    feedback_port::Integer,
                    control_port::Integer)
        return new(goal_location,
                    feedback_port,
                    control_port,
                    nothing,
                    nothing,
                    nothing)
    end
end

# receive feedback data for an agent
function get_feedback_data!(agent)
    agent.feedback_state = receive_feedback_data(agent.feedback_connection, TIMEOUT)
end

# receive feedback data for all agents
function get_all_feedback_data!(agents)
    for agent in agents
        get_feedback_data!(agent)
    end
end

# check if an agent has reached its goal
function goal_reached(agent)
    return dist_from_goal(agent.feedback_state, agent.goal_location) < GOAL_TOL
end

# check if all agents have reached their goals
function goals_reached(agents)
    reached = true
    for agent in agents
        reached = reached && goal_reached(agent)
    end
    return reached
end

# sends commands to move an agent forward
function move_forward(agent)
    commands = [[0.1, 0.0] for _ in 1:LENGTH]
    send_control_commands(agent.robot_connection, commands)
end

function run_example()

    # create each agent
    agent1 = Robot(goal_location = [0.0, 1.0],
                    feedback_port = 42431,
                    control_port = 42421)

    agent2 = Robot(goal_location = [-2.0, 1.0],
                    feedback_port = 42432,
                    control_port = 42422)

    agent3 = Robot(goal_location = [2.0, 1.0],
                    feedback_port = 42433,
                    control_port = 42423)

    # collection of agents                
    agents = [agent1, agent2, agent3]

    # open feedback and velocity control connections for each agent
    for agent in agents
        agent.feedback_connection = open_feedback_connection(agent.feedback_port)
        agent.robot_connection = open_robot_connection(IP, agent.control_port)
    end

    # obtain initial state of all agents
    get_all_feedback_data!(agents)

    # command each agent that is not at their goal location to move forward
    while !goals_reached(agents)
        for agent in agents
            get_feedback_data!(agent)
            if !goal_reached(agent)
                move_forward(agent)
            end
        end
    end

    # close connections for each agent
    for agent in agents
        close_robot_connection(agent.robot_connection)
        close_feedback_connection(agent.feedback_connection)
    end
end

run_example()