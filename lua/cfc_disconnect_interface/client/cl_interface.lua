include( "cfc_disconnect_interface/client/cl_api.lua" )

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

surface.CreateFont( "CFC_Special_Small",
    {
        font = "coolvetica",
        size = 22,
        weight = 400
    }
)

surface.CreateFont( "CFC_Mono",
    {
        font = "Lucida Console",
        size = 30,
        weight = 1500
    }
)

surface.CreateFont( "CFC_Mono_Small",
    {
        font = "Lucida Console",
        size = 18,
        weight = 400,
    }
)

surface.CreateFont( "CFC_Button",
    {
        font = "arial",
        size = 18,
        weight = 1500
    }
)

local GAME_URL = GetConVar( "cfc_disconnect_interface_game_url" ):GetString()
-- Width of the game on the website in pixels, needed as I didn't write the dinosaur game, and it doesn't like centering nicely
local GAME_WIDTH = 1256
local GAME_CODE

local interfaceDerma = false

local TIME_TO_RESTART = GetConVar( "cfc_disconnect_interface_restart_time" ):GetInt()

local timeDown = 0
local apiState
local previouslyShown = false
local disconnectMessages = {
    [CFCCrashAPI.SERVER_DOWN] = "Are you sure? Hang in there, the server will restart soon...",
    [CFCCrashAPI.SERVER_UP] = "Are you sure? The server is already back up and ready!",
    [CFCCrashAPI.NO_INTERNET] = "Are you sure? If your internet comes back, you can easily rejoin from this page."
}

-- Colors
local primaryCol = Color( 36, 41, 67 )
local secondaryCol = Color( 42, 47, 74 )
local accentCol = Color( 84, 84, 150 )
local whiteCol = Color( 255, 255, 255 )
local redCol = Color( 255, 0, 0 )
local yellowCol = Color( 255, 255, 0 )
local greenCol = Color( 50, 255, 50 )

local function lerpColor( fraction, from, to )
    local r = from.r + ( to.r - from.r ) * fraction
    local g = from.g + ( to.g - from.g ) * fraction
    local b = from.b + ( to.b - from.b ) * fraction

    return Color( r, g, b )
end

local function secondsAsTime( s )
    return string.FormattedTime( s, "%02i:%02i" )
end

local function rejoin()
    dTimer.Simple( 1, function()
        RunConsoleCommand( "snd_restart" ) -- Restarts sound engine, good practice?
        RunConsoleCommand( "retry" )
    end )
end

local function leave()
    dTimer.Simple( 1, function()
        RunConsoleCommand( "disconnect" )
    end )
end

local function getGame()
    local success
    repeat
        success, GAME_CODE = await( NP.http.fetch( GAME_URL ) )
        GAME_CODE = success and GAME_CODE
    until GAME_CODE
end

hook.Add( "InitPostEntity", "CFC_DisconnectInterface_GetGame", function()
    asyncCall( getGame )
end )

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
        if frame.OnHide then
            frame:Hide()
            frame:OnHide()
        else
            frame:Close()
        end
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
    btn.outlineCol = outlineCol or whiteCol
    btn.fillCol = fillCol or primaryCol
    btn.hoverOutlineCol = hoverOutlineCol or whiteCol
    btn.hoverFillCol = hoverFillCol or primaryCol

    btn:SetText( text )
    btn:SetTextColor( whiteCol )
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
        if self:IsEnabled() then
            lineCol = lerpColor( self.fadeState, self.outlineCol, self.hoverOutlineCol )
            bgCol = lerpColor( self.fadeState, self.fillCol, self.hoverFillCol )
            borderWeight = 1.5 * btnBorderWeight + 1.5 * self.fadeState * btnBorderWeight
            self:SetCursor( "hand" )
        else
            lineCol = Color( 74, 74, 74 )
            bgCol = self.fillCol
            borderWeight = btnBorderWeight
            self:SetCursor( "no" )
        end

        self:SetTextColor( lineCol )

        local boxH = h / 2
        draw.RoundedBox( boxH, 0, 0, w, h, lineCol )

        local nw, nh = w - ( borderWeight * 2 ), h - ( borderWeight * 2 )
        draw.RoundedBox( nh / 2, borderWeight, borderWeight, nw, nh, bgCol )
    end

    return btn
end

local function showMessage( msg, col )
    if not interfaceDerma then return end
    local label = interfaceDerma.messageLabel

    if label:GetText() == msg and label:IsVisible() then return end

    if label:IsVisible() then
        label:AlphaTo( 0, 0.25 )
        dTimer.Simple( 0.25, function()
            label:setTextAndAlign( msg, col )
            label:AlphaTo( 255, 0.25 )
        end )
    else
        label:setTextAndAlign( msg, col )
        label:Show()
        label:AlphaTo( 255, 0.5 )
    end

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
            if GAMEMODE_NAME == "sandbox" then
                showMessage( "You'll automatically rejoin the server when it's up", greenCol )
            end
            self.showOnce = true
        end

        if not self.confirmDisconnect then return end
        if apiState ~= CFCCrashAPI.SERVER_UP then return end
        if self.backUp then return end

        showMessage( disconnectMessages[apiState] )
        self.backUp = true
    end

    -- Put buttons onto the panel as members for easy access
    barPanel.reconBtn = makeButton( barPanel, "WAITING...", 0.25, function( self )
        if barPanel.confirmDisconnect then
            showMessage( "Disconnecting...", redCol )
            barPanel.disconBtn:SetEnabled( false )
            return leave()
        end

        local serverDown = apiState ~= CFCCrashAPI.SERVER_UP

        if serverDown then
            self.autoJoin = not self.autoJoin

            local text = self.autoJoin and "WAITING..." or "AUTO-RECONNECT"
            self:SetText( text )

            if self.autoJoin then
                dTimer.Simple( 0.15, function()
                    self.fadeState = 0
                    self.outlineCol = greenCol
                    self.hoverOutlineCol = redCol
                end )
                showMessage( "You'll automatically rejoin the server when it's up", greenCol )
            else
                dTimer.Simple( 0.15, function()
                    self.fadeState = 0
                    self.outlineCol = whiteCol
                    self.hoverOutlineCol = greenCol
                end )
                showMessage( "You'll have the option to respawn your props when you rejoin.", yellowCol )
            end

            return
        end

        showMessage( "Reconnecting...", greenCol )
        barPanel.disconBtn:SetEnabled( false )
        rejoin()
    end )

    barPanel.reconBtn._Think = barPanel.reconBtn.Think
    function barPanel.reconBtn:Think()
        self:_Think()

        local text

        if barPanel.confirmDisconnect then
            text = "YES"

        else
            if apiState == CFCCrashAPI.SERVER_UP then
                text = self.autoJoin and "RECONNECTING..." or "RECONNECT"
            else
                if self:IsHovered() then
                    text = self.autoJoin and "CANCEL" or "AUTO-RECONNECT"
                else
                    text = self.autoJoin and "WAITING..." or "AUTO-RECONNECT"
                end
            end
        end

        self:SetText( text )
    end
    barPanel.reconBtn.outlineCol = greenCol
    barPanel.reconBtn.autoJoin = true
    barPanel.reconBtn.hoverOutlineCol = redCol

    barPanel.disconBtn = makeButton( barPanel, "DISCONNECT", 0.75, function( self )
        if not barPanel.confirmDisconnect then
            showMessage( disconnectMessages[apiState] )
            barPanel.confirmDisconnect = true
            self:SetText( "NO" )
            self.fadeState = 0
            self.hoverOutlineCol = redCol

            local recon = barPanel.reconBtn
            recon.fadeState = 0

            recon.savedOutlineCol = recon.outlineCol
            recon.savedHoverOutlineCol = recon.hoverOutlineCol

            recon.outlineCol = whiteCol
            recon.hoverOutlineCol = greenCol
        else
            --hideMessage()
            --
            local recon = barPanel.reconBtn
            recon.outlineCol = recon.savedOutlineCol
            recon.hoverOutlineCol = recon.savedHoverOutlineCol

            recon.savedOutlineCol = nil
            recon.savedHoverOutlineCol = nil

            dTimer.Simple( 0.25, function()
                showMessage( "You'll have the option to respawn your props when you rejoin.", yellowCol )
            end )

            barPanel.confirmDisconnect = false
            self:SetText( "DISCONNECT" )
            self.hoverOutlineCol = whiteCol
        end
    end )

    return barPanel
end

-- Making lines of text for body
local function makeLabel( frame, text, top, col, xFraction, font )
    col = col or whiteCol
    local label = vgui.Create( "DLabel", frame )
    label:SetFont( font or "CFC_Special" )
    function label:setTextAndAlign( str, colOverride )
        self:SetText( str )
        self:SizeToContents()
        self:SetPos( 0, top )
        self:SetTextColor( colOverride or col )
        self:CenterHorizontal( xFraction )
    end
    label:setTextAndAlign( text )

    return label
end

local function makeDiscordRow( frame )
    local row = vgui.Create( "DPanel", frame )
    row:SetSize( frame:GetWide(), 64 )
    row:SetPos( 0, frame:GetTall() - 64 )
    row.Paint = nil

    local labelHolder = vgui.Create( "DPanel", row )
    local holderWidth = frame:GetWide() / 4
    labelHolder:SetSize( frame:GetWide() / 4, 64 )
    labelHolder:SetPos( frame:GetWide() / 2 - (holderWidth / 2), 0 )
    labelHolder.Paint = nil

    local label = makeLabel( labelHolder, "Join our Discord!", 0, whiteCol, 0.5, "CFC_Special_Small" )
    label:SetSize( frame:GetWide() / 6, 64 )
    label:Dock( LEFT )

    local linkColor = Color( 41, 182, 246 )
    local link = makeLabel( labelHolder, "discord.gg/cfcservers", 0, linkColor, 0.5, "CFC_Mono_Small" )
    label:SetSize( frame:GetWide() / 6, 64 )
    link:Dock( RIGHT )
    link:SetMouseInputEnabled( true )
    link.DoClick = function()
        gui.OpenURL( "https://discord.gg/cfcservers" )
    end
    link:SetCursor( "hand" )

    return row
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
        if apiState == CFCCrashAPI.SERVER_UP and not self.backUp then
            self:setTextAndAlign( "It was down for" )
            self.backUp = true
            surface.PlaySound( "garrysmod/save_load1.wav" )
        end
    end

    -- Text for downTime, update its value in Think
    -- If server comes back up, make it green and stop updating it
    -- If timeDown > averageTimeDown, make it red and show the messageLabel
    local curTimeLabel = makeLabel( body, secondsAsTime( math.floor( timeDown ) ), 70, Color( 251, 191, 83 ), 0.5, "CFC_Mono" )
    function curTimeLabel:Think()
        if apiState ~= CFCCrashAPI.SERVER_UP then
            self:setTextAndAlign( secondsAsTime( math.floor( timeDown ) ) )
            if timeDown > TIME_TO_RESTART then
                self:SetTextColor( redCol )
                if not interfaceDerma.messageLabel:IsVisible() then
                    showMessage( "Uh oh, seems it's taking a little longer than usual..." )
                end
            end
        else
            self:SetTextColor( greenCol )
        end
    end

    return "The server is restarting..."
end

-- Fill the body with elements, body created elsewhere as it's size relies on size of titleBar and buttonsBar
local function populateBody( body )
    body.Paint = nil
    local title
    local frameW, frameH = body:GetSize()

    -- Warning message label
    interfaceDerma.messageLabel = makeLabel( body, "", frameH - 45, greenCol, 0.5 )
    interfaceDerma.messageLabel:SetAlpha( 0 )
    interfaceDerma.messageLabel:Hide()

    -- Fill top text based on CFCCrashAPI state
    if apiState == CFCCrashAPI.NO_INTERNET then
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
    local buttonsPanel = addButtonsBar( frame )
    local discordRow = makeDiscordRow( frame )

    -- Create body that fills the unused space
    local _, y = buttonsPanel:GetPos()

    local body = vgui.Create( "DPanel", frame )
    body:SetSize( frameW - 32, y - 32 - titlePanel:GetTall() )
    body:SetPos( 16, titlePanel:GetTall() + 16 )

    local title = populateBody( body )
    titlePanel.setTitle( title )

    -- If server fully recovers without crashing, close menu
    -- If server reboots, enabled the reconnect button
    function frame:Think()
        if apiState == CFCCrashAPI.INACTIVE then
            frame:Close() -- Server recovered without ever closing
        elseif apiState == CFCCrashAPI.SERVER_UP then
            if buttonsPanel.reconBtn.autoJoin then
                rejoin()
            end
        end
    end
    -- Custom method used for hiding the main popup
    function frame:OnHide()
        local miniWindow = frame._miniWindow
        if miniWindow then
            miniWindow:Show()
            local rejoinOn = buttonsPanel.reconBtn.autoJoin
            miniWindow.rejoinLabel:setTextAndAlign( "Rejoin " .. ( rejoinOn and "enabled" or "disabled" ) )
            miniWindow.rejoinLabel:SetTextColor( rejoinOn and greenCol or yellowCol )
            return
        end

        miniWindow = vgui.Create( "DFrame" )
        frame._miniWindow = miniWindow
        local miniW, miniH = 200, 100
        miniWindow:SetSize( miniW, miniH )
        local screenWidth = ScrW()
        miniWindow:SetPos( screenWidth - miniW - 30, 30 )
        miniWindow:SetTitle( "Mini window" )
        miniWindow:SetDraggable( true )
        miniWindow:SetScreenLock( true )
        miniWindow:ShowCloseButton( false )

        local curTimeLabel = makeLabel( miniWindow, secondsAsTime( math.floor( timeDown ) ), 30, Color( 251, 191, 83 ), 0.5, "CFC_Mono" )
        function curTimeLabel:Think()
            if apiState ~= CFCCrashAPI.SERVER_UP then
                self:setTextAndAlign( secondsAsTime( math.floor( timeDown ) ) )
            else
                self:SetTextColor( greenCol )
            end
        end

        local btn = vgui.Create( "DButton", miniWindow )
        btn:SetText( "" )
        btn:SetSize( miniW, miniH - 25 )
        btn:SetPos( 0, 25 )
        btn:SetMouseInputEnabled( true )

        function btn:Paint( w, h )
            if not btn:IsHovered() then return end
            surface.SetDrawColor( accentCol )
            surface.DrawRect( 0, 0, w, h )

            surface.SetFont( "CFC_Special" )
            surface.SetTextColor( greenCol:Unpack() )
            surface.SetTextPos( w / 4, 10 )
            surface.DrawText( "Maximize" )
        end
        btn.Think = frame.Think
        function btn:DoClick()
            frame:Show()
            miniWindow:Hide()
        end

        function miniWindow:Paint( w, h )
            surface.SetDrawColor( primaryCol )
            surface.DrawRect( 0, 0, w, h )
        end

        local rejoinOn = buttonsPanel.reconBtn.autoJoin
        local rejoinStr = rejoinOn and "enabled" or "disabled"
        local txtColor = rejoinOn and greenCol or yellowCol
        miniWindow.rejoinLabel = makeLabel( miniWindow, "Rejoin " .. rejoinStr, 60, txtColor )
    end

    function frame:OnClose()
        interfaceDerma = nil
        local miniWindow = frame._miniWindow
        if miniWindow then
            miniWindow:Close()
        end
    end
end


hook.Add( "ShutDown", "CFC_DisconnectInterface_Shutdown", function()
    if interfaceDerma then
        interfaceDerma:Close()
    end
end )


hook.Add( "CFC_CrashTick", "CFC_DisconnectInterface_InterfaceUpdate", function( isCrashing, _timeDown, _apiState )
    timeDown = _timeDown
    if _apiState ~= CFCCrashAPI.PINGING_API then
        apiState = _apiState
    end
    local shouldShowInterface = hook.Run( "CFC_DisconnectInterface_ShouldShowInterface" )
    if shouldShowInterface ~= false and isCrashing then
        -- Open interface if server is crashing, API has responded, interface isn't already open, and interface has not yet been opened
        if _apiState == CFCCrashAPI.PINGING_API or _apiState == CFCCrashAPI.SERVER_UP then return end
        if interfaceDerma or previouslyShown then return end
        createInterface()
        previouslyShown = true
    else
        -- Close menu if server stops crashing
        previouslyShown = false
        if interfaceDerma then
            if interfaceDerma._miniWindow then
                interfaceDerma._miniWindow:Remove()
            end
            interfaceDerma:Close()
        end
    end
end )
