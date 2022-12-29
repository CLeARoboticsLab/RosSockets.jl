function to_state_vec(feedback_state::FeedbackData)
    x_0 = feedback_state.position[1]
    y_0 = feedback_state.position[2]

    rot_mat = QuatRotation(feedback_state.orientation[1],
                            feedback_state.orientation[2],
                            feedback_state.orientation[3],
                            feedback_state.orientation[4])
    heading = rot_mat*[1,0,0]
    θ_0 = atan(heading[2],heading[1])

    v_0 = norm(feedback_state.linear_vel[1:2])
    if abs(tan(feedback_state.linear_vel[2]/feedback_state.linear_vel[2]) -
        θ_0) > π/2
        v_0 = -v_0
    end

    return [x_0,y_0,v_0,θ_0]
end

function dist_from_goal(feedback_state::FeedbackData, goal_state)
    state = to_state_vec(feedback_state)
    diff = goal_state - state
    return norm(diff[1:2])
end