hook.Add("Move", "moveProp", function(ply,move)
	if SERVER && ply:Alive() && ply:Team() == TEAM_PROPS then
		-- Local variables
		local ent = ply.ph_prop
		-- Set position and angles
		if IsValid(ent) && IsValid(ply) && ply:Alive() then
			-- Set position
			if (ent:GetModel() == "models/player/kleiner.mdl" || ent:GetModel() == player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))) then
				ent:SetPos(move:GetOrigin())
			else
			    -- Set angles
                if !ply:GetPlayerLockedRot() then
                    if ply:GetRecentlyLocked() then
                        ply:SetRecentlyLocked(false)
                        ent:SetMoveType(MOVETYPE_NONE)
                        move:SetOrigin(ent:GetPos()+ Vector(0, 0, ent:OBBMins().z))
                    else
                        local ang = move:GetAngles()
                        ent:SetPos(move:GetOrigin() - Vector(0, 0, ent:OBBMins().z))
                        ent:SetAngles(Angle(0,ang.y,0))
                    end
                else
                    if not ply:GetRecentlyLocked() then
                        ent:SetMoveType(MOVETYPE_VPHYSICS)
                        ent:SetPos(move:GetOrigin() - Vector(0, 0, ent:OBBMins().z))
                    end
                    ply:SetRecentlyLocked(true)
                    local phys = ent:GetPhysicsObject()
                    if (phys:IsValid()) then
                        phys:Wake()
                    end
                    local entpos = ent:GetPos()
                    local playerpos = ply:GetPos()
                    local dist = entpos:DistToSqr(playerpos)
                    if dist > 200^2 then
                        move:SetOrigin(ent:GetPos()+ Vector(0, 0, ent:OBBMins().z))
                    end
                end
            end
		end
	end
end)

hook.Add("GetFallDamage","preventFallAsProp", function(ply, damage)
	if ply:GetPlayerLockedRot() then
		return 0
	end
end)