-- Initialize the shared variable
PHE = {}
PHE.__index = PHE

-- Initialize and Add ConVar Blocks.
AddCSLuaFile("sh_convars.lua")
include("sh_convars.lua")

-- Language implementation
AddCSLuaFile("sh_language.lua")
include("sh_language.lua")

-- Some config stuff
AddCSLuaFile("config/sh_init.lua")
include("config/sh_init.lua")

AddCSLuaFile("sh_drive_prop.lua")
include("sh_drive_prop.lua")

-- ULX Mapvote
AddCSLuaFile("ulx/modules/sh/sh_phe_mapvote.lua")
include("ulx/modules/sh/sh_phe_mapvote.lua")

-- Include the required lua files
AddCSLuaFile("sh_config.lua")
include("sh_config.lua")
include("sh_player.lua")

-- Add Sound Precaching Functions
AddCSLuaFile("sh_precache.lua")
include("sh_precache.lua")

-- Plugins! :D
PHE.PLUGINS = {}
AddCSLuaFile("sh_plugins.lua")
include("sh_plugins.lua")

-- MapVote
if SERVER then
	AddCSLuaFile("sh_mapvote.lua")
	AddCSLuaFile("mapvote/cl_mapvote.lua")

	include("sh_mapvote.lua")
	include("mapvote/sv_mapvote.lua")
	include("mapvote/rtv.lua")
else
	include("sh_mapvote.lua")
	include("mapvote/cl_mapvote.lua")
end

-- Fretta!
DeriveGamemode("fretta13")
IncludePlayerClasses()

-- Information about the gamemode
GM.Name		= "Prop Hunt: ENHANCED PLUS"
GM.Author	= "Wolvindra-Vinzuerio, D4UNKN0WNM4N2010, Fafy, Dralga & Zero, KO-pKAs3tnj5sU8e85yuXA"

GM._VERSION = "2020-04-07.1 (cfdc582)"
GM.DONATEURL = "https://prophunt.wolvindra.net/?go=donate"

-- Format PHE.LANG.Help
PHE.LANG.Help = string.format(PHE.LANG.Help, GM._VERSION)

-- Fretta configuration
GM.GameLength				= GetConVar("ph_game_time"):GetInt()
GM.AddFragsToTeamScore		= true
GM.CanOnlySpectateOwnTeam 	= true
GM.ValidSpectatorModes 		= { OBS_MODE_CHASE, OBS_MODE_IN_EYE, OBS_MODE_ROAMING }
GM.Data 					= {}
GM.EnableFreezeCam			= true
GM.NoAutomaticSpawning		= true
GM.NoNonPlayerPlayerDamage	= true
GM.NoPlayerPlayerDamage 	= true
GM.RoundBased				= true
GM.RoundLimit				= GetConVar("ph_rounds_per_map"):GetInt()
GM.RoundLength 				= GetConVar("ph_round_time"):GetInt()
GM.RoundPreStartTime		= 0
GM.SuicideString			= "was dead or died mysteriously." -- i think this one is pretty obsolete.
GM.TeamBased 				= true
GM.AutomaticTeamBalance 	= false
GM.ForceJoinBalancedTeams 	= true

GM.RotateTeams				= false
GM.HunterCount				= 0
GM.OriginalTeamBalance		= false
GM.PreventConsecutiveHunting = true


-- Called on gamemdoe initialization to create teams
function GM:CreateTeams()
	if not GAMEMODE.TeamBased then
		return
	end

	TEAM_HUNTERS = 1
	team.SetUp(TEAM_HUNTERS, "Hunters", Color(150, 205, 255, 255))
	team.SetSpawnPoint(TEAM_HUNTERS, {"info_player_counterterrorist", "info_player_combine", "info_player_deathmatch", "info_player_axis"})
	team.SetClass(TEAM_HUNTERS, {"Hunter"})

	TEAM_PROPS = 2
	team.SetUp(TEAM_PROPS, "Props", Color(255, 60, 60, 255))
	team.SetSpawnPoint(TEAM_PROPS, {"info_player_terrorist", "info_player_rebel", "info_player_deathmatch", "info_player_allies"})
	team.SetClass(TEAM_PROPS, {"Prop"})


end

function collision_check(entA, entB)
	local validA = IsValid(entA)
	local validB = IsValid(entB)
	if validA and validB then
		local isplyA = entA:IsPlayer()
		local isplyB = entB:IsPlayer()
		local teamA, teamB, propA, propB
		if isplyA then
			teamA = entA:Team()
			propA = entA:GetNWEntity("PlayerPropEntity")
		end
		if isplyB then
			teamB = entB:Team()
			propB = entB:GetNWEntity("PlayerPropEntity")
		end
		local classA = entA:GetClass()
		local classB = entB:GetClass()
		local modelA = entA:GetModel()
		local modelB = entB:GetModel()
		local succ, plyholdA = pcall(function() return entA:IsPlayerHolding() end)
		plyholdA = succ and plyholdA
		local succ, plyholdB = pcall(function() return entB:IsPlayerHolding() end)
		plyholdB = succ and plyholdB
		if isplyA and isplyB then return false end -- no collisions between players
		if teamA == TEAM_PROPS and classB == "ph_prop" and (modelB == "models/player/kleiner.mdl" or modelB == player_manager.TranslatePlayerModel(entB:GetOwner():GetInfo("cl_playermodel"))) then return false end -- No collision between other player props at round start
		if teamA == TEAM_PROPS and plyholdB then return false end -- prevent player held props from colliding with props
		if teamA == TEAM_PROPS and entA:GetPlayerLockedRot() and propA and not (propA:GetModel() == "models/player/kleiner.mdl" or propA:GetModel() == player_manager.TranslatePlayerModel(entA:GetInfo("cl_playermodel"))) then return false end
		--if teamA == TEAM_PROPS and (classB == "prop_physics" or classB == "prop_physics_multiplayer" or classB == "ph_prop") then return false end -- Fix server crash when swapping lock
		if teamA == TEAM_PROPS and entA:GetRecentlyLocked() then return false end
		if teamA == TEAM_PROPS and (classB == "prop_physics" or classB == "prop_physics_multiplayer" or classB == "ph_prop") then
			local pos = entA:GetPos()
			local st, en = entA:GetHull()
			local tracetable = {
				start = pos,
				endpos = pos,
				mins = st,
				maxs = en
			}
			local trace = util.TraceHull(tracetable)
			if trace.Hit then
				print(entA, 'colliding with', entB)
				return false
			end
		end
	end
end

-- Check collisions
function CheckPropCollision(entA, entB)
	local check1 = collision_check(entA, entB)
	local check2 = collision_check(entB, entA)
	if check1 ~= nil then return check1 end
	if check2 ~= nil then return check2 end
	--[[
	local validA = IsValid(entA)
	local validB = IsValid(entB)
	-- Disable prop on prop collisions
	if not GetConVar("ph_prop_collision"):GetBool() and (entA and entB and ((entA:IsPlayer() and entA:Team() == TEAM_PROPS and entB:IsValid() and entB:GetClass() == "ph_prop") or (entB:IsPlayer() and entB:Team() == TEAM_PROPS and entA:IsValid() and entA:GetClass() == "ph_prop"))) then
		return false
	end

	if validA and validB and entA:IsPlayer() and entB:IsPlayer() then
		return false
	end

	if validA and validB then
		if not entA:IsPlayer() then
			local succ, val = pcall(function() return entA:IsPlayerHolding() end)
			if succ and val then return false end
		end
		if not entB:IsPlayer() then
			local succ, val = pcall(function() return entB:IsPlayerHolding() end)
			if succ and val then return false end
		end
	end

	if (validA and entA:IsPlayer() and entA:GetPlayerLockedRot()) or (validB and entB:IsPlayer() and entB:GetPlayerLockedRot()) then
		return false
	end

	if  (validA and (entA:GetOwner():Team() == TEAM_PROPS or entA:IsPlayer()) and (entA:GetModel() == "models/player/kleiner.mdl" or entA:GetModel() == player_manager.TranslatePlayerModel(entA:GetOwner():GetInfo("cl_playermodel")))) and
		(validB and (entB:GetOwner():Team() == TEAM_PROPS or entB:IsPlayer()) and (entB:GetModel() == "models/player/kleiner.mdl" or entB:GetModel() == player_manager.TranslatePlayerModel(entB:GetOwner():GetInfo("cl_playermodel")))) then
		return false
	end

	-- Disable hunter on hunter collisions so we can allow bullets through them
	if (validA and validB and (entA:IsPlayer() and entA:Team() == TEAM_HUNTERS and entB:IsPlayer() and entB:Team() == TEAM_HUNTERS)) then
		return false
	end
	]]
end
hook.Add("ShouldCollide", "CheckPropCollision", CheckPropCollision)

function CheckStepSound(ply)
	if IsValid(ply) and ply:Team() == TEAM_PROPS then
		return true
	end
end
hook.Add("PlayerFootstep", "CheckStepSound", CheckStepSound)