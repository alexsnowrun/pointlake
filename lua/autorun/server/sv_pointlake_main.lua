PointLake = PointLake or {}
PointLake.Positions = PointLake.Positions or {}

if !file.Exists("pointlake", "DATA") then
	file.CreateDir("pointlake")
end

local mapname = game.GetMap() or ""
local rawdata = ""

function PointLake.LoadPositions()
    if mapname == "" then return false end
    if file.Exists("pointlake/"..mapname..".txt", "DATA") then
        local data = file.Read("pointlake/"..mapname..".txt", "DATA")
        if !data then return false end
        rawdata = data
        PointLake.Positions = util.JSONToTable(data)
    end
end

local function savepositions(data)
    if mapname == "" then return false end
    file.Write("pointlake/"..mapname..".txt", data == nil and util.TableToJSON(PointLake.Positions) or data)
end

function PointLake.SavePositions()
    savepositions(nil)
end

local time = SysTime()

hook.Add("Think", "PointLake - Autosave", function()
    if SysTime() > time then
        time = SysTime() + 300
        local data = util.TableToJSON(PointLake.Positions)
        if data ~= rawdata then
			rawdata = data
            savepositions(data)
        end
    end
end)

hook.Add("Shutdown","PointLake - Shutdown save",function()
    local data = util.TableToJSON(PointLake.Positions)
    if data ~= rawdata then
        savepositions(data)
    end
end)

-- This is what you can use and what you can change

function PointLake.GetGroupPositions(groupname)
    if PointLake.Positions[groupname] then
        return PointLake.Positions[groupname]
    end
    return false
end

function PointLake.GetRandomPosition(groupname) -- Only for number indexed positions!
    if PointLake.Positions[groupname] and #PointLake.Positions[groupname] > 0 then
        return PointLake.Positions[groupname][math.random(1, #PointLake.Positions[groupname])]
    end
    return false
end

function PointLake.GetPosition(groupname,posname)
    if PointLake.Positions[groupname] and PointLake.Positions[groupname][posname] then
        return PointLake.Positions[groupname][posname]
    end
    return false
end

PointLake.LoadPositions()
