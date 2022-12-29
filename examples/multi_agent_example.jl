using RosSockets

const ip = "192.168.1.135"  # ip address of the host of the ROS node
const timestep = 0.1        # duration of each timestep (sec)
const timeout = 10.0        # maximum seconds to wait for data with receive_feedback_data

mutable struct Robot
    goal_location::Vector{Float64}
    feedback_port::Integer
    control_port::Integer
    feedback_connection
    robot_connection

    function Robot(;goal_location::Vector{Float64},
                    feedback_port::Integer,
                    control_port::Integer)
        return new(goal_location,
                    feedback_port,
                    control_port,
                    nothing,
                    nothing)
    end
end

function run_example()
    agent1 = Robot(goal_location = [0.0, 2.0],
                    feedback_port = 42431,
                    control_port = 42421)

    agent2 = Robot(goal_location = [-3.0, 2.0],
                    feedback_port = 42432,
                    control_port = 42422)

    agent3 = Robot(goal_location = [3.0, 2.0],
                    feedback_port = 42433,
                    control_port = 42423)

    agents = [agent1, agent2, agent3]

    for agent in agents
        agent.feedback_connection = open_feedback_connection(agent.feedback_port)
        agent.robot_connection = open_robot_connection(ip, agent.control_port)
    end

    for agent in agents
        close_robot_connection(agent.robot_connection)
        close_feedback_connection(agent.feedback_connection)
    end
end

run_example()