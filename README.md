# RosSockets.jl

[![RosSockets](https://github.com/CLeARoboticsLab/RosSockets.jl/actions/workflows/test.yml/badge.svg)](https://github.com/CLeARoboticsLab/RosSockets.jl/actions/workflows/test.yml)

Tools for sending and receiving information from ROS via TCP that can be used to control robots.
This package is meant to communicate with the ROS nodes from [ros_sockets](https://github.com/CLeARoboticsLab/ros_sockets), but also provides a framework for communication with TCP server in general.

## Installation

Add the package in Julia with:

```jl
using Pkg
Pkg.add(url="https://github.com/CLeARoboticsLab/RosSockets.jl.git")
```

Note: if you have issues authenticating with github, download and unzip the package manually, then add it with:

```jl
using Pkg
Pkg.develop(path="<PATH>")
```

where `<PATH>` is the path to the unzipped file (i.e. the folder containing `Project.toml`).

## Usage

See [examples](examples/) for usage examples.

### Velocity Control

First, ensure the `/velocity_control` node from from [ros_sockets](https://github.com/CLeARoboticsLab/ros_sockets) is running on the target.

Open a connection to the ROS node, setting `ip` and `port` to match that of the node:

```jl
ip = "192.168.88.128"
port = 42421
robot_connection = open_robot_connection(ip, port)
```

With an open connection, send velocity commands to the robot:

```jl
send_control_commands(robot_connection, controls)
```

where `controls` is a collection of vectors; each vector is a pair of linear and angular velocities.
The ROS node will execute the controls at the rate it was configure with.

When complete with tasks, be sure to close the connection to ensure a graceful shutdown:

```jl
close_robot_connection(robot_connection)
```

### State Feedback

First, ensure the `/state_feedback` node from from [ros_sockets](https://github.com/CLeARoboticsLab/ros_sockets) is running on the target.

Open a connection to the ROS node, setting `ip` and `port` to match that of the node:

```jl
ip = "192.168.88.128"
port = 42422
feedback_connection = open_feedback_connection(ip, port)
```

With the connection open, wait for data to arrive from the ROS node.
Execution is blocked while waiting, up to the timeout duration (seconds) provided.
If the timeout duration elapses without the arrival of data, a TimeoutError exception is thrown.

```jl
timeout = 10.0
state = receive_feedback_data(feedback_connection, timeout)
```

`receive_feedback_data` returns a struct with the following fields: `position`, `orientation`, `linear_vel`, `angular_vel`.

When complete with tasks, be sure to close the connection:

```jl
close_feedback_connection(feedback_connection)
```

### General TCP Communication

First, open a connection to the TCP server, setting setting `ip` and `port` to match that of the server:

```jl
ip = "192.168.1.135"   
port = 42423
connection = open_connection(ip, port)
```

Send messages with `send`. Note: some TCP servers may be require the message be formatted a certain way (such as JSON), and may also require an end of line character, such as `\n`, to terminate the message. Here is an example of sending a JSON formatted message:

```jl
import JSON

# create a JSON formatted message with property name "action" and value "start_experiment"
start_cmd = JSON.json(Dict("action" => "start_experiment")) * "\n"

# send the message
send(connection, start_cmd)
```

Send a message and wait for a response with `send_receive`. Note: some TCP servers may be require the message be formatted a certain way (such as JSON), and may also require an end of line character, such as `\n`, to terminate the message. This function blocks execution while waiting, up to the timeout duration provided. If the timeout duration elapses without the arrival of data, throws a `TimeoutError` exception. Note: the payload which is returned will be in a raw format. To convert to a string, use `String(payload)`. This string may further converted to other formats such as JSON. Here is an example of sending a JSON formatted message, receiving a response, and parsing the response.

```jl
import JSON

# create a JSON formatted message with property name "action" and value "get_time_elapsed"
get_time_cmd = JSON.json(Dict("action" => "get_time_elapsed")) * "\n"

# send the message and wait for a response
payload = send_receive(connection, get_time_cmd)

# convert the payload to a String, parse the String as a JSON, extract the data, 
# and print it
data = JSON.parse(String(payload))
elapsed_time = data["elapsed_time"]
println("Elapsed time: $(elapsed_time)")
```

When complete with tasks, be sure to close the connection:

```jl
close_connection(connection)
```

## Acknowledgments

The velocity control is heavily based on infrastructure from [@schmidma](https://github.com/schmidma) and [@lassepe](https://github.com/lassepe).
