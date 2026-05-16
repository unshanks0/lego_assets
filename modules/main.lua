return function(ctx)
	local cfg            = ctx.cfg
	local GuiLib         = ctx.GuiLib
	local Icons          = ctx.Icons
	local playersService = ctx.playersService
	local inputService   = ctx.inputService
	local tweenService   = ctx.tweenService
	local runService     = ctx.runService
	local coreGui        = ctx.coreGui
	local lplr           = ctx.lplr
	local _EXIT_CONNS    = ctx.EXIT_CONNS
	local _EXIT_THREADS  = ctx.EXIT_THREADS
	local R              = ctx.R
	local mainVars       = ctx.mainVars
	local mkSG     = GuiLib.mkScreenGui
	local C_BG     = GuiLib.C_BG
	local C_PANEL  = GuiLib.C_PANEL
	local C_STR    = GuiLib.C_STR
	local C_DIM    = GuiLib.C_DIM
	local C_TEXT   = GuiLib.C_TEXT
	local C_WHITE  = GuiLib.C_WHITE
	local C_DARK   = GuiLib.C_DARK
	local TI_F     = GuiLib.TI_F
	local TI_M     = GuiLib.TI_M
	local FONT_H   = GuiLib.FONT_H
	local FONT_UI  = GuiLib.FONT_UI
	local FONT_UB  = GuiLib.FONT_UB
	local mkCorner = GuiLib.mkCorner
	local mkStroke = GuiLib.mkStroke
	local mkLbl    = GuiLib.mkLbl
	local gameCamera = R.getCamera()
	_EXIT_CONNS[#_EXIT_CONNS+1] = workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end)
	local function _sc(s) local r,g,b=s:match("^(%d+),(%d+),(%d+)$") if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end return Color3.new(1,1,1) end
	local function strToColor(s) local r,g,b=s:match('^(%d+),(%d+),(%d+)$') if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end return Color3.new(1,1,1) end
	local function colorToStr(c3) return math.round(c3.R*255)..','..math.round(c3.G*255)..','..math.round(c3.B*255) end
	local function waitForChild(obj,name,timeout,prop)
		local t=tick()+timeout local r
		repeat r=prop and obj[name] or obj:FindFirstChildOfClass(name) if r or t<tick() then break end task.wait() until false
		return r
	end
	local function getMousePos()
		if inputService.TouchEnabled then return gameCamera.ViewportSize/2 end
		return inputService.GetMouseLocation(inputService)
	end
	local entitylib = {
		isAlive=false,character={},List={},Connections={},
		PlayerConnections={},EntityThreads={},Running=false,
		Events=setmetatable({},{__index=function(self,ind)
			self[ind]={Connections={},
				Connect=function(rs,func) table.insert(rs.Connections,func) return{Disconnect=function() local i=table.find(rs.Connections,func) if i then table.remove(rs.Connections,i) end end} end,
				Fire=function(rs,...) for _,v in rs.Connections do task.spawn(v,...) end end,
				Destroy=function(rs) table.clear(rs.Connections) table.clear(rs) end}
			return self[ind]
		end})
	}
	entitylib.targetCheck=function(ent)
		if ent.NPC then return true end
		if ent.HumanoidRootPart and ent.HumanoidRootPart:FindFirstChild('TeammateLabel') then return false end
		return true
	end
	entitylib.getUpdateConnections=function(ent) return{ent.Humanoid:GetPropertyChangedSignal('Health'),ent.Humanoid:GetPropertyChangedSignal('MaxHealth')} end
	entitylib.isVulnerable=function(ent) return ent.Health>0 and not ent.Character.FindFirstChildWhichIsA(ent.Character,'ForceField') end
	entitylib.IgnoreObject=RaycastParams.new()
	entitylib.IgnoreObject.RespectCanCollide=true
	entitylib.Wallcheck=function(origin,position,ignoreobject)
		if typeof(ignoreobject)~='Instance' then
			local list={gameCamera,lplr.Character}
			for _,v in entitylib.List do if v.Targetable then table.insert(list,v.Character) end end
			if typeof(ignoreobject)=='table' then for _,v in ignoreobject do table.insert(list,v) end end
			ignoreobject=entitylib.IgnoreObject
			ignoreobject.FilterDescendantsInstances=list
		end
		return workspace.Raycast(workspace,origin,(position-origin),ignoreobject)
	end
	entitylib.EntityMouse=function(s)
		if entitylib.isAlive then
			local mouse=s.MouseOrigin or getMousePos()
			local t={}
			local lplrRoot=lplr.Character and lplr.Character.HumanoidRootPart
			for _,v in entitylib.List do
				if not s.Players and v.Player then continue end
				if not s.NPCs and v.NPC then continue end
				if not v.Targetable then continue end
				local rootPos=v.RootPart.Position
				if lplrRoot and (rootPos-lplrRoot.Position).Magnitude>650 then continue end
				local pos,vis=gameCamera.WorldToViewportPoint(gameCamera,v[s.Part].Position)
				if not vis then continue end
				local mag=(mouse-Vector2.new(pos.x,pos.y)).Magnitude
				if mag>s.Range then continue end
				if entitylib.isVulnerable(v) then table.insert(t,{Entity=v,Magnitude=v.Target and -1 or mag}) end
			end
			table.sort(t,s.Sort or function(a,b) return a.Magnitude<b.Magnitude end)
			for _,v in t do
				if s.Wallcheck then if entitylib.Wallcheck(s.Origin,v.Entity[s.Part].Position,s.Wallcheck) then continue end end
				table.clear(s) table.clear(t) return v.Entity
			end
			table.clear(t)
		end
		table.clear(s)
	end
	entitylib.getEntity=function(char) for i,v in entitylib.List do if v.Player==char or v.Character==char then return v,i end end end
	entitylib.addEntity=function(char,plr,teamfunc)
		if not char then return end
		entitylib.EntityThreads[char]=task.spawn(function()
			local hum=waitForChild(char,'Humanoid',10)
			local root=hum and waitForChild(hum,'RootPart',workspace.StreamingEnabled and 9e9 or 10,true)
			local head=char:WaitForChild('Head',10) or root
			if hum and root then
				local ent={Connections={},Character=char,Health=hum.Health,Head=head,Humanoid=hum,
					HumanoidRootPart=root,HipHeight=hum.HipHeight+(root.Size.Y/2)+(hum.RigType==Enum.HumanoidRigType.R6 and 2 or 0),
					MaxHealth=hum.MaxHealth,NPC=plr==nil,Player=plr,RootPart=root,TeamCheck=teamfunc}
				if plr==lplr then
					entitylib.character=ent entitylib.isAlive=true entitylib.Events.LocalAdded:Fire(ent)
				else
					ent.Targetable=entitylib.targetCheck(ent)
					for _,v in entitylib.getUpdateConnections(ent) do
						table.insert(ent.Connections,v:Connect(function() ent.Health=hum.Health ent.MaxHealth=hum.MaxHealth end))
					end
					table.insert(ent.Connections,root.ChildAdded:Connect(function(c) if c.Name=='TeammateLabel' then ent.Targetable=false end end))
					table.insert(ent.Connections,root.ChildRemoved:Connect(function(c) if c.Name=='TeammateLabel' then ent.Targetable=entitylib.targetCheck(ent) end end))
					table.insert(entitylib.List,ent)
					entitylib.Events.EntityAdded:Fire(ent)
				end
			end
			entitylib.EntityThreads[char]=nil
		end)
	end
	entitylib.removeEntity=function(char,localcheck)
		if localcheck then
			if entitylib.isAlive then entitylib.isAlive=false for _,v in entitylib.character.Connections do v:Disconnect() end table.clear(entitylib.character.Connections) end
			return
		end
		if char then
			if entitylib.EntityThreads[char] then task.cancel(entitylib.EntityThreads[char]) entitylib.EntityThreads[char]=nil end
			local ent,ind=entitylib.getEntity(char)
			if ind then for _,v in ent.Connections do v:Disconnect() end table.clear(ent.Connections) table.remove(entitylib.List,ind) entitylib.Events.EntityRemoved:Fire(ent) end
		end
	end
	entitylib.refreshEntity=function(char,plr) entitylib.removeEntity(char) entitylib.addEntity(char,plr) end
	entitylib.addPlayer=function(plr)
		if plr.Character then entitylib.refreshEntity(plr.Character,plr) end
		entitylib.PlayerConnections[plr]={
			plr.CharacterAdded:Connect(function(c) entitylib.refreshEntity(c,plr) end),
			plr.CharacterRemoving:Connect(function(c) entitylib.removeEntity(c,plr==lplr) end),
			plr:GetPropertyChangedSignal('Team'):Connect(function()
				for _,v in entitylib.List do if v.Targetable~=entitylib.targetCheck(v) then entitylib.refreshEntity(v.Character,v.Player) end end
				if plr==lplr then entitylib.start() else entitylib.refreshEntity(plr.Character,plr) end
			end)
		}
	end
	entitylib.removePlayer=function(plr)
		if entitylib.PlayerConnections[plr] then for _,v in entitylib.PlayerConnections[plr] do v:Disconnect() end table.clear(entitylib.PlayerConnections[plr]) entitylib.PlayerConnections[plr]=nil end
		entitylib.removeEntity(plr)
	end
	entitylib.start=function()
		if entitylib.Running then entitylib.stop() end
		table.insert(entitylib.Connections,playersService.PlayerAdded:Connect(function(v) entitylib.addPlayer(v) end))
		table.insert(entitylib.Connections,playersService.PlayerRemoving:Connect(function(v) entitylib.removePlayer(v) end))
		for _,v in playersService:GetPlayers() do entitylib.addPlayer(v) end
		table.insert(entitylib.Connections,workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
			gameCamera=workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
		end))
		entitylib.Running=true
	end
	entitylib.stop=function()
		for _,v in entitylib.Connections do v:Disconnect() end
		for _,v in entitylib.PlayerConnections do for _,v2 in v do v2:Disconnect() end table.clear(v) end
		entitylib.removeEntity(nil,true)
		local cl=table.clone(entitylib.List)
		for _,v in cl do entitylib.removeEntity(v.Character) end
		for _,v in entitylib.EntityThreads do task.cancel(v) end
		table.clear(entitylib.PlayerConnections) table.clear(entitylib.EntityThreads) table.clear(entitylib.Connections) table.clear(cl) entitylib.Running=false
	end
	local kdaEnabled    = cfg.getBool('kdaEnabled',true)
	local hudLogoEnabled= cfg.getBool('hudLogoEnabled',true)
	local hudLogoScale  = cfg.getNum('hudLogoScale',60)
	local kda={kills=0,assists=0,killsTotal=0,assistsTotal=0}
	do local ok,raw=pcall(readfile,'lego/params/kd.txt') if ok and raw then local kt,at=raw:match('kills=(%d+).*assists=(%d+)') if kt then kda.killsTotal=tonumber(kt) or 0 end if at then kda.assistsTotal=tonumber(at) or 0 end end end
	local function kdaSave() pcall(makefolder,'lego/params') pcall(writefile,'lego/params/kd.txt','kills='..kda.killsTotal..'\nassists='..kda.assistsTotal) end
	local rand          = Random.new()
	local FA_MethodRay  = {Value='All'}
	local FA_Ignored    = {ListEnabled={}}
	local FA_Range      = {Value=cfg.getNum('faRange',200)}
	local FA_HitChance  = {Value=cfg.getNum('faHitChance',100)}
	local FA_HeadChance = {Value=cfg.getNum('faHeadChance',100)}
	local FA_Wallbang   = {Enabled=false}
	local FA_Target     = {Walls={Enabled=false},Players={Enabled=true},NPCs={Enabled=false}}
	local FA_RWL        = RaycastParams.new()
	FA_RWL.FilterType   = Enum.RaycastFilterType.Include
	local faEnabled     = cfg.getBool('faEnabled',false)
	local faFovColor    = _sc(cfg.getStr('faFovColor','255,255,255'))
	local maFovColor    = _sc(cfg.getStr('maFovColor','255,255,255'))
	local TB_enabled    = cfg.getBool('tbEnabled',false)
	local TB_distance   = {Value=cfg.getNum('tbDistance',100)}
	local TB_delay      = {Value=cfg.getNum('tbDelay',0)}
	local TB_rayParams  = RaycastParams.new()
	local TB_clicked    = false
	local TB_nextShot   = 0
	local TB_conn       = nil
	local MA_enabled    = cfg.getBool('maEnabled',false)
	local MA_fov        = {Value=cfg.getNum('maFov',150)}
	local MA_speed      = {Value=cfg.getNum('maSpeed',100)}
	local MA_targetHead = cfg.getBool('maTargetHead',true)
	local MA_onClickOn  = cfg.getBool('maOnClick',true)
	local MA_keybind    = Enum.KeyCode.Unknown
	local MA_keybindMB  = Enum.UserInputType.MouseButton2
	local MA_useMouseBtn= true
	do
		local kbRaw=cfg.getStr('maKeybind','MB:MouseButton2')
		if kbRaw:sub(1,3)=='MB:' then MA_useMouseBtn=true MA_keybindMB=Enum.UserInputType[kbRaw:sub(4)] or Enum.UserInputType.MouseButton2
		elseif kbRaw:sub(1,3)=='KC:' then MA_useMouseBtn=false MA_keybind=Enum.KeyCode[kbRaw:sub(4)] or Enum.KeyCode.Unknown end
	end
	local MA_conn1,MA_conn2,MA_renderConn=nil,nil,nil
	local fovRing,maFovRing=nil,nil
	local WHITE=Color3.new(1,1,1) local RED=Color3.fromRGB(255,50,50)
	local Refs={skel={},box2d={},box3d={},tag={},weap={},tracer={}}
	local skelEnabled   = cfg.getBool('skelEnabled',false)
	local skelThick     = cfg.getNum('skelThick',1)
	local skelHeadDot   = cfg.getBool('skelHeadDot',true)
	local headDotSize   = cfg.getNum('headDotSize',6)
	local headDotTrans  = cfg.getNum('headDotTrans',0.65)
	local skelColor     = strToColor(cfg.getStr('skelColor',colorToStr(WHITE)))
	local headDotColor  = strToColor(cfg.getStr('headDotColor',colorToStr(RED)))
	local box2dEnabled  = cfg.getBool('box2dEnabled',false)
	local box2dThick    = cfg.getNum('box2dThick',2)
	local box2dColor    = strToColor(cfg.getStr('box2dColor',colorToStr(WHITE)))
	local box3dEnabled  = cfg.getBool('box3dEnabled',false)
	local box3dThick    = cfg.getNum('box3dThick',1)
	local box3dColor    = strToColor(cfg.getStr('box3dColor',colorToStr(WHITE)))
	local tagEnabled    = cfg.getBool('tagEnabled',false)
	local tagScale      = cfg.getNum('tagScale',1)
	local tagShowHealth = cfg.getBool('tagShowHealth',true)
	local tagShowDist   = cfg.getBool('tagShowDist',true)
	local tagShowName   = cfg.getBool('tagShowName',true)
	local tagNameColor  = strToColor(cfg.getStr('tagNameColor',colorToStr(WHITE)))
	local weaponEnabled = cfg.getBool('weaponEnabled',false)
	local weapColor     = strToColor(cfg.getStr('weapColor',colorToStr(Color3.fromRGB(200,200,200))))
	local tracerEnabled = cfg.getBool('tracerEnabled',false)
	local tracerThick   = cfg.getNum('tracerThick',1)
	local tracerColor   = strToColor(cfg.getStr('tracerColor',colorToStr(WHITE)))
	local tracerOrigin  = cfg.getStr('tracerOrigin','Bottom')
	local BT={
		enabled=cfg.getBool('btEnabled',false),duration=cfg.getNum('btDuration',2),thick=cfg.getNum('btThick',1),
		color=strToColor(cfg.getStr('btColor','255,255,255')),fwdOff=cfg.getNum('btFwdOff',3),downOff=cfg.getNum('btDownOff',0.5),
		minDist=cfg.getNum('btMinDist',1),drawTime=cfg.getNum('btDrawTime',0.1),shrinkTime=cfg.getNum('btShrinkTime',0.25),
		fadeIn=cfg.getNum('btFadeIn',0.1),fadeOut=cfg.getNum('btFadeOut',0.1),screenTol=cfg.getNum('btScreenTol',1500),
		ammoLabels={},prevAmmo={},scanConn=nil,childConn=nil,
	}
	local rbFaFov=cfg.getBool('rbFaFov',false) local rbMaFov=cfg.getBool('rbMaFov',false)
	local rbSkel=cfg.getBool('rbSkel',false)    local rbHead=cfg.getBool('rbHead',false)
	local rbBox2d=cfg.getBool('rbBox2d',false)  local rbBox3d=cfg.getBool('rbBox3d',false)
	local rbTagName=cfg.getBool('rbTagName',false) local rbWeap=cfg.getBool('rbWeap',false)
	local rbTracer=cfg.getBool('rbTracer',false)   local rbBT=cfg.getBool('rbBT',false)
	local TXT_FONTS={Gotham=Font.new('rbxasset://fonts/families/GothamSSm.json'),Arial=Font.new('rbxasset://fonts/families/Arial.json'),Scifi=Font.fromEnum(Enum.Font.SciFi)}
	local txtFont=cfg.getStr('txtFont','Arial')    local txtSize=cfg.getNum('txtSize',13)
	local txtColor=strToColor(cfg.getStr('txtColor','255,255,255'))
	local txtBg=cfg.getBool('txtBg',true)          local txtBgTrans=cfg.getNum('txtBgTrans',50)
	local txtRainbow=cfg.getBool('txtRainbow',true) local txtAlign=cfg.getStr('txtAlign','Left')
	local txtEnabled=cfg.getBool('txtEnabled',true) local txtStroke=cfg.getBool('txtStroke',false)
	local txtX=cfg.getNum('txtX',1)                local txtY=cfg.getNum('txtY',80)
	local rainbowHue=0
	local UISetters={}
	local tagGui=mkSG('RenderTagGui',9999996)
	local moveConst=Vector2.new(1,0.77)*math.rad(0.5)
	local function wrapAngle(n) n=n%math.pi n-=n>=(math.pi/2) and math.pi or 0 n+=n<-(math.pi/2) and math.pi or 0 return n end
	local function makeFovCircle(radius,col) local c=Drawing.new('Circle') c.Visible=false c.Filled=false c.Color=col or Color3.new(1,1,1) c.Thickness=1 c.Radius=radius c.NumSides=1000 c.Transparency=1 return c end
	local function makeFovRing() if fovRing then pcall(function() fovRing:Remove() end) end fovRing=makeFovCircle(FA_Range.Value,faFovColor) end
	local function makeMAFovRing() if maFovRing then pcall(function() maFovRing:Remove() end) end maFovRing=makeFovCircle(MA_fov.Value,maFovColor) end
	_EXIT_THREADS[#_EXIT_THREADS+1]=task.spawn(function()
		while true do runService.RenderStepped:Wait() local vp=gameCamera.ViewportSize local cx,cy=vp.X/2,vp.Y/2
			if fovRing then fovRing.Position=Vector2.new(cx,cy) fovRing.Visible=faEnabled end
			if maFovRing then maFovRing.Position=Vector2.new(cx,cy) maFovRing.Visible=MA_enabled end
		end
	end)
	local function maStop()
		if MA_conn1 then MA_conn1:Disconnect() MA_conn1=nil end
		if MA_conn2 then MA_conn2:Disconnect() MA_conn2=nil end
		if MA_renderConn then MA_renderConn:Disconnect() MA_renderConn=nil end
	end
	local function maStart()
		maStop()
		local partName=MA_targetHead and 'Head' or 'RootPart' local pressing=false
		if MA_onClickOn then
			MA_conn1=inputService.InputBegan:Connect(function(inp,gp)
				if gp then return end
				local match=MA_useMouseBtn and inp.UserInputType==MA_keybindMB or (not MA_useMouseBtn and inp.KeyCode==MA_keybind)
				if match then pressing=true if maFovRing then maFovRing.Radius=MA_fov.Value*1.25 end end
			end)
			MA_conn2=inputService.InputEnded:Connect(function(inp)
				local match=MA_useMouseBtn and inp.UserInputType==MA_keybindMB or (not MA_useMouseBtn and inp.KeyCode==MA_keybind)
				if match then pressing=false if maFovRing then maFovRing.Radius=MA_fov.Value end end
			end)
		end
		MA_renderConn=runService.RenderStepped:Connect(function(dt)
			if not MA_enabled then maStop() return end
			if MA_onClickOn and not pressing then return end
			local ent=entitylib.EntityMouse({Range=MA_fov.Value,Part=partName,Players=true,NPCs=false,Origin=gameCamera.CFrame.Position})
			if not ent then return end
			local facing=gameCamera.CFrame.LookVector
			local new=(ent[partName].Position-gameCamera.CFrame.Position).Unit
			new=new==new and new or Vector3.zero if new==Vector3.zero then return end
			local diffYaw=wrapAngle(math.atan2(facing.X,facing.Z)-math.atan2(new.X,new.Z))
			local diffPitch=math.asin(facing.Y)-math.asin(new.Y)
			local sens=UserSettings():GetService('UserGameSettings').MouseSensitivity
			local angle=Vector2.new(diffYaw,diffPitch)//(moveConst*sens)
			angle*=math.min((MA_speed.Value/1000)*dt*60,1) mousemoverel(angle.X,angle.Y)
		end)
	end
	local oldnamecall=nil
	local function faGetTarget(origin)
		if rand.NextNumber(rand,0,100)>FA_HitChance.Value then return end
		local part=rand.NextNumber(rand,0,100)<FA_HeadChance.Value and 'Head' or 'RootPart'
		local ent=entitylib.EntityMouse({Range=FA_Range.Value,Part=part,Origin=origin,Players=FA_Target.Players.Enabled,NPCs=FA_Target.NPCs.Enabled})
		return ent,ent and ent[part],origin
	end
	local faHooks={}
	faHooks.Raycast=function(args)
		if FA_MethodRay.Value~='All' and args[3] and args[3].FilterType~=Enum.RaycastFilterType[FA_MethodRay.Value] then return end
		local ent,tp,origin=faGetTarget(args[1])
		if not ent or not tp then return end
		args[2]=CFrame.lookAt(origin,tp.Position).LookVector*args[2].Magnitude
	end
	local function faHook()
		if oldnamecall then return end
		oldnamecall=hookmetamethod(game,'__namecall',function(...)
			if getnamecallmethod()~='Raycast' then return oldnamecall(...) end
			if checkcaller() then return oldnamecall(...) end
			local calling=getcallingscript()
			if calling then local list=#FA_Ignored.ListEnabled>0 and FA_Ignored.ListEnabled or {'ControlScript','ControlModule'} if table.find(list,tostring(calling)) then return oldnamecall(...) end end
			local self,args=...,{select(2,...)}
			faHooks.Raycast(args)
			return oldnamecall(self,unpack(args))
		end)
	end
	local function faUnhook() if oldnamecall then hookmetamethod(game,'__namecall',oldnamecall) oldnamecall=nil end end
	local applySkelColor,applyBox2dColor,applyBox3dColor,applyTracerColor
	local applyHeadDotColor,applyHeadDotSize,applyHeadDotTrans,applyTextStyle
	local skelAdd,skelRemove,skelUpdate,box2dAdd,box2dRemove,box2dUpdate
	local box3dAdd,box3dRemove,box3dUpdate,tagAdd,tagRemove,tagUpdate
	local weaponAdd,weaponRemove,weaponUpdate,tracerAdd,tracerRemove,tracerUpdate,setESPFeature
	local tagFont='Jura' local tagBgTrans=50
	local FONT_JURA=Font.new('rbxasset://fonts/families/Jura.json')
	local TAG_FONTS={Gotham=Font.new('rbxasset://fonts/families/GothamSSm.json'),Arial=Font.new('rbxasset://fonts/families/Arial.json'),Jura=Font.new('rbxasset://fonts/families/Jura.json'),Scifi=Font.fromEnum(Enum.Font.SciFi)}
	;(function()
		local function newLine(t,col) local l=Drawing.new('Line') l.Thickness=t l.Color=col or WHITE l.Visible=false return l end
		local function newCircle(r,col) local c=Drawing.new('Circle') c.Radius=r c.NumSides=20 c.Filled=true c.Transparency=headDotTrans c.Color=col or RED c.Visible=false c.Thickness=1 return c end
		function applySkelColor(col) skelColor=col for _,e in Refs.skel do for k,v in e do if k~='HeadDot' then v.Color=col end end end end
		function applyBox2dColor(col) box2dColor=col for _,e in Refs.box2d do for _,l in e do l.Color=col end end end
		function applyBox3dColor(col) box3dColor=col for _,e in Refs.box3d do for _,l in e do l.Color=col end end end
		function applyTracerColor(col) tracerColor=col for _,l in Refs.tracer do l.Color=col end end
		function applyHeadDotColor(col) headDotColor=col for _,e in Refs.skel do e.HeadDot.Color=col end end
		function applyHeadDotSize(sz) headDotSize=sz for _,e in Refs.skel do e.HeadDot.Radius=sz end end
		function applyHeadDotTrans(t) headDotTrans=t for _,e in Refs.skel do e.HeadDot.Transparency=t end end
		function applyTextStyle()
			local font=TXT_FONTS[txtFont] or TXT_FONTS.Arial local bgTrans=txtBg and (txtBgTrans/100) or 1
			for _,e in Refs.tag do if e.hp then e.hp.FontFace=font end if e.name then e.name.FontFace=font end if e.dist then e.dist.FontFace=font end if e.frame then e.frame.BackgroundTransparency=bgTrans end end
			for _,e in Refs.weap do if e.lbl then e.lbl.FontFace=font end if e.frame then e.frame.BackgroundTransparency=bgTrans end end
		end
		function skelAdd(ent)
			if Refs.skel[ent] then return end
			local e={Torso=newLine(skelThick,skelColor),UpperTorso=newLine(skelThick,skelColor),LowerTorso=newLine(skelThick,skelColor),LeftArm=newLine(skelThick,skelColor),RightArm=newLine(skelThick,skelColor),LeftLeg=newLine(skelThick,skelColor),RightLeg=newLine(skelThick,skelColor)}
			e.HeadDot=newCircle(headDotSize,headDotColor) e.HeadDot.Transparency=headDotTrans Refs.skel[ent]=e
		end
		function skelRemove(ent) local e=Refs.skel[ent] if not e then return end Refs.skel[ent]=nil for _,v in e do pcall(function() v.Visible=false v:Remove() end) end end
		function skelUpdate()
			for ent,e in Refs.skel do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local _,rv=gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				if not rv or hide then e.UpperTorso.Visible=false e.Torso.Visible=false e.LowerTorso.Visible=false e.LeftArm.Visible=false e.RightArm.Visible=false e.LeftLeg.Visible=false e.RightLeg.Visible=false e.HeadDot.Visible=false continue end
				local ok=pcall(function()
					local rig=ent.Humanoid.RigType==Enum.HumanoidRigType.R6
					local off=rig and CFrame.new(0,-0.8,0) or CFrame.identity
					local torso=ent.Character:FindFirstChild(rig and 'Torso' or 'UpperTorso') if not torso then return end
					local function wp(p) local v=gameCamera:WorldToViewportPoint(p) return Vector2.new(v.X,v.Y) end
					local head=wp(ent.Head.CFrame.p) local tcf=torso.CFrame
					local tl=wp((tcf*CFrame.new(-1.5,0.8,0)).p) local tr=wp((tcf*CFrame.new(1.5,0.8,0)).p)
					local tt=wp((tcf*CFrame.new(0,0.8,0)).p) local tb=wp((tcf*CFrame.new(0,-0.8,0)).p)
					local bl=wp((tcf*CFrame.new(-0.5,-0.8,0)).p) local br=wp((tcf*CFrame.new(0.5,-0.8,0)).p)
					local lA=ent.Character:FindFirstChild(rig and 'Left Arm' or 'LeftHand')
					local rA=ent.Character:FindFirstChild(rig and 'Right Arm' or 'RightHand')
					local lL=ent.Character:FindFirstChild(rig and 'Left Leg' or 'LeftFoot')
					local rL=ent.Character:FindFirstChild(rig and 'Right Leg' or 'RightFoot')
					if not(lA and rA and lL and rL) then return end
					local la=wp((lA.CFrame*off).p) local ra=wp((rA.CFrame*off).p)
					local ll=wp((lL.CFrame*off).p) local rl=wp((rL.CFrame*off).p)
					e.UpperTorso.From=tl e.UpperTorso.To=tr e.UpperTorso.Visible=true
					e.Torso.From=tt e.Torso.To=tb e.Torso.Visible=true
					e.LowerTorso.From=bl e.LowerTorso.To=br e.LowerTorso.Visible=true
					e.LeftArm.From=tl e.LeftArm.To=la e.LeftArm.Visible=true
					e.RightArm.From=tr e.RightArm.To=ra e.RightArm.Visible=true
					e.LeftLeg.From=bl e.LeftLeg.To=ll e.LeftLeg.Visible=true
					e.RightLeg.From=br e.RightLeg.To=rl e.RightLeg.Visible=true
					if skelHeadDot then local hw=gameCamera:WorldToViewportPoint(ent.Head.CFrame.p) e.HeadDot.Radius=math.clamp(headDotSize*60/math.max(hw.Z,1),1,headDotSize*4) e.HeadDot.Position=head e.HeadDot.Visible=true else e.HeadDot.Visible=false end
				end)
				if not ok then e.UpperTorso.Visible=false e.Torso.Visible=false e.LowerTorso.Visible=false e.LeftArm.Visible=false e.RightArm.Visible=false e.LeftLeg.Visible=false e.RightLeg.Visible=false e.HeadDot.Visible=false end
			end
		end
		function box2dAdd(ent) if Refs.box2d[ent] then return end local e={} for i=1,4 do e['L'..i]=newLine(box2dThick,box2dColor) end Refs.box2d[ent]=e end
		function box2dRemove(ent) local e=Refs.box2d[ent] if not e then return end Refs.box2d[ent]=nil for _,v in e do pcall(function() v.Visible=false v:Remove() end) end end
		function box2dUpdate()
			for ent,e in Refs.box2d do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local rp,rv=gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				if not rv or hide then e.L1.Visible=false e.L2.Visible=false e.L3.Visible=false e.L4.Visible=false continue end
				local h=ent.HipHeight local right=gameCamera.CFrame.RightVector
				local top=gameCamera:WorldToViewportPoint(ent.RootPart.Position+Vector3.new(0,h+0.5,0))
				local bot=gameCamera:WorldToViewportPoint(ent.RootPart.Position-Vector3.new(0,h+0.5,0))
				local rside=gameCamera:WorldToViewportPoint(ent.RootPart.Position+right*2)
				local lside=gameCamera:WorldToViewportPoint(ent.RootPart.Position-right*2)
				local hw=math.abs(rside.X-lside.X)/2
				local x0,y0,x1,y1=rp.X-hw,top.Y,rp.X+hw,bot.Y
				e.L1.From=Vector2.new(x0,y0) e.L1.To=Vector2.new(x1,y0) e.L1.Visible=true
				e.L2.From=Vector2.new(x1,y0) e.L2.To=Vector2.new(x1,y1) e.L2.Visible=true
				e.L3.From=Vector2.new(x1,y1) e.L3.To=Vector2.new(x0,y1) e.L3.Visible=true
				e.L4.From=Vector2.new(x0,y1) e.L4.To=Vector2.new(x0,y0) e.L4.Visible=true
			end
		end
		function box3dAdd(ent) if Refs.box3d[ent] then return end local e={} for i=1,12 do e['L'..i]=newLine(box3dThick,box3dColor) end Refs.box3d[ent]=e end
		function box3dRemove(ent) local e=Refs.box3d[ent] if not e then return end Refs.box3d[ent]=nil for _,v in e do pcall(function() v.Visible=false v:Remove() end) end end
		function box3dUpdate()
			for ent,e in Refs.box3d do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local _,rv=gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				if not rv or hide then for i=1,12 do e['L'..i].Visible=false end continue end
				local h=ent.HipHeight local cf=ent.RootPart.CFrame
				local function wp(p) local v=gameCamera:WorldToViewportPoint(p) return Vector2.new(v.X,v.Y) end
				local p1=wp((cf*CFrame.new(1.5,h,1.5)).p) local p2=wp((cf*CFrame.new(1.5,-h,1.5)).p)
				local p3=wp((cf*CFrame.new(-1.5,h,1.5)).p) local p4=wp((cf*CFrame.new(-1.5,-h,1.5)).p)
				local p5=wp((cf*CFrame.new(1.5,h,-1.5)).p) local p6=wp((cf*CFrame.new(1.5,-h,-1.5)).p)
				local p7=wp((cf*CFrame.new(-1.5,h,-1.5)).p) local p8=wp((cf*CFrame.new(-1.5,-h,-1.5)).p)
				local ls={{p1,p2},{p3,p4},{p5,p6},{p7,p8},{p1,p3},{p1,p5},{p5,p7},{p7,p3},{p2,p4},{p2,p6},{p6,p8},{p8,p4}}
				for i,ln in ls do e['L'..i].From=ln[1] e['L'..i].To=ln[2] e['L'..i].Visible=true e['L'..i].Thickness=box3dThick end
			end
		end
		local function makeTagFrame(parent)
			local f=Instance.new('Frame',parent) f.BackgroundColor3=Color3.new() f.BackgroundTransparency=0.5 f.BorderSizePixel=0 f.AutomaticSize=Enum.AutomaticSize.XY f.AnchorPoint=Vector2.new(0.5,1) f.Visible=false
			Instance.new('UICorner',f).CornerRadius=UDim.new(0,3)
			local ly=Instance.new('UIListLayout',f) ly.FillDirection=Enum.FillDirection.Horizontal ly.SortOrder=Enum.SortOrder.LayoutOrder ly.VerticalAlignment=Enum.VerticalAlignment.Center ly.Padding=UDim.new(0,4)
			local pad=Instance.new('UIPadding',f) pad.PaddingLeft=UDim.new(0,5) pad.PaddingRight=UDim.new(0,5) pad.PaddingTop=UDim.new(0,2) pad.PaddingBottom=UDim.new(0,2)
			return f
		end
		local function makeTxtLbl(parent,col,order) local l=Instance.new('TextLabel',parent) l.BackgroundTransparency=1 l.TextColor3=col l.AutomaticSize=Enum.AutomaticSize.XY l.Text='' l.FontFace=FONT_JURA l.LayoutOrder=order return l end
		function tagAdd(ent)
			if Refs.tag[ent] then return end
			local frame=makeTagFrame(tagGui)
			local heartImg=Instance.new('ImageLabel',frame) heartImg.Size=UDim2.fromOffset(10,10) heartImg.BackgroundTransparency=1 heartImg.Image=Icons.heart or '' heartImg.ImageColor3=Color3.fromRGB(255,80,80) heartImg.LayoutOrder=0 heartImg.Visible=tagShowHealth
			local hpLbl=makeTxtLbl(frame,Color3.fromRGB(220,220,220),1) hpLbl.Visible=tagShowHealth
			local nameLbl=makeTxtLbl(frame,tagNameColor,2) nameLbl.Text=ent.Player and ent.Player.Name or ent.Character.Name nameLbl.Visible=tagShowName
			local distLbl=makeTxtLbl(frame,WHITE,3) distLbl.Visible=tagShowDist
			Refs.tag[ent]={frame=frame,heart=heartImg,hp=hpLbl,name=nameLbl,dist=distLbl}
		end
		function tagRemove(ent) local e=Refs.tag[ent] if not e then return end Refs.tag[ent]=nil pcall(function() e.frame:Destroy() end) end
		function tagUpdate()
			for ent,e in Refs.tag do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local hp,hv=gameCamera:WorldToViewportPoint(ent.RootPart.Position+Vector3.new(0,ent.HipHeight+1,0))
				local show=hv and tagEnabled and not hide
				e.frame.Visible=show if not show then continue end
				local ts=math.round(12*tagScale)
				e.frame.Position=UDim2.fromOffset(hp.X,hp.Y)
				e.frame.BackgroundTransparency=txtBg and (tagBgTrans/100) or 1
				local _tf=TAG_FONTS[tagFont] or TAG_FONTS.Jura
				e.hp.FontFace=_tf e.name.FontFace=_tf e.dist.FontFace=_tf e.heart.Size=UDim2.fromOffset(ts,ts)
				local hpVal=math.round(ent.Health)
				if hpVal<=0 then e.heart.Visible=false e.hp.Visible=true e.hp.TextSize=ts e.hp.Text='Dead' e.hp.TextColor3=Color3.fromRGB(112,112,112) e.name.Visible=false e.dist.Visible=false if Refs.weap[ent] then Refs.weap[ent].frame.Visible=false end continue end
				e.heart.Visible=tagShowHealth e.hp.Visible=tagShowHealth e.hp.TextSize=ts e.hp.Text=tostring(hpVal)
				if hpVal>55 then e.hp.TextColor3=Color3.fromRGB(146,209,152) elseif hpVal>20 then e.hp.TextColor3=Color3.fromRGB(209,202,146) else e.hp.TextColor3=Color3.fromRGB(209,152,146) end
				e.name.TextSize=ts e.name.TextColor3=tagNameColor e.name.Text=ent.Player and ent.Player.Name or ent.Character.Name e.name.Visible=tagShowName
				e.dist.TextSize=ts
				if tagShowDist and entitylib.isAlive then e.dist.Text=math.floor((entitylib.character.RootPart.Position-ent.RootPart.Position).Magnitude)..'m' e.dist.Visible=true else e.dist.Text='' e.dist.Visible=false end
			end
		end
		local function getWeaponName(plrName) local vms=workspace:FindFirstChild('ViewModels') if not vms then return 'Hand' end for _,child in vms:GetChildren() do local parts=child.Name:split(' - ') if #parts>=2 and parts[1]==plrName then return parts[2] end end return 'Hand' end
		function weaponAdd(ent) if Refs.weap[ent] then return end local frame=makeTagFrame(tagGui) local lbl=makeTxtLbl(frame,weapColor,0) lbl.Text='Hand' Refs.weap[ent]={frame=frame,lbl=lbl} end
		function weaponRemove(ent) local e=Refs.weap[ent] if not e then return end Refs.weap[ent]=nil pcall(function() e.frame:Destroy() end) end
		function weaponUpdate()
			for ent,e in Refs.weap do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local hp,hv=gameCamera:WorldToViewportPoint(ent.RootPart.Position+Vector3.new(0,ent.HipHeight+1,0))
				local show=hv and weaponEnabled and not hide e.frame.Visible=show if not show then continue end
				local ts=math.round(12*tagScale) e.lbl.TextSize=ts e.lbl.TextColor3=weapColor e.lbl.FontFace=TAG_FONTS[tagFont] or TAG_FONTS.Jura
				e.frame.BackgroundTransparency=txtBg and (txtBgTrans/100) or 1
				if ent.Player then e.lbl.Text=getWeaponName(ent.Player.Name) end
				local tagH=0 local tagE=Refs.tag[ent]
				if tagEnabled and tagE and tagE.frame.Visible then tagH=tagE.frame.AbsoluteSize.Y>0 and tagE.frame.AbsoluteSize.Y or (ts+6) end
				e.frame.Position=UDim2.fromOffset(hp.X,hp.Y-tagH)
			end
		end
		function tracerAdd(ent) if Refs.tracer[ent] then return end local l=Drawing.new('Line') l.Thickness=tracerThick l.Color=tracerColor l.Visible=false Refs.tracer[ent]=l end
		function tracerRemove(ent) local v=Refs.tracer[ent] if not v then return end Refs.tracer[ent]=nil pcall(function() v.Visible=false v:Remove() end) end
		function tracerUpdate()
			local vp=gameCamera.ViewportSize
			local from=tracerOrigin=='Top' and Vector2.new(vp.X/2,0) or tracerOrigin=='Middle' and Vector2.new(vp.X/2,vp.Y/2) or Vector2.new(vp.X/2,vp.Y)
			for ent,l in Refs.tracer do
				local hide=not ent.Targetable or (lplr.Character and (ent.RootPart.Position-lplr.Character.HumanoidRootPart.Position).Magnitude>650)
				local tPos=tracerOrigin=='Top' and ent.RootPart.Position+Vector3.new(0,ent.HipHeight+1,0) or tracerOrigin=='Middle' and ent.RootPart.Position or ent.RootPart.Position-Vector3.new(0,ent.HipHeight,0)
				local pos,vis=gameCamera:WorldToViewportPoint(tPos) l.Visible=vis and tracerEnabled and not hide
				if not vis or hide then continue end l.From=from l.To=Vector2.new(pos.X,pos.Y)
			end
		end
		function setESPFeature(name,enabled)
			local addFn={skeleton=skelAdd,box2d=box2dAdd,box3d=box3dAdd,tag=tagAdd,weapon=weaponAdd,tracer=tracerAdd}
			local remFn={skeleton=skelRemove,box2d=box2dRemove,box3d=box3dRemove,tag=tagRemove,weapon=weaponRemove,tracer=tracerRemove}
			local ref={skeleton=Refs.skel,box2d=Refs.box2d,box3d=Refs.box3d,tag=Refs.tag,weapon=Refs.weap,tracer=Refs.tracer}
			if enabled then for _,ent in entitylib.List do addFn[name](ent) end else for ent in ref[name] do remFn[name](ent) end end
		end
	end)()
	local _espRenderConn=runService.RenderStepped:Connect(function()
		if skelEnabled then skelUpdate() end if box2dEnabled then box2dUpdate() end if box3dEnabled then box3dUpdate() end
		if tagEnabled then tagUpdate() end if weaponEnabled then weaponUpdate() end if tracerEnabled then tracerUpdate() end
	end)
	local _entityAddedConn=entitylib.Events.EntityAdded:Connect(function(ent)
		if skelEnabled then skelAdd(ent) end if box2dEnabled then box2dAdd(ent) end if box3dEnabled then box3dAdd(ent) end
		if tagEnabled then tagAdd(ent) end if weaponEnabled then weaponAdd(ent) end if tracerEnabled then tracerAdd(ent) end
	end)
	local _entityRemovedConn=entitylib.Events.EntityRemoved:Connect(function(ent)
		skelRemove(ent) box2dRemove(ent) box3dRemove(ent) tagRemove(ent) weaponRemove(ent) tracerRemove(ent)
	end)
	if cfg.hasData() then
		task.defer(function()
			if skelEnabled then setESPFeature('skeleton',true) end if box2dEnabled then setESPFeature('box2d',true) end
			if box3dEnabled then setESPFeature('box3d',true) end if tagEnabled then setESPFeature('tag',true) end
			if weaponEnabled then setESPFeature('weapon',true) end if tracerEnabled then setESPFeature('tracer',true) end
		end)
	end
	local REQUIRED_KEYS={'faEnabled','maEnabled','skelEnabled','box2dEnabled','txtEnabled'}
	local function isConfigBroken(raw)
		if not raw or raw=='' then return true end
		for _,k in REQUIRED_KEYS do if not raw:find(k..'=',1,true) then return true end end
		return false
	end
	local function saveAll()
		local mv=mainVars or {}
		cfg.save({
			faEnabled=tostring(faEnabled),tbEnabled=tostring(TB_enabled),tbDistance=tostring(TB_distance.Value),tbDelay=tostring(TB_delay.Value),
			faHeadChance=tostring(FA_HeadChance.Value),faHitChance=tostring(FA_HitChance.Value),faRange=tostring(FA_Range.Value),
			faFovColor=math.round(faFovColor.R*255)..','..math.round(faFovColor.G*255)..','..math.round(faFovColor.B*255),
			maEnabled=tostring(MA_enabled),maFov=tostring(MA_fov.Value),maSpeed=tostring(MA_speed.Value),maOnClick=tostring(MA_onClickOn),
			maKeybind=(MA_useMouseBtn and ('MB:'..tostring(MA_keybindMB):gsub('Enum.UserInputType.','')) or ('KC:'..tostring(MA_keybind):gsub('Enum.KeyCode.',''))),
			maKeybindIsMouseBtn=tostring(MA_useMouseBtn),maTargetHead=tostring(MA_targetHead),
			maFovColor=math.round(maFovColor.R*255)..','..math.round(maFovColor.G*255)..','..math.round(maFovColor.B*255),
			skelEnabled=tostring(skelEnabled),skelThick=tostring(skelThick),skelColor=colorToStr(skelColor),
			skelHeadDot=tostring(skelHeadDot),headDotSize=tostring(headDotSize),headDotTrans=tostring(headDotTrans),headDotColor=colorToStr(headDotColor),
			box2dEnabled=tostring(box2dEnabled),box2dThick=tostring(box2dThick),box2dColor=colorToStr(box2dColor),
			box3dEnabled=tostring(box3dEnabled),box3dThick=tostring(box3dThick),box3dColor=colorToStr(box3dColor),
			tagEnabled=tostring(tagEnabled),tagScale=tostring(tagScale),
			tagShowHealth=tostring(tagShowHealth),tagShowDist=tostring(tagShowDist),tagShowName=tostring(tagShowName),tagNameColor=colorToStr(tagNameColor),
			weaponEnabled=tostring(weaponEnabled),weapColor=colorToStr(weapColor),
			tracerEnabled=tostring(tracerEnabled),tracerThick=tostring(tracerThick),tracerColor=colorToStr(tracerColor),tracerOrigin=tracerOrigin,
			kdaEnabled=tostring(kdaEnabled),hudLogoEnabled=tostring(hudLogoEnabled),hudLogoScale=tostring(hudLogoScale),
			rbFaFov=tostring(rbFaFov),rbMaFov=tostring(rbMaFov),rbSkel=tostring(rbSkel),rbHead=tostring(rbHead),
			rbBox2d=tostring(rbBox2d),rbBox3d=tostring(rbBox3d),rbTagName=tostring(rbTagName),rbWeap=tostring(rbWeap),rbTracer=tostring(rbTracer),rbBT=tostring(rbBT),
			btColor=colorToStr(BT.color),btFwdOff=tostring(BT.fwdOff),btDownOff=tostring(BT.downOff),btMinDist=tostring(BT.minDist),
			btDrawTime=tostring(BT.drawTime),btShrinkTime=tostring(BT.shrinkTime),btFadeIn=tostring(BT.fadeIn),btFadeOut=tostring(BT.fadeOut),btScreenTol=tostring(BT.screenTol),
			txtFont=txtFont,txtSize=tostring(txtSize),txtBg=tostring(txtBg),txtBgTrans=tostring(txtBgTrans),
			txtRainbow=tostring(txtRainbow),txtAlign=txtAlign,txtEnabled=tostring(txtEnabled),txtStroke=tostring(txtStroke),txtX=tostring(txtX),txtY=tostring(txtY),
			configName=mv.configName or '',legoUsername=mv.legoUsername or 'Unnamed',
			mainBannerUrl=mv.mainBannerUrl or '',mainParagraph=mv.mainParagraph or '',mainHudImgUrl=mv.mainHudImgUrl or '',
		})
	end
	local function applyConfig()
		faEnabled=cfg.getBool('faEnabled',false) TB_enabled=cfg.getBool('tbEnabled',false)
		TB_distance.Value=cfg.getNum('tbDistance',100) TB_delay.Value=cfg.getNum('tbDelay',0)
		FA_HeadChance.Value=cfg.getNum('faHeadChance',100) FA_HitChance.Value=cfg.getNum('faHitChance',100) FA_Range.Value=cfg.getNum('faRange',200)
		faFovColor=_sc(cfg.getStr('faFovColor','255,255,255')) maFovColor=_sc(cfg.getStr('maFovColor','255,255,255'))
		MA_enabled=cfg.getBool('maEnabled',false) MA_fov.Value=cfg.getNum('maFov',80) MA_speed.Value=cfg.getNum('maSpeed',10)
		MA_onClickOn=cfg.getBool('maOnClick',false) MA_targetHead=cfg.getBool('maTargetHead',true)
		skelEnabled=cfg.getBool('skelEnabled',false) skelThick=cfg.getNum('skelThick',1) skelColor=_sc(cfg.getStr('skelColor','255,255,255'))
		skelHeadDot=cfg.getBool('skelHeadDot',false) headDotSize=cfg.getNum('headDotSize',6) headDotTrans=cfg.getNum('headDotTrans',0) headDotColor=_sc(cfg.getStr('headDotColor','255,255,255'))
		box2dEnabled=cfg.getBool('box2dEnabled',false) box2dThick=cfg.getNum('box2dThick',1) box2dColor=_sc(cfg.getStr('box2dColor','255,255,255'))
		box3dEnabled=cfg.getBool('box3dEnabled',false) box3dThick=cfg.getNum('box3dThick',1) box3dColor=_sc(cfg.getStr('box3dColor','255,255,255'))
		tagEnabled=cfg.getBool('tagEnabled',false) tagScale=cfg.getNum('tagScale',1)
		tagShowHealth=cfg.getBool('tagShowHealth',true) tagShowDist=cfg.getBool('tagShowDist',true) tagShowName=cfg.getBool('tagShowName',true) tagNameColor=_sc(cfg.getStr('tagNameColor','255,255,255'))
		weaponEnabled=cfg.getBool('weaponEnabled',false) weapColor=_sc(cfg.getStr('weapColor','255,255,255'))
		tracerEnabled=cfg.getBool('tracerEnabled',false) tracerThick=cfg.getNum('tracerThick',1) tracerColor=_sc(cfg.getStr('tracerColor','255,255,255')) tracerOrigin=cfg.getStr('tracerOrigin','Bottom')
		BT.enabled=cfg.getBool('btEnabled',false) BT.color=_sc(cfg.getStr('btColor','255,255,255')) BT.duration=cfg.getNum('btDuration',1) BT.thick=cfg.getNum('btThick',1)
		BT.fwdOff=cfg.getNum('btFwdOff',0) BT.downOff=cfg.getNum('btDownOff',0) BT.minDist=cfg.getNum('btMinDist',50) BT.drawTime=cfg.getNum('btDrawTime',0.5)
		BT.shrinkTime=cfg.getNum('btShrinkTime',0.5) BT.fadeIn=cfg.getNum('btFadeIn',0.1) BT.fadeOut=cfg.getNum('btFadeOut',0.3) BT.screenTol=cfg.getNum('btScreenTol',100)
		kdaEnabled=cfg.getBool('kdaEnabled',true) hudLogoEnabled=cfg.getBool('hudLogoEnabled',true) hudLogoScale=cfg.getNum('hudLogoScale',60)
		txtEnabled=cfg.getBool('txtEnabled',true) txtFont=cfg.getStr('txtFont','Gotham') txtSize=cfg.getNum('txtSize',13) txtBg=cfg.getBool('txtBg',false)
		txtBgTrans=cfg.getNum('txtBgTrans',50) txtRainbow=cfg.getBool('txtRainbow',false) txtAlign=cfg.getStr('txtAlign','Left') txtStroke=cfg.getBool('txtStroke',true)
		txtX=cfg.getNum('txtX',20) txtY=cfg.getNum('txtY',180)
		rbFaFov=cfg.getBool('rbFaFov',false) rbMaFov=cfg.getBool('rbMaFov',false) rbSkel=cfg.getBool('rbSkel',false) rbHead=cfg.getBool('rbHead',false)
		rbBox2d=cfg.getBool('rbBox2d',false) rbBox3d=cfg.getBool('rbBox3d',false) rbTagName=cfg.getBool('rbTagName',false) rbWeap=cfg.getBool('rbWeap',false)
		rbTracer=cfg.getBool('rbTracer',false) rbBT=cfg.getBool('rbBT',false)
		setESPFeature('skeleton',skelEnabled) setESPFeature('box2d',box2dEnabled) setESPFeature('box3d',box3dEnabled)
		setESPFeature('tag',tagEnabled) setESPFeature('weapon',weaponEnabled) setESPFeature('tracer',tracerEnabled)
		if fovRing then fovRing.Color=faFovColor end if maFovRing then maFovRing.Color=maFovColor end
	end
	local function applyConfigTable(t)
		local function b(k,d) local v=t[k] if v==nil then return d end return v=='true' end
		local function n(k,d) return tonumber(t[k]) or d end
		local function s(k,d) local v=t[k] if v and v~='' then return v end return d end
		faEnabled=b('faEnabled',false) TB_enabled=b('tbEnabled',false)
		TB_distance.Value=n('tbDistance',100) TB_delay.Value=n('tbDelay',0)
		FA_HeadChance.Value=n('faHeadChance',100) FA_HitChance.Value=n('faHitChance',100) FA_Range.Value=n('faRange',200)
		faFovColor=_sc(s('faFovColor','255,255,255')) maFovColor=_sc(s('maFovColor','255,255,255'))
		MA_enabled=b('maEnabled',false) MA_fov.Value=n('maFov',80) MA_speed.Value=n('maSpeed',10)
		MA_onClickOn=b('maOnClick',false) MA_targetHead=b('maTargetHead',true)
		skelEnabled=b('skelEnabled',false) skelThick=n('skelThick',1) skelColor=_sc(s('skelColor','255,255,255'))
		skelHeadDot=b('skelHeadDot',false) headDotSize=n('headDotSize',6) headDotTrans=n('headDotTrans',0) headDotColor=_sc(s('headDotColor','255,255,255'))
		box2dEnabled=b('box2dEnabled',false) box2dThick=n('box2dThick',1) box2dColor=_sc(s('box2dColor','255,255,255'))
		box3dEnabled=b('box3dEnabled',false) box3dThick=n('box3dThick',1) box3dColor=_sc(s('box3dColor','255,255,255'))
		tagEnabled=b('tagEnabled',false) tagScale=n('tagScale',1)
		tagShowHealth=b('tagShowHealth',true) tagShowDist=b('tagShowDist',true) tagShowName=b('tagShowName',true) tagNameColor=_sc(s('tagNameColor','255,255,255'))
		weaponEnabled=b('weaponEnabled',false) weapColor=_sc(s('weapColor','255,255,255'))
		tracerEnabled=b('tracerEnabled',false) tracerThick=n('tracerThick',1) tracerColor=_sc(s('tracerColor','255,255,255')) tracerOrigin=s('tracerOrigin','Bottom')
		BT.enabled=b('btEnabled',false) BT.color=_sc(s('btColor','255,255,255')) BT.duration=n('btDuration',1) BT.thick=n('btThick',1)
		BT.fwdOff=n('btFwdOff',0) BT.downOff=n('btDownOff',0) BT.minDist=n('btMinDist',50) BT.drawTime=n('btDrawTime',0.5)
		BT.shrinkTime=n('btShrinkTime',0.5) BT.fadeIn=n('btFadeIn',0.1) BT.fadeOut=n('btFadeOut',0.3) BT.screenTol=n('btScreenTol',100)
		kdaEnabled=b('kdaEnabled',true) hudLogoEnabled=b('hudLogoEnabled',true) hudLogoScale=n('hudLogoScale',60)
		txtEnabled=b('txtEnabled',true) txtFont=s('txtFont','Gotham') txtSize=n('txtSize',13) txtBg=b('txtBg',false)
		txtBgTrans=n('txtBgTrans',50) txtRainbow=b('txtRainbow',false) txtAlign=s('txtAlign','Left') txtStroke=b('txtStroke',true)
		txtX=n('txtX',20) txtY=n('txtY',180)
		rbFaFov=b('rbFaFov',false) rbMaFov=b('rbMaFov',false) rbSkel=b('rbSkel',false) rbHead=b('rbHead',false)
		rbBox2d=b('rbBox2d',false) rbBox3d=b('rbBox3d',false) rbTagName=b('rbTagName',false) rbWeap=b('rbWeap',false)
		rbTracer=b('rbTracer',false) rbBT=b('rbBT',false)
		setESPFeature('skeleton',skelEnabled) setESPFeature('box2d',box2dEnabled) setESPFeature('box3d',box3dEnabled)
		setESPFeature('tag',tagEnabled) setESPFeature('weapon',weaponEnabled) setESPFeature('tracer',tracerEnabled)
		if fovRing then fovRing.Color=faFovColor end if maFovRing then maFovRing.Color=maFovColor end
		faUnhook()
		maStop()
		if tbStop_ref then tbStop_ref() end
		btStop()
		if faEnabled then faHook() end
		if MA_enabled then maStart() end
		if BT.enabled then btStart() end
	end
	local _saveDebounce=nil
	local function _debouncedSave()
		if GuiLib.rainbowActive then return end
		if _saveDebounce then task.cancel(_saveDebounce) end
		_saveDebounce=task.delay(0.5,function()
			_saveDebounce=nil
			R.notif.showAction('Save config?','Save',function()
				saveAll()
				if R.onSave then R.onSave() end
				R.notif.showInfo('Saved!',2,Icons.info)
			end,6,Icons.info)
		end)
	end
	local function onFaChanged() _debouncedSave() end
	local function onEspChanged() _debouncedSave() end
	local function applyUIState()
		if UISetters.faEnabled then UISetters.faEnabled(faEnabled) end if UISetters.faHeadChance then UISetters.faHeadChance(FA_HeadChance.Value) end
		if UISetters.faHitChance then UISetters.faHitChance(FA_HitChance.Value) end if UISetters.faRange then UISetters.faRange(FA_Range.Value) end
		if UISetters.tbEnabled then UISetters.tbEnabled(TB_enabled) end if UISetters.tbDistance then UISetters.tbDistance(TB_distance.Value) end
		if UISetters.tbDelay then UISetters.tbDelay(math.round(TB_delay.Value*1000)) end
		if UISetters.maEnabled then UISetters.maEnabled(MA_enabled) end if UISetters.maFov then UISetters.maFov(MA_fov.Value) end
		if UISetters.maSpeed then UISetters.maSpeed(MA_speed.Value) end if UISetters.maOnClick then UISetters.maOnClick(MA_onClickOn) end
		if UISetters.skelEnabled then UISetters.skelEnabled(skelEnabled) end if UISetters.skelThick then UISetters.skelThick(math.clamp(math.round(skelThick*2),1,10)) end
		if UISetters.skelHeadDot then UISetters.skelHeadDot(skelHeadDot) end if UISetters.headDotSize then UISetters.headDotSize(math.clamp(math.round(headDotSize),1,12)) end
		if UISetters.headDotTrans then UISetters.headDotTrans(math.clamp(math.round(headDotTrans*100),0,100)) end
		if UISetters.box2dEnabled then UISetters.box2dEnabled(box2dEnabled) end if UISetters.box2dThick then UISetters.box2dThick(math.clamp(math.round(box2dThick*2),1,10)) end
		if UISetters.box3dEnabled then UISetters.box3dEnabled(box3dEnabled) end if UISetters.box3dThick then UISetters.box3dThick(math.clamp(math.round(box3dThick*2),1,10)) end
		if UISetters.tagEnabled then UISetters.tagEnabled(tagEnabled) end if UISetters.weapEnabled then UISetters.weapEnabled(weaponEnabled) end
		if UISetters.tagScale then UISetters.tagScale(math.clamp(math.round(tagScale*100),50,200)) end if UISetters.tagBgTrans then UISetters.tagBgTrans(tagBgTrans) end
		if UISetters.tracerEnabled then UISetters.tracerEnabled(tracerEnabled) end if UISetters.tracerThick then UISetters.tracerThick(math.clamp(math.round(tracerThick*2),1,10)) end
		if UISetters.btEnabled then UISetters.btEnabled(BT.enabled) end if UISetters.btDuration then UISetters.btDuration(math.round(BT.duration*10)) end
		if UISetters.btThick then UISetters.btThick(math.round(BT.thick*2)) end
		if UISetters.txtEnabled then UISetters.txtEnabled(txtEnabled) end if UISetters.txtX then UISetters.txtX(math.clamp(math.round(txtX),0,100)) end
		if UISetters.txtY then UISetters.txtY(math.clamp(math.round(txtY),0,100)) end if UISetters.txtSize then UISetters.txtSize(txtSize) end
		if UISetters.txtRainbow then UISetters.txtRainbow(txtRainbow) end if UISetters.txtStroke then UISetters.txtStroke(txtStroke) end
		if UISetters.txtBg then UISetters.txtBg(txtBg) end if UISetters.txtBgTrans then UISetters.txtBgTrans(txtBgTrans) end
		if UISetters.txtAlign then UISetters.txtAlign(txtAlign) end
		if UISetters.kdaEnabled then UISetters.kdaEnabled(kdaEnabled) end if UISetters.hudLogoEnabled then UISetters.hudLogoEnabled(hudLogoEnabled) end
		if UISetters.hudLogoScale then UISetters.hudLogoScale(hudLogoScale) end
	end
	local notif=GuiLib.mkNotifSystem(R.sgAim)
	R.notif=notif
	local function btCreateTracer(fromPos,toPos)
		if not BT.enabled then return end
		local line=Drawing.new('Line') line.Color=BT.color line.Thickness=BT.thick line.Transparency=0 line.Visible=false
		local startTime=tick()
		local conn conn=runService.RenderStepped:Connect(function()
			local elapsed=tick()-startTime
			if elapsed>BT.duration then line:Remove() conn:Disconnect() return end
			local fromVP=gameCamera:WorldToViewportPoint(fromPos) local toVP=gameCamera:WorldToViewportPoint(toPos)
			local vs=gameCamera.ViewportSize
			local function onScreen(p) return p.Z>0 and p.X>-BT.screenTol and p.X<vs.X+BT.screenTol and p.Y>-BT.screenTol and p.Y<vs.Y+BT.screenTol end
			local fromD=(fromPos-gameCamera.CFrame.Position).Magnitude local toD=(toPos-gameCamera.CFrame.Position).Magnitude
			if not(onScreen(fromVP) and onScreen(toVP)) or fromD<BT.minDist or toD<BT.minDist then line.Visible=false return end
			line.Visible=true
			local alpha=1
			if elapsed<BT.fadeIn then alpha=elapsed/BT.fadeIn elseif elapsed>(BT.duration-BT.fadeOut) then alpha=1-(elapsed-(BT.duration-BT.fadeOut))/BT.fadeOut end
			local cFrom,cTo=fromVP,toVP
			if elapsed<=BT.drawTime then local t=elapsed/BT.drawTime cTo=Vector2.new(fromVP.X+(toVP.X-fromVP.X)*t,fromVP.Y+(toVP.Y-fromVP.Y)*t)
			elseif elapsed>(BT.duration-BT.shrinkTime) then local t=(elapsed-(BT.duration-BT.shrinkTime))/BT.shrinkTime cFrom=Vector2.new(toVP.X+(fromVP.X-toVP.X)*t,toVP.Y+(fromVP.Y-toVP.Y)*t) end
			line.From=Vector2.new(cFrom.X,cFrom.Y) line.To=Vector2.new(cTo.X,cTo.Y) line.Transparency=alpha
		end)
	end
	local function btStop() if BT.scanConn then BT.scanConn:Disconnect() BT.scanConn=nil end if BT.childConn then BT.childConn:Disconnect() BT.childConn=nil end BT.ammoLabels={} BT.prevAmmo={} end
	local function btGetContainer() local ok,fi=pcall(function() return lplr.PlayerGui.MainGui.MainFrame.FighterInterfaces end) if not ok or not fi then return nil end for _,child in fi:GetChildren() do local con=child:FindFirstChild('Hotbar') and child.Hotbar:FindFirstChild('Container') and child.Hotbar.Container:FindFirstChild('AmmoDisplays') if con then return con end end end
	local function btOnAmmoChanged(lbl)
		local cur=tonumber(lbl.Text) if not cur then return end local old=BT.prevAmmo[lbl]
		if old and cur==old-1 then
			local cf=gameCamera.CFrame local origin=cf.Position+cf.LookVector*BT.fwdOff+cf.UpVector*-BT.downOff local target
			if faEnabled then local part=MA_targetHead and 'Head' or 'RootPart' local ent=entitylib.EntityMouse({Range=FA_Range.Value,Part=part,Origin=origin,Players=true,NPCs=false}) if ent and ent[part] then target=ent[part].Position end end
			if not target then local rp=RaycastParams.new() rp.FilterDescendantsInstances={lplr.Character} rp.FilterType=Enum.RaycastFilterType.Blacklist local res=workspace:Raycast(origin,cf.LookVector*500,rp) target=res and res.Position or origin+cf.LookVector*500 end
			btCreateTracer(origin,target)
		end
		BT.prevAmmo[lbl]=cur
	end
	local function btScan()
		local con=btGetContainer() if not con then return end
		for _,disp in con:GetChildren() do if disp.Name=='AmmoDisplay' then local res=disp:FindFirstChild('Reserve') if res then local lbl=res:FindFirstChild('Ammo') if lbl and lbl:IsA('TextLabel') and not BT.ammoLabels[lbl] then BT.ammoLabels[lbl]=true BT.prevAmmo[lbl]=tonumber(lbl.Text) lbl:GetPropertyChangedSignal('Text'):Connect(function() if BT.enabled then btOnAmmoChanged(lbl) end end) end end end end
	end
	local function btStart() btStop() btScan() local con=btGetContainer() if con then BT.childConn=con.ChildAdded:Connect(function() task.wait(0.3) btScan() end) end BT.scanConn=runService.Heartbeat:Connect(function() if math.random(1,30)==1 then btScan() end end) end
	task.spawn(function()
		local ok2,fighterSlots=pcall(function() return lplr.PlayerGui:WaitForChild('MainGui',10).MainFrame.FighterInterfaces:WaitForChild(lplr.Name,10).EliminationSlots end)
		local function checkSlot(slot)
			if slot.Name~='EliminationSlot' then return end task.wait(0.1)
			local lbl=slot:FindFirstChildWhichIsA('TextLabel',true) or slot:FindFirstChildWhichIsA('TextButton',true) if not lbl then return end
			if lbl.Text:find('Eliminated') then kda.kills+=1 kda.killsTotal+=1 kdaSave() elseif lbl.Text:find('Assist') then kda.assists+=1 kda.assistsTotal+=1 kdaSave() end
		end
		if ok2 and fighterSlots then for _,s in fighterSlots:GetChildren() do task.spawn(checkSlot,s) end fighterSlots.ChildAdded:Connect(checkSlot) end
	end)
	local tbStop_ref=nil
	local function cleanup()
		pcall(entitylib.stop) pcall(faUnhook) pcall(maStop)
		pcall(function() if tbStop_ref then tbStop_ref() end end) pcall(btStop)
		pcall(function() _espRenderConn:Disconnect() end)
		pcall(function() _entityAddedConn:Disconnect() end)
		pcall(function() _entityRemovedConn:Disconnect() end)
		for _,ref in {Refs.skel,Refs.box2d,Refs.box3d,Refs.weap} do for _,e in ref do for _,d in e do pcall(function() d.Visible=false d:Remove() end) end end end
		for _,l in Refs.tracer do pcall(function() l.Visible=false l:Remove() end) end
		for _,e in Refs.tag do pcall(function() if e.frame then e.frame:Destroy() end end) end
		if fovRing then pcall(function() fovRing.Visible=false fovRing:Remove() end) fovRing=nil end
		if maFovRing then pcall(function() maFovRing.Visible=false maFovRing:Remove() end) maFovRing=nil end
		table.clear(Refs.skel) table.clear(Refs.box2d) table.clear(Refs.box3d)
		table.clear(Refs.tag) table.clear(Refs.weap) table.clear(Refs.tracer)
		table.clear(UISetters)
	end
	local function buildAimGUI()
		local mkToggle=GuiLib.mkToggleRow local mkSlider=GuiLib.mkSliderRow local mkSubSlider=GuiLib.mkSubSlider
		local mkColorP=GuiLib.mkColorPicker local mkDiv=GuiLib.mkDivider local mkSec=GuiLib.mkSectionLabel
		local mkHeader=GuiLib.mkHeaderPanel local sgAim=R.sgAim
		local AIM_W=420 local AIM_HALF=209 local AIM_H=36
		local aimPanel,aimHeader=mkHeader(sgAim,'AIMTAB',Icons.aim,AIM_W,AIM_H,30,180)
		local outerGlow=Instance.new('ImageLabel',aimPanel)
		outerGlow.Size=UDim2.new(1,28,1,28) outerGlow.Position=UDim2.fromOffset(-14,-14) outerGlow.BackgroundTransparency=1 outerGlow.ZIndex=-1
		outerGlow.Image='rbxassetid://5028857084' outerGlow.ImageColor3=C_DARK outerGlow.ImageTransparency=0.85
		outerGlow.ScaleType=Enum.ScaleType.Slice outerGlow.SliceCenter=Rect.new(24,24,276,276)
		local function mkDot2(parent,xOff)
			local d=Instance.new('Frame',parent) d.Size=UDim2.fromOffset(7,7) d.Position=UDim2.new(1,xOff,0,8) d.BackgroundColor3=C_DARK d.BorderSizePixel=0 mkCorner(d,99) mkStroke(d,Color3.fromRGB(70,70,70))
			local g=Instance.new('ImageLabel',parent) g.Size=UDim2.fromOffset(18,18) g.Position=UDim2.new(1,xOff-5,0,3) g.BackgroundTransparency=1 g.ZIndex=0 g.Image='rbxassetid://5028857084' g.ImageColor3=C_DARK g.ImageTransparency=1 g.ScaleType=Enum.ScaleType.Slice g.SliceCenter=Rect.new(24,24,276,276)
			local l=Instance.new('TextLabel',parent) l.Size=UDim2.fromOffset(22,10) l.Position=UDim2.new(1,xOff-7,0,16) l.BackgroundTransparency=1 l.TextColor3=C_DIM l.TextSize=8 l.FontFace=FONT_UB l.TextXAlignment=Enum.TextXAlignment.Center
			return d,g,l
		end
		local dot,dotGlow,faLbl=mkDot2(aimHeader,-28) faLbl.Text='FA'
		local dotMA,dotMAGlow,maLbl=mkDot2(aimHeader,-14) maLbl.Text='MA'
		local aimVert=Instance.new('Frame',aimPanel) aimVert.Position=UDim2.fromOffset(AIM_HALF,AIM_H+1) aimVert.Size=UDim2.fromOffset(1,999) aimVert.BackgroundColor3=C_STR aimVert.BorderSizePixel=0
		local leftCol=Instance.new('Frame',aimPanel) leftCol.Position=UDim2.fromOffset(0,AIM_H+1) leftCol.Size=UDim2.fromOffset(AIM_HALF,800) leftCol.BackgroundTransparency=1 leftCol.BorderSizePixel=0
		local rightCol=Instance.new('Frame',aimPanel) rightCol.Position=UDim2.fromOffset(AIM_HALF+1,AIM_H+1) rightCol.Size=UDim2.fromOffset(AIM_HALF,800) rightCol.BackgroundTransparency=1 rightCol.BorderSizePixel=0
		local W=AIM_HALF local yL,yR=0,0
		local function tbGetTarget()
			TB_rayParams.FilterDescendantsInstances={lplr.Character,gameCamera} TB_rayParams.FilterType=Enum.RaycastFilterType.Blacklist
			local ray=workspace:Raycast(gameCamera.CFrame.Position,gameCamera.CFrame.LookVector*TB_distance.Value,TB_rayParams)
			if ray and ray.Instance then for _,v in entitylib.List do if v.Targetable and v.Character and v.Player and ray.Instance:IsDescendantOf(v.Character) then return v end end end
		end
		local function tbStopLocal() if TB_conn then TB_conn:Disconnect() TB_conn=nil end if TB_clicked then if mouse1release then pcall(mouse1release) end TB_clicked=false end end
		tbStop_ref=tbStopLocal
		local function tbStart()
			tbStopLocal()
			TB_conn=runService.Heartbeat:Connect(function()
				local wActive=(isrbxactive and isrbxactive()) or (iswindowactive and iswindowactive()) or true if not wActive then return end
				if tbGetTarget() then
					if tick()>=TB_nextShot then
						if TB_clicked then if mouse1release then pcall(mouse1release) end TB_clicked=false TB_nextShot=tick()+TB_delay.Value
						else if mouse1press then pcall(mouse1press) end TB_clicked=true end
					end
				else if TB_clicked then if mouse1release then pcall(mouse1release) end TB_clicked=false end end
			end)
		end
		local function tbSetEnabled(state) TB_enabled=state if state then tbStart() else tbStopLocal() end onFaChanged() end
		local function faSetEnabled(state)
			faEnabled=state
			if state then makeFovRing() faHook() tweenService:Create(dot,TI_M,{BackgroundColor3=C_TEXT}):Play() tweenService:Create(dotGlow,TI_M,{ImageColor3=C_TEXT,ImageTransparency=0.4}):Play() tweenService:Create(outerGlow,TI_M,{ImageColor3=Color3.fromRGB(200,200,200)}):Play()
			else faUnhook() tweenService:Create(dot,TI_M,{BackgroundColor3=C_DARK}):Play() tweenService:Create(dotGlow,TI_M,{ImageColor3=C_DARK,ImageTransparency=1}):Play() tweenService:Create(outerGlow,TI_M,{ImageColor3=C_DARK}):Play() if fovRing then fovRing.Visible=false end end
			onFaChanged()
		end
		local function maSetEnabled(state)
			MA_enabled=state
			if state then makeMAFovRing() maStart() tweenService:Create(dotMA,TI_M,{BackgroundColor3=C_TEXT}):Play() tweenService:Create(dotMAGlow,TI_M,{ImageColor3=C_TEXT,ImageTransparency=0.4}):Play() tweenService:Create(maLbl,TI_M,{TextColor3=C_TEXT}):Play()
			else maStop() if maFovRing then maFovRing.Visible=false end tweenService:Create(dotMA,TI_M,{BackgroundColor3=C_DARK}):Play() tweenService:Create(dotMAGlow,TI_M,{ImageColor3=C_DARK,ImageTransparency=1}):Play() tweenService:Create(maLbl,TI_M,{TextColor3=C_DIM}):Play() end
			onFaChanged()
		end
		yL=yL+mkSec(leftCol,yL,W,'FUNAIM')
		do local _h,_s=mkToggle(leftCol,'FunAim',yL,W,faEnabled,faSetEnabled) UISetters.faEnabled=function(v) _s(v,true) end yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W) yL=yL+mkSec(leftCol,yL,W,'SETTINGS')
		do local _h,_s=mkSlider(leftCol,'Headshot Chance',yL,W,0,100,FA_HeadChance.Value,'%',function(v) FA_HeadChance.Value=v onFaChanged() end) UISetters.faHeadChance=_s yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W)
		do local _h,_s=mkSlider(leftCol,'Hit Chance',yL,W,0,100,FA_HitChance.Value,'%',function(v) FA_HitChance.Value=v onFaChanged() end) UISetters.faHitChance=_s yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W)
		do local _h,_s=mkSlider(leftCol,'FOV Radius',yL,W,10,1000,FA_Range.Value,'px',function(v) FA_Range.Value=v if fovRing then fovRing.Radius=v end onFaChanged() end) UISetters.faRange=_s yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W)
		yL=yL+(mkColorP(leftCol,yL,W,'FOV Color',faFovColor,function(col) faFovColor=col if fovRing then fovRing.Color=col end rbFaFov=false onFaChanged() end,sgAim,rbFaFov))
		yL=yL+mkDiv(leftCol,yL,W) yL=yL+mkSec(leftCol,yL,W,'TRIGGERBOT')
		do local _h,_s=mkToggle(leftCol,'TriggerBot',yL,W,TB_enabled,tbSetEnabled) UISetters.tbEnabled=function(v) _s(v,true) end yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W)
		do local _h,_s=mkSlider(leftCol,'Distance',yL,W,1,1000,TB_distance.Value,'st',function(v) TB_distance.Value=v onFaChanged() end) UISetters.tbDistance=_s yL=yL+_h end
		yL=yL+mkDiv(leftCol,yL,W)
		do local _h,_s=mkSlider(leftCol,'Shot Delay',yL,W,0,2000,TB_delay.Value,'ms',function(v) TB_delay.Value=v/1000 onFaChanged() end) UISetters.tbDelay=_s yL=yL+_h end
		yR=yR+mkSec(rightCol,yR,W,'MOUSEANIM')
		do local _h,_s=mkToggle(rightCol,'MouseAnimation',yR,W,MA_enabled,maSetEnabled) UISetters.maEnabled=function(v) _s(v,true) end yR=yR+_h end
		yR=yR+mkDiv(rightCol,yR,W) yR=yR+mkSec(rightCol,yR,W,'SETTINGS')
		do local _h,_s=mkSlider(rightCol,'FOV',yR,W,1,1000,MA_fov.Value,'px',function(v) MA_fov.Value=v if maFovRing then maFovRing.Radius=v end onFaChanged() end) UISetters.maFov=_s yR=yR+_h end
		yR=yR+mkDiv(rightCol,yR,W)
		yR=yR+(mkColorP(rightCol,yR,W,'FOV Color',maFovColor,function(col) maFovColor=col if maFovRing then maFovRing.Color=col end rbMaFov=false onFaChanged() end,sgAim,rbMaFov))
		yR=yR+mkDiv(rightCol,yR,W)
		do local _h,_s=mkSlider(rightCol,'Aim Speed',yR,W,10,1000,MA_speed.Value,'',function(v) MA_speed.Value=v onFaChanged() end) UISetters.maSpeed=_s yR=yR+_h end
		yR=yR+mkDiv(rightCol,yR,W)
		do local _h,_s=mkToggle(rightCol,'OnClick Mode',yR,W,MA_onClickOn,function(s) MA_onClickOn=s if MA_enabled then maStop() maStart() end onFaChanged() end) UISetters.maOnClick=function(v) _s(v,true) end yR=yR+_h end
		yR=yR+mkDiv(rightCol,yR,W)
		local KBIND_H=44
		local kRow=Instance.new('Frame',rightCol) kRow.Position=UDim2.fromOffset(0,yR) kRow.Size=UDim2.fromOffset(W,KBIND_H) kRow.BackgroundColor3=C_PANEL kRow.BorderSizePixel=0
		local kbar=Instance.new('Frame',kRow) kbar.Size=UDim2.fromOffset(2,KBIND_H) kbar.BackgroundColor3=C_TEXT kbar.BorderSizePixel=0
		mkLbl(kRow,'Keybind',16,4,W-80,14,11,FONT_UI,C_DIM)
		local kbBtn=Instance.new('TextButton',kRow) kbBtn.Position=UDim2.fromOffset(16,22) kbBtn.Size=UDim2.fromOffset(W-32,18) kbBtn.BackgroundColor3=Color3.fromRGB(22,22,22) kbBtn.BorderSizePixel=0 kbBtn.Text='' kbBtn.TextColor3=C_TEXT kbBtn.TextSize=11 kbBtn.FontFace=FONT_UB kbBtn.AutoButtonColor=false mkCorner(kbBtn,3) mkStroke(kbBtn,C_STR)
		yR=yR+KBIND_H yR=yR+mkDiv(rightCol,yR,W)
		local function kbName() if MA_useMouseBtn then if MA_keybindMB==Enum.UserInputType.MouseButton1 then return 'LMB' elseif MA_keybindMB==Enum.UserInputType.MouseButton2 then return 'RMB' else return tostring(MA_keybindMB):gsub('Enum.UserInputType.','') end else return tostring(MA_keybind):gsub('Enum.KeyCode.','') end end
		kbBtn.Text=kbName()
		local waitingKey=false local waitOverlay=nil local dimOverlay=nil
		kbBtn.MouseButton1Click:Connect(function()
			if waitingKey then return end waitingKey=true kbBtn.Text='...'
			dimOverlay=Instance.new('Frame',sgAim) dimOverlay.Size=UDim2.fromScale(1,1) dimOverlay.BackgroundColor3=Color3.new(0,0,0) dimOverlay.BackgroundTransparency=0.6 dimOverlay.BorderSizePixel=0 dimOverlay.ZIndex=98
			local KBW,KBH=748,104
			waitOverlay=Instance.new('Frame',sgAim) waitOverlay.Size=UDim2.fromOffset(KBW,KBH) waitOverlay.AnchorPoint=Vector2.new(0.5,0.5) waitOverlay.Position=UDim2.fromScale(0.5,0.48) waitOverlay.BackgroundColor3=Color3.fromRGB(14,14,14) waitOverlay.BorderSizePixel=0 mkCorner(waitOverlay,8) mkStroke(waitOverlay,C_WHITE) waitOverlay.ZIndex=100
			local kbIcon=Instance.new('ImageLabel',waitOverlay) kbIcon.Size=UDim2.fromOffset(46,46) kbIcon.Position=UDim2.fromOffset(16,(KBH-46)/2) kbIcon.BackgroundTransparency=1 kbIcon.Image=Icons.keybind or '' kbIcon.ImageColor3=C_TEXT kbIcon.ZIndex=101
			local kbLbl=Instance.new('TextLabel',waitOverlay) kbLbl.Size=UDim2.fromOffset(KBW-80,KBH) kbLbl.Position=UDim2.fromOffset(58,0) kbLbl.BackgroundTransparency=1 kbLbl.Text='Press any key to set keybind' kbLbl.TextColor3=C_TEXT kbLbl.TextSize=14 kbLbl.ZIndex=101 kbLbl.FontFace=FONT_UB kbLbl.TextXAlignment=Enum.TextXAlignment.Center kbLbl.TextYAlignment=Enum.TextYAlignment.Center
			local MSW,MSH=460,64
			local mousePopup=Instance.new('Frame',sgAim) mousePopup.Size=UDim2.fromOffset(MSW,MSH) mousePopup.AnchorPoint=Vector2.new(0.5,0.5) mousePopup.Position=UDim2.fromScale(0.5,0.57) mousePopup.BackgroundColor3=Color3.fromRGB(11,11,11) mousePopup.BorderSizePixel=0 mkCorner(mousePopup,8) mkStroke(mousePopup,C_STR) mousePopup.ZIndex=100
			local msIcon=Instance.new('ImageLabel',mousePopup) msIcon.Size=UDim2.fromOffset(26,26) msIcon.Position=UDim2.fromOffset(12,(MSH-26)/2) msIcon.BackgroundTransparency=1 msIcon.Image=Icons.mouse or '' msIcon.ImageColor3=C_DIM msIcon.ZIndex=101
			local msLbl=Instance.new('TextLabel',mousePopup) msLbl.Size=UDim2.fromOffset(MSW-52,MSH) msLbl.Position=UDim2.fromOffset(46,0) msLbl.BackgroundTransparency=1 msLbl.Text='Click LMB / RMB to select mouse buttons' msLbl.TextColor3=C_DIM msLbl.TextSize=11 msLbl.ZIndex=101 msLbl.FontFace=FONT_UI msLbl.TextXAlignment=Enum.TextXAlignment.Center msLbl.TextYAlignment=Enum.TextYAlignment.Center
			task.delay(0.15,function()
				local c1 c1=inputService.InputBegan:Connect(function(inp,gp)
					if not waitingKey then return end
					local t=inp.UserInputType local isMB=t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.MouseButton2 or t==Enum.UserInputType.MouseButton3
					local isK=not gp and inp.KeyCode~=Enum.KeyCode.Unknown
					if isMB then MA_useMouseBtn=true MA_keybindMB=t elseif isK then MA_useMouseBtn=false MA_keybind=inp.KeyCode else return end
					waitingKey=false kbBtn.Text=kbName() if waitOverlay then waitOverlay:Destroy() waitOverlay=nil end if mousePopup then mousePopup:Destroy() end if dimOverlay then dimOverlay:Destroy() dimOverlay=nil end c1:Disconnect()
					if MA_enabled then maStop() maStart() end
				end)
			end)
		end)
		local HB_H=32
		local hbRow=Instance.new('Frame',rightCol) hbRow.Position=UDim2.fromOffset(0,yR) hbRow.Size=UDim2.fromOffset(W,HB_H) hbRow.BackgroundColor3=C_PANEL hbRow.BorderSizePixel=0
		local hbbar=Instance.new('Frame',hbRow) hbbar.Size=UDim2.fromOffset(2,HB_H) hbbar.BackgroundColor3=C_TEXT hbbar.BorderSizePixel=0
		local HBW=60
		local hbHead=Instance.new('TextButton',hbRow) hbHead.Size=UDim2.fromOffset(HBW,HB_H-8) hbHead.Position=UDim2.fromOffset(W/2-HBW-2,4) hbHead.BackgroundColor3=MA_targetHead and C_TEXT or C_DARK hbHead.BorderSizePixel=0 hbHead.Text='HEAD' hbHead.TextColor3=MA_targetHead and C_BG or C_DIM hbHead.TextSize=10 hbHead.FontFace=FONT_UB hbHead.AutoButtonColor=false mkCorner(hbHead,4)
		local hbBody=Instance.new('TextButton',hbRow) hbBody.Size=UDim2.fromOffset(HBW,HB_H-8) hbBody.Position=UDim2.fromOffset(W/2+2,4) hbBody.BackgroundColor3=MA_targetHead and C_DARK or C_TEXT hbBody.BorderSizePixel=0 hbBody.Text='BODY' hbBody.TextColor3=MA_targetHead and C_DIM or C_BG hbBody.TextSize=10 hbBody.FontFace=FONT_UB hbBody.AutoButtonColor=false mkCorner(hbBody,4)
		local function setHB(head) MA_targetHead=head tweenService:Create(hbHead,TI_F,{BackgroundColor3=head and C_TEXT or C_DARK,TextColor3=head and C_BG or C_DIM}):Play() tweenService:Create(hbBody,TI_F,{BackgroundColor3=head and C_DARK or C_TEXT,TextColor3=head and C_DIM or C_BG}):Play() onFaChanged() end
		hbHead.MouseButton1Click:Connect(function() setHB(true) end) hbBody.MouseButton1Click:Connect(function() setHB(false) end) yR=yR+HB_H
		local aimH=math.max(yL,yR)+8 aimPanel.Size=UDim2.fromOffset(AIM_W,AIM_H+1+aimH) aimVert.Size=UDim2.fromOffset(1,aimH) leftCol.Size=UDim2.fromOffset(AIM_HALF,aimH) rightCol.Size=UDim2.fromOffset(AIM_HALF,aimH)
		if faEnabled then faHook() end
		if MA_enabled then maStart() end
		if TB_enabled then tbStart() end
	end
	local function buildRenderGUI()
		local mkToggle=GuiLib.mkToggleRow local mkSlider=GuiLib.mkSliderRow local mkSubSlider=GuiLib.mkSubSlider
		local mkColorP=GuiLib.mkColorPicker local mkSubColor=GuiLib.mkSubColorPicker
		local mkDiv=GuiLib.mkDivider local mkSec=GuiLib.mkSectionLabel
		local mkMulti=GuiLib.mkMultiSelect local mkSingle=GuiLib.mkSingleSelect local mkHeader=GuiLib.mkHeaderPanel
		local sgRend=R.sgRend
		local REND_W=560 local REND_HALF=279 local REND_H=36
		local rendPanel,rendHeader=mkHeader(sgRend,'RENDER',Icons.render,REND_W,REND_H,480,180)
		local rendVert=Instance.new('Frame',rendPanel) rendVert.Position=UDim2.fromOffset(REND_HALF,REND_H+1) rendVert.Size=UDim2.fromOffset(1,999) rendVert.BackgroundColor3=C_STR rendVert.BorderSizePixel=0
		local rL=Instance.new('Frame',rendPanel) rL.Position=UDim2.fromOffset(0,REND_H+1) rL.Size=UDim2.fromOffset(REND_HALF,800) rL.BackgroundTransparency=1 rL.BorderSizePixel=0
		local rR=Instance.new('Frame',rendPanel) rR.Position=UDim2.fromOffset(REND_HALF+1,REND_H+1) rR.Size=UDim2.fromOffset(REND_HALF,800) rR.BackgroundTransparency=1 rR.BorderSizePixel=0
		local RW=REND_HALF local yRL=0 local yRR=0
		yRL=yRL+mkSec(rL,yRL,RW,'SKELETON')
		do local _h,_s=mkToggle(rL,'Skeleton',yRL,RW,skelEnabled,function(s) skelEnabled=s setESPFeature('skeleton',s) onEspChanged() end) UISetters.skelEnabled=function(v) _s(v,true) end yRL=yRL+_h end
		do local _h,_s=mkSubSlider(rL,'Thickness',yRL,RW,1,10,math.clamp(math.round(skelThick*2),1,10),'',function(v) skelThick=v/2 for _,e in Refs.skel do for k,l in e do if k~='HeadDot' then l.Thickness=skelThick end end end onEspChanged() end) UISetters.skelThick=_s yRL=yRL+_h end
		yRL=yRL+(mkSubColor(rL,yRL,RW,'Color',skelColor,function(col) applySkelColor(col) rbSkel=false onEspChanged() end,sgRend,rbSkel))
		yRL=yRL+mkDiv(rL,yRL,RW)
		do local _h,_s=mkToggle(rL,'Head Dot',yRL,RW,skelHeadDot,function(s) skelHeadDot=s if not s then for _,e in Refs.skel do e.HeadDot.Visible=false end end onEspChanged() end) UISetters.skelHeadDot=function(v) _s(v,true) end yRL=yRL+_h end
		do local _h,_s=mkSubSlider(rL,'Size',yRL,RW,1,12,math.clamp(math.round(headDotSize),1,12),'px',function(v) applyHeadDotSize(v) onEspChanged() end) UISetters.headDotSize=_s yRL=yRL+_h end
		do local _h,_s=mkSubSlider(rL,'Transparency',yRL,RW,0,100,math.clamp(math.round(headDotTrans*100),0,100),'%',function(v) applyHeadDotTrans(v/100) onEspChanged() end) UISetters.headDotTrans=_s yRL=yRL+_h end
		yRL=yRL+(mkSubColor(rL,yRL,RW,'Color',headDotColor,function(col) applyHeadDotColor(col) rbHead=false onEspChanged() end,sgRend,rbHead))
		yRL=yRL+mkDiv(rL,yRL,RW) yRL=yRL+mkSec(rL,yRL,RW,'2D BOX')
		do local _h,_s=mkToggle(rL,'2D Box',yRL,RW,box2dEnabled,function(s) box2dEnabled=s setESPFeature('box2d',s) onEspChanged() end) UISetters.box2dEnabled=function(v) _s(v,true) end yRL=yRL+_h end
		do local _h,_s=mkSubSlider(rL,'Thickness',yRL,RW,1,10,math.clamp(math.round(box2dThick*2),1,10),'',function(v) box2dThick=v/2 for _,e in Refs.box2d do for _,l in e do l.Thickness=box2dThick end end onEspChanged() end) UISetters.box2dThick=_s yRL=yRL+_h end
		yRL=yRL+(mkSubColor(rL,yRL,RW,'Color',box2dColor,function(col) applyBox2dColor(col) rbBox2d=false onEspChanged() end,sgRend,rbBox2d))
		yRL=yRL+mkDiv(rL,yRL,RW) yRL=yRL+mkSec(rL,yRL,RW,'3D BOX')
		do local _h,_s=mkToggle(rL,'3D Box',yRL,RW,box3dEnabled,function(s) box3dEnabled=s setESPFeature('box3d',s) onEspChanged() end) UISetters.box3dEnabled=function(v) _s(v,true) end yRL=yRL+_h end
		do local _h,_s=mkSubSlider(rL,'Thickness',yRL,RW,1,10,math.clamp(math.round(box3dThick*2),1,10),'',function(v) box3dThick=v/2 for _,e in Refs.box3d do for _,l in e do l.Thickness=box3dThick end end onEspChanged() end) UISetters.box3dThick=_s yRL=yRL+_h end
		yRL=yRL+(mkSubColor(rL,yRL,RW,'Color',box3dColor,function(col) applyBox3dColor(col) rbBox3d=false onEspChanged() end,sgRend,rbBox3d))
		do local _h,_s=mkToggle(rR,'Name Tag',yRR,RW,tagEnabled,function(s) tagEnabled=s setESPFeature('tag',s) onEspChanged() end) UISetters.tagEnabled=function(v) _s(v,true) end yRR=yRR+_h end
		do local _h,_s=mkToggle(rR,'Weapon ESP',yRR,RW,weaponEnabled,function(s) weaponEnabled=s setESPFeature('weapon',s) onEspChanged() end) UISetters.weapEnabled=function(v) _s(v,true) end yRR=yRR+_h end
		do local _h,_s=mkSubSlider(rR,'Scale',yRR,RW,50,200,math.clamp(math.round(tagScale*100),50,200),'%',function(v) tagScale=v/100 onEspChanged() end) UISetters.tagScale=_s yRR=yRR+_h end
		yRR=yRR+mkMulti(rR,yRR,RW,{'Health','Distance','Name'},{Health=tagShowHealth,Distance=tagShowDist,Name=tagShowName},1,function(state) tagShowHealth=state['Health'] tagShowDist=state['Distance'] tagShowName=state['Name'] onEspChanged() end)
		yRR=yRR+(mkSubColor(rR,yRR,RW,'Name Color',tagNameColor,function(col) tagNameColor=col for _,e in Refs.tag do e.name.TextColor3=col end rbTagName=false onEspChanged() end,sgRend,rbTagName))
		yRR=yRR+mkDiv(rR,yRR,RW)
		yRR=yRR+(mkSubColor(rR,yRR,RW,'Weapon Color',weapColor,function(col) weapColor=col for _,e in Refs.weap do e.lbl.TextColor3=col end rbWeap=false onEspChanged() end,sgRend,rbWeap))
		yRR=yRR+mkDiv(rR,yRR,RW)
		local TAG_FONT_NAMES={'Gotham','Arial','Jura','Scifi'} local TAG_FONT_FAMS={Gotham='GothamSSm',Arial='Arial',Jura='Jura',Scifi='SciFi'}
		local tfRow=Instance.new('Frame',rR) tfRow.Position=UDim2.fromOffset(0,yRR) tfRow.Size=UDim2.fromOffset(RW,28) tfRow.BackgroundColor3=Color3.fromRGB(14,14,14) tfRow.BorderSizePixel=0
		Instance.new('Frame',tfRow).Size=UDim2.fromOffset(2,28)
		tfRow:FindFirstChildWhichIsA('Frame').BackgroundColor3=Color3.fromRGB(220,220,220) tfRow:FindFirstChildWhichIsA('Frame').BorderSizePixel=0
		mkLbl(tfRow,'Tag Font',16,0,RW-80,28,10,FONT_UI,Color3.fromRGB(100,100,100))
		local TBW=math.floor((RW-82)/4)-1 local tagFontBtns={}
		for i,fname in TAG_FONT_NAMES do
			local b=Instance.new('TextButton',tfRow) b.Size=UDim2.fromOffset(TBW,18) b.Position=UDim2.fromOffset(80+(i-1)*(TBW+2),5) b.BackgroundColor3=tagFont==fname and Color3.fromRGB(220,220,220) or Color3.fromRGB(35,35,35) b.TextColor3=tagFont==fname and Color3.fromRGB(8,8,8) or Color3.fromRGB(100,100,100) b.Text=fname b.TextSize=8 b.FontFace=Font.new('rbxasset://fonts/families/'..TAG_FONT_FAMS[fname]..'.json') b.BorderSizePixel=0 b.AutoButtonColor=false mkCorner(b,3) tagFontBtns[fname]=b
			b.MouseButton1Click:Connect(function() tagFont=fname for k,bb in tagFontBtns do bb.BackgroundColor3=k==fname and Color3.fromRGB(220,220,220) or Color3.fromRGB(35,35,35) bb.TextColor3=k==fname and Color3.fromRGB(8,8,8) or Color3.fromRGB(100,100,100) end end)
		end
		yRR=yRR+28 yRR=yRR+mkDiv(rR,yRR,RW)
		do local _h,_s=mkSlider(rR,'Tag BG Trans',yRR,RW,0,100,tagBgTrans,'%',function(v) tagBgTrans=v end) UISetters.tagBgTrans=_s yRR=yRR+_h end
		yRR=yRR+mkDiv(rR,yRR,RW) yRR=yRR+mkSec(rR,yRR,RW,'TRACERS')
		do local _h,_s=mkToggle(rR,'Tracers',yRR,RW,tracerEnabled,function(s) tracerEnabled=s setESPFeature('tracer',s) onEspChanged() end) UISetters.tracerEnabled=function(v) _s(v,true) end yRR=yRR+_h end
		do local _h,_s=mkSubSlider(rR,'Thickness',yRR,RW,1,10,math.clamp(math.round(tracerThick*2),1,10),'',function(v) tracerThick=v/2 for _,l in Refs.tracer do l.Thickness=tracerThick end onEspChanged() end) UISetters.tracerThick=_s yRR=yRR+_h end
		yRR=yRR+(mkSubColor(rR,yRR,RW,'Color',tracerColor,function(col) applyTracerColor(col) rbTracer=false onEspChanged() end,sgRend,rbTracer))
		yRR=yRR+mkDiv(rR,yRR,RW)
		mkSingle(rR,yRR,RW,{'Top','Middle','Bottom'},tracerOrigin,function(v) tracerOrigin=v onEspChanged() end)
		yRR=yRR+mkDiv(rR,yRR,RW) yRR=yRR+mkSec(rR,yRR,RW,'BULLET TRAILS')
		do local _h,_s=mkToggle(rR,'Bullet Trails',yRR,RW,BT.enabled,function(s) BT.enabled=s if s then btStart() else btStop() end onEspChanged() end) UISetters.btEnabled=function(v) _s(v,true) end yRR=yRR+_h end
		do local _h,_s=mkSubSlider(rR,'Duration',yRR,RW,1,100,math.round(BT.duration*10),'s',function(v) BT.duration=v/10 onEspChanged() end) UISetters.btDuration=_s yRR=yRR+_h end
		do local _h,_s=mkSubSlider(rR,'Thickness',yRR,RW,1,20,math.round(BT.thick*2),'',function(v) BT.thick=v/2 onEspChanged() end) UISetters.btThick=_s yRR=yRR+_h end
		yRR=yRR+(mkSubColor(rR,yRR,RW,'Color',BT.color,function(col) BT.color=col rbBT=false onEspChanged() end,sgRend,rbBT))
		yRR=yRR+mkDiv(rR,yRR,RW)
		local rendH=math.max(yRL,yRR)+8 rendPanel.Size=UDim2.fromOffset(REND_W,REND_H+1+rendH)
		rendVert.Size=UDim2.fromOffset(1,rendH) rL.Size=UDim2.fromOffset(REND_HALF,rendH) rR.Size=UDim2.fromOffset(REND_HALF,rendH)
	end
	local function buildHudDisplay()
		local BAR=2 local GAP=4
		local TWEEN_IN=TweenInfo.new(0.18,Enum.EasingStyle.Quad) local TWEEN_OUT=TweenInfo.new(0.12,Enum.EasingStyle.Quad)
		local function isRight() return txtAlign=='Right' end
		local function getBarPos() return isRight() and UDim2.new(1,-BAR,0,0) or UDim2.fromOffset(0,0) end
		local function getTxtX() return isRight() and 0 or BAR+GAP end
		local function holderW(tw) return tw+BAR+GAP end
		local sgHUD=mkSG('HudGUI',9999994)
		local hudHolder=Instance.new('Frame',sgHUD) hudHolder.BackgroundTransparency=1 hudHolder.BorderSizePixel=0 hudHolder.Size=UDim2.fromOffset(0,0) hudHolder.AutomaticSize=Enum.AutomaticSize.XY hudHolder.Visible=false
		local hudLayout=Instance.new('UIListLayout',hudHolder) hudLayout.SortOrder=Enum.SortOrder.LayoutOrder hudLayout.FillDirection=Enum.FillDirection.Vertical hudLayout.HorizontalAlignment=Enum.HorizontalAlignment.Right hudLayout.Padding=UDim.new(0,1)
		local IMG_W=math.round(180*(hudLogoScale/100)) local IMG_H=math.round(IMG_W/3)
		local hudImgFrame=Instance.new('Frame',hudHolder) hudImgFrame.BackgroundTransparency=1 hudImgFrame.BorderSizePixel=0 hudImgFrame.Size=UDim2.fromOffset(IMG_W,IMG_H) hudImgFrame.LayoutOrder=0 hudImgFrame.Visible=hudLogoEnabled
		local hudImgLabel=Instance.new('ImageLabel',hudImgFrame) hudImgLabel.Size=UDim2.fromScale(1,1) hudImgLabel.BackgroundTransparency=1 hudImgLabel.Image=(mainVars and mainVars.mainHudImgUrl~='' and mainVars.mainHudImgUrl) or Icons.hudImg or '' hudImgLabel.ScaleType=Enum.ScaleType.Stretch
		local STATUS_ITEMS={
			{key='weaponEnabled',label='Weapon ESP',col=Color3.fromRGB(255,160,80)},{key='MA_enabled',label='Mouse Anim',col=Color3.fromRGB(180,180,255)},
			{key='tracerEnabled',label='Tracers',col=Color3.fromRGB(180,255,140)},{key='skelEnabled',label='Skeleton',col=Color3.fromRGB(255,220,130)},
			{key='tagEnabled',label='Name Tag',col=Color3.fromRGB(255,170,170)},{key='faEnabled',label='FunAim',col=Color3.fromRGB(255,255,255)},
			{key='box2dEnabled',label='2D Box',col=Color3.fromRGB(130,210,255)},{key='box3dEnabled',label='3D Box',col=Color3.fromRGB(130,255,190)},
			{key='btEnabled',label='Bullet Trail',col=Color3.fromRGB(255,200,100)},
		}
		local STATE_MAP={faEnabled=function() return faEnabled end,MA_enabled=function() return MA_enabled end,skelEnabled=function() return skelEnabled end,box2dEnabled=function() return box2dEnabled end,box3dEnabled=function() return box3dEnabled end,tagEnabled=function() return tagEnabled end,weaponEnabled=function() return weaponEnabled end,tracerEnabled=function() return tracerEnabled end,btEnabled=function() return BT.enabled end}
		local hudRows={}
		local function makeRow(parent,order,col)
			local holder=Instance.new('Frame',parent) holder.LayoutOrder=order holder.BackgroundTransparency=1 holder.BorderSizePixel=0 holder.Size=UDim2.fromOffset(0,0) holder.AutomaticSize=Enum.AutomaticSize.None
			local hbg=Instance.new('Frame',holder) hbg.Size=UDim2.fromScale(1,1) hbg.BackgroundColor3=Color3.new(0,0,0) hbg.BackgroundTransparency=0.5 hbg.BorderSizePixel=0 hbg.Visible=txtBg Instance.new('UICorner',hbg).CornerRadius=UDim.new(0,3)
			local hline=Instance.new('Frame',holder) hline.Size=UDim2.new(1,0,0,1) hline.Position=UDim2.new(0,0,1,-1) hline.BackgroundColor3=Color3.new(0,0,0) hline.BackgroundTransparency=0.85 hline.BorderSizePixel=0
			local bar=Instance.new('Frame',holder) bar.Name='Bar' bar.Size=UDim2.new(0,BAR,1,0) bar.Position=getBarPos() bar.BackgroundColor3=col bar.BorderSizePixel=0 bar.ZIndex=10
			return holder,hbg,bar
		end
		for i,item in STATUS_ITEMS do
			local holder,hbg,bar=makeRow(hudHolder,i,item.col)
			local htxt=Instance.new('TextLabel',holder) htxt.Name='Label' htxt.Position=UDim2.fromOffset(getTxtX(),2) htxt.BackgroundTransparency=1 htxt.Text=item.label htxt.TextSize=txtSize htxt.FontFace=TXT_FONTS[txtFont] or TXT_FONTS.Arial htxt.TextColor3=item.col htxt.RichText=true htxt.AutomaticSize=Enum.AutomaticSize.XY htxt.TextStrokeColor3=Color3.new(0,0,0) htxt.TextStrokeTransparency=0.5
			local hshadow=htxt:Clone() hshadow.Position=UDim2.fromOffset(getTxtX()+1,3) hshadow.TextColor3=Color3.new(0,0,0) hshadow.TextTransparency=0.4 hshadow.TextStrokeTransparency=1 hshadow.ZIndex=htxt.ZIndex-1 hshadow.Parent=holder
			hudRows[item.key]={holder=holder,htxt=htxt,hshadow=hshadow,hbg=hbg,bar=bar,col=item.col,label=item.label,on=false}
		end
		local KDA_ITEMS={{key='kills',label='Eliminations',col=Color3.fromRGB(120,255,120),gray=Color3.fromRGB(120,200,120)},{key='assists',label='Assist',col=Color3.fromRGB(255,255,100),gray=Color3.fromRGB(200,200,100)}}
		local OFFWHITE=Color3.fromRGB(210,210,210) local kdaRows={}
		local kdaLayout=Instance.new('Frame',hudHolder) kdaLayout.Name='KDA' kdaLayout.BackgroundTransparency=1 kdaLayout.BorderSizePixel=0 kdaLayout.AutomaticSize=Enum.AutomaticSize.XY kdaLayout.LayoutOrder=999
		local kdaLL=Instance.new('UIListLayout',kdaLayout) kdaLL.SortOrder=Enum.SortOrder.LayoutOrder kdaLL.FillDirection=Enum.FillDirection.Vertical kdaLL.Padding=UDim.new(0,1) kdaLL.HorizontalAlignment=isRight() and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
		for i,item in KDA_ITEMS do
			local holder,hbg,bar=makeRow(kdaLayout,i,item.col)
			local htxt=Instance.new('TextLabel',holder) htxt.Position=UDim2.fromOffset(getTxtX(),2) htxt.BackgroundTransparency=1 htxt.Text='' htxt.TextSize=txtSize htxt.FontFace=TXT_FONTS[txtFont] or TXT_FONTS.Arial htxt.TextColor3=Color3.new(1,1,1) htxt.RichText=true htxt.AutomaticSize=Enum.AutomaticSize.XY htxt.TextStrokeColor3=Color3.new(0,0,0) htxt.TextStrokeTransparency=0.5
			kdaRows[item.key]={holder=holder,htxt=htxt,hbg=hbg,bar=bar,item=item}
		end
		local function toHex(c) return string.format('#%02X%02X%02X',math.floor(c.R*255),math.floor(c.G*255),math.floor(c.B*255)) end
		local function updateKdaRows()
			local rowH=txtSize+(txtBg and 5 or 3) kdaLL.HorizontalAlignment=isRight() and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
			for _,r in kdaRows do local item=r.item local mc=toHex(item.col) local gc=toHex(item.gray) local bc=toHex(OFFWHITE) r.htxt.Text=item.label..': <font color="'..mc..'">'..kda[item.key]..'</font> <font color="'..bc..'">['..  '</font><font color="'..gc..'">'..kda[item.key..'Total']..'</font><font color="'..bc..'">]</font>' r.htxt.TextSize=txtSize r.htxt.FontFace=TXT_FONTS[txtFont] or TXT_FONTS.Arial r.htxt.TextStrokeTransparency=txtStroke and 0.5 or 1 r.hbg.Visible=txtBg r.hbg.BackgroundTransparency=txtBgTrans/100 r.bar.Position=getBarPos() r.htxt.Position=UDim2.fromOffset(getTxtX(),2) r.holder.Size=UDim2.fromOffset(holderW(r.htxt.TextBounds.X),rowH) r.holder.Visible=kdaEnabled end
		end
		local function applyAlign()
			hudLayout.HorizontalAlignment=isRight() and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
			kdaLL.HorizontalAlignment=isRight() and Enum.HorizontalAlignment.Right or Enum.HorizontalAlignment.Left
			local bp=getBarPos() local tx=getTxtX()
			for _,r in hudRows do r.bar.Position=bp r.htxt.Position=UDim2.fromOffset(tx,2) r.hshadow.Position=UDim2.fromOffset(tx+1,3) end
			for _,r in kdaRows do r.bar.Position=bp r.htxt.Position=UDim2.fromOffset(tx,2) end
		end
		_EXIT_THREADS[#_EXIT_THREADS+1]=task.spawn(function()
			while true do
				task.wait(0.05) if txtRainbow then rainbowHue=(tick()*0.2)%1 end
				for i,item in STATUS_ITEMS do
					local r=hudRows[item.key] if not r then continue end
					local on=STATE_MAP[item.key] and STATE_MAP[item.key]()
					if on and not r.on then r.on=true local col=txtRainbow and Color3.fromHSV((rainbowHue+i*0.09)%1,0.7,1) or r.col r.htxt.TextColor3=col r.htxt.TextSize=txtSize r.htxt.FontFace=TXT_FONTS[txtFont] or TXT_FONTS.Arial r.htxt.TextStrokeTransparency=txtStroke and 0.5 or 1 r.hshadow.TextStrokeTransparency=1 r.bar.BackgroundColor3=col r.hbg.Visible=txtBg r.hbg.BackgroundTransparency=txtBgTrans/100 local rowH=txtSize+(txtBg and 5 or 3) local hw=math.max(r.htxt.TextBounds.X+12,60) tweenService:Create(r.holder,TWEEN_IN,{Size=UDim2.fromOffset(hw,rowH)}):Play()
					elseif on and r.on then local col=txtRainbow and Color3.fromHSV((rainbowHue+i*0.09)%1,0.7,1) or r.col r.htxt.TextColor3=col r.htxt.TextSize=txtSize r.htxt.FontFace=TXT_FONTS[txtFont] or TXT_FONTS.Arial r.htxt.TextStrokeTransparency=txtStroke and 0.5 or 1 r.hshadow.TextStrokeTransparency=1 r.bar.BackgroundColor3=col r.bar.Position=getBarPos() r.htxt.Position=UDim2.fromOffset(getTxtX(),2) r.hshadow.Position=UDim2.fromOffset(getTxtX()+1,3) r.hbg.Visible=txtBg r.hbg.BackgroundTransparency=txtBgTrans/100 local rowH=txtSize+(txtBg and 5 or 3) r.holder.Size=UDim2.fromOffset(math.max(r.htxt.TextBounds.X+12,60),rowH)
					elseif not on and r.on then r.on=false tweenService:Create(r.holder,TWEEN_OUT,{Size=UDim2.fromOffset(0,0)}):Play() end
				end
				updateKdaRows()
				if txtEnabled then local _vp=gameCamera.ViewportSize local _sz=hudHolder.AbsoluteSize local _px=math.round((_vp.X-_sz.X)*(txtX/100)) local _py=math.round((_vp.Y-_sz.Y)*(txtY/100)) hudHolder.Position=UDim2.fromOffset(_px,_py) end
				hudHolder.Visible=txtEnabled
			end
		end)
		return hudHolder,hudRows,kdaRows,hudImgFrame,updateKdaRows,applyAlign,getBarPos,getTxtX,holderW,TWEEN_IN,TWEEN_OUT
	end
	local function makeTextWidgets(con,W,ybox)
		local TI2=TweenInfo.new(0.12,Enum.EasingStyle.Quad) local h={}
		function h.sec(lbl) local H=22 local f=Instance.new('Frame',con) f.Position=UDim2.fromOffset(0,ybox[1]) f.Size=UDim2.fromOffset(W,H) f.BackgroundColor3=Color3.fromRGB(11,11,11) f.BorderSizePixel=0 local b=Instance.new('Frame',f) b.Size=UDim2.fromOffset(2,H) b.BackgroundColor3=Color3.fromRGB(220,220,220) b.BorderSizePixel=0 local l=Instance.new('TextLabel',f) l.Position=UDim2.fromOffset(10,0) l.Size=UDim2.fromOffset(W-10,H) l.BackgroundTransparency=1 l.Text=lbl l.TextColor3=Color3.fromRGB(100,100,100) l.TextSize=11 l.FontFace=FONT_UB l.TextXAlignment=Enum.TextXAlignment.Left ybox[1]=ybox[1]+H end
		function h.div() local f=Instance.new('Frame',con) f.Position=UDim2.fromOffset(0,ybox[1]) f.Size=UDim2.fromOffset(W,1) f.BackgroundColor3=Color3.fromRGB(38,38,38) f.BorderSizePixel=0 ybox[1]=ybox[1]+1 end
		function h.tog(lbl,def,fn)
			local H=30 local row=Instance.new('Frame',con) row.Position=UDim2.fromOffset(0,ybox[1]) row.Size=UDim2.fromOffset(W,H) row.BackgroundColor3=Color3.fromRGB(14,14,14) row.BorderSizePixel=0
			local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=def and Color3.fromRGB(220,220,220) or Color3.fromRGB(38,38,38) bar.BorderSizePixel=0
			local lb=Instance.new('TextLabel',row) lb.Position=UDim2.fromOffset(14,0) lb.Size=UDim2.fromOffset(W-60,H) lb.BackgroundTransparency=1 lb.Text=lbl lb.TextColor3=def and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100) lb.TextSize=11 lb.FontFace=FONT_UI lb.TextXAlignment=Enum.TextXAlignment.Left
			local tbg=Instance.new('Frame',row) tbg.Position=UDim2.fromOffset(W-42,5) tbg.Size=UDim2.fromOffset(34,20) tbg.BackgroundColor3=def and Color3.fromRGB(220,220,220) or Color3.fromRGB(38,38,38) tbg.BorderSizePixel=0 mkCorner(tbg,99)
			local kn=Instance.new('Frame',tbg) kn.Size=UDim2.fromOffset(16,16) kn.Position=def and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2) kn.BackgroundColor3=def and Color3.fromRGB(8,8,8) or Color3.fromRGB(180,180,180) kn.BorderSizePixel=0 mkCorner(kn,99)
			local st=def local btn=Instance.new('TextButton',row) btn.Size=UDim2.fromScale(1,1) btn.BackgroundTransparency=1 btn.Text='' btn.ZIndex=5
			local function set(v) st=v tweenService:Create(tbg,TI2,{BackgroundColor3=v and Color3.fromRGB(220,220,220) or Color3.fromRGB(38,38,38)}):Play() tweenService:Create(kn,TI2,{Position=v and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2),BackgroundColor3=v and Color3.fromRGB(8,8,8) or Color3.fromRGB(180,180,180)}):Play() tweenService:Create(bar,TI2,{BackgroundColor3=v and Color3.fromRGB(220,220,220) or Color3.fromRGB(38,38,38)}):Play() tweenService:Create(lb,TI2,{TextColor3=v and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100)}):Play() end
			btn.MouseButton1Click:Connect(function() set(not st) fn(st) end) ybox[1]=ybox[1]+H return set
		end
		function h.sld(lbl,minV,maxV,defV,sfx,fn)
			local H=40 local row=Instance.new('Frame',con) row.Position=UDim2.fromOffset(0,ybox[1]) row.Size=UDim2.fromOffset(W,H) row.BackgroundColor3=Color3.fromRGB(14,14,14) row.BorderSizePixel=0
			Instance.new('Frame',row).Size=UDim2.fromOffset(2,H) local _b=row:FindFirstChildOfClass('Frame') if _b then _b.BackgroundColor3=Color3.fromRGB(220,220,220) _b.BorderSizePixel=0 end
			local lb=Instance.new('TextLabel',row) lb.Position=UDim2.fromOffset(14,4) lb.Size=UDim2.fromOffset(W-80,14) lb.BackgroundTransparency=1 lb.Text=lbl lb.TextColor3=Color3.fromRGB(100,100,100) lb.TextSize=11 lb.FontFace=FONT_UI lb.TextXAlignment=Enum.TextXAlignment.Left
			local vl=Instance.new('TextLabel',row) vl.Size=UDim2.fromOffset(W-4,14) vl.Position=UDim2.fromOffset(0,4) vl.BackgroundTransparency=1 vl.Text=tostring(defV)..(sfx or '') vl.TextColor3=Color3.fromRGB(220,220,220) vl.TextSize=11 vl.FontFace=FONT_UB vl.TextXAlignment=Enum.TextXAlignment.Right
			local tr=Instance.new('Frame',row) tr.Position=UDim2.fromOffset(14,22) tr.Size=UDim2.fromOffset(W-28,4) tr.BackgroundColor3=Color3.fromRGB(28,28,28) tr.BorderSizePixel=0 mkCorner(tr,2)
			local fi=Instance.new('Frame',tr) fi.Size=UDim2.fromScale((defV-minV)/(maxV-minV),1) fi.BackgroundColor3=Color3.fromRGB(220,220,220) fi.BorderSizePixel=0 mkCorner(fi,2)
			local kn=Instance.new('Frame',tr) kn.Size=UDim2.fromOffset(12,12) kn.Position=UDim2.new((defV-minV)/(maxV-minV),-6,0.5,-6) kn.BackgroundColor3=Color3.fromRGB(220,220,220) kn.BorderSizePixel=0 mkCorner(kn,99)
			local dr=false
			local function upd(ax) local p=math.clamp((ax-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1) local v=math.round(minV+p*(maxV-minV)) local f2=(v-minV)/(maxV-minV) fi.Size=UDim2.fromScale(f2,1) kn.Position=UDim2.new(f2,-6,0.5,-6) vl.Text=tostring(v)..(sfx or '') fn(v) end
			tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true upd(i.Position.X) end end)
			tr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
			kn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true end end)
			kn.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end)
			inputService.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then upd(i.Position.X) end end)
			local function set(v) v=math.clamp(math.round(v),minV,maxV) local fp=(v-minV)/(maxV-minV) fi.Size=UDim2.fromScale(fp,1) kn.Position=UDim2.new(fp,-6,0.5,-6) vl.Text=tostring(v)..(sfx or '') end
			ybox[1]=ybox[1]+H return set
		end
		function h.drop(lbl,opts,def,fn)
			local H=30 local isOpen=false local cur=def
			local row=Instance.new('Frame',con) row.Position=UDim2.fromOffset(0,ybox[1]) row.Size=UDim2.fromOffset(W,H) row.BackgroundColor3=Color3.fromRGB(14,14,14) row.BorderSizePixel=0 row.ClipsDescendants=false row.ZIndex=50
			local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=Color3.fromRGB(220,220,220) bar.BorderSizePixel=0 bar.ZIndex=50
			local lb=Instance.new('TextLabel',row) lb.Position=UDim2.fromOffset(14,0) lb.Size=UDim2.fromOffset(W-80,H) lb.BackgroundTransparency=1 lb.Text=lbl lb.TextColor3=Color3.fromRGB(100,100,100) lb.TextSize=11 lb.FontFace=FONT_UI lb.TextXAlignment=Enum.TextXAlignment.Left lb.ZIndex=50
			local vl=Instance.new('TextLabel',row) vl.Size=UDim2.fromOffset(W-30,H) vl.Position=UDim2.fromOffset(0,0) vl.BackgroundTransparency=1 vl.Text=cur vl.TextColor3=Color3.fromRGB(220,220,220) vl.TextSize=11 vl.FontFace=FONT_UB vl.TextXAlignment=Enum.TextXAlignment.Right vl.ZIndex=50
			local arr=Instance.new('TextLabel',row) arr.Size=UDim2.fromOffset(W-6,H) arr.Position=UDim2.fromOffset(0,0) arr.BackgroundTransparency=1 arr.Text='v' arr.TextColor3=Color3.fromRGB(70,70,70) arr.TextSize=10 arr.FontFace=FONT_UB arr.TextXAlignment=Enum.TextXAlignment.Right arr.ZIndex=50
			local df=Instance.new('Frame',row) df.Position=UDim2.fromOffset(0,H) df.Size=UDim2.fromOffset(W,#opts*26) df.BackgroundColor3=Color3.fromRGB(12,12,12) df.BorderSizePixel=0 df.Visible=false df.ZIndex=200 mkCorner(df,4) mkStroke(df,Color3.fromRGB(38,38,38))
			for i,opt in opts do
				local ob=Instance.new('TextButton',df) ob.Size=UDim2.fromOffset(W,24) ob.Position=UDim2.fromOffset(0,(i-1)*26) ob.BackgroundColor3=opt==cur and Color3.fromRGB(30,30,30) or Color3.fromRGB(12,12,12) ob.BorderSizePixel=0 ob.Text=opt ob.TextColor3=opt==cur and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100) ob.TextSize=11 ob.FontFace=FONT_UI ob.AutoButtonColor=false ob.ZIndex=201
				ob.MouseEnter:Connect(function() if opt~=cur then ob.BackgroundColor3=Color3.fromRGB(22,22,22) end end)
				ob.MouseLeave:Connect(function() ob.BackgroundColor3=opt==cur and Color3.fromRGB(30,30,30) or Color3.fromRGB(12,12,12) end)
				ob.MouseButton1Click:Connect(function() cur=opt vl.Text=opt for _,ch in df:GetChildren() do if ch:IsA('TextButton') then ch.BackgroundColor3=ch.Text==opt and Color3.fromRGB(30,30,30) or Color3.fromRGB(12,12,12) ch.TextColor3=ch.Text==opt and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100) end end isOpen=false df.Visible=false arr.Text='v' fn(opt) end)
			end
			local btn=Instance.new('TextButton',row) btn.Size=UDim2.fromScale(1,1) btn.BackgroundTransparency=1 btn.Text='' btn.ZIndex=60
			btn.MouseButton1Click:Connect(function() isOpen=not isOpen df.Visible=isOpen arr.Text=isOpen and '^' or 'v' end)
			local function set(v) cur=v vl.Text=v for _,ch in df:GetChildren() do if ch:IsA('TextButton') then ch.BackgroundColor3=ch.Text==v and Color3.fromRGB(30,30,30) or Color3.fromRGB(12,12,12) ch.TextColor3=ch.Text==v and Color3.fromRGB(220,220,220) or Color3.fromRGB(100,100,100) end end end
			ybox[1]=ybox[1]+H return set
		end
		return h
	end
	local function buildTextPanel(hudHolder,hudRows,hudImgFrame,applyAlign,saveAndNotify)
		local sgTxt=mkSG('TextGUI',9999995) local TW,TH=220,36 local W=TW local ybox={0}
		local panel=Instance.new('Frame',sgTxt) panel.Position=UDim2.fromOffset(1060,180) panel.BackgroundColor3=Color3.fromRGB(8,8,8) panel.BorderSizePixel=0 panel.Active=true mkCorner(panel,10) mkStroke(panel,Color3.fromRGB(38,38,38))
		local header=Instance.new('Frame',panel) header.Size=UDim2.fromOffset(TW,TH) header.BackgroundColor3=Color3.fromRGB(14,14,14) header.BorderSizePixel=0 header.Active=true mkCorner(header,10)
		local hfix=Instance.new('Frame',header) hfix.Size=UDim2.fromOffset(TW,10) hfix.Position=UDim2.fromOffset(0,TH-10) hfix.BackgroundColor3=Color3.fromRGB(14,14,14) hfix.BorderSizePixel=0
		local hgrad=Instance.new('UIGradient',header) hgrad.Rotation=180
		_EXIT_THREADS[#_EXIT_THREADS+1]=task.spawn(function() local t=0 while true do runService.RenderStepped:Wait() t=t+0.003 local s=math.sin(t)*0.5+0.5 local v=math.round(28+s*16) hgrad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(v,v,v)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(14,14,14)),ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,8))}) end end)
		local hdiv=Instance.new('Frame',panel) hdiv.Size=UDim2.fromOffset(TW,1) hdiv.Position=UDim2.fromOffset(0,TH) hdiv.BackgroundColor3=Color3.fromRGB(38,38,38) hdiv.BorderSizePixel=0
		local hicon=Instance.new('ImageLabel',header) hicon.Size=UDim2.fromOffset(18,18) hicon.Position=UDim2.fromOffset(10,(TH-18)/2) hicon.BackgroundTransparency=1 hicon.Image=Icons.hud or '' hicon.ImageColor3=Color3.fromRGB(220,220,220)
		local htitle=Instance.new('TextLabel',header) htitle.Position=UDim2.fromOffset(34,0) htitle.Size=UDim2.fromOffset(TW-50,TH) htitle.BackgroundTransparency=1 htitle.Text='TEXT' htitle.TextColor3=Color3.fromRGB(225,225,225) htitle.TextSize=14 htitle.FontFace=FONT_H htitle.TextXAlignment=Enum.TextXAlignment.Left
		local isDrag=false local dragSt=Vector2.zero local dragOr=UDim2.fromOffset(0,0)
		header.InputBegan:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end isDrag=true dragSt=Vector2.new(i.Position.X,i.Position.Y) dragOr=panel.Position end)
		_EXIT_CONNS[#_EXIT_CONNS+1]=inputService.InputChanged:Connect(function(i) if not isDrag or i.UserInputType~=Enum.UserInputType.MouseMovement then return end local d=Vector2.new(i.Position.X,i.Position.Y)-dragSt panel.Position=UDim2.fromOffset(dragOr.X.Offset+d.X,dragOr.Y.Offset+d.Y) end)
		_EXIT_CONNS[#_EXIT_CONNS+1]=inputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then isDrag=false end end)
		local con=Instance.new('Frame',panel) con.Position=UDim2.fromOffset(0,TH+1) con.Size=UDim2.fromOffset(TW,10) con.BackgroundTransparency=1 con.BorderSizePixel=0
		local wg=makeTextWidgets(con,W,ybox)
		wg.sec('DISPLAY')
		UISetters.txtEnabled=wg.tog('Enable HUD',txtEnabled,function(s) txtEnabled=s if not s then hudHolder.Visible=false end end)
		wg.div() UISetters.txtX=wg.sld('X Position',0,100,math.clamp(txtX,0,100),'%',function(v) txtX=v end)
		wg.div() UISetters.txtY=wg.sld('Y Position',0,100,math.clamp(txtY,0,100),'%',function(v) txtY=v end)
		wg.div() wg.sec('FONT')
		local BW2=math.floor((W-16)/3)-1
		local fRow=Instance.new('Frame',con) fRow.Position=UDim2.fromOffset(0,ybox[1]) fRow.Size=UDim2.fromOffset(W,28) fRow.BackgroundColor3=Color3.fromRGB(14,14,14) fRow.BorderSizePixel=0 Instance.new('Frame',fRow).Size=UDim2.fromOffset(2,28)
		local fontFams={Gotham='GothamSSm',Arial='Arial',Scifi='SciFi'} local fontBtns={}
		for i,fname in {'Gotham','Arial','Scifi'} do
			local b=Instance.new('TextButton',fRow) b.Size=UDim2.fromOffset(BW2,18) b.Position=UDim2.fromOffset(4+(i-1)*(BW2+2),5) b.BackgroundColor3=txtFont==fname and Color3.fromRGB(220,220,220) or Color3.fromRGB(35,35,35) b.TextColor3=txtFont==fname and Color3.fromRGB(8,8,8) or Color3.fromRGB(100,100,100) b.Text=fname b.TextSize=8 b.FontFace=Font.new('rbxasset://fonts/families/'..fontFams[fname]..'.json') b.BorderSizePixel=0 b.AutoButtonColor=false mkCorner(b,3) fontBtns[fname]=b
			b.MouseButton1Click:Connect(function() txtFont=fname for k,bb in fontBtns do bb.BackgroundColor3=k==fname and Color3.fromRGB(220,220,220) or Color3.fromRGB(35,35,35) bb.TextColor3=k==fname and Color3.fromRGB(8,8,8) or Color3.fromRGB(100,100,100) end saveAndNotify() end)
		end
		ybox[1]=ybox[1]+28 wg.div()
		UISetters.txtSize=wg.sld('Text Size',8,30,txtSize,'px',function(v) txtSize=v saveAndNotify() end)
		wg.div() wg.sec('STYLE')
		UISetters.txtRainbow=wg.tog('Rainbow',txtRainbow,function(s) txtRainbow=s if not s then for _,r in hudRows do r.htxt.TextColor3=r.col end end saveAndNotify() end)
		wg.div() UISetters.txtStroke=wg.tog('Text Stroke',txtStroke,function(s) txtStroke=s saveAndNotify() end)
		wg.div() wg.sec('BACKGROUND')
		UISetters.txtBg=wg.tog('Show Background',txtBg,function(s) txtBg=s saveAndNotify() end)
		wg.div() UISetters.txtBgTrans=wg.sld('Transparency',0,100,txtBgTrans,'%',function(v) txtBgTrans=v saveAndNotify() end)
		wg.div() wg.sec('ALIGN')
		UISetters.txtAlign=wg.drop('Side',{'Left','Right'},txtAlign,function(v) txtAlign=v applyAlign() saveAndNotify() end)
		wg.div() wg.sec('INDICATORS')
		UISetters.kdaEnabled=wg.tog('Kill / Assist Counter',kdaEnabled,function(s) kdaEnabled=s saveAndNotify() end)
		wg.div() UISetters.hudLogoEnabled=wg.tog('Logo',hudLogoEnabled,function(s) hudLogoEnabled=s hudImgFrame.Visible=s saveAndNotify() end)
		wg.div() UISetters.hudLogoScale=wg.sld('Logo Scale',50,200,hudLogoScale,'%',function(v) hudLogoScale=v local w=math.round(180*(v/100)) hudImgFrame.Size=UDim2.fromOffset(w,math.round(w/3)) saveAndNotify() end)
		con.Size=UDim2.fromOffset(TW,ybox[1]+8) panel.Size=UDim2.fromOffset(TW,TH+1+ybox[1]+8) applyAlign()
	end
	local function buildTextGUI()
		local hudHolder,hudRows,_kdaRows,hudImgFrame,_updateKda,applyAlign=buildHudDisplay()
		local function saveAndNotify() saveAll() notif.showAction('Save config?','Save',function() notif.showInfo('Saved!',2,Icons.info) end,6,Icons.info) end
		buildTextPanel(hudHolder,hudRows,hudImgFrame,applyAlign,saveAndNotify)
	end
	entitylib.start()
	return {
		entitylib      = entitylib,
		saveAll        = saveAll,
		applyConfig    = applyConfig,
		applyConfigTable = applyConfigTable,
		applyUIState   = applyUIState,
		buildAimGUI    = buildAimGUI,
		buildRenderGUI = buildRenderGUI,
		buildTextGUI   = buildTextGUI,
		faHook         = faHook,
		faUnhook       = faUnhook,
		maStart        = maStart,
		maStop         = maStop,
		btStart        = btStart,
		btStop         = btStop,
		tbStop         = function() if tbStop_ref then tbStop_ref() end end,
		makeFovRing    = makeFovRing,
		makeMAFovRing  = makeMAFovRing,
		Refs           = Refs,
		UISetters      = UISetters,
		isConfigBroken = isConfigBroken,
		notif          = notif,
		cleanup        = cleanup,
		getFovRing     = function() return fovRing end,
		getMaFovRing   = function() return maFovRing end,
		getFaEnabled   = function() return faEnabled end,
		getMAEnabled   = function() return MA_enabled end,
		setScreenGuis  = function(sa,sr,tg)
			R.sgAim=sa R.sgRend=sr tagGui=tg
			notif=GuiLib.mkNotifSystem(sa) R.notif=notif
		end,
		remakeFovRings = function()
			if faEnabled then makeFovRing() end
			if MA_enabled then makeMAFovRing() end
		end,
	}
end
