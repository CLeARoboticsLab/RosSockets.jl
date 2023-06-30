# In this example, a connection for rollout data from a ROS node is opened and
# the program waits for data to arrive. When data arrives, the data is printed,
# and then the connection is closed.

using RosSockets

function run_example()

    ip = "192.168.1.223"    # ip address of the host of the ROS node
    port = 42425            # port to connect on
    timeout = 10.0  # maximum seconds to wait for data with rollout_data

    # Open listener for rollout data from the ROS node
    rollout_data_connection = open_connection(ip, port)

    # Wait for data to arrive from the ROS node. Execution is blocked while
    # waiting, up to the timout duration provided. If the timeout duration
    # elapses without the arrival of data, throws a TimeoutError exception.
    data = rollout_data(rollout_data_connection, timeout)

    # Print each data field to console
    println("Times: $(data.ts)")
    println("States: $(data.xs)")
    println("Desired states: $(data.xds)")
    println("Control inputs: $(data.us)")

    # Close the listener
    close_connection(rollout_data_connection)
end

run_example()
