using RosSockets

function run_example()
    
    ip = "192.168.88.128"   # ip address of the host of the ROS node
    port = 42421            # port to connect on
    timestep = 0.5          # duration of each timestep (sec)
    length = 10             # length of the control sequence

    # open a connection to the ROS node
    robot_connection = open_robot_connection(ip, port)
    
    # create a sequence of identical control inputs and send to the node
    control_sequence = [[0.1, 0.25] for _ in 1:length]
    send_control_commands(robot_connection, control_sequence)

    # sleep for the time it takes to execute the control sequence
    duration = timestep*length
    sleep(duration)
    
    # Close the connection to the ROS node.
    # This should always be called when complete with tasks
    # to ensure graceful shutdown.
    close_robot_connection(robot_connection)
end

run_example()