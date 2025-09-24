--[[
     _      ___         ____  ______
    | | /| / (_)__  ___/ / / / /  _/
    | |/ |/ / / _ \/ _  / /_/ // /  
    |__/|__/_/_//_/\_,_/\____/___/
    
    v1.6.52  |  2025-09-22  |  Roblox UI Library for scripts
    
    This script is NOT intended to be modified.
    To view the source code, see the `src/` folder on the official GitHub repository.
    
    Author: Footagesus (Footages, .ftgs, oftgs)
    Github: https://github.com/Footagesus/WindUI
    Discord: https://discord.gg/ftgs-development-hub-1300692552005189632
    License: MIT
]]

local WindUI = {}

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")

-- Core variables
local useStudio = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer

-- Core modules
local Core = {}
local Themes = {}
local Notifications = {}
local Localization = {}
local Discord = {}

-- Default configuration
local DefaultConfig = {
    Font = "rbxassetid://12187365364",
    Localization = nil,
    CanDraggable = true,
    Theme = nil,
    Themes = {},
    Signals = {},
    Objects = {},
    LocalizationObjects = {},
    FontObjects = {},
    Language = string.match(LocalizationService.SystemLocaleId, "^[a-z]+"),
    Request = (syn and syn.request) or request or http_request,
    
    DefaultProperties = {
        ScreenGui = { ResetOnSpawn = false, ZIndexBehavior = "Sibling" },
        CanvasGroup = { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) },
        Frame = { BorderSizePixel = 0, BackgroundColor3 = Color3.new(1,1,1) },
        TextLabel = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", RichText = true, TextColor3 = Color3.new(1,1,1), TextSize = 14 },
        TextButton = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Text = "", AutoButtonColor = false, TextColor3 = Color3.new(1,1,1), TextSize = 14 },
        TextBox = { BackgroundColor3 = Color3.new(1,1,1), BorderColor3 = Color3.new(0,0,0), ClearTextOnFocus = false, Text = "", TextColor3 = Color3.new(0,0,0), TextSize = 14 },
        ImageLabel = { BackgroundTransparency = 1, BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0 },
        ImageButton = { BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, AutoButtonColor = false },
        UIListLayout = { SortOrder = "LayoutOrder" },
        ScrollingFrame = { ScrollBarImageTransparency = 1, BorderSizePixel = 0 },
        VideoFrame = { BorderSizePixel = 0 }
    },
    
    Colors = {
        Red = "#e53935",
        Orange = "#f57c00",
        Green = "#43a047",
        Blue = "#039be5",
        White = "#ffffff",
        Grey = "#484848",
    },
}

-- Discord Integration
function Discord.Invite(settings, folderName)
    if not settings.Enabled or useStudio then return false end
    
    local inviteFolder = "WindUI/" .. folderName .. "/Discord Invites"
    local inviteCode = settings.Invite
    local configExtension = ".txt"
    
    -- Create folder if it doesn't exist
    if isfolder and not isfolder(inviteFolder) then
        makefolder(inviteFolder)
    end
    
    -- Check if user already joined (if RememberJoins is enabled)
    if settings.RememberJoins and isfile and isfile(inviteFolder .. "/" .. inviteCode .. configExtension) then
        return true
    end
    
    -- Try to invite through Discord RPC
    local success = false
    
    if DefaultConfig.Request then
        local ok, result = pcall(function()
            local response = DefaultConfig.Request({
                Url = 'http://127.0.0.1:6463/rpc?v=1',
                Method = 'POST',
                Headers = {
                    ['Content-Type'] = 'application/json',
                    Origin = 'https://discord.com'
                },
                Body = HttpService:JSONEncode({
                    cmd = 'INVITE_BROWSER',
                    nonce = HttpService:GenerateGUID(false),
                    args = {code = inviteCode}
                })
            })
            
            if response.StatusCode == 200 then
                success = true
            end
        end)
        
        if not ok then
            warn("[WindUI] Discord invite failed: " .. tostring(result))
        end
    end
    
    -- Remember the invite if successful and RememberJoins is enabled
    if success and settings.RememberJoins and writefile then
        pcall(function()
            writefile(inviteFolder .. "/" .. inviteCode .. configExtension, "WindUI RememberJoins is true for this invite")
        end)
    end
    
    return success
end

function Discord.ExtractInviteCode(url)
    if not url or url == "" then return "" end
    
    -- Remove various Discord URL formats
    local code = url:gsub("https?://discord%.gg/", "")
    code = code:gsub("https?://discord%.com/invite/", "")
    code = code:gsub("discord%.gg/", "")
    code = code:gsub("discord%.com/invite/", "")
    
    -- Remove any trailing slashes or parameters
    code = code:gsub("/.*", "")
    code = code:gsub("%?.*", "")
    
    return code
end

-- Core functionality
function Core.New(className, properties, children)
    local instance = Instance.new(className)
    
    -- Apply default properties
    local defaults = DefaultConfig.DefaultProperties[className] or {}
    for property, value in pairs(defaults) do
        instance[property] = value
    end
    
    -- Apply custom properties
    for property, value in pairs(properties or {}) do
        if property ~= "ThemeTag" then
            instance[property] = value
        end
    end
    
    -- Add children
    for _, child in pairs(children or {}) do
        child.Parent = instance
    end
    
    return instance
end

function Core.Tween(object, duration, properties, easingStyle, easingDirection)
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    return TweenService:Create(object, TweenInfo.new(duration, easingStyle, easingDirection), properties)
end

function Core.AddSignal(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(DefaultConfig.Signals, connection)
    return connection
end

-- Theme system
Themes.List = {
    Dark = { Name = "Dark", Accent = "#18181b", Dialog = "#161616", Outline = "#FFFFFF", Text = "#FFFFFF", Placeholder = "#999999", Background = "#101010", Button = "#52525b", Icon = "#a1a1aa" },
    Light = { Name = "Light", Accent = "#FFFFFF", Dialog = "#f4f4f5", Outline = "#09090b", Text = "#000000", Placeholder = "#777777", Background = "#e4e4e7", Button = "#18181b", Icon = "#52525b" },
    Rose = { Name = "Rose", Accent = "#be185d", Dialog = "#4c0519", Outline = "#fecdd3", Text = "#fdf2f8", Placeholder = "#f9a8d4", Background = "#1f0308", Button = "#e11d48", Icon = "#fb7185" },
    Plant = { Name = "Plant", Accent = "#166534", Dialog = "#052e16", Outline = "#bbf7d0", Text = "#f0fdf4", Placeholder = "#86efac", Background = "#0a1b0f", Button = "#16a34a", Icon = "#4ade80" },
}

function WindUI:SetTheme(themeName)
    if Themes.List[themeName] then
        DefaultConfig.Theme = Themes.List[themeName]
        -- Apply theme to all themed objects
        for _, themedObject in pairs(DefaultConfig.Objects) do
            -- Theme application logic here
        end
        return true
    end
    return false
end

function WindUI:AddTheme(themeData)
    if themeData and themeData.Name then
        Themes.List[themeData.Name] = themeData
        return themeData
    end
    return nil
end

function WindUI:GetThemes()
    return Themes.List
end

-- Notification system
function WindUI:Notify(notificationData)
    notificationData = notificationData or {}
    
    -- Create notification UI elements
    local notification = {
        Title = notificationData.Title or "Notification",
        Content = notificationData.Content,
        Duration = notificationData.Duration or 5,
        Icon = notificationData.Icon
    }
    
    -- Notification implementation here
    return notification
end

-- Localization system
function WindUI:Localization(config)
    DefaultConfig.Localization = {
        Enabled = config.Enabled or false,
        Translations = config.Translations or {},
        Prefix = config.Prefix or "loc:",
        DefaultLanguage = config.DefaultLanguage or "en"
    }
    return DefaultConfig.Localization
end

function WindUI:SetLanguage(languageCode)
    if DefaultConfig.Localization and DefaultConfig.Localization.Translations[languageCode] then
        DefaultConfig.Language = languageCode
        -- Update all localized objects
        for _, localizedObject in pairs(DefaultConfig.LocalizationObjects) do
            -- Language update logic here
        end
        return true
    end
    return false
end

-- Gradient utility
function WindUI:Gradient(colorStops, additionalProperties)
    local colorKeypoints = {}
    local transparencyKeypoints = {}
    
    for position, data in pairs(colorStops) do
        local time = tonumber(position)
        if time then
            time = math.clamp(time / 100, 0, 1)
            table.insert(colorKeypoints, ColorSequenceKeypoint.new(time, data.Color))
            table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(time, data.Transparency or 0))
        end
    end
    
    table.sort(colorKeypoints, function(a, b) return a.Time < b.Time end)
    table.sort(transparencyKeypoints, function(a, b) return a.Time < b.Time end)
    
    if #colorKeypoints < 2 then
        error("Gradient requires at least 2 color stops")
    end
    
    local gradient = {
        Color = ColorSequence.new(colorKeypoints),
        Transparency = NumberSequence.new(transparencyKeypoints)
    }
    
    if additionalProperties then
        for property, value in pairs(additionalProperties) do
            gradient[property] = value
        end
    end
    
    return gradient
end

-- Window creation
function WindUI:CreateWindow(config)
    config = config or {}
    
    -- Default window configuration
    local windowConfig = {
        Title = config.Title or "WindUI Window",
        Icon = config.Icon,
        Author = config.Author,
        Folder = config.Folder or config.Title,
        Size = config.Size or UDim2.fromOffset(580, 460),
        Transparent = config.Transparent or false,
        Theme = config.Theme or "Dark",
        Background = config.Background,
        User = config.User or { Enabled = false },
        Discord = config.Discord or { Enabled = false, RememberJoins = true, Invite = "" },
        SideBarWidth = config.SideBarWidth or 200,
        ToggleKey = config.ToggleKey,
        Resizable = config.Resizable ~= false,
        MinSize = config.MinSize or Vector2.new(560, 350),
        MaxSize = config.MaxSize or Vector2.new(850, 560)
    }
    
    -- Process Discord invite if enabled
    if windowConfig.Discord.Enabled and not useStudio then
        -- Extract invite code if full URL is provided
        if windowConfig.Discord.Invite:find("discord") then
            windowConfig.Discord.Invite = Discord.ExtractInviteCode(windowConfig.Discord.Invite)
        end
        
        Discord.Invite(windowConfig.Discord, windowConfig.Folder)
    end
    
    -- Set theme
    self:SetTheme(windowConfig.Theme)
    
    -- Create window UI structure
    local window = {
        Config = windowConfig,
        UIElements = {},
        Tabs = {},
        IsOpen = false,
        Destroyed = false
    }
    
    -- Create main GUI containers
    local screenGui = Core.New("ScreenGui", {
        Name = "WindUI_" .. windowConfig.Title,
        ResetOnSpawn = false,
        ZIndexBehavior = "Sibling"
    })
    
    local mainFrame = Core.New("Frame", {
        Size = windowConfig.Size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1
    }, {
        Core.New("UICorner", { CornerRadius = UDim.new(0, 16) })
    })
    
    -- Apply background
    if windowConfig.Background then
        local background = Core.New("ImageLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ScaleType = "Crop",
            Image = typeof(windowConfig.Background) == "string" and windowConfig.Background or "",
            ImageTransparency = windowConfig.Transparent and 0.8 or 0.6
        }, {
            Core.New("UICorner", { CornerRadius = UDim.new(0, 16) })
        })
        background.Parent = mainFrame
    end
    
    -- Create top bar
    local topBar = Core.New("Frame", {
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 0.95,
        BackgroundColor3 = Color3.fromHex("#ffffff")
    }, {
        Core.New("UICorner", { CornerRadius = UDim.new(0, 16, 0, 0) })
    })
    
    -- Add title
    local titleLabel = Core.New("TextLabel", {
        Text = windowConfig.Title,
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        TextColor3 = Color3.fromHex("#ffffff"),
        TextSize = 18,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = "Left"
    })
    titleLabel.Parent = topBar
    
    -- Add author if provided
    if windowConfig.Author then
        local authorLabel = Core.New("TextLabel", {
            Text = windowConfig.Author,
            Size = UDim2.new(1, -100, 0, 20),
            Position = UDim2.new(0, 50, 1, -25),
            BackgroundTransparency = 1,
            TextColor3 = Color3.fromHex("#aaaaaa"),
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = "Left"
        })
        authorLabel.Parent = topBar
    end
    
    topBar.Parent = mainFrame
    mainFrame.Parent = screenGui
    
    -- Store UI elements
    window.UIElements.ScreenGui = screenGui
    window.UIElements.MainFrame = mainFrame
    window.UIElements.TopBar = topBar
    window.UIElements.TitleLabel = titleLabel
    
    -- Window methods
    function window:Open()
        if self.Destroyed then return end
        
        self.IsOpen = true
        screenGui.Parent = game:GetService("CoreGui")
        
        -- Animation for opening
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        Core.Tween(mainFrame, 0.3, {
            Size = windowConfig.Size
        }):Play()
        
        return self
    end
    
    function window:Close()
        if self.Destroyed then return end
        
        self.IsOpen = false
        
        -- Animation for closing
        Core.Tween(mainFrame, 0.3, {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        
        task.wait(0.3)
        screenGui.Parent = nil
        
        return function()
            self:Destroy()
        end
    end
    
    function window:Destroy()
        if self.Destroyed then return end
        
        self.Destroyed = true
        if screenGui then
            screenGui:Destroy()
        end
        
        if WindUI.OnDestroyCallback then
            WindUI.OnDestroyCallback(self)
        end
    end
    
    function window:Toggle()
        if self.IsOpen then
            return self:Close()
        else
            return self:Open()
        end
    end
    
    function window:SetTitle(newTitle)
        windowConfig.Title = newTitle
        if titleLabel then
            titleLabel.Text = newTitle
        end
        return self
    end
    
    -- Add tab functionality
    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        
        local tab = {
            Name = tabConfig.Title or "Tab",
            Icon = tabConfig.Icon,
            Elements = {}
        }
        
        -- Tab implementation here
        table.insert(window.Tabs, tab)
        return tab
    end
    
    -- Key binding for toggling
    if windowConfig.ToggleKey then
        Core.AddSignal(UserInputService.InputBegan, function(input)
            if input.KeyCode == windowConfig.ToggleKey then
                window:Toggle()
            end
        end)
    end
    
    -- Auto-open window
    window:Open()
    
    return window
end

-- Callback system
WindUI.OnDestroyCallback = nil

function WindUI:OnDestroy(callback)
    self.OnDestroyCallback = callback
end

-- Initialize WindUI
function WindUI:Init()
    -- Initialization logic here
    return self
end

-- Return the WindUI object
return WindUI:Init()
