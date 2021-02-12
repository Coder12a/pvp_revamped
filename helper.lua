local cos = math.cos
local sin = math.sin

-- Rotates around a point via yaw.
function rotate_point(yaw, x, z)
    local co = cos(yaw)
    local si = sin(yaw)

    return co * x - si * z, si * x + co * z
end
