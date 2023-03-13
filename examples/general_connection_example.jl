using RosSockets
import JSON

function test_time_server()
    ip = "192.168.1.135"    # ip address of the host of the ROS node    
    port = 42423            # port to connect on

    # open a connection to the ROS node
    connection = open_connection(ip, port)

    # create command strings that are in the form of JSONs. These strings should
    # be formatted as required by the receiving ROS node. Note that some nodes
    # may require an end of line character, such as "\n", to terminate the command.
    start_cmd = JSON.json(Dict("action" => "start_experiment")) * "\n"
    stop_cmd = JSON.json(Dict("action" => "stop_experiment")) * "\n"
    get_time_cmd = JSON.json(Dict("action" => "get_time_elapsed")) * "\n"

    # send a command to the ROS node
    send(connection, start_cmd)

    # send a command and wait to receive a response from the ROS node
    for _ in 1:10
        payload = send_receive(connection, get_time_cmd)
        data = JSON.parse(String(payload))
        elapsed_time = data["elapsed_time"]
        println("Elapsed time: $(elapsed_time)")
        sleep(0.5)
    end

    # send another command to the ROS node
    send(connection, stop_cmd)
    sleep(1.0)

    # Close the connection to the ROS node. This should always be called when
    # complete with tasks to ensure graceful shutdown.
    close_connection(connection)
end