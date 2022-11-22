# RosSockets.jl

Tools for sending and receiving information from ROS via TCP that can be used to control robots. This package is meant to communicate with the ROS nodes from [ros_sockets](https://github.com/CLeARoboticsLab/ros_sockets).

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

Load the package:

```jl
using RosSockets
```

Next, open a connection to the ROS node, setting `ip` and `port` to match that of the node:

```jl
ip = "192.168.88.128"
port = 42421
robot_connection = open_robot_connection(ip, port)
```

With an open connection, send velocity commands to the robot:

```jl
send_control_commands(robot_connection, controls)
```

where `controls` is a collection of vectors; each vector is a pair of linear and angular velocities. The ROS node will execute the controls at the rate it was configure with.

When complete with tasks, be sure to close the connection to ensure a graceful shutdown:

```jl
close_robot_connection(robot_connection)
```

## Acknowledgments

This package is heavily based on infrastructure from [@schmidma](https://github.com/schmidma) and [@lassepe](https://github.com/lassepe).
