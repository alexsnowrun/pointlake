PointLake = PointLake or {}

function PointLake.HasPlayerAccess(ply) -- you can change this shit
    return ply:IsUserGroup("superadmin")
end
