local Player = FindMetaTable( "Player" )
if !Player then return end

if engine.ActiveGamemode() == "prop_hunt" then
	local FCVAR = FCVAR_ARCHIVE+FCVAR_REPLICATED+FCVAR_NOTIFY+FCVAR_SERVER_CAN_EXECUTE
	CreateConVar( "lps_ammocount_ak47", "90", FCVAR, "Last Prop Standing: Ammunition count for AK47 weapon. Min: -1, Max: 1000", -1, 1000 )
	CreateConVar( "lps_wepdamage_ak47", "15", FCVAR, "Last Prop Standing: Damage for AK47 weapon. Min: 1, Max: 100", 1, 100 )
	CreateConVar( "lps_2ndammo_ak47_count", "2", FCVAR, "Last Prop Standing: Grenade Launcher Count for AK47 weapon. Min: 1, Max: 10", 1, 10 )
	CreateConVar( "lps_2ndammo_ak47_dmg", "50", FCVAR, "Last Prop Standing: Grenade Launcher Damage for AK47 weapon. Min: 5, Max: 100", 5, 100 )
	
	if CLIENT then
		killicon.Add( "weapon_ak47_dummy", "vgui/hud/weapon_phx_ak47", Color(255,128,40) )
		
		LPS_AK47SecAmmo = 0
	end
	
	sound.Add({
		name = 			"Weapon_AK47.PHXFire",
		channel = 		CHAN_WEAPON,
		volume = 		1.0,
		level = 		75,
		sound = 		"weapons/ak47/ak47-1.wav"
	})
	
	function Player:LPSResetAKSecondary()
		self.AK47LPSSecondaryAmmo = 0
		self:SendLua( "LPS_AK47SecAmmo=0" )
	end
	
	function Player:LPSUpdateAKSecondary()
		self.AK47LPSSecondaryAmmo = math.Clamp( self.AK47LPSSecondaryAmmo - 1, 0, GetConVar( "lps_2ndammo_ak47_count" ):GetInt() )
		self:SendLua( "LPS_AK47SecAmmo=" .. tostring( self.AK47LPSSecondaryAmmo ) )
	end
	
	function Player:LPSCanFireAKSecondary()
		
		if !(self.LastAK47SecFire) then self.LastAK47SecFire = 0 end
		
		if self.LastAK47SecFire <= CurTime() then
			
			if self.AK47LPSSecondaryAmmo <= 0 then
				self:EmitSound( Sound("Weapon_Pistol.Empty") )
				self.LastAK47SecFire = CurTime() + 0.5
				return
			end
			
			-- Sorry for having these on server sided... :(
			self:EmitSound( Sound( "NPC_Combine.GrenadeLaunch" ) )
			timer.Simple(0.1, function() self:EmitSound( Sound("Weapon_AR2.Reload") ) end)
			
			self:ViewPunch( Angle(-7.5, 0, 0) )
			
			local Forward = self:EyeAngles():Forward()
			local g = ents.Create("grenade_ar2")
			if ( IsValid(g) ) then
				g:SetPos( self:GetShootPos() + Forward * 32 ) -- We'll use Player Eyes instead.
				g:SetAngles( self:EyeAngles() )
				g:SetMoveType( MOVETYPE_FLYGRAVITY )
				g:SetMoveCollide( MOVECOLLIDE_FLY_BOUNCE )
				g:Spawn()
				
				g:SetVelocity( Forward * 1000 )
				g:SetLocalAngularVelocity(Angle(math.random(-400,400),math.random(-400,400),math.random(-400,400)))
				g:SetSaveValue( "m_flDamage", GetConVar("lps_2ndammo_ak47_dmg"):GetInt() )
				g:SetOwner( self )
			end
			
			self.LastAK47SecFire = CurTime() + 1.6
			self:LPSUpdateAKSecondary()
			
		end
		
	end
	
end

local WepName = "AK47"

if engine.ActiveGamemode() == "prop_hunt" then

hook.Add( "PostGamemodeLoaded", "LPS.AddCustomWeapon_"..WepName, function()
		
		if (IS_PHX) then
			
			-- Begin Adding here.
			list.Set("LPS.XCustomWeapon", WepName:lower(), {
				Delay           = 0.12,
				AmmoCount       = "lps_ammocount_ak47",
				WorldModel      = Model("models/weapons/w_rif_ak47.mdl"),
				Type            = "custom",
				Reload          = false,
				FixPos          = Vector(0,8,0),
				FixAngles        = Angle(0,0,0),
				ViewPunch		= { x = {-2.0,0.3}, y = {-0.3,0.3} },
				
				Sound			= Sound( "Weapon_AK47.PHXFire" ),
				Damage			= "lps_wepdamage_ak47",
				
				Function        = function( self, pl )
					
					local _,max   = pl:GetHull()
					local WepEnt  = pl:GetLPSWeaponEntity()
					local ph_prop = pl:GetPlayerPropEntity()
					
					if IsValid( WepEnt ) and IsValid( ph_prop ) then
					
						local Att = WepEnt:GetAttachment( 1 )
						
						local ShootPos = pl:GetShootPos()
						if (Att) then ShootPos = Att.Pos end
						
						local tr = util.LPSgetAccurateAim( { ph_prop }, pl:EyePos(), ShootPos, pl:EyeAngles(), max.z )
						local Forward = tr.Normal
						
						local b = {}
						b.Num          = 1
						b.Src          = ShootPos
						b.Dir          = Forward
						b.Spread       = pl:GetVelocity():Length() < 10 and util.LPSgetSpread( 0.02 ) or util.LPSgetSpread( { 0.075, 0.15 } )
						b.Tracer       = 3
						b.TracerName   = "Tracer"
						b.Force        = 1.25
						b.Damage       = util.LPSgetConValue( self.Damage )
						b.AmmoType     = "AR2"
						b.Attacker     = pl
						b.IgnoreEntity = ph_prop
						b.Callback = function(atk,_,cDamage)
							if SERVER and IsValid( pl.AK47LPS ) then
								cDamage:SetInflictor( pl.AK47LPS )
							else
								cDamage:SetInflictor( atk:GetLPSWeaponEntity() )
							end
						end
						
						pl:LagCompensation(true)
						pl:FireBullets( b )
						pl:LagCompensation(false)
						
						local vp = self.ViewPunch
						pl:ViewPunch( Angle( math.Rand(vp.x[1],vp.x[2]), math.Rand(vp.y[1],vp.y[2]), 0 ) )
						
						-- Shoot
						local curWep = pl:GetActiveWeapon()
						if pl:HasWeapon( PHX.LPS.DUMMYWEAPON ) and curWep:GetClass() == PHX.LPS.DUMMYWEAPON then
							curWep:EmitSound( self.Sound )
						end
						
						local M = EffectData()
						M:SetEntity( WepEnt )
						M:SetAttachment( 1 )
						M:SetFlags( 1 )
						util.Effect( "MuzzleFlash", M )
						
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
	
if SERVER then
	hook.Add( "PHInLastPropStanding", "PHX.AK47LPSStart", function(pl, name, data)
		
		if (name) and name == WepName:lower() then
		
			-- if anything exists, kills it.
			if (pl.AK47LPS) and IsValid( pl.AK47LPS ) then pl.AK47LPS:Remove() pl.AK47LPS = nil end
		
			pl.AK47LPS = ents.Create( "weapon_ak47_dummy" )
			pl.AK47LPS:SetPos( pl:GetPos() )
			pl.AK47LPS:SetAngles( angle_zero )
			pl.AK47LPS:Spawn()
			
			pl.AK47LPSSecondaryAmmo = GetConVar( "lps_2ndammo_ak47_count" ):GetInt()
			pl:SendLua( "LPS_AK47SecAmmo=" .. tostring( pl.AK47LPSSecondaryAmmo ) )
		
		end
		
	end)
	
	hook.Add( "PostPlayerDeath", "PHX.LPSClearAK47s", function( pl )
	
		if (IS_PHX) then
	
			if pl:IsLastStanding() then
				
				pl:LPSResetAKSecondary()
				
				if ( pl.AK47LPS ) and IsValid( pl.AK47LPS ) then
					pl.AK47LPS:Remove()
					pl.AK47LPS = nil
				end
				
			end
		
		end
		
	end )
	
	hook.Add( "PH_RoundEnd", "PHX.LPSClearAK47s_RoundEnd", function()
	
		if (IS_PHX) then
	
			for _,pl in ipairs( team.GetPlayers( TEAM_PROPS ) ) do

				pl:LPSResetAKSecondary()
			
				if ( pl.AK47LPS ) and IsValid( pl.AK47LPS ) then
					pl.AK47LPS:Remove()
					pl.AK47LPS = nil
				end
				
			end
		
		end
		
	end )
	
	-- Fire secondary event
	hook.Add( "PlayerButtonDown", "PHX.LPSAK47CanDoSecondary", function( ply, btn )
		
		if (PHX:GetCVar( "lps_enable" ) and IsValid( ply ) and btn == KEY_G and
			ply:Team() == TEAM_PROPS and ply:IsLastStanding() and ply:Alive() and !ply:InVehicle() and !ply:IsLPSHolstered() and
			ply:GetLPSWeaponName() == WepName:lower() and GetGlobalBool("LPS.InLastPropStanding", false) and GAMEMODE:InRound()) then
			
			ply:LPSCanFireAKSecondary()
		end

	end )
	
end

if CLIENT then

	local Yellow  = Color(220,255,0,255)
	
	hook.Add( "HUDPaint", "PHX.LPSAK47Hint", function()
	
		local ply = LocalPlayer()
		if !IsValid( ply ) then return end
	
		if (PHX:GetCVar( "lps_enable" ) and
			ply:Team() == TEAM_PROPS and ply:IsLastStanding() and ply:Alive() and !ply:InVehicle() and !ply:IsLPSHolstered() and
			ply:GetLPSWeaponName() == WepName:lower() and GetGlobalBool("LPS.InLastPropStanding", false) and GetGlobalBool("InRound", false)) then
			
			local SW = ScrW()
			local SH = ScrH()
			
			local cW = SW*0.5
			local cH = SH*0.75
			
			draw.SimpleText( "Ammo: " .. LPS_AK47SecAmmo .. " | [Press G] Launch Grenade", "ChatFont", cW, cH+64, Yellow, TEXT_ALIGN_CENTER )
			
		end
	
	end )

end

end