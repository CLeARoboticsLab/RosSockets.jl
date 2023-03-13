struct FeedbackData
    position::Vector{Float64}
    orientation::Vector{Float64}
    linear_vel::Vector{Float64}
    angular_vel::Vector{Float64}

    function FeedbackData(data::Dict)
        position = data["position"]
        orientation = data["orientation"]
        linear_vel = data["linear_vel"]
        angular_vel = data["angular_vel"]
        return new(position,
                    orientation,
                    linear_vel,
                    angular_vel)
    end
end

"""
    open_feedback_connection(ip::String, port::Integer)

Open a connection to the ROS node and return the `FeedbackConnection`.

The `ip` must be a string formatted as `"123.123.123.123"`
"""
function open_feedback_connection(ip::String, port::Integer)
    return open_connection(ip, port)
end

"""
    receive_feedback_data(feedback_connection::FeedbackConnection, 
        timeout::Real = 10.0)

Waits for data to arrive from the ROS node and returns a struct of the data with
the following fields: position, orientation, linear_vel, angular_vel. This
function blocks execution while waiting, up to the timeout duration provided. If
the timeout duration elapses without the arrival of data, throws a TimeoutError
exception.

# Arguments
- `feedback_connection`: the `FeedbackConnection` obtained from
  `open_feedback_connection`.
- `timeout`: maximum time in seconds to wait for data. 
"""
function receive_feedback_data(feedback_connection::Connection, timeout::Real = 10.0)
    msg = """{ "action": "get_feedback_data" }\n"""
    payload = send_receive(feedback_connection, msg, timeout)
    data = JSON.parse(String(payload))
    feedback_data = FeedbackData(data)
    return feedback_data
end

"""
    close_feedback_connection(feedback_connection::FeedbackConnection)

Close the connection with the ROS node.
"""
function close_feedback_connection(feedback_connection::Connection)
    close_connection(feedback_connection)
end
