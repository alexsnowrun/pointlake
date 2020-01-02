TOOL.Category = "Construction"
TOOL.Name = "PointLake - PosEditor"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["curgroup"] = ""
TOOL.ClientConVar["curpos"] = ""

TOOL.Information = {
	{name = "left"},
	{name = "right"},
	{name = "reload"}
}

function string:IsBlank()
   return tostring(self) == "" or tostring(self):find("^%s+$")
end

if CLIENT then

	local col_pos = Color(0, 220, 100, 170)
	local col_pos_h = Color(240, 0, 50, 170)

	language.Add("tool.pl_poseditor.name", "PointLake - Position tool")
	language.Add("tool.pl_poseditor.desc", "Allow to create and remove positions!")
	language.Add("tool.pl_poseditor.left", "Add numbered position")
	language.Add("tool.pl_poseditor.right", "Add named position")
	language.Add("tool.pl_poseditor.reload", "Remove position")

	local positions = {}
	local curgroup = GetConVar("pl_poseditor_curgroup")
	local curpos = GetConVar("pl_poseditor_curpos")

	local showall = true
	local tr = {}
	local pos = Vector()
	local screen_pos
	local pl
	local col = Color(0, 255, 200, 170)

	hook.Add("PostDrawOpaqueRenderables", "PointLake - Drawing", function()
		pl = LocalPlayer()
		if pl:GetTool() == nil or pl:GetActiveWeapon() == NULL or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" or pl:GetTool().Mode ~= "pl_poseditor" then return end
		if !curgroup then curgroup = GetConVar("pl_poseditor_curgroup") end
		if !curpos then curpos = GetConVar("pl_poseditor_curpos") end
		if positions[curgroup:GetString()] then
			cam.Start3D()
				tr = pl:GetEyeTrace()
				curpos:SetString("")
				for k, v in pairs(positions[curgroup:GetString()]) do
					if pl:GetPos():DistToSqr(v) < 65536 then
						if curpos:GetString() == "" and tr.HitPos:DistToSqr(v) < 48 then
							col = col_pos_h
							curpos:SetString(k)
							pos = v + Vector(0, 0, 24)
						else
							col = col_pos
						end
						render.SetColorMaterial()
						render.DrawSphere(v, 4, 24, 24, color_white)
						render.DrawSphere(v, 12, 24, 24, col)
					end
				end
			cam.End3D()
		end
	end)

	function TOOL:DrawHUD()
		pl = LocalPlayer()
		if showall and positions[curgroup:GetString()] then
			for k, v in pairs(positions[curgroup:GetString()]) do
				if pl:GetPos():DistToSqr(v) >= 65536 then
					screen_pos = v:ToScreen()
					draw.RoundedBox(6, screen_pos.x+3, screen_pos.y+3, 6, 6, color_white)
					draw.RoundedBox(12, screen_pos.x, screen_pos.y, 12, 12, col_pos)
				end
			end
		end
		if curpos:GetString() ~= "" then
			screen_pos = pos:ToScreen()
			draw.SimpleText(curpos:GetString(), "DermaLarge", screen_pos.x, screen_pos.y, color_white, TEXT_ALIGN_CENTER)
		end
	end


	local tree

	local function getgroupnode(name)
		if !tree.RootNode.ChildNodes then return nil end
		for k, v in pairs(tree.RootNode.ChildNodes:GetChildren()) do
			if v.Label:GetText() == tostring(name) then
				return v
			end
		end
		return nil
	end

	local function send_removegroup(group)
		net.Start("PointLake_Data")
		net.WriteUInt(1, 2)
		net.WriteBit(1)
		net.WriteString(group)
		net.SendToServer()
	end

	local function send_removepos(group, name)
		net.Start("PointLake_Data")
		net.WriteUInt(1, 2)
		net.WriteBit(0)
		net.WriteString(group)
		net.WriteString(name)
		net.SendToServer()
	end

	local function send_addgroup(group)
		net.Start("PointLake_Data")
		net.WriteUInt(2, 2)
		net.WriteBit(1)
		net.WriteString(group)
		net.SendToServer()
	end

	local function send_addpos(group, name, pos)
		net.Start("PointLake_Data")
		net.WriteUInt(2, 2)
		net.WriteBit(0)
		net.WriteString(group)
		net.WriteString(name)
		net.WriteVector(pos)
		net.SendToServer()
	end

	local function send_renamegroup(oldname, newname)
		net.Start("PointLake_Data")
		net.WriteUInt(3, 2)
		net.WriteBit(1)
		net.WriteString(oldname)
		net.WriteString(newname)
		net.SendToServer()
	end

	local function send_renamepos(group, oldname, newname)

		net.Start("PointLake_Data")
		net.WriteUInt(3, 2)
		net.WriteBit(0)
		net.WriteString(group)
		net.WriteString(oldname)
		net.WriteString(newname)
		net.SendToServer()
	end

	local function removepos(group, name)
		if getgroupnode(group) then
			name = tonumber(name) or name
			for k, v in pairs(getgroupnode(group).ChildNodes:GetChildren()) do
				if v.Label:GetText() == tostring(name) then
					v:Remove()
					positions[group][name] = nil
					break
				end
			end
		end
	end

	local function addpos(group, name, pos)
		name = tonumber(name) or name
		positions[group][name] = pos
		local x = getgroupnode(group):AddNode(name)
		x:SetIcon("icon16/flag_yellow.png")
		function x:DoRightClick()
			local d = DermaMenu()
			d:AddOption("Delete", function()
				send_removepos(self:GetParentNode().Label:GetText(), self.Label:GetText())
			end)
			d:AddOption("Reaname", function()
				Derma_StringRequest("Point name changing", "Enter a new name of the point", self.Label:GetText(), function(text)
					if text ~= self.Label:GetText() and #text <= 24 then
						send_renamepos(self:GetParentNode().Label:GetText(), self.Label:GetText(), text)
					end
				end, function() end, "OK", "Cancel")
			end)
			d:Open()
		end
	end
	local function addgroup(group)
		tree:AddNode(group)
		positions[group] = {}
		local node = getgroupnode(group)
		node.DoRightClick = function(self)
			local d = DermaMenu()
			d:AddOption("Delete", function()
				send_removegroup(self.Label:GetText())
			end)
			d:AddOption("Reaname", function()
				Derma_StringRequest("Group name changing", "Enter a new name of the group", self.Label:GetText(), function(text)
					if text ~= self.Label:GetText() and #text <= 24 then
						send_renamegroup(self.Label:GetText(), text)
					end
				end, function() end, "OK", "Cancel")
			end)
				d:Open()
		end
		node.DoClick = function(self)
			if !curgroup then curgroup = GetConVar("pl_poseditor_curgroup") end
			if !curpos then curpos = GetConVar("pl_poseditor_curpos") end
			curgroup:SetString(self.Label:GetText())
			if self.Clicked then return end
			self.Clicked = true
			if self.ChildNodes then
				for _, v in pairs(self.ChildNodes:GetChildren()) do
					v:Remove()
				end
			end

			net.Start("PointLake_Data")
			net.WriteUInt(0, 2)
			net.WriteBit(1)
			net.WriteString(self.Label:GetText())
			net.SendToServer()

			timer.Simple(120, function()
				if IsValid(self) then
					self.Clicked = false
				end
			end)
		end
	end

	function TOOL.BuildCPanel(CPanel)
		CPanel:AddControl("Header", {Description = "PointLake - groups and positions. Right click on the node to rename or delete."})

		tree = vgui.Create("DTree", CPanel)
		tree:SetTall(256)
		CPanel:AddItem(tree)

		CPanel:AddControl("Header", {Description = "Create group. Enter the name of a new group."})

		local addgroup_entry = vgui.Create("DTextEntry")
		CPanel:AddItem(addgroup_entry)

		local addgroup_button = vgui.Create("DButton")
		addgroup_button:SetText("Add group")
		function addgroup_button:DoClick()
			local name = addgroup_entry:GetValue() or ""
			if !name:IsBlank() then
				net.Start("PointLake_Data")
				net.WriteUInt(2, 2)
				net.WriteBit(1)
				net.WriteString(name)
				net.SendToServer()
			end
		end

		CPanel:AddItem(addgroup_button)

		net.Start("PointLake_Data")
		net.WriteUInt(0, 2)
		net.WriteBit(0)
		net.SendToServer()
	end
local lc_clicked = false
local rc_clicked = false
local r_clicked = false
	function TOOL:LeftClick(trace)
		if !PointLake.HasPlayerAccess(pl) then return false end
		if lc_clicked then return false end
		if curpos:GetString() ~= "" or curgroup:GetString() == "" then return false end
		lc_clicked = true
		timer.Simple(0.05, function() lc_clicked = false end)
		send_addpos(curgroup:GetString(), #positions[curgroup:GetString()]+1, trace.HitPos)
		return true
	end

	function TOOL:RightClick(trace)
		if !PointLake.HasPlayerAccess(pl) then return false end
		if rc_clicked then return false end
		if curpos:GetString() ~= "" or curgroup:GetString() == "" then return false end
		rc_clicked = true
		Derma_StringRequest("Create a new position", "Enter the name of position", "pos"..#positions[curgroup:GetString()]+1, function(text)
			if !positions[curgroup:GetString()][text] and #text <= 24 then
				send_addpos(curgroup:GetString(), text, trace.HitPos)
				rc_clicked = false
			end
		end, function() rc_clicked = false end, "OK", "Cancel")
		return true
	end

	function TOOL:Reload(trace)
		if !PointLake.HasPlayerAccess(pl) then return false end
		if r_clicked then return false end
		if curpos:GetString() == "" or curgroup:GetString() == "" then return false end
		r_clicked = true
		timer.Simple(0.05, function() r_clicked = false end)
		send_removepos(curgroup:GetString(), curpos:GetString())
		return true
	end
	net.Receive("PointLake_Data", function()
		local type = net.ReadUInt(2)
		if type == 0 then
			if net.ReadBit() == 0 then
				for k, _ in pairs(net.ReadTable()) do
					addgroup(k)
				end
			else
				local group = net.ReadString()
				positions[group] = {}
				local node = getgroupnode(group)
				if node.ChildNodes then
					for _, v in pairs(node.ChildNodes:GetChildren()) do
						v:Remove()
					end
				end
				for k, v in pairs(net.ReadTable()) do
					addpos(group, k, v)
				end
			end
		elseif type == 1 then
			if net.ReadBit() == 0 then
				removepos(net.ReadString(), net.ReadString())
			else
				local group = net.ReadString()
				local node = getgroupnode(group)
				if node then
					node:Remove()
					positions[group] = nil
				end
			end
		elseif type == 2 then
			if net.ReadBit() == 0 then
				local group = net.ReadString()
				if getgroupnode(group) then
					local name = net.ReadString()
					local pos = net.ReadVector()

					addpos(group, name, pos)
				end
			else
				addgroup(net.ReadString())
			end
		elseif type == 3 then
			if net.ReadBit() == 0 then
				local group = net.ReadString()
				local oldname = net.ReadString()
				local newname = net.ReadString()
				oldname = tonumber(oldname) or oldname
				newname = tonumber(newname) or newname
				if positions[group] and positions[group][oldname] and tostring(oldname) ~= tostring(newname) then
					local vec = positions[group][oldname]
					positions[group][newname] = vec
					if isnumber(oldname) then
						table.remove(positions, oldname)
					else
						positions[group][oldname] = nil
					end
					for k, v in pairs(getgroupnode(group).ChildNodes:GetChildren()) do
						if v.Label:GetText() == tostring(oldname) then
							v.Label:SetText(newname)
							break
						end
					end
				end
			else
				local oldname = net.ReadString()
				local newname = net.ReadString()
				positions[newname] = {}
				table.CopyFromTo(positions[oldname], positions[newname])
				positions[oldname] = nil
				getgroupnode(oldname).Label:SetText(newname)
				if curgroup:GetString() == oldname then
					curgroup:SetString(newname)
				end
			end
		end
	end)

else

	util.AddNetworkString("PointLake_Data")

	local function getaccesibleplayers()
		local tb = {}
		for _, v in pairs(player.GetAll()) do
			if PointLake.HasPlayerAccess(v) then
				table.insert(tb, v)
			end
		end

		return tb
	end

	local function PL_SendPostions(ply, group)
		if group:IsBlank() or !PointLake.Positions[group] then return end

		local tb = {}
		for k, v in pairs(PointLake.Positions[group]) do
			tb[k] = v
		end

		net.Start("PointLake_Data")
		net.WriteUInt(0, 2)
		net.WriteBit(1)
		net.WriteString(group)
		net.WriteTable(tb)
		net.Send(ply)
	end

	local function PL_AddPostion(ply, group, name, pos)
		if tostring(name):IsBlank() or group:IsBlank() or !PointLake.Positions[group] or PointLake.Positions[group][name]  or pos == nil then return end
		PointLake.Positions[group][name] = pos
		net.Start("PointLake_Data")
		net.WriteUInt(2, 2)
		net.WriteBit(0)
		net.WriteString(group)
		net.WriteString(name)
		net.WriteVector(pos)
		net.Send(getaccesibleplayers())
	end

	local function PL_AddGroup(ply, group)
		if group:IsBlank() or PointLake.Positions[group] then return end
		PointLake.Positions[group] = {}
		net.Start("PointLake_Data")
		net.WriteUInt(2, 2)
		net.WriteBit(1)
		net.WriteString(group)
		net.Send(getaccesibleplayers())
	end

	local function PL_RemovePosition(ply, name, group)
		name = tonumber(name) or name
		if tostring(name):IsBlank() or group:IsBlank() or !PointLake.Positions[group] or !PointLake.Positions[group][name] then return end
		if isnumber(name) then
			table.remove(PointLake.Positions[group], name)
			PL_SendPostions(getaccesibleplayers(), group)
			return
		end
		PointLake.Positions[group][name] = nil
		net.Start("PointLake_Data")
		net.WriteUInt(1, 2)
		net.WriteBit(0)
		net.WriteString(group)
		net.WriteString(name)
		net.Send(getaccesibleplayers())
	end

	local function PL_RemoveGroup(ply, group)
		if group:IsBlank() or !PointLake.Positions[group] then return end
		PointLake.Positions[group] = nil
		net.Start("PointLake_Data")
		net.WriteUInt(1, 2)
		net.WriteBit(1)
		net.WriteString(group)
		net.Send(getaccesibleplayers())
	end

	net.Receive("PointLake_Data", function(len, ply)
		if !PointLake.HasPlayerAccess(ply) then return end
		local type = net.ReadUInt(2)
		if type == 0 then
			if net.ReadBit() == 0 then
				local tb = {}
				for k, _ in pairs(PointLake.Positions) do
					tb[k] = true
				end
				net.Start("PointLake_Data")
				net.WriteUInt(0, 2)
				net.WriteBit(0)
				net.WriteTable(tb)
				net.Send(ply)
			else
				PL_SendPostions(ply, net.ReadString())
			end
		elseif type == 1 then
			if net.ReadBit() == 0 then
				local group = net.ReadString()
				local name = net.ReadString()
				PL_RemovePosition(ply, name, group)
			else
				local group = net.ReadString()
				PL_RemoveGroup(ply, group)
			end
		elseif type == 2 then
			if net.ReadBit() == 0 then
				local group = net.ReadString()
				local name = net.ReadString()
				local pos = net.ReadVector()
				name = tonumber(name) or name
				PL_AddPostion(ply, group, name, pos)
			else
				local group = net.ReadString()
				PL_AddGroup(ply, group)
			end
		elseif type == 3 then
			if net.ReadBit() == 0 then
				local group = net.ReadString()
				local oldname = net.ReadString()
				local newname = net.ReadString()
				oldname = tonumber(oldname) or oldname
				newname = tonumber(newname) or newname
				if PointLake.Positions[group] and PointLake.Positions[group][oldname] and oldname ~= newname then
					local vec = PointLake.Positions[group][oldname]
					if isnumber(oldname) then
						table.remove(PointLake.Positions, oldname)
					else
						PointLake.Positions[group][oldname] = nil
					end
				end
				net.Start("PointLake_Data")
				net.WriteUInt(3, 2)
				net.WriteBit(0)
				net.WriteString(group)
				net.WriteString(oldname)
				net.WriteString(newname)
				net.Send(getaccesibleplayers())
			else
				local oldname = net.ReadString()
				local newname = net.ReadString()
				if PointLake.Positions[oldname] and !PointLake.Positions[newname] and oldname ~= newname then
					PointLake.Positions[newname] = {}
					table.CopyFromTo(PointLake.Positions[oldname], PointLake.Positions[newname])
					PointLake.Positions[oldname] = nil
					net.Start("PointLake_Data")
					net.WriteUInt(3, 2)
					net.WriteBit(1)
					net.WriteString(oldname)
					net.WriteString(newname)
					net.Send(getaccesibleplayers())
				end
			end
		end
	end)
end
