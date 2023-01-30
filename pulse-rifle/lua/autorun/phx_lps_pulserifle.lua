
if engine.ActiveGamemode() == "prop_hunt" then
	CreateConVar( "lps_ammocount_ar2", "100", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Ammunition count for Pulse Rifle weapon" )
	CreateConVar( "lps_wepdamage_ar2", "15", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Damage per shot for Pulse Rifle weapon" )
end

local ExcludeMap = {
	["phx_restaurant"] = true,
	["phx_restaurant_2022"] = true,
}

hook.Add( "PostGamemodeLoaded", "LPS.AddCustomWeapon_PulseRifle", function()

	if GetConVar( "developer" ):GetInt() == 1 then
		print( "PH:X Varialble: ", (PHX) )
		print( "IS_PHX ?", (IS_PHX) )
		
		if (PHX) and (PHX.REVISION) then
			print( "PH:X Version: ", PHX.REVISION )
		else
			print( "PH:X Version: ERROR=Couldn't get PH:X Version, reason: `PHX.REVISION` not available or I was too late to get the information upon PostGamemodeLoaded." )
		end
	end

	if engine.ActiveGamemode() == "prop_hunt" then

		if !( ExcludeMap[game.GetMap()] ) then
		
			if (IS_PHX) then
				
				-- Begin Adding here.
				list.Set("LPS.XCustomWeapon", "pulse-rifle", {

					Delay           = 0.09,
					AmmoCount       = "lps_ammocount_ar2",
					WorldModel      = Model("models/weapons/w_irifle.mdl"),
					ShootSound      = Sound("Weapon_AR2.NPC_Single"),
					Type            = "weapon",
					ViewPunch       = {
						x = {-0.8,0.018},
						y = {-0.02,0.02}
					},
					
					FixAngles		= Angle(0,180,0),
					FixPos          = Vector(0,5,0),
					MuzzleFx        = function( ent, pos, endpos, ang )
						local m = EffectData()
						m:SetEntity( ent )
						m:SetStart( pos )
						m:SetOrigin( endpos )
						m:SetAngles( ang )
						m:SetFlags( 5 )
						util.Effect( "MuzzleFlash", m )
					end,
					
					Num 			= 1,
					Spread 		    = {0.01,0.018},
					Tracer		    = 2,
					TracerName 	    = "AR2Tracer",
					Force		    = 5,
					AmmoType        = "AR2",
					Damage		    = "lps_wepdamage_ar2"
					
				})
				-- End of the weapon data.
				
			else
			
				print(" *************************** ")
				MsgC( Color(220,20,20), "[Last Prop Standing] ERROR: Can not load 'Pulse-Rifle' LPS Weapon, reason: Prop Hunt: X is not available!\n" )
				print(" *************************** ")
			
			end
			
		end
	
	end
end )