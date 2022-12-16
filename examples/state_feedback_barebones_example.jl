using RosSockets

function run_example()

    port = 42422    # port to listen for ROS data on
    timeout = 10.0  # maximum seconds to wait for data with receive_feedback_data

    # Open listener for feedback data from the ROS node
    feedback_connection = open_feedback_connection(port)

    # Wait for data to arrive from the ROS node. Execution is blocked while
    # waiting, up to the timout duration provided. If the timeout duration
    # elapses without the arrival of data, throws a TimeoutError exception.
    state = receive_feedback_data(feedback_connection, timeout)

    # Print each data field to console
    println("Position: $(state.position)")
    println("Orientation (quaternion): $(state.orientation)")
    println("Linear Velocity: $(state.linear_vel)")
    println("Angular Velocity: $(state.angular_vel)")

    # Close the listener
    close_feedback_connection(feedback_connection)
end

run_example()
