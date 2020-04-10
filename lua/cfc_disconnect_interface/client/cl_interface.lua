include( "cfc_disconnect_interface/client/cl_api.lua" )

local vgui, hook = vgui, hook

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
        size = 30,
        weight = 500
    }
)

surface.CreateFont( "CFC_Mono",
    {
        font = "Lucida Console",
        size = 30,
        weight = 1500
    }
)

surface.CreateFont( "CFC_Button",
    {
        font = "arial",
        size = 18,
        weight = 1500
    }
)

-- local GAME_CODE
local GAME_URL = "https://cdn.cfcservers.org/media/dinosaur/index.html"
-- local GAME_URL = "http://local:8000/"
-- Width of the game on the website in pixels, needed as I didn't write the dinosaur game, and it doesn't like centering nicely
local GAME_WIDTH = 1256

local interfaceDerma = false

local TIME_TO_RESTART = 180
local timeDown = 0
local apiState
local previouslyShown = false
local disconnectMessages = {}
disconnectMessages[crashApi.SERVER_DOWN] = "Are you sure? Hang in there, the server will restart soon..."
disconnectMessages[crashApi.SERVER_UP] = "Are you sure? The server is already back up and ready!"
disconnectMessages[crashApi.NO_INTERNET] = "Are you sure? If your internet comes back, you can easily rejoin from this page."

-- Helper function
local function getFrom( i, ... )
    return ( {...} )[i]
end

-- Colors
primaryCol = Color( 36, 41, 67 )
secondaryCol = Color( 42, 47, 74 )
accentCol = Color( 84, 84, 150 )

local function lerpColor( fraction, from, to )
    return Color( from.r + ( to.r - from.r ) * fraction,
        from.g + ( to.g - from.g ) * fraction,
        from.b + ( to.b - from.b ) * fraction )
end

local function secondsAsTime( s )
    return string.FormattedTime( s, "%02i:%02i" )
end

-- Delay Function
-- Delays a function call until the next "tick", gm_crashsys does this, and I'm assuming its for a reason
local delayId = 0
local function delaycall( time, callback )
    local wait = RealTime() + time
    delayId = delayId + 1
    local hookName = "cfc_di_delay_" .. delayId
    hook.Add( "Tick", hookName, function()
        if RealTime() > wait then
            hook.Remove( "Tick", hookName )
            callback()
        end
    end )
end

local function rejoin()
    delaycall( 1, function()
        RunConsoleCommand( "snd_restart" ) -- Restarts sound engine, good practice?
        RunConsoleCommand( "retry" )
    end )
end

local function leave()
    delaycall( 1, function()
        RunConsoleCommand( "disconnect" )
    end )
end

local init

init = function()
    http.Fetch( GAME_URL, function( body )
        GAME_CODE = body
    end, function()
        dTimer.Simple( 5, init )
    end )
end

hook.Add( "Initialize", "cfc_di_init", init )

-- Creates and populates a title bar for the frame
local function addTitleBar( frame )
    local frameW = frame:GetWide()
    local titleBarHeight = 70

    -- The bar itself
    local titleBar = vgui.Create( "DPanel", frame )
    titleBar:SetSize( frameW, titleBarHeight )
    titleBar:SetPos( 0, 0 )
    function titleBar:Paint( w, h )
        surface.SetDrawColor( secondaryCol )
        surface.DrawRect( 0, 0, w, h )
    end

    -- Close button, could be removed, but I personally think it should stay, allows you to save e2/sf files
    local closeBtnSize = 32
    local closeBtnPadding = ( titleBarHeight - closeBtnSize ) / 2
    local closeBtn = vgui.Create( "DImageButton", titleBar )
    closeBtn:SetSize( closeBtnSize, closeBtnSize )
    closeBtn:SetPos( frameW - closeBtnSize - closeBtnPadding, closeBtnPadding )
    closeBtn:SetImage( "icons/cross.png" )
    function closeBtn:DoClick()
        frame:Close()
    end

    -- Title label
    local titleLabelPadding = ( titleBarHeight - 26 ) / 2
    local titleLabel = vgui.Create( "DLabel", titleBar )
    titleLabel:SetFont( "CFC_Special" )

    local function setTitle( title )
        titleLabel:SetText( title )
        titleLabel:SizeToContents()
        titleLabel:SetPos( 0, titleLabelPadding + 2 )
        titleLabel:CenterHorizontal()
    end

    setTitle( "Oops! Looks like you disconnected..." )
    titleBar.setTitle = setTitle

    return titleBar
end

-- Create a button in specific format for button bar
-- xFraction is 0-1 for how far across the button should be
-- Colours are self explan
local function makeButton( frame, text, xFraction, doClick, outlineCol, fillCol, hoverOutlineCol, hoverFillCol )


    local frameW, frameH = frame:GetSize()
    local btn = vgui.Create( "DButton", frame )

    -- Defaults for colours
    btn.outlineCol = outlineCol or Color( 255, 255, 255 )
    btn.fillCol = fillCol or primaryCol
    btn.hoverOutlineCol = hoverOutlineCol or Color( 255, 255, 255 )
    btn.hoverFillCol = hoverFillCol or primaryCol

    btn:SetText( text )
    btn:SetTextColor( Color( 255, 255, 255 ) )
    btn:SetFont( "CFC_Button" )
    btn:SetSize( frameW * 0.3, frameH )
    btn:CenterHorizontal( xFraction )
    btn:CenterVertical()
    btn.DoClick = doClick

    -- Fade animation state and time for consistant animation speed on different FPS
    btn.fadeState = 0
    btn.prevTime = SysTime()

    local btnAnimSpeed = 0.1 * 60

    function btn:Think()
        -- Make anim same speed for all framerates
        local dt = SysTime() - self.prevTime
        self.prevTime = SysTime()
        if dt > 1 then dt = 0 end -- This happens on first Think after being Shown, dt ends up being very large

        if self:IsHovered() and self.fadeState < 1 then
            self.fadeState = math.Clamp( self.fadeState + btnAnimSpeed * dt, 0, 1 )
        elseif not self:IsHovered() and self.fadeState > 0 then
            self.fadeState = math.Clamp( self.fadeState - btnAnimSpeed * dt, 0, 1 )
        end
    end

    local btnBorderWeight = 2
    function btn:Paint( w, h )
        local lineCol
        local bgCol
        local borderWeight
        if self:GetDisabled() then
            lineCol = Color( 74, 74, 74 )
            bgCol = self.fillCol
            borderWeight = btnBorderWeight
            self:SetCursor( "no" )
        else
            lineCol = lerpColor( self.fadeState, self.outlineCol, self.hoverOutlineCol )
            bgCol = lerpColor( self.fadeState, self.fillCol, self.hoverFillCol )
            borderWeight = 1.5 * btnBorderWeight + 1.5 * self.fadeState * btnBorderWeight
            self:SetCursor( "hand" )
        end

        self:SetTextColor( lineCol )

        local boxH = h / 2
        draw.RoundedBox( boxH, 0, 0, w, h, lineCol )

        local nw, nh = w - ( borderWeight * 2 ), h - ( borderWeight * 2 )
        draw.RoundedBox( nh / 2, borderWeight, borderWeight, nw, nh, bgCol )
    end

    return btn
end

local function showMessage( msg )
    if not interfaceDerma then return end
    if interfaceDerma.messageLabel:GetText() == msg and interfaceDerma.messageLabel:IsVisible() then return end

    if interfaceDerma.messageLabel:IsVisible() then
        interfaceDerma.messageLabel:AlphaTo( 0, 0.25 )
        dTimer.Simple( 0.25, function()
            interfaceDerma.messageLabel:setTextAndAlign( msg )
            interfaceDerma.messageLabel:AlphaTo( 255, 0.25 )
        end )
    else
        interfaceDerma.messageLabel:setTextAndAlign( msg )
        interfaceDerma.messageLabel:Show()
        interfaceDerma.messageLabel:AlphaTo( 255, 0.5 )
    end
end

local function hideMessage()
    if not interfaceDerma then return end
    if not interfaceDerma.messageLabel:IsVisible() then return end

    interfaceDerma.messageLabel:AlphaTo( 0, 0.25 )
    dTimer.Simple( 0.25, function()
        interfaceDerma.messageLabel:Hide()
    end )
end

local function getDisconnectMessage()
    return disconnectMessages[apiState]
end

-- Create bar panel and add buttons
local function addButtonsBar( frame )
    local frameW, frameH = frame:GetSize()

    local buttonBarHeight = 90
    local buttonBarOffset = 90


    local barPanel = vgui.Create( "DPanel", frame )
    barPanel:SetSize( frameW, buttonBarHeight )
    barPanel:SetPos( 0, frameH - buttonBarHeight - buttonBarOffset )
    barPanel.Paint = nil
    function barPanel:Think()   
        if not self.showOnce then
            showMessage( "You'll have the option to respawn your props when you rejoin." )
            self.showOnce = true
        end

        if not self.disconMode then return end
        if apiState ~= crashApi.SERVER_UP then return end
        if self.backUp then return end

        showMessage( getDisconnectMessage() )
        self.backUp = true
    end

    -- Put buttons onto the panel as members for easy access
    barPanel.reconBtn = makeButton( barPanel, "RECONNECT", 0.25, function()
        barPanel.reconBtn:SetDisabled( true )
        barPanel.reconBtn.dontEnable = true
        barPanel.disconBtn:SetDisabled( true )

        if not barPanel.disconMode then
            showMessage( "Reconnecting..." )
            rejoin()
        else
            showMessage( "Disconnecting..." )
            leave()
        end
    end )
        -- Color( 74, 251, 191 ), nil, Color( 74, 251, 191 ), Color( 64, 141, 131 ) )
    -- Reconnect button will usually start as disabled
    barPanel.reconBtn:SetDisabled( true )
    barPanel.disconBtn = makeButton( barPanel, "DISCONNECT", 0.75, function( self )
        if not barPanel.disconMode then
            showMessage( getDisconnectMessage() )
            barPanel.disconMode = true
            barPanel.disconPrevDisabled = barPanel.reconBtn:GetDisabled()
            barPanel.reconBtn:SetDisabled( false )
            self:SetText( "NO" )
            self.fadeState = 0
            self.hoverOutlineCol = Color( 255, 0, 0 )
            barPanel.reconBtn.hoverOutlineCol = Color( 0, 255, 0 )
            barPanel.reconBtn:SetText( "YES" )
        else
            hideMessage()

            timer.Simple( 0.25, function() 
                showMessage( "You'll have the option to respawn your props when you rejoin." )
            end )

            barPanel.disconMode = false
            self:SetText( "DISCONNECT" )
            self.hoverOutlineCol = Color( 255, 255, 255 )
            barPanel.reconBtn:SetText( "RECONNECT" )
            barPanel.reconBtn.hoverOutlineCol = Color( 255, 255, 255 )
            barPanel.reconBtn:SetDisabled( barPanel.disconPrevDisabled )
        end
    end )

    return barPanel
end

-- Making lines of text for body
local function makeLabel( frame, text, top, col, xFraction, font )
    col = col or Color( 255, 255, 255 )
    local label = vgui.Create( "DLabel", frame )
    label:SetFont( font or "CFC_Special" )
    function label:setTextAndAlign( str )
        self:SetText( str )
        self:SizeToContents()
        self:SetPos( 0, top )
        self:SetTextColor( col )
        self:CenterHorizontal( xFraction )
    end
    label:setTextAndAlign( text )
    return label
end

-- Text for internet down on body
local function populateBodyInternetDown( body )
    makeLabel( body, "Please check you're still connected to the internet.", 20 )
    makeLabel( body, "In the meantime, ", 80 )

    return "Oops, looks like you disconnected"
end

-- Text for server down on body
local function populateBodyServerDown( body )
    local restartTimeStr = "The server normally takes about " .. secondsAsTime( TIME_TO_RESTART ) .. " to restart."

    -- Restart time label
    makeLabel( body, restartTimeStr, 0 )

    local curTimePreLabel = makeLabel( body, "It has been down for", 32 )

    -- When the server comes back up, "It has been down for" => "It was down for"
    -- Then resize and move
    function curTimePreLabel:Think()
        if apiState == crashApi.SERVER_UP and not self.backUp then
            self:setTextAndAlign( "It was down for" )
            self.backUp = true
        end
    end

    -- Text for downTime, update its value in Think
    -- If server comes back up, make it green and stop updating it
    -- If timeDown > averageTimeDown, make it red and show the messageLabel
    local curTimeLabel = makeLabel( body, secondsAsTime( math.floor( timeDown ) ), 70, Color( 251, 191, 83 ), 0.5, "CFC_Mono" )
    function curTimeLabel:Think()
        if apiState ~= crashApi.SERVER_UP then
            self:setTextAndAlign( secondsAsTime( math.floor( timeDown ) ) )
            if timeDown > TIME_TO_RESTART then
                self:SetTextColor( Color( 255, 0, 0 ) )
                if not interfaceDerma.messageLabel:IsVisible() then
                    showMessage( "Uh oh, seems it's taking a little longer than usual..." )
                end
            end
        else
            self:SetTextColor( Color( 0, 255, 0 ) )
        end
    end

    return "Oops, looks like the server crashed..."
end

-- Fill the body with elements, body created elsewhere as it's size relies on size of titleBar and buttonsBar
local function populateBody( body )
    body.Paint = nil
    local title
    local frameW, frameH = body:GetSize()

    -- Warning message label
    interfaceDerma.messageLabel = makeLabel( body, "", frameH - 45, Color( 255, 255, 0 ), 0.5 )
    interfaceDerma.messageLabel:SetAlpha( 0 )
    interfaceDerma.messageLabel:Hide()

    -- Fill top text based on crashApi state
    if apiState == crashApi.NO_INTERNET then
        title = populateBodyInternetDown( body )
    else -- Server down or up via api, and down via net
        title = populateBodyServerDown( body )
    end

    makeLabel( body, "Why not play a game while you wait? ( Press space )", 108 )

    -- Game wrapper, in case we ever want to make a game that runs in lua
    local gamePanel = vgui.Create( "DPanel", body )
    gamePanel:SetSize( frameW - 20, frameH - 134 - 15 )
    gamePanel:SetPos( 10, 134 )
    gamePanel.Paint = nil

    -- HTML element rending game at GAME_URL, constantly grabs focus
    local gameHtml = vgui.Create( "DHTML", gamePanel )
    gameHtml:SetSize( gamePanel:GetSize() )
    gameHtml:SetPos( ( gamePanel:GetWide() - GAME_WIDTH ) / 2, 0 )
    gameHtml:SetHTML( GAME_CODE or "Oops, it didn't load lol" )
    function gameHtml:Think()
        if not gameHtml:HasFocus() then gameHtml:RequestFocus() end
    end

    return title
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
    frame:SetTitle( "" )
    frame:SetDraggable( false )
    frame:MakePopup()
    frame:ShowCloseButton( false )

    function frame:Paint( w, h )
        Derma_DrawBackgroundBlur( self, startTime )
        surface.SetDrawColor( primaryCol )
        surface.DrawRect( 0, 0, w, h )
    end

    -- Generate title and buttons bars
    local titlePanel = addTitleBar( frame )
    local btnsPanel = addButtonsBar( frame )

    -- Create body that fills the unused space
    local body = vgui.Create( "DPanel", frame )
    body:SetSize( frameW - 32, getFrom( 2, btnsPanel:GetPos() ) - 32 - titlePanel:GetTall() )
    body:SetPos( 16, titlePanel:GetTall() + 16 )
    local title = populateBody( body )
    titlePanel.setTitle( title )

    -- If server fully recovers without crashing, close menu
    -- If server reboots, enabled the reconnect button
    function frame:Think()
        if apiState == crashApi.INACTIVE then
            frame:Close() -- Server recovered without ever closing
        elseif apiState == crashApi.SERVER_UP then
            if btnsPanel.reconBtn:GetDisabled() == true and not btnsPanel.reconBtn.dontEnable then
                btnsPanel.reconBtn:SetDisabled( false ) -- Server back up
            end
        end
    end

    function frame:OnClose()
        interfaceDerma = nil
    end
end

hook.Add( "cfc_di_crashTick", "cfc_di_interfaceUpdate", function( isCrashing, _timeDown, _apiState )
    timeDown = _timeDown or 0
    if _apiState ~= crashApi.PINGING_API then
        apiState = _apiState
    end


    if isCrashing then
        -- Open interface if server is crashing, API has responded, interface isn't already open, and interface has not yet been opened
        if _apiState == crashApi.PINGING_API or _apiState == crashApi.SERVER_UP then return end
        if interfaceDerma or previouslyShown then return end
        createInterface()
        previouslyShown = true
    else
        -- Close menu if server stops crashing
        previouslyShown = false
        if interfaceDerma then
            interfaceDerma:Close()
        end
    end
end )

