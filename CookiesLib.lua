local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
Library.Version = "3.3.0"
Library.Flags = {}
Library.Options = Library.Flags
Library.Windows = {}
Library._binding = false

local rgb = Color3.fromRGB
local Theme = {
    Background  = rgb(19, 13, 10),
    Panel       = rgb(27, 19, 14),
    Element     = rgb(33, 23, 17),
    Row         = rgb(40, 28, 20),
    RowHover    = rgb(50, 34, 24),
    Input       = rgb(21, 14, 11),
    Stroke      = rgb(74, 51, 33),
    Outline     = rgb(10, 7, 5),
    Accent      = rgb(245, 194, 12),
    AccentHi    = rgb(255, 214, 64),
    AccentSoft  = rgb(52, 38, 16),
    OnAccent    = rgb(46, 28, 6),
    Text        = rgb(244, 235, 222),
    Muted       = rgb(176, 156, 134),
    Dim         = rgb(122, 105, 90),
    Success     = rgb(96, 196, 124),
    Warning     = rgb(232, 148, 58),
    Error       = rgb(224, 92, 92),
}
Library.Theme = Theme

local function tryFont(name)
    local ok, f = pcall(function() return Enum.Font[name] end)
    return ok and f or nil
end

local Fonts = {
    Title = tryFont("BuilderSansBold") or Enum.Font.GothamBold,
    Body  = tryFont("BuilderSans") or Enum.Font.GothamMedium,
    Bold  = tryFont("BuilderSansBold") or Enum.Font.GothamBold,
}
Library.Fonts = Fonts

local DEFAULT_LOGO = "rbxassetid://76143769732706"
local DEFAULT_INTRO_LOGO = "rbxassetid://82156497939861"

local SOFT, SOFT_DIR = Enum.EasingStyle.Quart, Enum.EasingDirection.InOut

Library.Config = {
    Animations = true,
    AnimationSpeed = 1,
    EasingStyle = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,

    Window = {
        Title = "Cookies Hub",
        Subtitle = nil,
        Logo = DEFAULT_LOGO,
        Width = 740, Height = 500,
        MinWidth = 480, MinHeight = 320,
        SidebarWidth = 160,
        CompactSidebarWidth = 58,
        CompactBelow = 600,
        MinScale = 0.7,
        ToggleKey = Enum.KeyCode.RightShift,
        ConfigFolder = "CookiesHub",
        FloatingButton = true,
        Resizable = true,
        Draggable = true,
        Minimizable = true,
        Closable = true,
        ShowProfile = true,
        AutoScale = true,
        DisplayOrder = 50,
        Corner = 10,
    },
    Tab = { Columns = 2, Padding = 12, Gap = 10, IconSize = 20, IconTint = true, SingleColumnBelow = 440 },
    Section = {
        Collapsible = true, Minimized = false, Columns = 1, MaxHeight = nil,
        Gap = 6, ColumnGap = 8, Corner = 8,
    },
    Element = { Height = 32, Corner = 6 },
    Notify = { Duration = 4, Width = 290 },
    Intro = {
        Enabled = true,
        Duration = 2.4,            -- segundos totales que dura la intro
        Logo = DEFAULT_INTRO_LOGO, -- logo de Cookies (PNG sin fondo)
        Width = 300, Height = 180,
        ShowBar = true,            -- barra de carga debajo del logo
    },
}

local function pick(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then return v end
    end
    return nil
end

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local c = {}
    for k, v in pairs(t) do c[k] = deepCopy(v) end
    return c
end

local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            merge(dst[k], v)
        else
            dst[k] = v
        end
    end
    return dst
end

local function applyTheme(t)
    merge(Theme, t)
    if t.Accent then
        if not t.AccentHi then Theme.AccentHi = t.Accent:Lerp(Color3.new(1, 1, 1), 0.25) end
        if not t.AccentSoft then Theme.AccentSoft = Theme.Panel:Lerp(t.Accent, 0.14) end
        if not t.OnAccent then
            local lum = 0.299 * t.Accent.R + 0.587 * t.Accent.G + 0.114 * t.Accent.B
            Theme.OnAccent = lum > 0.55 and rgb(40, 20, 8) or Color3.new(1, 1, 1)
        end
    end
end

function Library:SetTheme(t) applyTheme(t) end

function Library:Configure(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
        if k == "Theme" then applyTheme(v)
        elseif type(v) == "table" and type(Library.Config[k]) == "table" then merge(Library.Config[k], v)
        else Library.Config[k] = v end
    end
end

local function create(className, props, children)
    local inst = Instance.new(className)
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if inst:IsA("GuiButton") then inst.AutoButtonColor = false end
    if className == "TextLabel" or className == "ImageLabel" then
        inst.BackgroundTransparency = 1
    end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, child in ipairs(children or {}) do child.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, thickness, transparency)
    return create("UIStroke", {
        Color = color, Thickness = thickness or 1, Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(l, t, r, b)
    return create("UIPadding", {
        PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b),
    })
end

local function listLayout(pad, props)
    local p = { Padding = UDim.new(0, pad or 0), SortOrder = Enum.SortOrder.LayoutOrder }
    for k, v in pairs(props or {}) do p[k] = v end
    return create("UIListLayout", p)
end

local function tween(obj, props, time, style, dir)
    local C = Library.Config
    if not time or time <= 0 or not C.Animations then
        for k, v in pairs(props) do obj[k] = v end
        return nil
    end
    time = time / math.max(C.AnimationSpeed or 1, 0.05)
    local tw = TweenService:Create(obj, TweenInfo.new(time, style or C.EasingStyle, dir or C.EasingDirection), props)
    tw:Play()
    return tw
end

local function tweenThen(obj, props, time, fn, style, dir)
    local tw = tween(obj, props, time, style, dir)
    if tw then
        tw.Completed:Connect(function() fn() end)
    else
        fn()
    end
    return tw
end

local function label(props)
    local p = {
        Font = Fonts.Body, TextSize = 13, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props) do p[k] = v end
    return create("TextLabel", p)
end

local function hover(obj, normal, over, prop)
    prop = prop or "BackgroundColor3"
    obj.MouseEnter:Connect(function() tween(obj, { [prop] = over }, 0.12) end)
    obj.MouseLeave:Connect(function() tween(obj, { [prop] = normal }, 0.12) end)
end

local function emit(callback, ...)
    if callback then task.spawn(callback, ...) end
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function dragger(handle, onStart, onMove, onEnd)
    handle.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        if onStart then onStart(input) end
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i == input then
                onMove(i)
            end
        end)
        endConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConn:Disconnect()
                endConn:Disconnect()
                if onEnd then onEnd(input) end
            end
        end)
    end)
end

local function keyFromValue(v)
    if typeof(v) == "EnumItem" then return v end
    if type(v) == "string" and Enum.KeyCode[v] then return Enum.KeyCode[v] end
    return Enum.KeyCode.Unknown
end

local function keyName(k)
    return (k == nil or k == Enum.KeyCode.Unknown) and "None" or k.Name
end

local function toHex(c)
    return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function resolveIcon(icon, fallbackName)
    local fallback = tostring(fallbackName or "?"):sub(1, 1):upper()
    if type(icon) == "table" then
        local asset = icon.Image or icon.Asset or icon.AssetId or icon.Id
        if asset ~= nil then
            if type(asset) == "number" then asset = "rbxassetid://" .. tostring(asset) end
            asset = tostring(asset)
            if asset:match("^%d+$") then asset = "rbxassetid://" .. asset end
            local hasRect = typeof(icon.ImageRectSize) == "Vector2" and typeof(icon.ImageRectOffset) == "Vector2"
            return "image", asset, hasRect and { icon.ImageRectSize, icon.ImageRectOffset } or nil
        end
        return "letter", tostring(icon.Text or icon.Letter or fallback):sub(1, 2)
    end
    if type(icon) == "number" then return "image", "rbxassetid://" .. tostring(icon) end
    if type(icon) == "string" and icon ~= "" then
        local lower = string.lower(icon)
        if lower:match("^rbxassetid://") or lower:match("^rbxthumb://") or lower:match("^rbxasset://")
            or lower:match("^https?://") then
            return "image", icon
        end
        if icon:match("^%d+$") and #icon > 4 then return "image", "rbxassetid://" .. icon end
        return "letter", icon:sub(1, 2)
    end
    return "letter", fallback
end

local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function"
    and typeof(isfolder) == "function" and typeof(makefolder) == "function"

local IS_TOUCH = UserInputService.TouchEnabled

local WindowMT, TabMT, SectionMT = {}, {}, {}
WindowMT.__index = WindowMT
TabMT.__index = TabMT
SectionMT.__index = SectionMT

function Library:GetObject(flag) return Library.Flags[flag] end
function Library:GetFlag(flag)
    local o = Library.Flags[flag]
    if o then return o.Value end
    return nil
end
function Library:SetFlag(flag, value, silent)
    local o = Library.Flags[flag]
    if not o then return false end
    o:Set(value, silent)
    return true
end
Library.Get = Library.GetFlag
Library.Set = Library.SetFlag

local function fire(obj, o, ...)
    emit(o.Callback, ...)
    for _, fn in ipairs(obj._listeners) do emit(fn, ...) end
end

local function decorate(section, obj, frame, o)
    obj.Frame = frame
    obj.Section = section
    obj.Enabled = true
    obj._listeners = obj._listeners or {}
    function obj:SetVisible(v) frame.Visible = v ~= false end
    function obj:SetCallback(fn) o.Callback = fn end
    function obj:OnChanged(fn)
        table.insert(obj._listeners, fn)
        return { Disconnect = function()
            local i = table.find(obj._listeners, fn)
            if i then table.remove(obj._listeners, i) end
        end }
    end
    local overlay
    function obj:SetEnabled(state)
        state = state ~= false
        obj.Enabled = state
        if not state and not overlay then
            overlay = create("TextButton", {
                Text = "", Size = UDim2.fromScale(1, 1), ZIndex = 20, Active = true,
                BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.45, Parent = frame,
            }, { corner(section.Window.Config.Element.Corner) })
        end
        if overlay then overlay.Visible = not state end
    end
    function obj:Destroy()
        if o.Flag and Library.Flags[o.Flag] == obj then Library.Flags[o.Flag] = nil end
        local kb = table.find(section.Window._keybinds, obj)
        if kb then table.remove(section.Window._keybinds, kb) end
        frame:Destroy()
    end
    if o.Enabled == false or o.Disabled == true then obj:SetEnabled(false) end
    if o.Visible == false then frame.Visible = false end
    return obj
end

local TOP_H = 48
local BODY_Y = 58
local SHELL_PAD = 10
local MIN_H = 76
local BODY_OFFSET = SHELL_PAD * 2 + BODY_Y

function Library:CreateWindow(opts)
    opts = opts or {}
    local cfg = deepCopy(Library.Config)
    if type(opts.Config) == "table" then merge(cfg, opts.Config) end
    for _, k in ipairs({ "Tab", "Section", "Element", "Notify", "Intro" }) do
        if type(opts[k]) == "table" then merge(cfg[k], opts[k]) end
    end
    for k, v in pairs(opts) do
        if k ~= "Theme" and k ~= "Config" and k ~= "Tab" and k ~= "Section"
            and k ~= "Element" and k ~= "Notify" and k ~= "Intro" then
            cfg.Window[k] = v
        end
    end
    if type(opts.Theme) == "table" then applyTheme(opts.Theme) end
    local W = cfg.Window

    local self = setmetatable({}, WindowMT)
    self.Config = cfg
    self.Tabs = {}
    self.ToggleKey = W.ToggleKey
    self.ConfigFolder = W.ConfigFolder
    self.Visible = true
    self.Minimized = false
    self._conns = {}
    self._keybinds = {}
    self._flags = {}
    self._cats = {}
    self._navOrder = 0
    self._minId = 0
    self._minShift = 0
    self._ready = false
    self._intro = false
    self._w, self._h = W.Width, W.Height
    self._ew, self._eh = W.Width, W.Height

    local logo = W.Logo

    local parent = PlayerGui
    pcall(function()
        if typeof(gethui) == "function" then parent = gethui() end
    end)
    local old = parent:FindFirstChild("CookiesHubUI")
    if old then old:Destroy() end

    local gui = create("ScreenGui", {
        Name = "CookiesHubUI", ResetOnSpawn = false, DisplayOrder = W.DisplayOrder,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
    local ok = pcall(function() gui.Parent = parent end)
    if not ok then gui.Parent = PlayerGui end
    self.Gui = gui

    local function getViewport()
        local s = gui.AbsoluteSize
        if s.X < 50 or s.Y < 50 then
            local cam = workspace.CurrentCamera
            s = cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        return s
    end

    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self._w, self._h), BackgroundTransparency = 1, Parent = gui,
    })
    local uiScale = create("UIScale", { Scale = 0.96, Parent = root })
    local baseScale = 1
    self._root, self._scale = root, uiScale
    self._baseScale = function() return baseScale end

    local shell = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        ClipsDescendants = true, Parent = root,
    }, { corner(W.Corner), stroke(Theme.Outline, 1), padding(SHELL_PAD, SHELL_PAD, SHELL_PAD, SHELL_PAD) })

    local top = create("Frame", {
        Size = UDim2.new(1, 0, 0, TOP_H), BackgroundTransparency = 1, ZIndex = 5, Parent = shell,
    })
    create("Frame", {
        Position = UDim2.fromOffset(14, TOP_H + 5), Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.55, Parent = shell,
    })

    local titleX = 14
    if logo then
        create("ImageLabel", {
            Image = logo, AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 12, 0.5, 0), Size = UDim2.fromOffset(32, 32),
            ScaleType = Enum.ScaleType.Fit, ZIndex = 6, Parent = top,
        })
        titleX = 54
    end

    local titleBox = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(titleX, 0),
        Size = UDim2.new(1, -(titleX + 90), 1, 0), ZIndex = 6, Parent = top,
    }, { listLayout(0, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
    self._title = label({
        Text = W.Title, Font = Fonts.Title, TextSize = 16, ZIndex = 6,
        Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Parent = titleBox,
    })
    self._subtitle = label({
        Text = W.Subtitle or ("v" .. Library.Version), TextSize = 11, ZIndex = 6,
        TextColor3 = Theme.Dim, Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2, Parent = titleBox,
    })

    local nBtns = (W.Minimizable and 1 or 0) + (W.Closable and 1 or 0)
    local btnHolder = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0), ZIndex = 6,
        Size = UDim2.fromOffset(math.max(nBtns, 1) * 26 + math.max(nBtns - 1, 0) * 6, 26), Parent = top,
    }, { listLayout(6, { FillDirection = Enum.FillDirection.Horizontal }) })

    local function iconButton(kind, order, hoverColor)
        local b = create("TextButton", {
            Text = "", Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.Row,
            LayoutOrder = order, ZIndex = 7, Parent = btnHolder,
        }, { corner(6) })
        local bars = {}
        local function bar(rot)
            table.insert(bars, create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(10, 2), Rotation = rot, BackgroundColor3 = Theme.Muted,
                ZIndex = 8, Parent = b,
            }, { corner(1) }))
        end
        if kind == "close" then bar(45) bar(-45) else bar(0) end
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundColor3 = hoverColor }, 0.15)
            for _, f in ipairs(bars) do tween(f, { BackgroundColor3 = Theme.Text }, 0.15) end
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundColor3 = Theme.Row }, 0.15)
            for _, f in ipairs(bars) do tween(f, { BackgroundColor3 = Theme.Muted }, 0.15) end
        end)
        return b
    end
    local minBtn = W.Minimizable and iconButton("min", 1, Theme.RowHover) or nil
    local closeBtn = W.Closable and iconButton("close", 2, rgb(110, 40, 36)) or nil

    local bodyClip = create("Frame", {
        BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 1,
        Position = UDim2.fromOffset(0, BODY_Y),
        Size = UDim2.new(1, 0, 0, math.max(self._eh - BODY_OFFSET, 0)), Parent = shell,
    })
    local body = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, math.max(self._eh - BODY_OFFSET, 0)),
        Parent = bodyClip,
    })
    self._bodyClip, self._body = bodyClip, body
    local SB = W.SidebarWidth

    local sidebar = create("Frame", {
        Size = UDim2.new(0, SB, 1, 0), BackgroundTransparency = 1, Parent = body,
    })

    self._nav = create("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, W.ShowProfile and -62 or 0),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0, Parent = sidebar,
    }, { padding(8, 8, 8, 4), listLayout(4) })

    local profile, avatar, profileNames
    if W.ShowProfile then
        profile = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -8),
            Size = UDim2.new(1, -16, 0, 44), BackgroundColor3 = Theme.Row, Parent = sidebar,
        }, { corner(6) })
        avatar = create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
            Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Input, BackgroundTransparency = 0,
            Parent = profile,
        }, { corner(14), stroke(Theme.Stroke, 1, 0.4) })
        task.spawn(function()
            local success, img = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId,
                Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
            if success and avatar.Parent then avatar.Image = img end
        end)
        profileNames = create("Frame", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(44, 0),
            Size = UDim2.new(1, -50, 1, 0), Parent = profile,
        }, { listLayout(0, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
        label({ Text = LocalPlayer.DisplayName, Font = Fonts.Bold, TextSize = 12,
            Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1, Parent = profileNames })
        label({ Text = "@" .. LocalPlayer.Name, TextSize = 10, TextColor3 = Theme.Dim,
            Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2, Parent = profileNames })
    end

    local content = create("Frame", {
        Position = UDim2.fromOffset(SB + 10, 0), Size = UDim2.new(1, -(SB + 10), 1, 0),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = body,
    })
    self._content = content

    self._notifs = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0, cfg.Notify.Width, 1, -32), Parent = gui,
    }, { listLayout(8, { VerticalAlignment = Enum.VerticalAlignment.Bottom }) })

    local FLOAT_SIZE = 74
    -- solo el logo, sin fondo ni borde: el TextButton es transparente y sirve de area de click/arrastre
    local floating = create("TextButton", {
        Text = "", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, 0),
        Size = UDim2.fromOffset(FLOAT_SIZE, FLOAT_SIZE), BackgroundTransparency = 1,
        AutoButtonColor = false, Parent = gui,
    })
    local floatLogo
    if logo then
        floatLogo = create("ImageLabel", {
            Image = logo, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit,
            Parent = floating,
        })
    else
        floatLogo = label({ Text = "C", Font = Fonts.Title, TextSize = 28, TextColor3 = Theme.Accent,
            TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center,
            Size = UDim2.fromScale(1, 1), Parent = floating })
    end
    self._floating = floating

    local function clampFloating(pos)
        local vp = getViewport()
        local x = math.clamp(pos.X.Scale * vp.X + pos.X.Offset, 0, math.max(vp.X - FLOAT_SIZE, 0))
        local y = math.clamp(pos.Y.Scale * vp.Y + pos.Y.Offset, 22, math.max(vp.Y - 22, 22))
        return UDim2.fromOffset(x, y)
    end

    do
        local startInput, startPos, moved
        dragger(floating, function(input)
            startInput, startPos, moved = input.Position, floating.Position, false
        end, function(i)
            local d = i.Position - startInput
            if d.Magnitude > 6 then moved = true end
            if moved then
                floating.Position = clampFloating(UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y))
            end
        end, function()
            if not moved then self:Toggle() end
        end)
        floating.MouseEnter:Connect(function()
            tween(floatLogo, { Size = UDim2.fromScale(1.08, 1.08) }, 0.15)
        end)
        floating.MouseLeave:Connect(function()
            tween(floatLogo, { Size = UDim2.fromScale(1, 1) }, 0.15)
        end)
        floating.MouseButton1Down:Connect(function()
            tween(floatLogo, { Size = UDim2.fromScale(0.9, 0.9) }, 0.1)
        end)
        floating.MouseButton1Up:Connect(function()
            tween(floatLogo, { Size = UDim2.fromScale(1, 1) }, 0.15, Enum.EasingStyle.Back)
        end)
    end

    -- FloatingButton = false en CreateWindow oculta el boton (tambien en touch)
    if W.FloatingButton == false then floating.Visible = false end

    local function clampRoot(pos)
        local vp = getViewport()
        local s = uiScale.Scale
        local w = self._ew * s
        local h = (self.Minimized and MIN_H or self._eh) * s
        local cx = pos.X.Scale * vp.X + pos.X.Offset
        local cy = pos.Y.Scale * vp.Y + pos.Y.Offset
        local loX, hiX = 100 - w / 2, vp.X - 100 + w / 2
        local loY, hiY = h / 2, vp.Y - 48 + h / 2
        if loX > hiX then loX, hiX = vp.X / 2, vp.X / 2 end
        if loY > hiY then loY, hiY = vp.Y / 2, vp.Y / 2 end
        cx = math.clamp(cx, loX, hiX)
        cy = math.clamp(cy, loY, hiY)
        return UDim2.new(pos.X.Scale, cx - pos.X.Scale * vp.X, pos.Y.Scale, cy - pos.Y.Scale * vp.Y)
    end

    if W.Draggable then
        local startInput, startPos
        dragger(top, function(input)
            startInput, startPos = input.Position, root.Position
        end, function(i)
            local d = i.Position - startInput
            root.Position = clampRoot(UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y))
        end)
    end

    local function applyCompact(c)
        if profile then
            profileNames.Visible = not c
            avatar.AnchorPoint = c and Vector2.new(0.5, 0.5) or Vector2.new(0, 0.5)
            avatar.Position = c and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 8, 0.5, 0)
        end
        for _, cat in ipairs(self._cats) do cat.Visible = not c end
        for _, t in ipairs(self.Tabs) do t:_setCompact(c) end
    end

    local function fit()
        local vp = getViewport()
        local availX, availY = math.max(vp.X - 24, 100), math.max(vp.Y - 24, 100)
        local ew, eh, sc = self._w, self._h, 1
        if W.AutoScale then
            local ms = W.MinScale or 0.7
            ew = math.min(self._w, availX / ms)
            eh = math.min(self._h, availY / ms)
            ew = math.max(ew, math.min(W.MinWidth, availX / 0.4))
            eh = math.max(eh, math.min(W.MinHeight, availY / 0.4))
            sc = math.clamp(math.min(availX / ew, availY / eh), 0.3, 1)
        end
        ew, eh = math.floor(ew + 0.5), math.floor(eh + 0.5)
        self._ew, self._eh, baseScale = ew, eh, sc

        local compact = ew < (W.CompactBelow or 600)
        local SBw = compact and (W.CompactSidebarWidth or 58) or W.SidebarWidth
        local single = (ew - SHELL_PAD * 2 - SBw - 10) < (cfg.Tab.SingleColumnBelow or 440)
        local bh = math.max(eh - BODY_OFFSET, 0)

        sidebar.Size = UDim2.new(0, SBw, 1, 0)
        content.Position = UDim2.fromOffset(SBw + 10, 0)
        content.Size = UDim2.new(1, -(SBw + 10), 1, 0)
        body.Size = UDim2.new(1, 0, 0, bh)

        if not self.Minimized then
            root.Size = UDim2.fromOffset(ew, eh)
            bodyClip.Size = UDim2.new(1, 0, 0, bh)
        else
            root.Size = UDim2.fromOffset(ew, MIN_H)
        end

        if self._ready and self.Visible then uiScale.Scale = sc end

        if compact ~= self._compact then
            self._compact = compact
            applyCompact(compact)
        end
        if single ~= self._single then
            self._single = single
            for _, t in ipairs(self.Tabs) do t:_setSingle(single) end
        end

        self._notifs.Size = UDim2.new(0, math.min(cfg.Notify.Width, availX - 8), 1, -32)
        root.Position = clampRoot(root.Position)
        floating.Position = clampFloating(floating.Position)
    end
    self._fit = fit

    local gripSize = IS_TOUCH and 30 or 18
    local grip = create("TextButton", {
        Text = "", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2),
        Size = UDim2.fromOffset(gripSize, gripSize), BackgroundTransparency = 1, ZIndex = 30,
        Visible = W.Resizable, Parent = root,
    })
    do
        local marks = create("Frame", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(12, 12), ZIndex = 31, Parent = grip,
        })
        local dots = { { 3, 10 }, { 0, 6 }, { -3, 3 } }
        for _, d in ipairs(dots) do
            create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, d[1], 0.5, d[1]), Size = UDim2.fromOffset(d[2], 1),
                Rotation = -45, BackgroundColor3 = Theme.Dim, BackgroundTransparency = 0.3,
                ZIndex = 31, Parent = marks,
            })
        end
    end
    self._grip = grip
    do
        local startInput, startEW, startEH, startPos, startScale
        dragger(grip, function(input)
            startInput, startEW, startEH, startPos = input.Position, self._ew, self._eh, root.Position
            startScale = math.max(uiScale.Scale, 0.05)
        end, function(i)
            local d = i.Position - startInput
            local nw = math.clamp(startEW + d.X / startScale, W.MinWidth, 2000)
            local nh = math.clamp(startEH + d.Y / startScale, W.MinHeight, 1400)
            self._w, self._h = nw, nh
            fit()
            -- mantener fija la esquina superior-izquierda
            local s = uiScale.Scale
            local tlX = startPos.X.Offset - startEW * startScale / 2
            local tlY = startPos.Y.Offset - startEH * startScale / 2
            root.Position = clampRoot(UDim2.new(startPos.X.Scale, tlX + self._ew * s / 2,
                startPos.Y.Scale, tlY + self._eh * s / 2))
        end)
    end

    if minBtn then minBtn.Activated:Connect(function() self:Minimize() end) end
    if closeBtn then closeBtn.Activated:Connect(function() self:SetVisible(false) end) end

    table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gp)
        if Library._binding or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
            return
        end
        if gp then return end
        for _, kb in ipairs(self._keybinds) do
            if kb.Enabled ~= false and kb.Value ~= Enum.KeyCode.Unknown and kb.Value == input.KeyCode then
                if kb.Mode == "Hold" then
                    kb.Active = true
                    emit(kb._callback, true)
                elseif kb.Mode == "Toggle" then
                    kb.Active = not kb.Active
                    emit(kb._callback, kb.Active)
                else
                    emit(kb._callback)
                end
            end
        end
    end))
    table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        for _, kb in ipairs(self._keybinds) do
            if kb.Mode == "Hold" and kb.Value == input.KeyCode then
                kb.Active = false
                emit(kb._callback, false)
            end
        end
    end))

    table.insert(self._conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))
    if workspace.CurrentCamera then
        table.insert(self._conns, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
    end

    fit()
    self._ready = true
    table.insert(Library.Windows, self)

    if cfg.Intro and cfg.Intro.Enabled ~= false then
        -- el menu queda oculto hasta que termine la intro; luego se abre con su animacion normal
        self._intro = true
        self.Visible = false
        root.Visible = false
        self:_playIntro()
    else
        tween(uiScale, { Scale = baseScale }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end
    return self
end

-- Intro: logo de Cookies con fade + pop, barra de carga, y luego aparece el menu
function WindowMT:_playIntro()
    local I = self.Config.Intro
    local gui = self.Gui
    local logoId = I.Logo or DEFAULT_INTRO_LOGO
    local W, H = I.Width or 300, I.Height or 180

    local function tw(obj, props, t, style, dir)
        local x = TweenService:Create(obj, TweenInfo.new(t,
            style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
        x:Play()
        return x
    end

    local vp = gui.AbsoluteSize
    local base = 1
    if vp.X >= 50 and vp.Y >= 50 then
        base = math.clamp(math.min((vp.X * 0.8) / W, (vp.Y * 0.5) / H), 0.4, 1)
    end

    local overlay = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1, Active = true, ZIndex = 100, Parent = gui,
    })
    local img = create("ImageLabel", {
        Image = logoId, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, -12), Size = UDim2.fromOffset(W, H),
        ScaleType = Enum.ScaleType.Fit, ImageTransparency = 1, ZIndex = 101, Parent = overlay,
    })
    local imgScale = create("UIScale", { Scale = base * 0.8, Parent = img })

    local track, fill
    if I.ShowBar ~= false then
        track = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0.5, (H / 2) * base + 14),
            Size = UDim2.fromOffset(150, 4), BackgroundColor3 = Theme.Input,
            BackgroundTransparency = 1, ZIndex = 101, Parent = overlay,
        }, { corner(2) })
        fill = create("Frame", {
            Size = UDim2.fromScale(0, 1), BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0, ZIndex = 102, Parent = track,
        }, { corner(2) })
    end

    task.spawn(function()
        -- esperar a que cargue la imagen (max 3s) para que no aparezca vacia
        local loaded = false
        task.spawn(function()
            pcall(function() ContentProvider:PreloadAsync({ img }) end)
            loaded = true
        end)
        local t0 = os.clock()
        while not loaded and os.clock() - t0 < 3 do task.wait() end
        if not gui.Parent then return end

        local dur = math.max(I.Duration or 2.4, 1)
        tw(overlay, { BackgroundTransparency = 0.1 }, 0.35, Enum.EasingStyle.Quad)
        tw(img, { ImageTransparency = 0 }, 0.45)
        tw(imgScale, { Scale = base }, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if track then
            tw(track, { BackgroundTransparency = 0 }, 0.4)
            tw(fill, { Size = UDim2.fromScale(1, 1) }, dur - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        end
        task.wait(dur - 0.45)
        if not gui.Parent then return end

        -- salida
        tw(img, { ImageTransparency = 1 }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tw(imgScale, { Scale = base * 1.1 }, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if track then
            tw(track, { BackgroundTransparency = 1 }, 0.25)
            tw(fill, { BackgroundTransparency = 1 }, 0.25)
        end
        tw(overlay, { BackgroundTransparency = 1 }, 0.45, Enum.EasingStyle.Quad)
        task.wait(0.3)
        if not gui.Parent then return end

        self._intro = false
        self:SetVisible(true) -- aqui aparece el menu con su animacion normal
        task.wait(0.2)
        overlay:Destroy()
    end)
end

function WindowMT:SetVisible(state)
    if self._intro then return end
    state = state and true or false
    if self.Visible == state then return end
    self.Visible = state
    if state then
        self._root.Visible = true
        tween(self._scale, { Scale = self._baseScale() }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    else
        tween(self._scale, { Scale = 0.94 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        task.delay(Library.Config.Animations and (0.15 / math.max(Library.Config.AnimationSpeed or 1, 0.05)) or 0, function()
            if not self.Visible and self._root then self._root.Visible = false end
        end)
    end
end

function WindowMT:Toggle() self:SetVisible(not self.Visible) end
function WindowMT:Show() self:SetVisible(true) end
function WindowMT:Hide() self:SetVisible(false) end

function WindowMT:Minimize(state)
    if state == nil then state = not self.Minimized end
    state = state and true or false
    if state == self.Minimized then return end
    self.Minimized = state
    self._minId = self._minId + 1
    local id = self._minId
    local dur = 0.34
    local root, clip = self._root, self._bodyClip
    local bh = math.max(self._eh - BODY_OFFSET, 0)
    local p = root.Position

    if state then
        self._grip.Visible = false
        -- la barra superior se queda fija: compensamos el anclaje central de la ventana
        local shift = math.floor((self._eh - MIN_H) * self._scale.Scale / 2 + 0.5)
        self._minShift = shift
        tween(root, {
            Size = UDim2.fromOffset(self._ew, MIN_H),
            Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - shift),
        }, dur, SOFT, SOFT_DIR)
        tweenThen(clip, { Size = UDim2.new(1, 0, 0, 0) }, dur, function()
            if id == self._minId and self.Minimized then clip.Visible = false end
        end, SOFT, SOFT_DIR)
    else
        clip.Visible = true
        local shift = self._minShift or 0
        self._minShift = 0
        tween(root, {
            Size = UDim2.fromOffset(self._ew, self._eh),
            Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + shift),
        }, dur, SOFT, SOFT_DIR)
        tweenThen(clip, { Size = UDim2.new(1, 0, 0, bh) }, dur, function()
            if id == self._minId and not self.Minimized then
                self._grip.Visible = self.Config.Window.Resizable
            end
        end, SOFT, SOFT_DIR)
    end
end

function WindowMT:Resize(w, h)
    local W = self.Config.Window
    self._w = math.clamp(w or self._w, W.MinWidth, 2000)
    self._h = math.clamp(h or self._h, W.MinHeight, 1400)
    self._fit()
end

function WindowMT:SetTitle(t) self._title.Text = tostring(t) end
function WindowMT:SetSubtitle(t) self._subtitle.Text = tostring(t) end
function WindowMT:SetToggleKey(k) self.ToggleKey = keyFromValue(k) end
function WindowMT:SetFloatingButton(v) self._floating.Visible = v and true or false end
function WindowMT:ResetPosition()
    local shift = self.Minimized and (self._minShift or 0) or 0
    tween(self._root, { Position = UDim2.new(0.5, 0, 0.5, -shift) }, 0.3, SOFT, SOFT_DIR)
end

function WindowMT:Destroy()
    for _, c in ipairs(self._conns) do c:Disconnect() end
    for _, flag in ipairs(self._flags) do Library.Flags[flag] = nil end
    local i = table.find(Library.Windows, self)
    if i then table.remove(Library.Windows, i) end
    Library._binding = false
    if self.Gui then self.Gui:Destroy() end
end

function WindowMT:GetTab(name)
    for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end
    return nil
end

function WindowMT:Notify(o)
    if type(o) == "string" then o = { Title = o } end
    local colors = { Info = Theme.Accent, Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error }
    local color = o.Color or colors[o.Type or "Info"] or Theme.Accent
    local duration = pick(o.Duration, self.Config.Notify.Duration)

    local wrap = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = self._notifs,
    })
    local toast = create("TextButton", {
        Text = "", Position = UDim2.new(1, 40, 0, 0), Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Element, Parent = wrap,
    }, { corner(8), stroke(Theme.Stroke, 1, 0.4) })
    create("Frame", {
        Position = UDim2.fromOffset(10, 10), Size = UDim2.new(0, 3, 1, -20),
        BackgroundColor3 = color, Parent = toast,
    }, { corner(2) })
    local content = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = toast,
    }, { padding(22, 10, 12, 10), listLayout(3) })

    label({ Text = o.Title or "Cookies Hub", Font = Fonts.Bold, TextSize = 13,
        TextTruncate = Enum.TextTruncate.None, TextWrapped = true,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = content })
    if o.Content and o.Content ~= "" then
        label({ Text = o.Content, TextSize = 12, TextColor3 = Theme.Muted,
            TextTruncate = Enum.TextTruncate.None, TextWrapped = true,
            Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
            LayoutOrder = 2, Parent = content })
    end
    local fill
    if duration and duration > 0 then
        local track = create("Frame", {
            Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = Theme.Input, LayoutOrder = 3, Parent = content,
        }, { corner(2) })
        fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, Parent = track }, { corner(2) })
    end

    local closed = false
    local function close()
        if closed then return end
        closed = true
        if not toast.Parent then return end
        tweenThen(toast, { Position = UDim2.new(1, 40, 0, 0) }, 0.3, function() wrap:Destroy() end,
            Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    end
    toast.Activated:Connect(close)
    tween(toast, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    if fill then
        tween(fill, { Size = UDim2.new(0, 0, 1, 0) }, duration, Enum.EasingStyle.Linear)
        task.delay(duration, close)
    end
    return { Close = close }
end

function Library:Notify(o)
    local w = Library.Windows[#Library.Windows]
    if w then return w:Notify(o) end
end

local function serialize(obj)
    local v = obj.Value
    if obj.Type == "ColorPicker" then
        return { math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) }
    elseif obj.Type == "Keybind" then
        return keyName(v)
    elseif type(v) == "table" then
        return table.clone(v)
    end
    return v
end

local function deserialize(obj, v)
    if obj.Type == "ColorPicker" then
        if type(v) == "table" then obj:Set(Color3.fromRGB(v[1], v[2], v[3])) end
    elseif obj.Type == "Keybind" then
        obj:Set(keyFromValue(v))
    else
        obj:Set(v)
    end
end

function WindowMT:GetConfigs()
    local list = {}
    if not hasFS or not isfolder(self.ConfigFolder) or typeof(listfiles) ~= "function" then return list end
    for _, path in ipairs(listfiles(self.ConfigFolder)) do
        local name = path:match("([^/\\]+)%.json$")
        if name then table.insert(list, name) end
    end
    return list
end

function WindowMT:SaveConfig(name)
    if not hasFS then return false, "Tu executor no soporta writefile" end
    if not name or name == "" then return false, "Escribe un nombre" end
    if not isfolder(self.ConfigFolder) then makefolder(self.ConfigFolder) end
    local data = {}
    for flag, obj in pairs(Library.Flags) do
        if obj.Savable ~= false then data[flag] = serialize(obj) end
    end
    writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
    return true
end

function WindowMT:LoadConfig(name)
    if not hasFS then return false, "Tu executor no soporta readfile" end
    local path = self.ConfigFolder .. "/" .. tostring(name) .. ".json"
    if typeof(isfile) == "function" and not isfile(path) then return false, "No existe esa config" end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if not ok then return false, "Config dañada" end
    for flag, value in pairs(data) do
        local obj = Library.Flags[flag]
        if obj and obj.Savable ~= false then pcall(deserialize, obj, value) end
    end
    return true
end

function WindowMT:AddTabCategory(text)
    self._navOrder = self._navOrder + 1
    local l = label({
        Text = string.upper(tostring(text)), Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Dim,
        Size = UDim2.new(1, 0, 0, 20), LayoutOrder = self._navOrder, Parent = self._nav,
        Visible = not self._compact,
    })
    table.insert(self._cats, l)
    return l
end

function WindowMT:CreateTab(name, icon)
    local win = self
    local o
    if type(name) == "table" then o = name else o = { Name = name, Icon = icon } end
    name = tostring(o.Name or "Tab")
    local tcfg = self.Config.Tab
    local tab = setmetatable({ Name = name, Window = self, _next = 0, _sections = {}, Active = false }, TabMT)

    local nCols = math.max(1, math.floor(pick(o.Columns, tcfg.Columns)))
    local gap = pick(o.Gap, tcfg.Gap)
    local pad = pick(o.Padding, tcfg.Padding)
    local iconSize = pick(o.IconSize, tcfg.IconSize)
    local tint = pick(o.IconTint, tcfg.IconTint)
    local iconColor = o.IconColor or Theme.Accent

    self._navOrder = self._navOrder + 1
    local btn = create("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Theme.Row,
        BackgroundTransparency = 1, LayoutOrder = self._navOrder, Parent = self._nav,
    }, { corner(6) })
    local indicator = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(2, 16), BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1, Parent = btn,
    }, { corner(1) })

    local iconHolder = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 25, 0.5, 0),
        Size = UDim2.fromOffset(iconSize, iconSize), BackgroundColor3 = Theme.Row, Parent = btn,
    }, { corner(6) })
    local iconImg, iconTxt

    local function paintIcon(active, animate)
        local t = animate and 0.18 or 0
        if iconImg then
            iconHolder.BackgroundTransparency = 1
            local c = Color3.new(1, 1, 1)
            if tint then c = active and iconColor or Theme.Dim end
            tween(iconImg, { ImageColor3 = c, ImageTransparency = active and 0 or (tint and 0 or 0.35) }, t)
        elseif iconTxt then
            iconHolder.BackgroundTransparency = 0
            tween(iconHolder, { BackgroundColor3 = active and Theme.Accent or Theme.Row }, t)
            tween(iconTxt, { TextColor3 = active and Theme.OnAccent or Theme.Dim }, t)
        end
    end

    local function buildIcon(spec)
        for _, c in ipairs(iconHolder:GetChildren()) do
            if not c:IsA("UICorner") then c:Destroy() end
        end
        iconImg, iconTxt = nil, nil
        local kind, value, rect = resolveIcon(spec, name)
        tab.IconKind = kind
        if kind == "image" then
            local props = { Image = value, Size = UDim2.fromScale(1, 1), ScaleType = Enum.ScaleType.Fit, Parent = iconHolder }
            if rect then
                props.ImageRectSize = rect[1]
                props.ImageRectOffset = rect[2]
            end
            iconImg = create("ImageLabel", props)
        else
            iconTxt = label({
                Text = value, Font = Fonts.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
                TextTruncate = Enum.TextTruncate.None, Size = UDim2.fromScale(1, 1), Parent = iconHolder,
            })
        end
        paintIcon(tab.Active, false)
    end

    local nameLabel = label({
        Text = name, Font = Fonts.Bold, TextSize = 13, TextColor3 = Theme.Dim,
        Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -50, 1, 0), Parent = btn,
    })
    buildIcon(o.Icon)

    local page = create("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = IS_TOUCH and 4 or 3, ScrollBarImageColor3 = Theme.Dim, ScrollBarImageTransparency = 0.5,
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self._content,
    }, { padding(pad, pad, pad + 2, pad), listLayout(gap) })

    local full = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Visible = false, Parent = page,
    }, { listLayout(gap) })
    local colLayout = listLayout(gap, { FillDirection = Enum.FillDirection.Horizontal })
    local columns = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = page,
    }, { colLayout })
    tab._cols = {}
    for i = 1, nCols do
        tab._cols[i] = create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1 / nCols, -gap * (nCols - 1) / nCols, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, Parent = columns,
        }, { listLayout(gap) })
    end
    tab._full, tab._page, tab._btn, tab._nameLabel = full, page, btn, nameLabel

    function tab:_setCompact(c)
        nameLabel.Visible = not c
        iconHolder.Position = c and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(0, 25, 0.5, 0)
    end
    function tab:_setSingle(single)
        if nCols <= 1 then return end
        colLayout.FillDirection = single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
        for _, c in ipairs(self._cols) do
            c.Size = single and UDim2.new(1, 0, 0, 0)
                or UDim2.new(1 / nCols, -gap * (nCols - 1) / nCols, 0, 0)
            c.Visible = (not single) or #c:GetChildren() > 1
        end
        self._single = single
    end

    function tab:_setActive(active)
        tween(btn, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = Theme.Row }, 0.18)
        tween(indicator, { BackgroundTransparency = active and 0 or 1 }, 0.18)
        tween(nameLabel, { TextColor3 = active and Theme.Text or Theme.Dim }, 0.18)
        self.Active = active
        paintIcon(active, true)
        if active then
            page.Visible = true
            page.Position = UDim2.fromOffset(0, 8)
            tween(page, { Position = UDim2.fromOffset(0, 0) }, 0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            task.defer(function() self:Refresh() end)
        else
            page.Visible = false
        end
    end

    function tab:Refresh()
        for _, s in ipairs(self._sections) do s:_apply() end
    end
    function tab:Select() win:SelectTab(self) end
    function tab:SetIcon(spec) buildIcon(spec) end
    function tab:SetName(n) self.Name = tostring(n) nameLabel.Text = self.Name end
    function tab:SetVisible(v) btn.Visible = v ~= false end
    function tab:ScrollToTop() page.CanvasPosition = Vector2.new(0, 0) end
    function tab:Destroy()
        local i = table.find(win.Tabs, self)
        if i then table.remove(win.Tabs, i) end
        btn:Destroy() page:Destroy()
        if win.ActiveTab == self then win.ActiveTab = nil if win.Tabs[1] then win:SelectTab(win.Tabs[1]) end end
    end

    btn.MouseEnter:Connect(function()
        if not tab.Active then tween(btn, { BackgroundTransparency = 0.6 }, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if not tab.Active then tween(btn, { BackgroundTransparency = 1 }, 0.15) end
    end)
    btn.Activated:Connect(function() win:SelectTab(tab) end)

    table.insert(self.Tabs, tab)
    tab:_setCompact(self._compact == true)
    if self._single then tab:_setSingle(true) end
    if #self.Tabs == 1 then self:SelectTab(tab) end
    return tab
end

function WindowMT:SelectTab(tab)
    if type(tab) == "string" then
        for _, t in ipairs(self.Tabs) do if t.Name == tab then tab = t break end end
    end
    if type(tab) ~= "table" then return end
    for _, t in ipairs(self.Tabs) do
        if t ~= tab and t.Active then t:_setActive(false) end
    end
    if not tab.Active then tab:_setActive(true) end
    self.ActiveTab = tab
end

local HEADER_H = 28

function TabMT:CreateSection(o)
    if type(o) == "string" then o = { Name = o } end
    o = o or {}
    local win = self.Window
    local scfg = win.Config.Section

    local collapsible = pick(o.Collapsible, scfg.Collapsible)
    local minimized = pick(o.Minimized, o.Collapsed, scfg.Minimized)
    local nCols = math.max(1, math.floor(pick(o.Columns, scfg.Columns)))
    local maxH = pick(o.MaxHeight, scfg.MaxHeight)
    local gap = pick(o.Gap, scfg.Gap)
    local cgap = pick(o.ColumnGap, scfg.ColumnGap)
    local accent = o.Color or Theme.Accent

    local parentFrame
    local where = pick(o.Column, o.Side)
    if where == "Full" or o.Full == true then
        parentFrame = self._full
        self._full.Visible = true
    else
        local idx
        if where == "Left" then idx = 1
        elseif where == "Right" then idx = #self._cols
        elseif type(where) == "number" then idx = math.clamp(math.floor(where), 1, #self._cols)
        else
            self._next = self._next % #self._cols + 1
            idx = self._next
        end
        parentFrame = self._cols[idx]
        parentFrame.Visible = true
    end

    local section = setmetatable({
        Tab = self, Window = win, Name = o.Name or "Section", Open = true,
        _rr = 0, _orders = {}, _anim = 0,
    }, SectionMT)
    section._main = section

    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Element, Parent = parentFrame,
    }, { corner(scfg.Corner), stroke(Theme.Stroke, 1, 0.45), padding(10, 10, 10, 10), listLayout(0) })
    section._frame, section.Frame = frame, frame

    local header = create(collapsible and "TextButton" or "Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEADER_H), LayoutOrder = 0, Parent = frame,
        Text = collapsible and "" or nil,
    })
    local titleX = 14
    local dot
    local iconKind, iconValue, iconRect
    if o.Icon ~= nil then iconKind, iconValue, iconRect = resolveIcon(o.Icon, "") end
    if iconKind == "image" then
        local props = {
            Image = iconValue, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(16, 16), ScaleType = Enum.ScaleType.Fit,
            ImageColor3 = pick(o.IconColor, accent), Parent = header,
        }
        if iconRect then
            props.ImageRectSize = iconRect[1]
            props.ImageRectOffset = iconRect[2]
        end
        create("ImageLabel", props)
        titleX = 24
    else
        dot = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(6, 6), BackgroundColor3 = accent, Parent = header,
        }, { corner(3) })
    end
    local title = label({
        Text = section.Name, Font = Fonts.Bold, TextSize = 13, TextColor3 = Theme.Text,
        Position = UDim2.fromOffset(titleX, 0), Size = UDim2.new(1, -(titleX + (collapsible and 30 or 0)), 1, 0),
        Parent = header,
    })

    local arrow, chip, chevBars
    if collapsible then
        chip = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Theme.Row,
            BackgroundTransparency = 1, Parent = header,
        }, { corner(6) })
        arrow = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = chip,
        })
        chevBars = {}
        local function arm(rot, dx)
            table.insert(chevBars, create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, dx, 0.5, -1),
                Size = UDim2.fromOffset(11, 2), Rotation = rot, BackgroundColor3 = Theme.Muted, Parent = arrow,
            }, { corner(1) }))
        end
        arm(45, -4)
        arm(-45, 4)
        header.MouseEnter:Connect(function()
            tween(chip, { BackgroundColor3 = Theme.RowHover, BackgroundTransparency = 0 }, 0.15)
            for _, b in ipairs(chevBars) do tween(b, { BackgroundColor3 = Theme.Text }, 0.15) end
        end)
        header.MouseLeave:Connect(function()
            tween(chip, { BackgroundTransparency = 1 }, 0.15)
            for _, b in ipairs(chevBars) do tween(b, { BackgroundColor3 = Theme.Muted }, 0.15) end
        end)
    end

    local body = create("Frame", {
        BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = frame,
    })
    local inner = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = body,
    }, { padding(0, gap, 0, 0), listLayout(gap) })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.45,
        LayoutOrder = 1, Parent = inner,
    })
    local contentBox = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = maxH and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
        LayoutOrder = 2, Parent = inner,
    })
    local holderParent = contentBox
    if maxH then
        local scroller = create("ScrollingFrame", {
            BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = IS_TOUCH and 4 or 3, ScrollBarImageColor3 = Theme.Dim, ScrollBarImageTransparency = 0.5,
            ScrollingDirection = Enum.ScrollingDirection.Y, Parent = contentBox,
        }, { padding(0, 0, 8, 0) })
        section._scroller = scroller
        holderParent = scroller
    end
    local holder = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Parent = holderParent,
    }, { listLayout(cgap, { FillDirection = Enum.FillDirection.Horizontal }) })
    section._cols = {}
    for i = 1, nCols do
        section._cols[i] = create("Frame", {
            BackgroundTransparency = 1, LayoutOrder = i, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1 / nCols, -cgap * (nCols - 1) / nCols, 0, 0), Parent = holder,
        }, { listLayout(gap) })
        section._orders[i] = 0
    end

    local function unscaled(px)
        local s = win._baseScale()
        if s <= 0.01 then s = 1 end
        return px / s
    end
    local function targetH()
        return math.ceil(unscaled(inner.AbsoluteSize.Y))
    end
    local function finishOpen()
        body.AutomaticSize = Enum.AutomaticSize.Y
        body.Size = UDim2.new(1, 0, 0, 0)
    end

    function section:_apply()
        if not maxH then return end
        contentBox.Size = UDim2.new(1, 0, 0, math.min(math.ceil(unscaled(holder.AbsoluteSize.Y)), maxH))
    end
    if maxH then
        holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() section:_apply() end)
    end

    function section:SetOpen(open, instant)
        open = open and true or false
        if not collapsible and not open then return end
        if self.Open == open then return end
        self.Open = open
        self._anim = self._anim + 1
        local id = self._anim
        local dur = instant and 0 or 0.25

        if arrow then tween(arrow, { Rotation = open and 0 or -90 }, dur, SOFT, SOFT_DIR) end

        -- arrancamos desde la altura actual (si se interrumpe una animación, continúa suave)
        local current = unscaled(body.AbsoluteSize.Y)
        body.AutomaticSize = Enum.AutomaticSize.None
        body.Size = UDim2.new(1, 0, 0, current)

        if open then self:_apply() end
        local goal = open and targetH() or 0
        tweenThen(body, { Size = UDim2.new(1, 0, 0, goal) }, dur, function()
            if id == self._anim and open then finishOpen() end
        end, SOFT, SOFT_DIR)

        if self._onToggle then emit(self._onToggle, open) end
    end

    function section:Toggle() self:SetOpen(not self.Open) end
    function section:Minimize() self:SetOpen(false) end
    function section:Expand() self:SetOpen(true) end
    function section:SetTitle(t) self.Name = tostring(t) title.Text = self.Name end
    function section:SetColor(c) accent = c if dot then dot.BackgroundColor3 = c end end
    function section:SetVisible(v) frame.Visible = v ~= false end
    function section:OnToggle(fn) self._onToggle = fn end
    function section:SetMaxHeight(h)
        -- solo funciona si la sección se creó con MaxHeight
        if section._scroller then maxH = h or math.huge section:_apply() end
    end
    function section:Destroy()
        local i = table.find(self.Tab._sections, self)
        if i then table.remove(self.Tab._sections, i) end
        frame:Destroy()
    end

    if collapsible then header.Activated:Connect(function() section:Toggle() end) end

    -- estado inicial
    if collapsible and minimized then
        section.Open = false
        if arrow then arrow.Rotation = -90 end
        body.AutomaticSize = Enum.AutomaticSize.None
        body.Size = UDim2.new(1, 0, 0, 0)
    else
        finishOpen()
    end

    table.insert(self._sections, section)
    return section
end
TabMT.AddSection = TabMT.CreateSection

function SectionMT:AddColumns(n, o)
    o = o or {}
    n = math.max(1, math.floor(n or 2))
    local parent, order = self:_slot(o)
    local cgap = pick(o.Gap, self.Window.Config.Section.ColumnGap)
    local gap = pick(o.RowGap, self.Window.Config.Section.Gap)
    local holder = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = order, Parent = parent,
    }, { listLayout(cgap, { FillDirection = Enum.FillDirection.Horizontal }) })
    local subs = {}
    for i = 1, n do
        local col = create("Frame", {
            BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i,
            Size = UDim2.new(1 / n, -cgap * (n - 1) / n, 0, 0), Parent = holder,
        }, { listLayout(gap) })
        subs[i] = setmetatable({
            Tab = self.Tab, Window = self.Window, _main = self._main, _cols = { col },
            _orders = { 0 }, _rr = 0, Frame = col,
        }, SectionMT)
    end
    return table.unpack(subs)
end

function SectionMT:_slot(o)
    local n = #self._cols
    local idx
    if o and type(o.Column) == "number" and n > 1 then
        idx = math.clamp(math.floor(o.Column), 1, n)
    else
        self._rr = self._rr % n + 1
        idx = self._rr
    end
    self._orders[idx] = self._orders[idx] + 1
    return self._cols[idx], self._orders[idx]
end

function SectionMT:_eh(o)
    return pick(o and o.Height, self.Window.Config.Element.Height)
end

function SectionMT:_row(height, clickable, o)
    local parent, order = self:_slot(o)
    local props = {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Row,
        LayoutOrder = order, Parent = parent,
    }
    if clickable then props.Text = "" end
    local r = create(clickable and "TextButton" or "Frame", props, { corner(self.Window.Config.Element.Corner) })
    if clickable then hover(r, Theme.Row, Theme.RowHover) end
    return r
end

function SectionMT:_register(flag, obj)
    if flag then
        Library.Flags[flag] = obj
        table.insert(self.Window._flags, flag)
    end
end

function SectionMT:_lockScroll(locked)
    local m = self._main
    m.Tab._page.ScrollingEnabled = not locked
    if m._scroller then m._scroller.ScrollingEnabled = not locked end
end

function SectionMT:AddLabel(text)
    local o = type(text) == "table" and text or { Text = text }
    local parent, order = self:_slot(o)
    local l = label({
        Text = o.Text or "", TextSize = o.Size or 12, TextColor3 = o.Color or Theme.Muted, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = parent,
    })
    local obj = {
        Set = function(_, t) l.Text = tostring(t) end,
        SetText = function(_, t) l.Text = tostring(t) end,
        SetColor = function(_, c) l.TextColor3 = c end,
        SetVisible = function(_, v) l.Visible = v ~= false end,
        Destroy = function() l:Destroy() end,
        Frame = l,
    }
    return obj
end

function SectionMT:AddParagraph(o)
    o = o or {}
    local parent, order = self:_slot(o)
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Row, LayoutOrder = order, Parent = parent,
    }, { corner(self.Window.Config.Element.Corner), padding(12, 10, 12, 10), listLayout(3) })
    local t = label({ Text = o.Title or "", Font = Fonts.Bold, TextSize = 13,
        TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = box })
    local c = label({ Text = o.Content or "", TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 2, Parent = box })
    return {
        Set = function(_, title, content) t.Text = title or t.Text c.Text = content or c.Text end,
        SetVisible = function(_, v) box.Visible = v ~= false end,
        Destroy = function() box:Destroy() end,
        Frame = box,
    }
end

function SectionMT:AddDivider(text)
    local o = type(text) == "table" and text or { Text = text }
    local parent, order = self:_slot(o)
    if o.Text and o.Text ~= "" then
        local f = create("Frame", {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = order, Parent = parent,
        })
        local l = label({ Text = o.Text, Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Dim,
            TextXAlignment = Enum.TextXAlignment.Center, AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.fromScale(0.5, 0), TextTruncate = Enum.TextTruncate.None, ZIndex = 2, Parent = f },
            nil)
        create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = l })
        l.BackgroundTransparency = 0
        l.BackgroundColor3 = Theme.Element
        create("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, Parent = f })
        return { Frame = f, SetVisible = function(_, v) f.Visible = v ~= false end }
    end
    local d = create("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, LayoutOrder = order, Parent = parent,
    })
    return { Frame = d, SetVisible = function(_, v) d.Visible = v ~= false end }
end

function SectionMT:AddSpacer(height)
    local parent, order = self:_slot()
    return create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, height or 6),
        LayoutOrder = order, Parent = parent })
end

function SectionMT:AddButton(o)
    o = o or {}
    local style = o.Style or (o.Primary and "Primary") or "Default"
    local primary = style == "Primary" or style == "Danger"
    local base = style == "Danger" and Theme.Error or Theme.Accent
    local baseHi = style == "Danger" and Theme.Error:Lerp(Color3.new(1, 1, 1), 0.3) or Theme.AccentHi
    local onBase = style == "Danger" and Theme.Text or Theme.OnAccent

    local hasDesc = o.Description and o.Description ~= ""
    local b = self:_row(hasDesc and 46 or self:_eh(o), true, o)
    local normal = primary and base or Theme.Row
    local over = primary and baseHi or Theme.RowHover
    local textColor = primary and onBase or Theme.Text
    b.BackgroundColor3 = normal

    local nameLbl = label({
        Text = o.Name or "Button", Font = Fonts.Bold, TextSize = 13, TextColor3 = textColor,
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(8, hasDesc and 5 or 0), Size = UDim2.new(1, -16, hasDesc and 0 or 1, hasDesc and 20 or 0),
        Parent = b,
    })
    if hasDesc then
        label({ Text = o.Description, TextSize = 11, TextColor3 = primary and onBase or Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 25),
            Size = UDim2.new(1, -16, 0, 14), Parent = b })
    end
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = over }, 0.15) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = normal }, 0.15) end)

    local obj = { Type = "Button" }
    decorate(self, obj, b, o)
    function obj:Click()
        if obj.Enabled == false then return end
        b.BackgroundColor3 = over
        tween(b, { BackgroundColor3 = normal }, 0.25)
        fire(obj, o)
    end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    b.Activated:Connect(function() obj:Click() end)
    return obj
end

function SectionMT:AddToggle(o)
    o = o or {}
    local hasDesc = o.Description and o.Description ~= ""
    local H = hasDesc and 46 or self:_eh(o)
    local r = self:_row(H, true, o)
    local nameLbl = label({
        Text = o.Name or "Toggle", Position = UDim2.fromOffset(12, hasDesc and 6 or 0),
        Size = UDim2.new(1, -66, hasDesc and 0 or 1, hasDesc and 16 or 0), Parent = r,
    })
    if hasDesc then
        label({ Text = o.Description, TextSize = 11, TextColor3 = Theme.Muted,
            Position = UDim2.fromOffset(12, 24), Size = UDim2.new(1, -66, 0, 14), Parent = r })
    end
    local onColor = o.Color or Theme.Accent
    local sw = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(34, 18), BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(9), stroke(Theme.Stroke, 1, 0.5) })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Dim, Parent = sw,
    }, { corner(6) })

    local obj = { Type = "Toggle", Value = false }
    decorate(self, obj, r, o)
    function obj:Set(v, silent)
        v = v and true or false
        local animate = obj._ready and 0.22 or 0
        obj.Value = v
        tween(sw, { BackgroundColor3 = v and onColor or Theme.Input }, animate)
        tween(knob, {
            Position = v and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
            BackgroundColor3 = v and Theme.Text or Theme.Dim,
        }, animate, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:Toggle(silent) obj:Set(not obj.Value, silent) end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    obj:Set(o.Default or false, true)
    obj._ready = true
    r.Activated:Connect(function() if obj.Enabled then obj:Set(not obj.Value) end end)
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddSlider(o)
    o = o or {}
    local min, max = o.Min or 0, o.Max or 100
    local inc = o.Increment or 1
    local suffix = o.Suffix or ""
    local decimals = (tostring(inc):match("%.(%d+)") or ""):len()
    local fmt = "%." .. decimals .. "f"

    local r = self:_row(self:_eh(o) + 16, false, o)
    local nameLbl = label({ Text = o.Name or "Slider", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -86, 0, 30), Parent = r })
    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 6),
        Size = UDim2.fromOffset(60, 18), BackgroundColor3 = Theme.Input, Font = Fonts.Bold,
        TextSize = 12, TextColor3 = Theme.Text, ClearTextOnFocus = false, Text = "", Parent = r,
    }, { corner(6), stroke(Theme.Stroke, 1) })
    local track = create("Frame", {
        Position = UDim2.fromOffset(12, 36), Size = UDim2.new(1, -24, 0, 6),
        BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(3) })
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = o.Color or Theme.Accent, Parent = track,
    }, { corner(3) })
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Text, Parent = fill,
    }, { corner(6) })
    local hit = create("TextButton", {
        Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 26),
        Size = UDim2.new(1, -12, 0, 26), Parent = r,
    })

    local obj = { Type = "Slider", Value = min }
    decorate(self, obj, r, o)
    local function snap(v)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        v = math.clamp(v, min, max)
        return tonumber(string.format(fmt, v))
    end
    local function render()
        local alpha = (max == min) and 0 or (obj.Value - min) / (max - min)
        tween(fill, { Size = UDim2.fromScale(alpha, 1) }, obj._dragging and 0.06 or (obj._ready and 0.15 or 0),
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        box.Text = string.format(fmt, obj.Value) .. suffix
    end
    function obj:Set(v, silent)
        v = snap(tonumber(v) or min)
        obj.Value = v
        render()
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:SetRange(nmin, nmax)
        min, max = nmin, nmax
        obj:Set(obj.Value, true)
    end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    local function fromPos(pos)
        local a = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local snapped = snap(min + (max - min) * a)
        if snapped ~= obj.Value then obj:Set(snapped) end
    end
    dragger(hit, function(input)
        if not obj.Enabled then return end
        obj._dragging = true
        self:_lockScroll(true)
        tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.12)
        fromPos(input.Position)
    end, function(i)
        if obj._dragging then fromPos(i.Position) end
    end, function()
        obj._dragging = false
        self:_lockScroll(false)
        tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.12)
    end)
    box.Focused:Connect(function() box.Text = tostring(obj.Value) end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text:match("-?%d+%.?%d*"))
        obj:Set(n or obj.Value)
    end)

    obj:Set(o.Default or min, true)
    obj._ready = true
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddDropdown(o)
    o = o or {}
    local multi = o.Multi == true
    local options = o.Options or {}
    local ITEM_H = IS_TOUCH and 30 or 26
    local MAX_VISIBLE = o.MaxVisible or 5
    local H = self:_eh(o)
    local ecorner = self.Window.Config.Element.Corner

    local parent, order = self:_slot(o)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Row, ClipsDescendants = true,
        LayoutOrder = order, Parent = parent,
    }, { corner(ecorner) })
    local head = create("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1, Parent = holder,
    })
    local nameLbl = label({ Text = o.Name or "Dropdown", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.45, -12, 1, 0), Parent = head })
    local valueLabel = label({
        Text = "None", TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -28, 0.5, 0),
        Size = UDim2.new(0.55, -34, 1, 0), Parent = head,
    })
    local arrow = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(12, 12), Parent = head,
    })
    for _, s in ipairs({ { 45, -2 }, { -45, 2 } }) do
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, s[2], 0.5, 0),
            Size = UDim2.fromOffset(7, 2), Rotation = s[1], BackgroundColor3 = Theme.Muted, Parent = arrow,
        }, { corner(1) })
    end
    local list = create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(8, H + 6), Size = UDim2.new(1, -16, 0, 0),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Dim, ScrollBarImageTransparency = 0.5, Parent = holder,
    }, { listLayout(3) })

    local obj = { Type = "Dropdown", Value = multi and {} or nil, Options = options, Open = false }
    decorate(self, obj, holder, o)
    local buttons = {}

    local function listHeight()
        local n = math.min(#options, MAX_VISIBLE)
        return n * ITEM_H + math.max(n - 1, 0) * 3
    end
    local function resize()
        local h = obj.Open and (H + 6 + listHeight() + 8) or H
        tween(holder, { Size = UDim2.new(1, 0, 0, h) }, 0.22, SOFT, SOFT_DIR)
        tween(list, { Size = UDim2.new(1, -16, 0, listHeight()) }, 0.22, SOFT, SOFT_DIR)
        tween(arrow, { Rotation = obj.Open and 180 or 0 }, 0.22, SOFT, SOFT_DIR)
    end
    local function isSelected(opt)
        if multi then return table.find(obj.Value, opt) ~= nil end
        return obj.Value == opt
    end
    local function paint()
        for opt, b in pairs(buttons) do
            local sel = isSelected(opt)
            tween(b.label, { TextColor3 = sel and Theme.Accent or Theme.Text }, 0.15)
            tween(b.dot, { BackgroundTransparency = sel and 0 or 1 }, 0.15)
        end
        if multi then
            local names = {}
            for _, v in ipairs(obj.Value) do table.insert(names, tostring(v)) end
            valueLabel.Text = #names > 0 and table.concat(names, ", ") or "None"
            valueLabel.TextColor3 = #names > 0 and Theme.Text or Theme.Dim
        else
            valueLabel.Text = obj.Value ~= nil and tostring(obj.Value) or "None"
            valueLabel.TextColor3 = obj.Value ~= nil and Theme.Text or Theme.Dim
        end
    end
    local function current() return multi and table.clone(obj.Value) or obj.Value end

    function obj:Set(v, silent)
        if multi then
            local new = {}
            for _, opt in ipairs(type(v) == "table" and v or {}) do
                if table.find(options, opt) and not table.find(new, opt) then table.insert(new, opt) end
            end
            obj.Value = new
        else
            obj.Value = table.find(options, v) and v or nil
        end
        paint()
        if not silent then fire(obj, o, current()) end
    end
    function obj:Get() return current() end
    function obj:SetOpen(state)
        obj.Open = state and true or false
        resize()
    end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    local function toggleOption(opt)
        if multi then
            local idx = table.find(obj.Value, opt)
            if idx then table.remove(obj.Value, idx) else table.insert(obj.Value, opt) end
            paint()
            fire(obj, o, current())
        else
            obj:Set(opt)
            obj.Open = false
            resize()
        end
    end

    function obj:Refresh(newOptions, keepValue)
        for _, b in pairs(buttons) do b.button:Destroy() end
        buttons = {}
        options = newOptions or {}
        obj.Options = options
        for i, opt in ipairs(options) do
            local btn = create("TextButton", {
                Text = "", Size = UDim2.new(1, 0, 0, ITEM_H), BackgroundColor3 = Theme.Input,
                LayoutOrder = i, Parent = list,
            }, { corner(5) })
            local lbl = label({ Text = tostring(opt), TextSize = 12, Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -30, 1, 0), Parent = btn })
            local dot = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1,
                Parent = btn,
            }, { corner(4) })
            hover(btn, Theme.Input, Theme.RowHover)
            btn.Activated:Connect(function() toggleOption(opt) end)
            buttons[opt] = { button = btn, label = lbl, dot = dot }
        end
        if keepValue then obj:Set(obj.Value, true) else obj:Set(multi and {} or nil, true) end
        resize()
    end
    obj.SetOptions = obj.Refresh
    function obj:AddOption(opt)
        local new = table.clone(options)
        table.insert(new, opt)
        obj:Refresh(new, true)
    end
    function obj:RemoveOption(opt)
        local new = {}
        for _, v in ipairs(options) do if v ~= opt then table.insert(new, v) end end
        obj:Refresh(new, true)
    end

    head.Activated:Connect(function()
        if not obj.Enabled then return end
        obj.Open = not obj.Open
        resize()
    end)
    head.MouseEnter:Connect(function() tween(holder, { BackgroundColor3 = Theme.RowHover }, 0.15) end)
    head.MouseLeave:Connect(function() tween(holder, { BackgroundColor3 = Theme.Row }, 0.15) end)

    obj:Refresh(options)
    obj.Open = false
    resize()
    if o.Default ~= nil then obj:Set(o.Default, true) end
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddKeybind(o)
    o = o or {}
    local r = self:_row(self:_eh(o), true, o)
    local nameLbl = label({ Text = o.Name or "Keybind", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -100, 1, 0), Parent = r })
    local chip = label({
        Text = "None", Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Input, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 22),
        AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Parent = r,
    }, nil)
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = chip })
    create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Parent = chip })
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = chip })

    local obj = {
        Type = "Keybind", Value = Enum.KeyCode.Unknown, Mode = o.Mode or "Press",
        Active = false, _callback = o.Callback,
    }
    decorate(self, obj, r, o)
    function obj:Set(key, silent)
        obj.Value = keyFromValue(key)
        chip.Text = keyName(obj.Value)
        chip.TextColor3 = Theme.Text
        if not silent then emit(o.Changed, obj.Value) end
    end
    function obj:Get() return obj.Value end
    function obj:SetMode(m) obj.Mode = m end
    function obj:Press() emit(obj._callback) end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    r.Activated:Connect(function()
        if not obj.Enabled or Library._binding then return end
        Library._binding = true
        chip.Text = "..."
        chip.TextColor3 = Theme.Accent
        local conn
        conn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            conn:Disconnect()
            if input.KeyCode == Enum.KeyCode.Escape then
                obj:Set(obj.Value, true)
            elseif input.KeyCode == Enum.KeyCode.Backspace then
                obj:Set(Enum.KeyCode.Unknown)
            else
                obj:Set(input.KeyCode)
            end
            task.defer(function() Library._binding = false end)
        end)
    end)

    obj:Set(o.Default or Enum.KeyCode.Unknown, true)
    table.insert(self.Window._keybinds, obj)
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddTextBox(o)
    o = o or {}
    local r = self:_row(self:_eh(o), false, o)
    local nameLbl = label({ Text = o.Name or "Input", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.42, -12, 1, 0), Parent = r })
    local boxStroke = stroke(Theme.Stroke, 1)
    local box = create("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.58, -12, 0, 24), BackgroundColor3 = Theme.Input, Font = Fonts.Body,
        TextSize = 12, TextColor3 = Theme.Text, PlaceholderText = o.Placeholder or "...",
        PlaceholderColor3 = Theme.Dim, ClearTextOnFocus = o.ClearOnFocus == true, Text = "",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = r,
    }, { corner(5), boxStroke, padding(8, 0, 8, 0) })

    local obj = { Type = "TextBox", Value = o.Numeric and 0 or "" }
    decorate(self, obj, r, o)
    function obj:Set(v, silent)
        if o.Numeric then v = tonumber(v) or tonumber(obj.Value) or 0 else v = tostring(v == nil and "" or v) end
        obj.Value = v
        box.Text = tostring(v)
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    box.Focused:Connect(function() tween(boxStroke, { Color = Theme.Accent }, 0.15) end)
    box.FocusLost:Connect(function(enter)
        tween(boxStroke, { Color = Theme.Stroke }, 0.15)
        if enter or o.CallbackOnBlur ~= false then obj:Set(box.Text) end
    end)
    if o.Default ~= nil then obj:Set(o.Default, true) end
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddColorPicker(o)
    o = o or {}
    local HEAD = self:_eh(o)
    local PANEL_H = o.PanelHeight or 96
    local presets = type(o.Presets) == "table" and o.Presets or nil
    if presets and #presets == 0 then presets = nil end
    local hexY = 42 + PANEL_H + 8
    local presetsY = hexY + 24 + 8
    local total = hexY + 24 + (presets and 26 or 0) + 10
    local ecorner = self.Window.Config.Element.Corner

    local parent, order = self:_slot(o)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, HEAD), BackgroundColor3 = Theme.Row, ClipsDescendants = true,
        LayoutOrder = order, Parent = parent,
    }, { corner(ecorner) })
    local head = create("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, HEAD), BackgroundTransparency = 1, Parent = holder,
    })
    local nameLbl = label({ Text = o.Name or "Color", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -70, 1, 0), Parent = head })
    local swatch = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(30, 16), BackgroundColor3 = Theme.Accent, Parent = head,
    }, { corner(5), stroke(Theme.Stroke, 1, 0.4) })

    local sv = create("Frame", {
        Position = UDim2.fromOffset(10, 42), Size = UDim2.new(1, -40, 0, PANEL_H),
        BackgroundColor3 = Color3.new(1, 0, 0), Parent = holder,
    }, { corner(6) })
    create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), Parent = sv,
    }, { corner(7), create("UIGradient", {
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
    }) })
    create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), Parent = sv,
    }, { corner(7), create("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }),
    }) })
    local svCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1, ZIndex = 3, Parent = sv,
    }, { corner(5), stroke(Color3.new(1, 1, 1), 2) })
    local svHit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        ZIndex = 5, Parent = sv })

    local hue = create("Frame", {
        Position = UDim2.new(1, -24, 0, 42), Size = UDim2.fromOffset(14, PANEL_H),
        BackgroundColor3 = Color3.new(1, 1, 1), Parent = holder,
    }, { corner(6), create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, rgb(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, rgb(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, rgb(0, 255, 0)),
            ColorSequenceKeypoint.new(0.50, rgb(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, rgb(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, rgb(255, 0, 255)),
            ColorSequenceKeypoint.new(1.00, rgb(255, 0, 0)),
        }),
    }) })
    local hueCursor = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.new(1, 4, 0, 5),
        BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3, Parent = hue,
    }, { corner(2), stroke(Theme.Outline, 1) })
    local hueHit = create("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 10, 1, 0),
        Position = UDim2.fromOffset(-5, 0), ZIndex = 5, Parent = hue })

    local hexStroke = stroke(Theme.Stroke, 1)
    local hexBox = create("TextBox", {
        Position = UDim2.fromOffset(10, hexY), Size = UDim2.new(1, -20, 0, 24),
        BackgroundColor3 = Theme.Input, Font = Fonts.Bold, TextSize = 12, TextColor3 = Theme.Text,
        PlaceholderText = "#RRGGBB", PlaceholderColor3 = Theme.Dim, ClearTextOnFocus = false, Text = "",
        Parent = holder,
    }, { corner(5), hexStroke })

    local default = o.Default or Theme.Accent
    local h, s, v = default:ToHSV()
    local obj = { Type = "ColorPicker", Value = default, Open = false }
    decorate(self, obj, holder, o)

    local function refresh(silent)
        local c = Color3.fromHSV(h, s, v)
        obj.Value = c
        swatch.BackgroundColor3 = c
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svCursor.Position = UDim2.fromScale(s, 1 - v)
        hueCursor.Position = UDim2.fromScale(0.5, h)
        if not hexBox:IsFocused() then hexBox.Text = toHex(c) end
        if not silent then fire(obj, o, c) end
    end
    function obj:Set(color, silent)
        if typeof(color) ~= "Color3" then return end
        local nh, ns, nv = color:ToHSV()
        if ns > 0 and nv > 0 then h = nh end
        s, v = ns, nv
        refresh(silent)
    end
    function obj:Get() return obj.Value end
    function obj:SetHex(hex, silent)
        local r, g, b = tostring(hex):match("^#?(%x%x)(%x%x)(%x%x)$")
        if r then obj:Set(Color3.fromRGB(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)), silent) return true end
        return false
    end
    function obj:GetHex() return toHex(obj.Value) end
    function obj:SetOpen(state)
        obj.Open = state and true or false
        tween(holder, { Size = UDim2.new(1, 0, 0, obj.Open and total or HEAD) }, 0.22, SOFT, SOFT_DIR)
    end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    local function svMove(pos)
        s = math.clamp((pos.X - sv.AbsolutePosition.X) / math.max(sv.AbsoluteSize.X, 1), 0, 1)
        v = 1 - math.clamp((pos.Y - sv.AbsolutePosition.Y) / math.max(sv.AbsoluteSize.Y, 1), 0, 1)
        refresh()
    end
    local function hueMove(pos)
        h = math.clamp((pos.Y - hue.AbsolutePosition.Y) / math.max(hue.AbsoluteSize.Y, 1), 0, 1)
        refresh()
    end
    dragger(svHit, function(i) self:_lockScroll(true) svMove(i.Position) end,
        function(i) svMove(i.Position) end, function() self:_lockScroll(false) end)
    dragger(hueHit, function(i) self:_lockScroll(true) hueMove(i.Position) end,
        function(i) hueMove(i.Position) end, function() self:_lockScroll(false) end)

    hexBox.Focused:Connect(function() tween(hexStroke, { Color = Theme.Accent }, 0.15) end)
    hexBox.FocusLost:Connect(function()
        tween(hexStroke, { Color = Theme.Stroke }, 0.15)
        if not obj:SetHex(hexBox.Text) then hexBox.Text = toHex(obj.Value) end
    end)

    if presets then
        local row = create("Frame", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(10, presetsY),
            Size = UDim2.new(1, -20, 0, 18), Parent = holder,
        }, { listLayout(6, { FillDirection = Enum.FillDirection.Horizontal }) })
        for i, col in ipairs(presets) do
            local sw = create("TextButton", {
                Text = "", Size = UDim2.fromOffset(18, 18), BackgroundColor3 = col, LayoutOrder = i, Parent = row,
            }, { corner(5), stroke(Theme.Outline, 1) })
            sw.Activated:Connect(function() obj:Set(col) end)
        end
    end

    head.Activated:Connect(function()
        if not obj.Enabled then return end
        obj:SetOpen(not obj.Open)
    end)
    head.MouseEnter:Connect(function() tween(holder, { BackgroundColor3 = Theme.RowHover }, 0.15) end)
    head.MouseLeave:Connect(function() tween(holder, { BackgroundColor3 = Theme.Row }, 0.15) end)

    refresh(true)
    self:_register(o.Flag, obj)
    return obj
end

function SectionMT:AddProgress(o)
    o = o or {}
    local min, max = o.Min or 0, o.Max or 100
    local r = self:_row(self:_eh(o) + 6, false, o)
    local nameLbl = label({ Text = o.Name or "Progress", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -80, 0, 24), Parent = r })
    local valLbl = label({ Text = "", TextSize = 12, TextColor3 = Theme.Text, Font = Fonts.Bold,
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(60, 24), Parent = r })
    local track = create("Frame", {
        Position = UDim2.new(0, 12, 1, -14), Size = UDim2.new(1, -24, 0, 6), BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(3) })
    local fill = create("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = o.Color or Theme.Accent, Parent = track },
        { corner(3) })
    local obj = { Type = "Progress", Value = min, Savable = false }
    decorate(self, obj, r, o)
    function obj:Set(v, silent)
        v = math.clamp(tonumber(v) or min, min, max)
        obj.Value = v
        local a = (max == min) and 0 or (v - min) / (max - min)
        tween(fill, { Size = UDim2.fromScale(a, 1) }, 0.3, SOFT, Enum.EasingDirection.Out)
        valLbl.Text = (o.ShowPercent == false) and tostring(v) or (math.floor(a * 100 + 0.5) .. "%")
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    obj:Set(o.Default or min, true)
    self:_register(o.Flag, obj)
    return obj
end

function WindowMT:CreateSettingsTab(name, icon)
    local win = self
    local tab = self:CreateTab(name or "Settings", icon or "S")

    local ui = tab:CreateSection("Interface")
    ui:AddKeybind({
        Name = "Menu Key", Default = self.ToggleKey,
        Changed = function(key)
            if key ~= Enum.KeyCode.Unknown then win.ToggleKey = key end
        end,
    })
    ui:AddToggle({
        Name = "Floating Button", Default = self._floating.Visible,
        Callback = function(v) win._floating.Visible = v end,
    })
    ui:AddToggle({
        Name = "Animations", Default = Library.Config.Animations,
        Callback = function(v) Library.Config.Animations = v end,
    })
    ui:AddSlider({
        Name = "Animation Speed", Min = 0.25, Max = 3, Increment = 0.25, Suffix = "x",
        Default = Library.Config.AnimationSpeed,
        Callback = function(v) Library.Config.AnimationSpeed = v end,
    })
    ui:AddButton({
        Name = "Reset Position",
        Callback = function()
            win:ResetPosition()
            win:Notify({ Title = "Layout", Content = "Window position reset" })
        end,
    })
    ui:AddButton({ Name = "Unload UI", Style = "Danger", Callback = function() win:Destroy() end })

    local cfg = tab:CreateSection("Configs")
    local cfgName = ""
    local picker
    cfg:AddTextBox({ Name = "Name", Placeholder = "my config", Callback = function(t) cfgName = t end })
    cfg:AddButton({
        Name = "Save Config", Primary = true,
        Callback = function()
            local ok, err = win:SaveConfig(cfgName)
            win:Notify({ Title = ok and "Config saved" or "Error", Content = ok and cfgName or err,
                Type = ok and "Success" or "Error" })
            if ok and picker then picker:Refresh(win:GetConfigs(), true) end
        end,
    })
    picker = cfg:AddDropdown({ Name = "Configs", Options = win:GetConfigs() })
    cfg:AddButton({
        Name = "Load Selected",
        Callback = function()
            local sel = picker:Get()
            if not sel then return win:Notify({ Title = "Config", Content = "Select a config first", Type = "Warning" }) end
            local ok, err = win:LoadConfig(sel)
            win:Notify({ Title = ok and "Config loaded" or "Error", Content = ok and sel or err,
                Type = ok and "Success" or "Error" })
        end,
    })
    cfg:AddButton({
        Name = "Refresh List",
        Callback = function() picker:Refresh(win:GetConfigs()) end,
    })
    if not hasFS then
        cfg:AddLabel("Tu executor no soporta archivos: guardar/cargar está desactivado.")
    end
    return tab
end

Library.new = function(opts) return Library:CreateWindow(opts) end

return Library
