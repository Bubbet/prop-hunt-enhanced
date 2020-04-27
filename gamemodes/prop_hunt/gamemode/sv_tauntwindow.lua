-- Validity check to prevent some sort of spam
local function IsDelayed(ply)
	return ply:GetNWFloat("NextTauntTime") > CurTime()
end

net.Receive("CL2SV_PlayThisTaunt", function(len, ply)
	local snd = net.ReadString()

	if IsValid(ply) && !IsDelayed(ply) then
		if file.Exists("sound/" .. snd, "GAME") then
			

			local pitch = ply:GetInfoNum("ph_cl_tauntpitch", 100)
			local correctedPitch = math.Clamp(pitch, GetConVar("ph_tauntpitch_min"):GetInt(), GetConVar("ph_tauntpitch_max"):GetInt())

			ply:EmitSound(snd, 100, correctedPitch)

			ply:SetNWFloat("NextTauntTime", ply:getNextTauntTime())
		else
			ply:ChatPrint("[PH: Enhanced] - Warning: That taunt you selected does not exists on server!")
		end
	else
		ply:ChatPrint("[PH: Enhanced] - Please wait in few seconds...!")
	end
end)
