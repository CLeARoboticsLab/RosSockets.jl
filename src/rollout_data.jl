const GET_ROLLOUT_DATA = JSON.json(Dict("action" => "get_rollout_data")) * "\n"

"""
    rollout_data(connection::Connection)

Get the rollout data from the ROS node. Returns a named tuple of vectors and
matrices of the following:

- ts: vector of times
- xs: matrix of states (# states by # timesteps)
- xds: matrix of desired states (# states by # timesteps)
- us: matrix of control inputs (# inputs by # timesteps)
"""
function rollout_data(connection::Connection, timeout::Real = 10.0)
    payload = send_receive(connection, GET_ROLLOUT_DATA, timeout)
    data = JSON.parse(String(payload))
    return (
        ts = convert(Vector{Float64}, data["ts"]),
        xs = convert(Matrix{Float64}, reduce(hcat,data["xs"])),
        xds = convert(Matrix{Float64}, reduce(hcat,data["xds"])),
        us = convert(Matrix{Float64}, reduce(hcat,data["us"]))
    )
end