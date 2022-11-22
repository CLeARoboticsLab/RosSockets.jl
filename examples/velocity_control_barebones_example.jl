using RosSockets

function run_example()
    
    # open a connection to the ROS node
    ip = "192.168.88.128"
    port = 42421
    robot_connection = open_robot_connection(ip, port)
    
    # create a sequence of 10 control inputs and send to the node
    timesteps = 10
    control_sequence = [[0.1, 0.25] for _ in 1:timesteps]
    send_control_commands(robot_connection, control_sequence)

    # sleep for the time it takes to execute the control sequence
    cycle_time = 0.5
    duration = cycle_time*timesteps
    sleep(duration)
    
    # Close the connection to the ROS node.
    # This should always be called when complete with tasks
    # to ensure graceful shutdown.
    close_robot_connection(robot_connection)
end

run_example()