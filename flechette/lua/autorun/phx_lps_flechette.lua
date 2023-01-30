local SoundTbl = {}

if engine.ActiveGamemode() == "prop_hunt" then
	
	game.AddParticles( "particles/hunter_flechette.pcf" )
	game.AddParticles( "particles/hunter_projectile.pcf" )
	
	CreateConVar( "lps_ammocount_flechette", "100", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Ammunition count for Flechette weapon." )
	
	if CLIENT then
		killicon.Add( "hunter_flechette", "vgui/phx_flechette", Color(248,200,0,255) )
	end
	
	-- Sound Tables
	SoundTbl["NPC_Hunter.FlechetteShoot"] =
	{
		channel = CHAN_STATIC,
		volume = 1.0,
		level = 130,
		pitch = {98,104},
		sound = "^npc/ministrider/ministrider_fire1.wav"
	}

	SoundTbl["NPC_Hunter.FlechetteNearmiss"] =
	{
		channel = CHAN_BODY,
		volume = 1.0,
		level = 120,
		pitch = 100,

		sound = {
			">npc/ministrider/flechetteltor01.wav",
			">npc/ministrider/flechetteltor02.wav",
			">npc/ministrider/flechetteltor03.wav",
			">npc/ministrider/flechetteltor04.wav"
		}
	}

	SoundTbl["NPC_Hunter.FlechetteHitBody"] =
	{
		channel = CHAN_STATIC,
		volume = 0.7,
		pitch = {93,108},
		level = 80,

		sound = {
			"npc/ministrider/flechette_flesh_impact1.wav",
			"npc/ministrider/flechette_flesh_impact2.wav",
			"npc/ministrider/flechette_flesh_impact3.wav",
			"npc/ministrider/flechette_flesh_impact4.wav"
		}
	}

	SoundTbl["NPC_Hunter.FlechettePreExplode"] =
	{
		channel = CHAN_STATIC,
		volume = 0.6,
		pitch = {93,108},
		level = 70,

		sound = {
			"npc/ministrider/hunter_flechette_preexplode1.wav",
			"npc/ministrider/hunter_flechette_preexplode2.wav",
			"npc/ministrider/hunter_flechette_preexplode3.wav"
		}
	}

	SoundTbl["NPC_Hunter.FlechetteExplode"] =
	{
		channel = CHAN_STATIC,
		volume = 1.0,
		pitch = {93,108},
		level = 95,

		sound = {
			"npc/ministrider/flechette_explode1.wav",
			"npc/ministrider/flechette_explode2.wav",
			"npc/ministrider/flechette_explode3.wav",
		}
	}

	SoundTbl["NPC_Hunter.FlechetteHitWorld"] = 
	{
		channel = CHAN_STATIC,
		volume = {.95,1.0},
		pitch = {110,130},
		level = 80,

		sound = {
			"npc/ministrider/flechette_impact_stick1.wav",
			"npc/ministrider/flechette_impact_stick2.wav",
			"npc/ministrider/flechette_impact_stick3.wav",
			"npc/ministrider/flechette_impact_stick4.wav",
			"npc/ministrider/flechette_impact_stick5.wav"
		}
	}
	
	for k,v in pairs( SoundTbl ) do
		v.name = k,
		sound.Add( v )
	end
end

local WepName = "Flechette"

hook.Add( "PostGamemodeLoaded", "LPS.AddCustomWeapon_"..WepName, function()

	if engine.ActiveGamemode() == "prop_hunt" then
		
		if (IS_PHX) then
			
			-- Begin Adding here.
			list.Set("LPS.XCustomWeapon", WepName:lower(), {
				Delay           = 0.1,
				AmmoCount       = "lps_ammocount_flechette",
				WorldModel      = Model("models/weapons/w_phx_strider_wang.mdl"),
				Type            = "custom",
				Reload          = false,
				FixPos          = Vector(0,10,0),
				FixAngles        = Angle(0,180,0),
				
				Sound			= Sound( "NPC_Hunter.FlechetteShoot" ),
				
				Function        = function( self, pl )
					
					local _,max   = pl:GetHull()
					local WepEnt  = pl:GetLPSWeaponEntity()
					local ph_prop = pl:GetPlayerPropEntity()
					
					if IsValid( WepEnt ) and IsValid( ph_prop ) then
					
						local Att = WepEnt:GetAttachment( 1 )
						
						local ShootPos = pl:GetShootPos() --fallback
						if (Att) then ShootPos = Att.Pos end
						
						--Don't use `tr = pl:LPSCreatePropTrace()` because it's a simple trace. We'll use LPSgetAccurateAim for very accurate aim position
						--This of course very expensive operation by using 2 traces result line but somewhat works...
						
						local tr = util.LPSgetAccurateAim( { ph_prop }, pl:EyePos(), ShootPos, pl:EyeAngles(), max.z )
						local Forward = tr.Normal
						
						-- Shoot
						pl:EmitSound( self.Sound )
						
						local M = EffectData()
						M:SetEntity( WepEnt )
						M:SetAttachment( 1 )
						util.Effect( "GunshipMuzzleFlash", M )
						
						pl:ViewPunch( Angle( -1, math.random(-0.75,0.75),0 ) )
						
						if SERVER then
							SuppressHostEvents( NULL ) -- do not suppress flechette effect.
							local f = ents.Create("hunter_flechette")
							if (IsValid(f)) then
								f:SetPos( ShootPos + Forward * 4 ) --todo: 2 ?
								f:SetAngles( Forward:Angle() )
								f:Spawn()
								f:SetVelocity( Forward * 2000 )
								f:SetOwner(pl)
							end
						end
					end
				
				end
			})
			-- End of the weapon data.
			
		else
		
			print(" *************************** ")
			MsgC( Color(220,20,20), "[Last Prop Standing] ERROR: Can not load '"..WepName.."' LPS Weapon, reason: Prop Hunt: X is not available!\n" )
			print(" *************************** ")
		
		end
	
	end
end )