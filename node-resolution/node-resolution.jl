

using Plots

pyplot()

# function integrate2D(x, y)
#     sum = 0.0
#     for i in 2:length(x[2:end])
#         sum += (x[i] - x[i - 1]) / (y[i]^2)
#     end
#     return sum
# end

function sunset_resolution_case_5(
    x,          # x values to sample
    dx0,
    dxmin,
    temp1,      # Size of refined region
    temp2;      # Location of refined region
    b0 = 4.0,   # Some control parameters
    b1 = 40.0,
    b2 = 50.0,
)

    dxio = 1.0 * dx0
    t2 = x .- temp2
    d2b_local = [(abs(t2_val) < temp1) ? 0.0 : min(abs(t2_val - temp1), abs(t2_val + temp1)) for t2_val in t2]

    val1 = zeros(size(x))
    val2 = zeros(size(x))
    val3 = zeros(size(x))
    val4 = zeros(size(x))
    res = zeros(size(x))
    for (i, d2b_local_val) in enumerate(d2b_local)
        new_val1 = dxmin
        new_val2 = 0.5 * (dx0 + dxmin) - 0.5 * (dx0 - dxmin) * cos((d2b_local_val - b0 * dx0) * π / ((b1 - b0) * dx0))
        new_val3 = dx0 + (dxio - dx0) * ((d2b_local_val - b1 * dx0) / (b2 * dxio))
        new_val4 = dxio
        val1[i] = new_val1
        val2[i] = new_val2
        val3[i] = new_val3
        val4[i] = new_val4

        new_res = 0.0
        if d2b_local_val <= b0 * dx0                    # Minimum res
            new_res = new_val1
        elseif d2b_local_val <= b1 * dx0                # Smooth (cos) change from dxmin to dx0
            new_res = new_val2
        elseif d2b_local_val <= b1 * dx0 + b2 * dxio    # Vary linearly from dx0 to dxio (these are the same for case 5)
            new_res = new_val3
        else                                            # At dxio
            new_res = new_val4
        end
        res[i] = new_res
    end

    if isinteractive()
        res_plot = plot(
            size = (1000, 800), legend = (1, 0.8),
            xticks = x[1]:0.1:x[end], yticks = [0.0, dxmin, dx0]
        )
    
        plot!(res_plot, x, res, color = :black, label = "res", )
        plot!(res_plot, x, val1, style = :dot, linewidth = 2.0, label = "val1: dxmin", )
        plot!(res_plot, x, val2, style = :dot, linewidth = 2.0, label = "val2: dxmin to dx0, cosine", )
        plot!(res_plot, x, val3, style = :dot, linewidth = 2.0, label = "val3: dx0 to dxio, linear", )
        plot!(res_plot, x, val4, style = :dot, linewidth = 2.0, label = "val4: dxio", )
        plot!(res_plot, x, d2b_local .* dxmin, style = :dash, linewidth = 2.0, label = "d2b_local")
    
        display(res_plot)
    end

    return (x, res)
end