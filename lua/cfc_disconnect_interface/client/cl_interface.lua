include("cfc_disconnect_interface/client/cl_api.lua")

local vgui, timer, hook = vgui, timer, hook

surface.CreateFont( "CFC_Normal",
    {
        font = "arial",
        size = 18,
        weight = 500
    }
)

surface.CreateFont( "CFC_Special",
    {
        font = "coolvetica",
        size = 26,
        weight = 500
    }
)

surface.CreateFont( "CFC_Button",
    {
        font = "arial",
        size = 18,
        weight = 1500
    }
)

local GAME_URL = "https://cdn.cfcservers.org/media/dinosaur/index.html"
-- local GAME_URL = "http://local:8080/"
-- Width of the game on the website in pixels, needed as I didn't write the dinosaur game, and it doesn't like centering nicely
local GAME_WIDTH = 1256

local interfaceDerma = false

local TIME_TO_RESTART = 10
local timeDown = 0
local apiState
local previouslyShown = false

-- Colors
primaryCol = Color( 36, 41, 67 )
secondaryCol = Color( 42, 47, 74 )
accentCol = Color( 84, 84, 150 )

local function lerpColor(fraction, from, to)
	return Color(from.r + (to.r - from.r) * fraction, 
		from.g + (to.g - from.g) * fraction,
		from.b + (to.b - from.b) * fraction)
end

local function secondsAsTime(s)
	return string.FormattedTime( s, "%02i:%02i" )
end

-- Delay Function
-- Delays a function call until the next "tick", gm_crashsys does this, and I'm assuming its for a reason
local delayId = 0
local function delaycall(time, callback)
	local wait = RealTime() + time
	delayId = delayId + 1
	local hookName = "cfc_di_delay_" .. delayId
	hook.Add("Tick", hookName, function()
		if RealTime() > wait then
			hook.Remove("Tick", hookName)
			callback()
		end
	end)
end

local function rejoin()
	delaycall(1, function()
		RunConsoleCommand( "snd_restart" ) -- Restarts sound engine, good practice?
		RunConsoleCommand( "retry" ) 
	end)
end

local function leave()
	delaycall(1, function()
		RunConsoleCommand( "disconnect" ) 
	end)
end

-- Creates and populates a title bar for the frame
local function addTitleBar(frame)
	local frameW, frameH = frame:GetSize()
	local titleBarHeight = 32

	-- The bar itself
	local titleBar = vgui.Create( "DPanel", frame )
	titleBar:SetSize( frameW, titleBarHeight )
	titleBar:SetPos( 0, 0 )
	function titleBar:Paint(w, h) 
		surface.SetDrawColor( secondaryCol )
		surface.DrawRect( 0, 0, w, h )
	end

	-- Close button, could be removed, but I personally think it should stay, allows you to save e2/sf files
	local closeBtnPadding = (titleBarHeight - 16) / 2
	local closeBtn = vgui.Create( "DImageButton", titleBar )
	closeBtn:SetSize( 16, 16 )
	closeBtn:SetPos( frameW - 16 - closeBtnPadding, closeBtnPadding)
	closeBtn:SetImage( "icon16/cross.png" )
	function closeBtn:DoClick()
		frame:Close()
	end

	-- Title label
	local titleLabelPadding = (titleBarHeight - 26) / 2
	local titleLabel = vgui.Create( "DLabel", titleBar )
	titleLabel:SetFont( "CFC_Special" )
	titleLabel:SetText( "Oops! Looks like the server crashed..." )
	titleLabel:SizeToContents()
	titleLabel:SetPos( 0, titleLabelPadding + 2 )
	titleLabel:CenterHorizontal()

	return titleBar
end

-- Create a button in specific format for button bar
-- xFraction is 0-1 for how far across the button should be
-- Colours are self explan
local function makeButton(frame, text, xFraction, doClick, outlineCol, fillCol, hoverOutlineCol, hoverFillCol)
	-- Defaults for colours
	outlineCol = outlineCol or Color( 255, 255, 255 )
	fillCol = fillCol or primaryCol
	hoverOutlineCol = hoverOutlineCol or Color(155,241,255)
	hoverFillCol = hoverFillCol or primaryCol

	local frameW, frameH = frame:GetSize()
	local btn = vgui.Create( "DButton", frame )
	btn:SetText( text )
	btn:SetTextColor( Color( 255, 255, 255 ) )
	btn:SetFont( "CFC_Button" )
	btn:SetSize( frameW * 0.4, frameH * 0.6 )
	btn:CenterHorizontal( xFraction )
	btn:CenterVertical()
	btn.DoClick = doClick

	-- Fade animation state and time for consistant animation speed on different FPS
	btn.fadeState = 0
	btn.prevTime = CurTime()

	local btnAnimSpeed = 0.05 * 60

	function btn:Think()
		-- Make anim same speed for all framerates
		local dt = CurTime() - self.prevTime
		self.prevTime = CurTime()
		if dt > 1 then dt = 0 end -- This happens on first Think after being Shown, dt ends up being very large

		if self:IsHovered() and self.fadeState < 1 then
			self.fadeState = math.Clamp(self.fadeState + btnAnimSpeed * dt, 0, 1)
		elseif not self:IsHovered() and self.fadeState > 0 then
			self.fadeState = math.Clamp(self.fadeState - btnAnimSpeed * dt, 0, 1)
		end
	end

	local btnBorderWeight = 2
	function btn:Paint(w, h)
		local lineCol
		local bgCol
		if self:GetDisabled() then
			lineCol = Color( 74, 74, 74 )
			bgCol = fillCol
			self:SetCursor( "no" )
		else
			lineCol = lerpColor(self.fadeState, outlineCol, hoverOutlineCol)
			bgCol = lerpColor(self.fadeState, fillCol, hoverFillCol)
			self:SetCursor( "hand" )
		end

		self:SetTextColor( lineCol )
		surface.SetDrawColor( lineCol )
		surface.DrawRect( 0, 0, w, h )
		surface.SetDrawColor( bgCol )
		surface.DrawRect( btnBorderWeight, btnBorderWeight, 
			w - (btnBorderWeight*2), h - (btnBorderWeight*2) )
	end

	return btn
end

-- Create bar panel and add buttons
local function addButtonsBar(frame)
	local frameW, frameH = frame:GetSize()

	local buttonBarHeight = 64

	local barPanel = vgui.Create( "DPanel", frame )
	barPanel:SetSize( frameW, buttonBarHeight )
	barPanel:SetPos( 0, frameH - buttonBarHeight )
	function barPanel:Paint(w, h)
		surface.SetDrawColor( accentCol )
		surface.DrawLine( 16, 0, w - 16, 0 )
	end

	-- Put buttons onto the panel as members for easy access
	barPanel.reconBtn = makeButton(barPanel, "RECONNECT", 0.25, rejoin, 
		Color( 74, 251, 191 ), nil, Color( 74, 251, 191 ), Color( 64, 141, 131 ))
	-- Reconnect button will usually start as disabled
	barPanel.reconBtn:SetDisabled( true )
	barPanel.disconBtn = makeButton(barPanel, "DISCONNECT", 0.75, leave)

	return barPanel
end

-- Making lines of text for body
local function makeLabel(frame, text, top, col, xFraction)
	col = col or Color( 255, 255, 255 )
	local label = vgui.Create( "DLabel", frame )
	label:SetText( text )
	label:SetFont( "CFC_Special" )
	label:SizeToContents()
	label:SetPos( 0, top )
	label:SetTextColor( col )
	label:CenterHorizontal( xFraction )
	return label
end

-- Text for internet down on body
local function populateBodyInternetDown(body)
	local label1 = makeLabel(body, "Looks like your internet has gone down!", 20)
	local label2 = makeLabel(body, "Stick around for when it comes back", 64)
end

-- Text for server down on body
local function populateBodyServerDown(body)

	local frameW, frameH = body:GetSize()
	local restartTimeStr = "The server normally takes about " .. secondsAsTime(TIME_TO_RESTART) .. " to restart!"
	local restartTimeLabel = makeLabel(body, restartTimeStr, 0)
	local curTimePreLabel = makeLabel(body, "It has been down for", 32)
	-- When the server comes back up, "It has been down for" => "It was down for"
	-- Then resize and move
	function curTimePreLabel:Think()
		if apiState == crashApi.SERVER_UP and not self.backUp then
			self:SetText( "It was down for" )
			self:SizeToContents()
			self:CenterHorizontal()
			self.backUp = true
		end
	end

	-- Label for when timeDown > averageTimeDown
	-- Currently on the right, change the 0.8 at the end to move it horizontally
	local tooLongLabel = makeLabel(body, "Uh oh, seems it's taking a little longer than usual!", 70, Color( 251, 191, 83 ), 0.8)
	tooLongLabel:SetAlpha(0)
	tooLongLabel:Hide()

	-- Text for downTime, update its value in Think
	-- If server comes back up, make it green and stop updating it
	-- If timeDown > averageTimeDown, make it red and show the tooLongLabel
	local curTimeLabel = makeLabel(body, secondsAsTime(math.floor(timeDown)), 70, Color( 251, 191, 83 ))
	function curTimeLabel:Think()
		if apiState ~= crashApi.SERVER_UP then
			self:SetText(secondsAsTime(math.floor(timeDown)))
			if timeDown > TIME_TO_RESTART then
				self:SetTextColor(Color(255, 0, 0))
				if not tooLongLabel:IsVisible() then
					tooLongLabel:Show()
					tooLongLabel:AlphaTo(255, 1)
				end
			end
		else
			self:SetTextColor(Color(0, 255, 0))
		end
	end
end

-- Fill the body with elements, body created elsewhere as it's size relies on size of titleBar and buttonsBar
local function populateBody(body)
	body.Paint = nil

	-- Fill top text based on crashApi state
	if apiState == crashApi.NO_INTERNET then
		populateBodyInternetDown(body) 
	else -- Server down or up via api, and down via net
		populateBodyServerDown(body)
	end

	local frameW, frameH = 0.8 * ScrW(), 0.8 * ScrH()
	local playGameLabel = makeLabel(body, "Why not play a game while you wait? (Press space)", 108)

	-- Game wrapper, in case we ever want to make a game that runs in lua
	local gamePanel = vgui.Create( "DPanel", body )
	gamePanel:SetSize( frameW - 20, frameH - 134 - 15 )
	gamePanel:SetPos( -6, 134 + 10 )
	gamePanel.Paint = nil

	-- HTML element rending game at GAME_URL, constantly grabs focus
	local gameHtml = vgui.Create( "DHTML", gamePanel )
	gameHtml:SetSize( gamePanel:GetSize() )
	gameHtml:SetPos( (gamePanel:GetWide() - GAME_WIDTH) / 2, 0 )
	gameHtml:OpenURL( GAME_URL )
	function gameHtml:Think()
		if not gameHtml:HasFocus() then gameHtml:RequestFocus() end
	end
end

-- Entry point for creating the interface
local function createInterface()

	-- Sized at 80% of the screen
	local frameW, frameH = 0.8 * ScrW(), 0.8 * ScrH()

	-- Needed for bg blur
	local startTime = SysTime()
	-- Main frame
	local frame = vgui.Create( "DFrame" )
	interfaceDerma = frame
	frame:SetSize( frameW, frameH )
	frame:Center()
	frame:SetTitle("")
	frame:SetDraggable( false )
	frame:MakePopup()
	frame:ShowCloseButton( false )

	function frame:Paint(w, h) 
		Derma_DrawBackgroundBlur(self, startTime)
		surface.SetDrawColor( primaryCol )
		surface.DrawRect( 0, 0, w, h )
	end

	-- Generate title and buttons bars
	local titlePanel = addTitleBar(frame)
	local btnsPanel = addButtonsBar(frame)

	-- Create body that fills the unused space
	local body = vgui.Create( "DPanel", frame )
	body:SetSize(frameW - 32, frameH - 32 - titlePanel:GetTall() - btnsPanel:GetTall())
	body:SetPos(16, titlePanel:GetTall() + 16)
	populateBody(body)

	-- If server fully recovers without crashing, close menu
	-- If server reboots, enabled the reconnect button
	function frame:Think() 
		if apiState == crashApi.INACTIVE then
			frame:Close() -- Server recovered without ever closing
		elseif apiState == crashApi.SERVER_UP then
			if btnsPanel.reconBtn:GetDisabled() == true then
				btnsPanel.reconBtn:SetDisabled( false ) -- Server back up
				-- Maybe show a "The server is back up, click here to reconnect?"
			end
		end
	end

	function frame:OnClose()
		interfaceDerma = nil
	end
end

hook.Add("cfc_di_crashTick", "cfc_di_interfaceUpdate", function(isCrashing, _timeDown, _apiState)
	timeDown = _timeDown or 0
	apiState = _apiState
	-- Open interface if server is crashing, API has responded, interface isn't already open, and interface has not yet been opened
	if isCrashing and apiState ~= crashApi.PINGING_API and not interfaceDerma and not previouslyShown then
		createInterface()
		previouslyShown = true
	end
	-- Close menu if server stops crashing
	if not isCrashing then
		previouslyShown = false
		if interfaceDerma then 
			interfaceDerma:Close() 
		end
	end
end)

