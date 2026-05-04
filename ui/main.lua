local GuiLib = {}

local cloneref     = cloneref or function(o) return o end
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local runService   = cloneref(game:GetService('RunService'))
local coreGui      = cloneref(game:GetService('CoreGui'))
local lplr         = cloneref(game:GetService('Players')).LocalPlayer
local threadfix    = setthreadidentity and true or false

local FONT_H  = Font.new('rbxasset://fonts/families/Montserrat.json',Enum.FontWeight.SemiBold)
local FONT_UI = Font.new('rbxasset://fonts/families/BuilderExtended.json')
local FONT_UB = Font.new('rbxasset://fonts/families/BuilderExtended.json',Enum.FontWeight.Bold)

local C_BG    = Color3.fromRGB(8,8,8)
local C_PANEL = Color3.fromRGB(14,14,14)
local C_HOVER = Color3.fromRGB(20,20,20)
local C_SUB   = Color3.fromRGB(11,11,11)
local C_STR   = Color3.fromRGB(38,38,38)
local C_DIM   = Color3.fromRGB(100,100,100)
local C_TEXT  = Color3.fromRGB(220,220,220)
local C_WHITE = Color3.fromRGB(255,255,255)
local C_DARK  = Color3.fromRGB(50,50,50)
local TI_F    = TweenInfo.new(0.14,Enum.EasingStyle.Quad)
local TI_M    = TweenInfo.new(0.22,Enum.EasingStyle.Quad)
local INDENT  = 12

GuiLib.C_BG    = C_BG
GuiLib.C_PANEL = C_PANEL
GuiLib.C_STR   = C_STR
GuiLib.C_DIM   = C_DIM
GuiLib.C_TEXT  = C_TEXT
GuiLib.C_WHITE = C_WHITE
GuiLib.C_DARK  = C_DARK
GuiLib.TI_F    = TI_F
GuiLib.TI_M    = TI_M
GuiLib.FONT_H  = FONT_H
GuiLib.FONT_UI = FONT_UI
GuiLib.FONT_UB = FONT_UB

local function mkCorner(p,r) Instance.new('UICorner',p).CornerRadius=UDim.new(0,r or 6) end
local function mkStroke(p,col,t) local s=Instance.new('UIStroke',p) s.Color=col or C_STR s.Thickness=t or 1 return s end
local function mkLbl(parent,txt,x,y,w,h,sz,font,col)
	local l=Instance.new('TextLabel',parent)
	l.Position=UDim2.fromOffset(x,y) l.Size=UDim2.fromOffset(w,h)
	l.BackgroundTransparency=1 l.Text=txt l.TextColor3=col or C_TEXT
	l.TextSize=sz or 11 l.FontFace=font or FONT_UI l.TextXAlignment=Enum.TextXAlignment.Left
	return l
end

GuiLib.mkCorner = mkCorner
GuiLib.mkStroke = mkStroke
GuiLib.mkLbl    = mkLbl

function GuiLib.mkDivider(parent,yPos,W)
	local f=Instance.new('Frame',parent)
	f.Position=UDim2.fromOffset(0,yPos) f.Size=UDim2.fromOffset(W,1)
	f.BackgroundColor3=C_STR f.BorderSizePixel=0
	return 1
end

function GuiLib.mkSectionLabel(parent,yPos,W,label)
	local H=22
	local f=Instance.new('Frame',parent)
	f.Position=UDim2.fromOffset(0,yPos) f.Size=UDim2.fromOffset(W,H)
	f.BackgroundColor3=Color3.fromRGB(11,11,11) f.BorderSizePixel=0
	local b=Instance.new('Frame',f) b.Size=UDim2.fromOffset(2,H) b.BackgroundColor3=C_TEXT b.BorderSizePixel=0
	mkLbl(f,label,14,0,W,H,11,FONT_UB,C_DIM)
	return H
end

function GuiLib.mkToggleRow(parent,label,yPos,W,default,onToggle)
	local H=30
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0
	local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H)
	bar.BackgroundColor3=default and C_TEXT or C_STR bar.BorderSizePixel=0
	local lbl=mkLbl(row,label,16,0,W-50,H,11,FONT_UI,default and C_TEXT or C_DIM)
	local togBg=Instance.new('Frame',row)
	togBg.Position=UDim2.fromOffset(W-42,5) togBg.Size=UDim2.fromOffset(34,20)
	togBg.BackgroundColor3=default and C_TEXT or C_STR togBg.BorderSizePixel=0 mkCorner(togBg,99)
	local glow=mkStroke(togBg,default and C_WHITE or C_STR)
	local knob=Instance.new('Frame',togBg) knob.Size=UDim2.fromOffset(16,16)
	knob.Position=default and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2)
	knob.BackgroundColor3=default and C_BG or Color3.fromRGB(180,180,180) knob.BorderSizePixel=0 mkCorner(knob,99)
	local state=default
	local btn=Instance.new('TextButton',row) btn.Size=UDim2.fromScale(1,1)
	btn.BackgroundTransparency=1 btn.Text='' btn.ZIndex=5
	btn.MouseButton1Click:Connect(function()
		state=not state
		tweenService:Create(togBg,TI_F,{BackgroundColor3=state and C_TEXT or C_STR}):Play()
		tweenService:Create(glow,TI_F,{Color=state and C_WHITE or C_STR}):Play()
		tweenService:Create(knob,TI_F,{Position=state and UDim2.fromOffset(16,2) or UDim2.fromOffset(2,2),
			BackgroundColor3=state and C_BG or Color3.fromRGB(180,180,180)}):Play()
		tweenService:Create(bar,TI_F,{BackgroundColor3=state and C_TEXT or C_STR}):Play()
		tweenService:Create(lbl,TI_F,{TextColor3=state and C_TEXT or C_DIM}):Play()
		onToggle(state)
	end)
	row.MouseEnter:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_HOVER}):Play() end)
	row.MouseLeave:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_PANEL}):Play() end)
	return H
end

local function buildSlider(row,bar,W,minV,maxV,defV,suffix,onChange,isSubStyle)
	local valLbl=mkLbl(row,'',0,2,W-4,14,isSubStyle and 10 or 11,FONT_UB,isSubStyle and Color3.fromRGB(155,155,155) or C_TEXT)
	valLbl.TextXAlignment=Enum.TextXAlignment.Right
	valLbl.Text=tostring(defV)..(suffix or '')
	local indent=isSubStyle and INDENT+8 or 16
	local TW=W-indent-(isSubStyle and 16 or 16)
	local trackBg=Instance.new('Frame',row)
	trackBg.Position=UDim2.fromOffset(indent,isSubStyle and 20 or 20)
	trackBg.Size=UDim2.fromOffset(TW,4)
	trackBg.BackgroundColor3=Color3.fromRGB(28,28,28) trackBg.BorderSizePixel=0 mkCorner(trackBg,2)
	local fill=Instance.new('Frame',trackBg)
	fill.Size=UDim2.fromScale((defV-minV)/(maxV-minV),1)
	fill.BackgroundColor3=isSubStyle and Color3.fromRGB(75,75,75) or C_TEXT
	fill.BorderSizePixel=0 mkCorner(fill,2)
	if not isSubStyle then
		Instance.new('UIGradient',fill).Color=ColorSequence.new(Color3.fromRGB(140,140,140),C_WHITE)
	end
	local knob=Instance.new('Frame',trackBg)
	knob.Size=UDim2.fromOffset(isSubStyle and 10 or 13,isSubStyle and 10 or 13)
	local kOff=isSubStyle and -5 or -6
	knob.Position=UDim2.new((defV-minV)/(maxV-minV),kOff,0.5,kOff)
	knob.BackgroundColor3=Color3.fromRGB(isSubStyle and 175 or 230,isSubStyle and 175 or 230,isSubStyle and 175 or 230)
	knob.BorderSizePixel=0 mkCorner(knob,99)
	mkStroke(knob,Color3.fromRGB(200,200,200))
	local dragging=false
	local function update(absX)
		local rel=math.clamp(absX-trackBg.AbsolutePosition.X,0,trackBg.AbsoluteSize.X)
		local pct=rel/trackBg.AbsoluteSize.X
		local val=math.round(minV+pct*(maxV-minV))
		local fp=(val-minV)/(maxV-minV)
		fill.Size=UDim2.fromScale(fp,1)
		knob.Position=UDim2.new(fp,kOff,0.5,kOff)
		valLbl.Text=tostring(val)..(suffix or '')
		onChange(val)
	end
	trackBg.InputBegan:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end dragging=true update(i.Position.X) end)
	trackBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
	knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true end end)
	knob.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
	inputService.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then update(i.Position.X) end end)
end

function GuiLib.mkSliderRow(parent,label,yPos,W,minV,maxV,defV,suffix,onChange)
	local H=40
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0
	local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=C_TEXT bar.BorderSizePixel=0
	mkLbl(row,label,16,4,W-80,14,11,FONT_UI,C_DIM)
	buildSlider(row,bar,W,minV,maxV,defV,suffix,onChange,false)
	row.MouseEnter:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_HOVER}):Play() end)
	row.MouseLeave:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_PANEL}):Play() end)
	return H
end

function GuiLib.mkSubSlider(parent,label,yPos,W,minV,maxV,defV,suffix,onChange)
	local H=36
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_SUB row.BorderSizePixel=0
	local ab=Instance.new('Frame',row) ab.Size=UDim2.fromOffset(2,H) ab.BackgroundColor3=Color3.fromRGB(50,50,50) ab.BorderSizePixel=0
	local ib=Instance.new('Frame',row) ib.Position=UDim2.fromOffset(INDENT,0) ib.Size=UDim2.fromOffset(2,H) ib.BackgroundColor3=Color3.fromRGB(38,38,38) ib.BorderSizePixel=0
	mkLbl(row,label,INDENT+8,2,W-80,14,10,FONT_UI,C_DIM)
	buildSlider(row,ab,W,minV,maxV,defV,suffix,onChange,true)
	return H
end

local activePickerClose = nil

local function buildPickerPopup(sg,swatch,defaultCol,onChange)
	local curH,curS,curV=Color3.toHSV(defaultCol)
	local popup=nil
	local function closeMe()
		if popup then popup:Destroy() popup=nil end
		if activePickerClose==closeMe then activePickerClose=nil end
	end
	swatch.MouseButton1Click:Connect(function()
		if popup then closeMe() return end
		if activePickerClose then activePickerClose() end
		activePickerClose=closeMe
		local SQ,BAR,PAD,GAP=130,16,8,6
		local PW=PAD+SQ+GAP+BAR+PAD local PH=PAD+SQ+GAP+16+PAD
		popup=Instance.new('Frame',sg)
		popup.Size=UDim2.fromOffset(PW,PH) popup.BackgroundColor3=Color3.fromRGB(10,10,10)
		popup.BorderSizePixel=0 popup.ZIndex=500 mkCorner(popup,6) mkStroke(popup,C_STR)
		task.defer(function()
			if not popup then return end
			local abs=swatch.AbsolutePosition
			local vp=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080)
			local px=abs.X-PW-6 if px<4 then px=abs.X+42 end
			popup.Position=UDim2.fromOffset(math.max(4,px),math.clamp(abs.Y-10,4,vp.Y-PH-4))
		end)
		local svBg=Instance.new('Frame',popup) svBg.Position=UDim2.fromOffset(PAD,PAD) svBg.Size=UDim2.fromOffset(SQ,SQ)
		svBg.BackgroundColor3=Color3.fromHSV(curH,1,1) svBg.BorderSizePixel=0 svBg.ZIndex=501 mkCorner(svBg,3)
		local wL=Instance.new('Frame',svBg) wL.Size=UDim2.fromScale(1,1) wL.BackgroundColor3=Color3.new(1,1,1) wL.BorderSizePixel=0 wL.ZIndex=502 mkCorner(wL,3)
		local wg=Instance.new('UIGradient',wL) wg.Color=ColorSequence.new(Color3.new(1,1,1),Color3.new(1,1,1)) wg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}) wg.Rotation=0
		local bL=Instance.new('Frame',wL) bL.Size=UDim2.fromScale(1,1) bL.BackgroundColor3=Color3.new(0,0,0) bL.BorderSizePixel=0 bL.ZIndex=503 mkCorner(bL,3)
		local bg=Instance.new('UIGradient',bL) bg.Color=ColorSequence.new(Color3.new(0,0,0),Color3.new(0,0,0)) bg.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)}) bg.Rotation=90
		local svK=Instance.new('Frame',svBg) svK.Size=UDim2.fromOffset(12,12) svK.AnchorPoint=Vector2.new(0.5,0.5) svK.Position=UDim2.new(curS,0,1-curV,0) svK.BackgroundColor3=Color3.new(1,1,1) svK.BorderSizePixel=0 svK.ZIndex=510 mkCorner(svK,99) mkStroke(svK,Color3.new(0,0,0),1.5)
		local hBar=Instance.new('Frame',popup) hBar.Position=UDim2.fromOffset(PAD+SQ+GAP,PAD) hBar.Size=UDim2.fromOffset(BAR,SQ) hBar.BackgroundColor3=Color3.new(0,0,0) hBar.BorderSizePixel=0 hBar.ZIndex=501 hBar.ClipsDescendants=true mkCorner(hBar,3)
		local hues={0,1/6,2/6,3/6,4/6,5/6,1} local segH=SQ/6
		for i=1,6 do local seg=Instance.new('Frame',hBar) seg.Position=UDim2.fromOffset(0,math.round((i-1)*segH)) seg.Size=UDim2.fromOffset(BAR,math.round(segH)+1) seg.BackgroundColor3=Color3.fromHSV(hues[i],1,1) seg.BorderSizePixel=0 seg.ZIndex=502 local g=Instance.new('UIGradient',seg) g.Color=ColorSequence.new(Color3.fromHSV(hues[i],1,1),Color3.fromHSV(hues[i+1],1,1)) g.Rotation=90 end
		local hK=Instance.new('Frame',hBar) hK.Size=UDim2.fromOffset(BAR+6,5) hK.AnchorPoint=Vector2.new(0.5,0.5) hK.Position=UDim2.new(0.5,0,curH,0) hK.BackgroundColor3=Color3.new(1,1,1) hK.BorderSizePixel=0 hK.ZIndex=510 mkCorner(hK,2) mkStroke(hK,Color3.new(0,0,0),1.5)
		local prev=Instance.new('Frame',popup) prev.Position=UDim2.fromOffset(PAD,PAD+SQ+GAP) prev.Size=UDim2.fromOffset(SQ+GAP+BAR,16) prev.BackgroundColor3=Color3.fromHSV(curH,curS,curV) prev.BorderSizePixel=0 prev.ZIndex=501 mkCorner(prev,3)
		local function refresh()
			local col=Color3.fromHSV(curH,curS,curV)
			svBg.BackgroundColor3=Color3.fromHSV(curH,1,1) svK.Position=UDim2.new(curS,0,1-curV,0)
			hK.Position=UDim2.new(0.5,0,curH,0) prev.BackgroundColor3=col swatch.BackgroundColor3=col onChange(col)
		end
		local svDrag,hDrag=false,false
		svBg.InputBegan:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end svDrag=true local rel=svBg.AbsolutePosition local sz=svBg.AbsoluteSize curS=math.clamp((i.Position.X-rel.X)/sz.X,0,1) curV=math.clamp(1-(i.Position.Y-rel.Y)/sz.Y,0,1) refresh() end)
		svBg.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false end end)
		hBar.InputBegan:Connect(function(i) if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end hDrag=true local rel=hBar.AbsolutePosition local sz=hBar.AbsoluteSize curH=math.clamp((i.Position.Y-rel.Y)/sz.Y,0,1) refresh() end)
		hBar.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then hDrag=false end end)
		inputService.InputChanged:Connect(function(i)
			if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
			if svDrag then local rel=svBg.AbsolutePosition local sz=svBg.AbsoluteSize curS=math.clamp((i.Position.X-rel.X)/sz.X,0,1) curV=math.clamp(1-(i.Position.Y-rel.Y)/sz.Y,0,1) refresh() end
			if hDrag then local rel=hBar.AbsolutePosition local sz=hBar.AbsoluteSize curH=math.clamp((i.Position.Y-rel.Y)/sz.Y,0,1) refresh() end
		end)
		inputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then svDrag=false hDrag=false end end)
		local oc oc=inputService.InputBegan:Connect(function(i)
			if i.UserInputType~=Enum.UserInputType.MouseButton1 or not popup then if not popup then oc:Disconnect() end return end
			local pos=Vector2.new(i.Position.X,i.Position.Y) local ap=popup.AbsolutePosition local as=popup.AbsoluteSize
			if not(pos.X>=ap.X and pos.X<=ap.X+as.X and pos.Y>=ap.Y and pos.Y<=ap.Y+as.Y) then closeMe() oc:Disconnect() end
		end)
	end)
end

function GuiLib.mkColorPicker(parent,yPos,W,label,defaultCol,onChange,sg)
	local H=28
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0
	local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=C_TEXT bar.BorderSizePixel=0
	mkLbl(row,label,16,0,W-50,H,11,FONT_UI,C_DIM)
	local swatch=Instance.new('TextButton',row)
	swatch.Size=UDim2.fromOffset(36,18) swatch.Position=UDim2.fromOffset(W-42,(H-18)/2)
	swatch.BackgroundColor3=defaultCol swatch.BorderSizePixel=0 swatch.Text='' swatch.AutoButtonColor=false
	mkCorner(swatch,4) mkStroke(swatch,C_STR)
	buildPickerPopup(sg,swatch,defaultCol,onChange)
	row.MouseEnter:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_HOVER}):Play() end)
	row.MouseLeave:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_PANEL}):Play() end)
	return H
end

function GuiLib.mkSubColorPicker(parent,yPos,W,label,defaultCol,onChange,sg)
	local H=26
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_SUB row.BorderSizePixel=0
	local ab=Instance.new('Frame',row) ab.Size=UDim2.fromOffset(2,H) ab.BackgroundColor3=Color3.fromRGB(50,50,50) ab.BorderSizePixel=0
	local ib=Instance.new('Frame',row) ib.Position=UDim2.fromOffset(INDENT,0) ib.Size=UDim2.fromOffset(2,H) ib.BackgroundColor3=Color3.fromRGB(38,38,38) ib.BorderSizePixel=0
	mkLbl(row,label,INDENT+8,0,W-60,H,10,FONT_UI,C_DIM)
	local swatch=Instance.new('TextButton',row)
	swatch.Size=UDim2.fromOffset(30,14) swatch.Position=UDim2.fromOffset(W-36,(H-14)/2)
	swatch.BackgroundColor3=defaultCol swatch.BorderSizePixel=0 swatch.Text='' swatch.AutoButtonColor=false
	mkCorner(swatch,3) mkStroke(swatch,Color3.fromRGB(55,55,55))
	buildPickerPopup(sg,swatch,defaultCol,onChange)
	return H
end

function GuiLib.mkMultiSelect(parent,yPos,W,options,defaults,minSelect,onChange)
	local BTN_W=(W-4-2*(#options-1))/#options
	local H=28
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0
	local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=C_TEXT bar.BorderSizePixel=0
	local state={} local btns={}
	for i,opt in options do
		state[opt]=defaults[opt] or false
		local b=Instance.new('TextButton',row)
		b.Size=UDim2.fromOffset(BTN_W,H-8) b.Position=UDim2.fromOffset(2+(i-1)*(BTN_W+2),4)
		b.BackgroundColor3=state[opt] and C_TEXT or C_DARK b.TextColor3=state[opt] and C_BG or C_DIM
		b.Text=opt b.TextSize=10 b.FontFace=FONT_UB b.BorderSizePixel=0 b.AutoButtonColor=false mkCorner(b,3)
		btns[opt]=b
		b.MouseButton1Click:Connect(function()
			local n=0 for _,v in state do if v then n+=1 end end
			if state[opt] and n<=minSelect then return end
			state[opt]=not state[opt]
			tweenService:Create(b,TI_F,{BackgroundColor3=state[opt] and C_TEXT or C_DARK,TextColor3=state[opt] and C_BG or C_DIM}):Play()
			onChange(state)
		end)
	end
	return H
end

function GuiLib.mkSingleSelect(parent,yPos,W,options,default,onChange)
	local BTN_W=(W-4-2*(#options-1))/#options
	local H=28
	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0
	local bar=Instance.new('Frame',row) bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=C_TEXT bar.BorderSizePixel=0
	local btns={}
	local function setActive(opt)
		for k,b in btns do tweenService:Create(b,TI_F,{BackgroundColor3=k==opt and C_TEXT or C_DARK,TextColor3=k==opt and C_BG or C_DIM}):Play() end
		onChange(opt)
	end
	for i,opt in options do
		local b=Instance.new('TextButton',row)
		b.Size=UDim2.fromOffset(BTN_W,H-8) b.Position=UDim2.fromOffset(2+(i-1)*(BTN_W+2),4)
		b.BackgroundColor3=opt==default and C_TEXT or C_DARK b.TextColor3=opt==default and C_BG or C_DIM
		b.Text=opt b.TextSize=10 b.FontFace=FONT_UB b.BorderSizePixel=0 b.AutoButtonColor=false mkCorner(b,3)
		btns[opt]=b b.MouseButton1Click:Connect(function() setActive(opt) end)
	end
	return H
end

function GuiLib.mkHeaderPanel(sg, title, iconUrl, panelW, headerH, xPos, yPos)
	local panel=Instance.new('Frame',sg)
	panel.Size=UDim2.fromOffset(panelW,400)
	panel.Position=UDim2.fromOffset(xPos,yPos)
	panel.BackgroundColor3=C_BG panel.BorderSizePixel=0 panel.Active=true
	mkCorner(panel,10) mkStroke(panel,C_STR)

	local header=Instance.new('Frame',panel)
	header.Size=UDim2.new(1,0,0,headerH) header.BackgroundColor3=Color3.fromRGB(14,14,14)
	header.BorderSizePixel=0 header.Active=true mkCorner(header,10)
	local hfix=Instance.new('Frame',header)
	hfix.Size=UDim2.new(1,0,0,8) hfix.Position=UDim2.new(0,0,1,-8)
	hfix.BackgroundColor3=Color3.fromRGB(14,14,14) hfix.BorderSizePixel=0

	local hgrad=Instance.new('UIGradient',header) hgrad.Rotation=180
	task.spawn(function()
		local t=0 while true do
			runService.RenderStepped:Wait() t=t+0.003
			local s=math.sin(t)*0.5+0.5 local v=math.round(28+s*16)
			hgrad.Color=ColorSequence.new({
				ColorSequenceKeypoint.new(0,Color3.fromRGB(v,v,v)),
				ColorSequenceKeypoint.new(0.5,Color3.fromRGB(14,14,14)),
				ColorSequenceKeypoint.new(1,Color3.fromRGB(8,8,8)),
			})
		end
	end)

	local hdiv=Instance.new('Frame',panel)
	hdiv.Size=UDim2.new(1,0,0,1) hdiv.Position=UDim2.fromOffset(0,headerH)
	hdiv.BackgroundColor3=C_STR hdiv.BorderSizePixel=0

	local icon=Instance.new('ImageLabel',header)
	icon.Size=UDim2.fromOffset(22,22) icon.Position=UDim2.fromOffset(12,(headerH-22)/2)
	icon.BackgroundTransparency=1 icon.Image=iconUrl or '' icon.ImageColor3=Color3.fromRGB(230,230,230)

	local titleLbl=Instance.new('TextLabel',header)
	titleLbl.Position=UDim2.fromOffset(42,0) titleLbl.Size=UDim2.new(1,-60,1,0)
	titleLbl.BackgroundTransparency=1 titleLbl.Text=title
	titleLbl.TextColor3=Color3.fromRGB(225,225,225) titleLbl.TextSize=15
	titleLbl.FontFace=FONT_H titleLbl.TextXAlignment=Enum.TextXAlignment.Left

	local isDragging=false local dragStart=Vector2.zero local dragOrigin=UDim2.fromOffset(0,0)
	header.InputBegan:Connect(function(i)
		if i.UserInputType~=Enum.UserInputType.MouseButton1 then return end
		isDragging=true dragStart=Vector2.new(i.Position.X,i.Position.Y) dragOrigin=panel.Position
	end)
	inputService.InputChanged:Connect(function(i)
		if not isDragging or i.UserInputType~=Enum.UserInputType.MouseMovement then return end
		local d=Vector2.new(i.Position.X,i.Position.Y)-dragStart
		panel.Position=UDim2.fromOffset(dragOrigin.X.Offset+d.X,dragOrigin.Y.Offset+d.Y)
	end)
	inputService.InputEnded:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then isDragging=false end
	end)

	return panel, header, icon, titleLbl
end

function GuiLib.mkNotifSystem(sg)
	local NOTIF_W,NOTIF_H=360,60
	local notifActive=nil
	local hideTimer=nil

	local function dismiss(f)
		if not f or not f.Parent then return end
		tweenService:Create(f,TweenInfo.new(0.25,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
			Position=UDim2.new(0.5,-NOTIF_W/2,1,20)
		}):Play()
		task.delay(0.3,function() if f and f.Parent then f:Destroy() end end)
		if notifActive==f then notifActive=nil end
	end

	local function buildFrame(iconUrl)
		if notifActive then dismiss(notifActive) end
		local f=Instance.new('Frame',sg)
		f.Size=UDim2.fromOffset(NOTIF_W,NOTIF_H)
		f.Position=UDim2.new(0.5,-NOTIF_W/2,1,20)
		f.BackgroundColor3=Color3.fromRGB(14,14,14) f.BorderSizePixel=0 f.ZIndex=999
		mkCorner(f,10) mkStroke(f,Color3.new(1,1,1)) mkStroke(f,Color3.fromRGB(255,255,255),1.5)
		notifActive=f
		if iconUrl and iconUrl~='' then
			local ic=Instance.new('ImageLabel',f)
			ic.Size=UDim2.fromOffset(18,18) ic.Position=UDim2.fromOffset(10,(NOTIF_H-18)/2)
			ic.BackgroundTransparency=1 ic.Image=iconUrl ic.ImageColor3=C_DIM ic.ZIndex=1000
		end
		tweenService:Create(f,TweenInfo.new(0.35,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
			Position=UDim2.new(0.5,-NOTIF_W/2,1,-NOTIF_H-20)
		}):Play()
		return f
	end

	local sys={}

	function sys.showInfo(text, duration, iconUrl)
		if hideTimer then task.cancel(hideTimer) hideTimer=nil end
		local f=buildFrame(iconUrl)
		local lbl=Instance.new('TextLabel',f)
		lbl.Size=UDim2.fromOffset(NOTIF_W-40,NOTIF_H) lbl.Position=UDim2.fromOffset(36,0)
		lbl.BackgroundTransparency=1 lbl.Text=text lbl.TextColor3=C_DIM lbl.TextSize=12
		lbl.FontFace=FONT_UI lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=1000
		hideTimer=task.delay(duration or 3,function() dismiss(f) hideTimer=nil end)
	end

	function sys.showAction(text, btnText, onConfirm, timeout, iconUrl)
		if hideTimer then task.cancel(hideTimer) hideTimer=nil end
		local f=buildFrame(iconUrl)
		local lbl=Instance.new('TextLabel',f)
		lbl.Size=UDim2.fromOffset(NOTIF_W-100,NOTIF_H) lbl.Position=UDim2.fromOffset(34,0)
		lbl.BackgroundTransparency=1 lbl.Text=text lbl.TextColor3=C_DIM lbl.TextSize=13
		lbl.FontFace=FONT_UI lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.ZIndex=1000

		local btn=Instance.new('TextButton',f)
		btn.Size=UDim2.fromOffset(72,32) btn.Position=UDim2.fromOffset(NOTIF_W-80,(NOTIF_H-32)/2)
		btn.BackgroundColor3=C_TEXT btn.BorderSizePixel=0
		btn.Text=btnText or 'OK' btn.TextColor3=C_BG btn.TextSize=13 btn.FontFace=FONT_UB
		btn.AutoButtonColor=false btn.ZIndex=1000 mkCorner(btn,6)
		btn.MouseEnter:Connect(function() tweenService:Create(btn,TI_F,{BackgroundColor3=C_WHITE}):Play() end)
		btn.MouseLeave:Connect(function() tweenService:Create(btn,TI_F,{BackgroundColor3=C_TEXT}):Play() end)
		btn.MouseButton1Click:Connect(function()
			dismiss(f) if onConfirm then onConfirm() end
		end)
		if timeout then
			hideTimer=task.delay(timeout,function() dismiss(f) hideTimer=nil end)
		end
	end

	return sys
end

function GuiLib.mkConfigSystem(configPath, requiredKeys)
	local httpService=cloneref(game:GetService('HttpService'))
	local cfg={}

	local function colorToStr(c3) return math.round(c3.R*255)..','..math.round(c3.G*255)..','..math.round(c3.B*255) end
	local function strToColor(s) local r,g,b=s:match('^(%d+),(%d+),(%d+)$') if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end return Color3.new(1,1,1) end

	cfg.colorToStr=colorToStr
	cfg.strToColor=strToColor

	local loaded=nil

	function cfg.load()
		local ok,raw=pcall(readfile,configPath)
		if not ok or not raw or raw=='' then return end
		local t={}
		for line in (raw..'\n'):gmatch('([^\n]*)\n') do
			local k,v=line:match('^([^=]+)=(.+)$')
			if k and v then t[k]=v end
		end
		if requiredKeys then
			for _,key in ipairs(requiredKeys) do
				if t[key]==nil then pcall(writefile,configPath,'') return end
			end
		end
		loaded=t
	end

	function cfg.save(data)
		pcall(makefolder, configPath:match('^(.*)/[^/]+$') or '')
		local lines={}
		for k,v in data do lines[#lines+1]=tostring(k)..'='..tostring(v) end
		return pcall(writefile,configPath,table.concat(lines,'\n'))
	end

	function cfg.get(k,default) if not loaded then return default end return loaded[k] or tostring(default) end
	function cfg.getBool(k,d) return cfg.get(k,tostring(d))=='true' end
	function cfg.getNum(k,d) return tonumber(cfg.get(k,tostring(d))) or d end
	function cfg.getColor(k,d) return strToColor(cfg.get(k,colorToStr(d or Color3.new(1,1,1)))) end
	function cfg.getStr(k,d) return cfg.get(k,d) end
	function cfg.hasData() return loaded~=nil end

	cfg.load()
	return cfg
end

function GuiLib.mkScreenGui(name, displayOrder)
	local sg=Instance.new('ScreenGui')
	sg.Name=name sg.DisplayOrder=displayOrder or 9999999
	sg.ZIndexBehavior=Enum.ZIndexBehavior.Global
	sg.IgnoreGuiInset=true sg.OnTopOfCoreBlur=true sg.ResetOnSpawn=false
	if threadfix then if setthreadidentity then setthreadidentity(8) end sg.Parent=coreGui
	else sg.Parent=lplr.PlayerGui end
	return sg
end

function GuiLib.mkDropdown(parent, yPos, W, label, options, default, onChange)
	local H=30 local OPT_H=26
	local isOpen=false
	local selectedVal=default

	local row=Instance.new('Frame',parent)
	row.Position=UDim2.fromOffset(0,yPos) row.Size=UDim2.fromOffset(W,H)
	row.BackgroundColor3=C_PANEL row.BorderSizePixel=0 row.ClipsDescendants=false

	local bar=Instance.new('Frame',row)
	bar.Size=UDim2.fromOffset(2,H) bar.BackgroundColor3=C_TEXT bar.BorderSizePixel=0

	local lbl=Instance.new('TextLabel',row)
	lbl.Position=UDim2.fromOffset(16,0) lbl.Size=UDim2.fromOffset(W-80,H)
	lbl.BackgroundTransparency=1 lbl.Text=label
	lbl.TextColor3=C_DIM lbl.TextSize=11 lbl.FontFace=FONT_UI
	lbl.TextXAlignment=Enum.TextXAlignment.Left

	local valLbl=Instance.new('TextLabel',row)
	valLbl.Size=UDim2.fromOffset(W-56,H) valLbl.Position=UDim2.fromOffset(0,0)
	valLbl.BackgroundTransparency=1 valLbl.Text=selectedVal
	valLbl.TextColor3=C_TEXT valLbl.TextSize=11 valLbl.FontFace=FONT_UB
	valLbl.TextXAlignment=Enum.TextXAlignment.Right

	local arrow=Instance.new('TextLabel',row)
	arrow.Size=UDim2.fromOffset(16,H) arrow.Position=UDim2.fromOffset(W-18,0)
	arrow.BackgroundTransparency=1 arrow.Text='v'
	arrow.TextColor3=C_DIM arrow.TextSize=10 arrow.FontFace=FONT_UB
	arrow.TextXAlignment=Enum.TextXAlignment.Center

	local dropdown=Instance.new('Frame',row)
	dropdown.Position=UDim2.fromOffset(0,H)
	dropdown.Size=UDim2.fromOffset(W,#options*OPT_H)
	dropdown.BackgroundColor3=Color3.fromRGB(10,10,10)
	dropdown.BorderSizePixel=0 dropdown.ZIndex=200 dropdown.Visible=false
	mkCorner(dropdown,4) mkStroke(dropdown,C_STR)

	for i,opt in options do
		local ob=Instance.new('TextButton',dropdown)
		ob.Position=UDim2.fromOffset(0,(i-1)*OPT_H)
		ob.Size=UDim2.fromOffset(W,OPT_H)
		ob.BackgroundColor3=opt==selectedVal and C_TEXT or Color3.fromRGB(10,10,10)
		ob.TextColor3=opt==selectedVal and C_BG or C_DIM
		ob.Text=opt ob.TextSize=11 ob.FontFace=FONT_UI
		ob.BorderSizePixel=0 ob.AutoButtonColor=false ob.ZIndex=201
		ob.TextXAlignment=Enum.TextXAlignment.Left
		local opad=Instance.new('UIPadding',ob)
		opad.PaddingLeft=UDim.new(0,14)
		ob.MouseEnter:Connect(function()
			if opt~=selectedVal then ob.BackgroundColor3=C_HOVER end
		end)
		ob.MouseLeave:Connect(function()
			if opt~=selectedVal then ob.BackgroundColor3=Color3.fromRGB(10,10,10) end
		end)
		ob.MouseButton1Click:Connect(function()
			selectedVal=opt valLbl.Text=opt
			for _,ch in dropdown:GetChildren() do
				if ch:IsA('TextButton') then
					ch.BackgroundColor3=ch.Text==opt and C_TEXT or Color3.fromRGB(10,10,10)
					ch.TextColor3=ch.Text==opt and C_BG or C_DIM
				end
			end
			isOpen=false dropdown.Visible=false arrow.Text='v'
			onChange(opt)
		end)
	end

	local btn=Instance.new('TextButton',row)
	btn.Size=UDim2.fromScale(1,1) btn.BackgroundTransparency=1 btn.Text='' btn.ZIndex=5
	btn.MouseButton1Click:Connect(function()
		isOpen=not isOpen
		dropdown.Visible=isOpen
		arrow.Text=isOpen and '^' or 'v'
	end)
	row.MouseEnter:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_HOVER}):Play() end)
	row.MouseLeave:Connect(function() tweenService:Create(row,TI_F,{BackgroundColor3=C_PANEL}):Play() end)

	return H, function(v) selectedVal=v valLbl.Text=v end
end


return GuiLib
