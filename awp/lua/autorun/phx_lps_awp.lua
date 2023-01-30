local Player = FindMetaTable( "Player" )
if !Player then return end

if engine.ActiveGamemode() == "prop_hunt" then
	
	CreateConVar( "lps_ammocount_awp", "30", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Ammunition count for Sniper Rifle weapon. Min: -1, Max: 200", -1, 200 )
	CreateConVar( "lps_wepdamage_awp", "80", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Damage for Sniper Rifle weapon. Min: 50, Max: 500", 50, 500 )
	CreateConVar( "lps_wepdamage_awp_headshot", "2.0", FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE, "Last Prop Standing: Headshot Damage Multiplier for Sniper Rifle weapon. Min: 1.1, Max: 5.0", 1.1, 5.0 )
	
	sound.Add({
		name = 			"Weapon_AWP.PHXFire",
		channel = 		CHAN_STATIC,
		volume = 		1.0,
		level = 		140,
		sound = 		")weapons/awp/awp1.wav"
	})
	
	sound.Add({
		name = 			"Weapon_AWP.PHXBolt",
		channel = 		CHAN_ITEM,
		volume = 		1.0,
		level = 		100,
		sound = 		")weapons/awp/the_bolt.wav"
	})
	
	if CLIENT then
		killicon.Add( "weapon_awp_dummy", "vgui/hud/weapon_phx_awp", Color(255,128,40) )
	end
	
	function Player:LPSAWPScopeState( bool )
		self:SetNWBool( "bLps.AwpScopeState", tobool(bool) )
		
		local b = self:GetNWBool( "bLps.AwpScopeState", false )
		
		if ( b ) then
			self:SetFOV( 40, 0.2 )
			if CLIENT then
				self:EmitSound( "binoculars_zoomin.wav", 60, 100, 1, CHAN_AUTO )
			end
		else
			self:SetFOV( 0, 0.1 )
			if CLIENT then
				self:EmitSound( "binoculars_zoomout.wav", 60, 100, 1, CHAN_AUTO )
			end
		end
	end
	
	function Player:LPSAWPGetScopeState()
		return self:GetNWBool( "bLps.AwpScopeState", false )
	end
	
end

local WepName = "Sniper-Rifle"

if engine.ActiveGamemode() == "prop_hunt" then

hook.Add( "PostGamemodeLoaded", "LPS.AddCustomWeapon_"..WepName, function()
		
		if (IS_PHX) then
			
			-- Begin Adding here.
			list.Set("LPS.XCustomWeapon", WepName:lower(), {
				Delay           = 1.5,
				AmmoCount       = "lps_ammocount_awp",
				WorldModel      = Model("models/weapons/w_snip_awp.mdl"),
				Type            = "custom",
				Reload          = true,
				FixPos          = Vector(0,10,0),
				FixAngles        = Angle(0,0,0),
				
				Sound			= Sound( "Weapon_AWP.PHXFire" ),
				BoltSound		= Sound( "Weapon_AWP.PHXBolt" ),
				Damage			= "lps_wepdamage_awp",
				
				Function        = function( self, pl )
					
					local _,max   = pl:GetHull()
					local WepEnt  = pl:GetLPSWeaponEntity()
					local ph_prop = pl:GetPlayerPropEntity()
					
					if IsValid( WepEnt ) and IsValid( ph_prop ) then
					
						timer.Simple( self.Delay, function()
							if IsValid(pl) and pl:Alive() and IsValid( WepEnt ) then
								pl:SetLPSWeaponState( LPS_WEAPON_READY )
							end
						end )
					
						local Att = WepEnt:GetAttachment( 1 )
						
						local ShootPos = pl:GetShootPos() --fallback
						if (Att) then ShootPos = Att.Pos end
						
						local tr = util.LPSgetAccurateAim( { ph_prop }, pl:EyePos(), ShootPos, pl:EyeAngles(), max.z )
						local Forward = tr.Normal
						
						if SERVER then
							pl.DummyAWPEnt = ents.Create( "weapon_awp_dummy" )
							pl.DummyAWPEnt:SetPos( pl:GetPos() )
							pl.DummyAWPEnt:SetAngles( angle_zero )
							pl.DummyAWPEnt:Spawn()
						end
						
						local b = {}
						b.Num          = 1
						b.Src          = ShootPos
						b.Dir          = Forward
						b.Spread       = ( pl:GetVelocity():Length() < 5 ) and util.LPSgetSpread( 0.01 ) or util.LPSgetSpread( { 0.05, 0.18 } )
						b.Tracer       = 1
						b.TracerName   = "Tracer"
						b.Force        = math.floor( util.LPSgetConValue( self.Damage ) / 25 )
						b.Damage       = util.LPSgetConValue( self.Damage )
						b.AmmoType     = "SniperPenetratedRound"
						b.Attacker     = pl
						b.IgnoreEntity = ph_prop
						b.Callback = function(atk,_,cDamage)
							if SERVER and IsValid( pl.DummyAWPEnt ) then
								cDamage:SetInflictor( pl.DummyAWPEnt )
							else
								cDamage:SetInflictor( atk:GetLPSWeaponEntity() )
							end
						end
						
						pl:LagCompensation(true)
						pl:FireBullets( b )
						pl:LagCompensation(false)
						
						pl:ViewPunch( Angle( -9, math.random(-0.8,0.8),0 ) )
						
						-- Shoot
						local curWep = pl:GetActiveWeapon()
						if pl:HasWeapon( PHX.LPS.DUMMYWEAPON ) and curWep:GetClass() == PHX.LPS.DUMMYWEAPON then
							curWep:EmitSound( self.Sound )
							timer.Simple(0.1, function() if IsValid( curWep ) then curWep:EmitSound( self.BoltSound ) end end)
						end
						
						local M = EffectData()
						M:SetEntity( WepEnt )
						M:SetAttachment( 1 )
						M:SetFlags( 7 )
						util.Effect( "MuzzleFlash", M )
						
						if SERVER then
							pl.DummyAWPEnt:Remove()
							pl.DummyAWPEnt = nil
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
	
end )

-- Headshot and stuff
local headshotsnd = { "player/headshot1.wav", "player/headshot2.wav", "player/headshot3.wav" }
	
-- Multiply Headshot
if SERVER then
	hook.Add( "ScalePlayerDamage", "PHX.LPSScalePlayerDamageAWP", function(ply, hitgroup, dmginfo)

		if (IS_PHX) then
		
			local atk = dmginfo:GetAttacker()
		
			if atk:IsPlayer() && ply:Team() == TEAM_HUNTERS and atk:Team() == TEAM_PROPS and atk:IsLastStanding() then
				if ( hitgroup == HITGROUP_HEAD ) then
					if ply:Armor() > 0 then
						ply:EmitSound( "player/bhit_helmet-1.wav", 90, 100, 1, CHAN_AUTO )
					else
						ply:EmitSound( headshotsnd[math.random( 1, #headshotsnd )], 75, 100, 1, CHAN_AUTO )
					end
					dmginfo:ScaleDamage( GetConVar("lps_wepdamage_awp_headshot"):GetInt() )
				end
			end
			
		end
	end)
	
	hook.Add( "PostPlayerDeath", "PHX.LPSClearAWPStuff", function( pl )
	
		if (IS_PHX) then
	
			if pl:IsLastStanding() then
		
				pl:LPSAWPScopeState( false )
				
				if ( pl.DummyAWPEnt ) and IsValid( pl.DummyAWPEnt ) then
					pl.DummyAWPEnt:Remove()
					pl.DummyAWPEnt = nil
				end
				
			end
		
		end
		
	end )
	
	hook.Add( "PH_RoundEnd", "PHX.LPSClearAWPStuff_RoundEnd", function()
	
		if (IS_PHX) then
	
			for _,pl in ipairs( team.GetPlayers( TEAM_PROPS ) ) do
				if ( pl:LPSAWPGetScopeState() ) then
					pl:LPSAWPScopeState( false )
				end
				
				if ( pl.DummyAWPEnt ) and IsValid( pl.DummyAWPEnt ) then
					pl.DummyAWPEnt:Remove()
					pl.DummyAWPEnt = nil
				end
			end
		
		end
		
	end )
	
end

hook.Add( "PlayerButtonDown", "PHX.LPSAWPReticleState", function( ply, btn )

	if CLIENT then
		if !( IsFirstTimePredicted() ) then return end
	end
	
	if (PHX:GetCVar( "lps_enable" ) and IsValid( ply ) and btn == MOUSE_MIDDLE and
		ply:Team() == TEAM_PROPS and ply:IsLastStanding() and ply:Alive() and !ply:InVehicle() and
		ply:GetLPSWeaponName() == WepName:lower() and GetGlobalBool("LPS.InLastPropStanding", false) and GetGlobalBool("InRound", false)) then
		
		ply:LPSAWPScopeState( !ply:LPSAWPGetScopeState() and true or false )
		
	end

end )

if CLIENT then

	local Reticle = surface.GetTextureID( "sprites/reticle" )
	local Yellow  = Color(220,255,0,255)
	
	hook.Add( "HUDPaint", "PHX.LPSDrawReticleScope", function()
	
		local ply = LocalPlayer()
		if !IsValid( ply ) then return end
	
		if (PHX:GetCVar( "lps_enable" ) and
			ply:Team() == TEAM_PROPS and ply:IsLastStanding() and ply:Alive() and !ply:InVehicle() and !ply:IsLPSHolstered() and
			ply:GetLPSWeaponName() == WepName:lower() and GetGlobalBool("LPS.InLastPropStanding", false) and GetGlobalBool("InRound", false)) then
			
			local SW = ScrW()
			local SH = ScrH()
			
			local cW = SW*0.5
			local cH = SH*0.75
			
			draw.SimpleText( "[MIDDLE CLICK] to Scope", "ChatFont", cW, cH+64, Yellow, TEXT_ALIGN_CENTER )
			
			if ( ply:LPSAWPGetScopeState() ) then
				
				local scrW = ScrW()
				local scrH = ScrH()
		
				local x = scrW / 2.0
				local y = scrH / 2.0
				
				surface.SetTexture( Reticle )
				surface.SetDrawColor( 255, 255, 255, 255 )
				surface.DrawTexturedRect( x-64, y-64, 128, 128 )
				
			end
			
		end
	
	end )

end

end