complete_control_sequence = zeros(500)

ip = "192.168.88.128"   # ip address of the host of the ROS node
port = 42421            # port to connect on

max_window_duration = 5.0   # maximum length of control sequence (sec)
update_time = 2.0           # duration between each sending of the control sequence (sec)
timestep = 0.1              # duration of each timestep (sec)

max_window_length = Integer(round(max_window_duration/timestep))
sleep_length = Integer(round(update_time/timestep))
complete_control_sequence_length = size(complete_control_sequence)[1]

robot_connection = open_robot_connection(ip, port)

idx = 1
while idx < complete_control_sequence_length
    window_length = min(max_window_length, complete_control_sequence_length - idx)
    control_sequence = complete_control_sequence[idx:idx+window_length]
    send_control_commands(robot_connection, control_sequence)
    idx += sleep_length
    sleep(update_time)
end

close_robot_connection(robot_connection)