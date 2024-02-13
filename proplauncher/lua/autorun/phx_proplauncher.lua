if engine.ActiveGamemode() == "prop_hunt" then

	local WepName = "PropLauncher"
	local Models=Models or {}
	local FCVAR=FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE

	local IsPropBanned,CollectProps,GetRandomModel,UsePropType
	if SERVER then
		IsPropBanned = function( mdl )
			return PHX:GetCVar( "ph_banned_models" ) and table.HasValue( PHX.BANNED_PROP_MODELS, mdl )
		end

		CollectProps = function()
			if (IS_PHX) or (GAMEMODE.IS_PHZ) then
				Models={}
				for _,v in ipairs(ents.FindByClass("prop_physics")) do
					local phy = v:GetPhysicsObject()
					local objCount = v:GetPhysicsObjectCount()
					if IsValid( phy ) and objCount == 1 then
						local mdl = v:GetModel()
						if IsPropBanned(mdl) then continue end
						if !table.HasValue( Models, mdl ) then
							table.insert( Models, mdl )
						end
					end
				end
			end
		end

		GetRandomModel = function( ph )
			if Models and istable(Models) and !table.IsEmpty(Models) then
				return Models[math.random(1,#Models)]
			end
			return ph:GetModel()
		end

		UsePropType = function( ph )
			local cv = math.Clamp( GetConVar("lps_proplauncher_proptype"):GetInt(), 0, 2 )
			if cv == 1 then return ph:GetModel() end
			if cv == 2 then return GetRandomModel( ph ) end

			-- cv == 0
			if math.random() < 0.5 then return GetRandomModel( ph ) end
			return ph:GetModel()
		end

		hook.Add("InitPostEntity","LPS.InitEnt_"..WepName, CollectProps)
	end

	-- Begin Adding here.
	local WepData = {
		Delay           = 1.5,
		AmmoCount       = "lps_ammocount_proplauncher",
		WorldModel      = Model("models/props_idbs/phenhanced/box.mdl"), --it's invisible weapon
		Type            = "custom",
		Reload          = false,
		
		Function        = function( self, pl )
			
			local WepEnt = pl:GetLPSWeaponEntity()
			local ph 	 = pl:GetPlayerPropEntity()
			
			if IsValid( WepEnt ) and IsValid( ph ) then

				local Forward = pl:EyeAngles():Forward()
				-- Shoot
				pl:ViewPunch( Angle( -1, math.random(-1,1),0 ) )
				
				if SERVER then
					if math.random() < 0.1 then 
						pl:EmitSound( Sound( "vo/npc/male01/hacks01.wav" ), 80 ) -- very low chance that prop will shout 'HAAAAX!'
					else
						pl:EmitSound( Sound( "prop_idbs/yeet_"..math.random(1,3)..".mp3" ), 80 )
					end
					
					local r = ents.Create("prop_physics")
					if (IsValid(r)) then
						r:SetModel( UsePropType(ph) )
						r:SetPos( pl:GetShootPos() + Forward * 4 )
						r:SetAngles( pl:EyeAngles() )
						r:SetKeyValue( "physdamagescale", GetConVar("lps_proplauncher_damagescale"):GetInt() )
						r:SetKeyValue( "nodamageforces", GetConVar("lps_proplauncher_nodamageforces"):GetInt() )
						
						r:Spawn()
						r:Activate()
						
						r:SetOwner(pl)
						r:SetPhysicsAttacker(pl, 5)
						
						r._PropTrash = true
						
						local phy = r:GetPhysicsObject()
						if IsValid(phy) then 
							phy:SetMass( GetConVar("lps_proplauncher_mass"):GetInt() )
							local AddUp = GetConVar("lps_proplauncher_speed_addup"):GetInt()
							local Speed = GetConVar("lps_proplauncher_speed"):GetInt()
							phy:SetVelocity( Forward * Speed + Vector(0, 0, AddUp) )
						end
						
						SafeRemoveEntityDelayed( r, math.random(5,8) )
						
					end
				end
			end
		
		end
	}
	-- End of the weapon data.

	hook.Add( "PostGamemodeLoaded", "LPS.AddCustomWeapon_"..WepName, function()
		if (IS_PHX) or (GAMEMODE.IS_PHZ) then
			CreateConVar( "lps_ammocount_proplauncher", "100", FCVAR, "Last Prop Standing: Ammunition count for PROP Launcher", 1, 1024 )
			CreateConVar( "lps_proplauncher_damagescale", "100", FCVAR, "Prop Launcher Physic Damage Scale", 2, 2500 )
			CreateConVar( "lps_proplauncher_nodamageforces", "0", FCVAR, "Prop Launcher Enable/Disable Damage Forces", 0, 1 )
			CreateConVar( "lps_proplauncher_mass", "100", FCVAR, "Prop Launcher Prop's Mass", 50, 5000 )
			CreateConVar( "lps_proplauncher_speed", "720", FCVAR, "Velocity when Launching Prop", 200, 2000 )
			CreateConVar( "lps_proplauncher_speed_addup", "150", FCVAR, "Add 'Up' velocity, the more value, the higher & further will be launched", 64, 256 )
			CreateConVar( "lps_proplauncher_proptype", "0", FCVAR, "Which prop should Prop Launcher pick from:\n0=ph_prop+Random Prop,\n1=ph_prop,\n2=Random Prop", 0, 2 )

			list.Set("LPS.XCustomWeapon", WepName:lower(), WepData)
		else
			print(" *************************** ")
			MsgC( Color(220,20,20), "[Last Prop Standing] ERROR: Can not load '"..WepName.."' LPS Weapon, reason: Prop Hunt: X2Z is not available!\n" )
			print(" *************************** ")
		end
	end )

end