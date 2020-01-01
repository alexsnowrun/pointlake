PointLake = PointLake or {}

function PointLake.IsPlayerHaveAccess(ply) -- you can change this shit
    return ply:IsUserGroup("superadmin")
end
