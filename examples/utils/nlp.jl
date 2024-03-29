function initialize_model(goal_state, timestep)
    x_f = goal_state[1]
    y_f = goal_state[2]
    v_f = goal_state[3]
    θ_f = goal_state[4]
    
    Q = 1
    R = 2

    dt = timestep
    T = Integer(round(40/dt))

    v_max = 0.22
    a_max = v_max
    ω_max = 0.2
    
    model = Model(Ipopt.Optimizer)
    set_optimizer_attribute(model, "max_iter", 100)
    set_optimizer_attribute(model, "print_level", 1)
    set_optimizer_attribute(model, "mu_strategy", "adaptive")

    @variables(model, begin
        x[1:T]
        y[1:T]
        v[1:T]
        θ[1:T]
        a[1:T]
        ω[1:T]
    end)

    @NLobjective(
        model,
        Min,
        sum(
            # penalize deviation from final state
            (x[t]-x_f)*Q*(x[t]-x_f) + 
            (y[t]-y_f)*Q*(y[t]-y_f) +
            (v[t]-v_f)*Q*(v[t]-v_f) +
            (θ[t]-θ_f)*Q*(θ[t]-θ_f) +

            # penalize control inputs
            (a[t]*R*a[t]) + 
            (ω[t]*R*ω[t]) +
            
            # penalize rate of change of acceleration input
            100000*(a[t+1]-a[t])^2
            
            for t in 1:T-1
        )
    )

    for t in 1:T-1
        @NLconstraint(model, x[t+1] == x[t] + v[t]*cos(θ[t])*dt)
        @NLconstraint(model, y[t+1] == y[t] + v[t]*sin(θ[t])*dt)
        @NLconstraint(model, v[t+1] == v[t] + a[t]*dt)
        @NLconstraint(model, θ[t+1] == θ[t] + ω[t]*dt)
    
        @NLconstraint(model, abs(v[t]) <= v_max)
        @NLconstraint(model, abs(a[t]) <= a_max)
        @NLconstraint(model, abs(ω[t]) <= ω_max)
    end

    return model
end

function solve!(model, feedback_state::FeedbackData, warm_start=false)

    state = to_state_vec(feedback_state)

    if warm_start
        x = all_variables(model)
        x_solution = value.(x)
        set_start_value.(x, x_solution)
    end

    fix(model[:x][1], state[1])
    fix(model[:y][1], state[2])
    fix(model[:v][1], state[3])
    fix(model[:θ][1], state[4])

    optimize!(model)

    lin_vel = value.(model[:v])
    turn_rate = value.(model[:ω])
    control_seq = [[lin_vel[k], turn_rate[k]] for k in 1:size(lin_vel,1)]

    x_coords = value.(model[:x])
    y_coords = value.(model[:y])
    trajectory = [x_coords y_coords]

    return control_seq, trajectory
end