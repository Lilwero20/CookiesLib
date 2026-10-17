local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local rgb = Color3.fromRGB

local DefaultTheme = {
    Background = rgb(19, 13, 10),
    Panel      = rgb(27, 19, 14),
    Element    = rgb(33, 23, 17),
    Row        = rgb(40, 28, 20),
    RowHover   = rgb(50, 34, 24),
    Input      = rgb(21, 14, 11),
    Stroke     = rgb(74, 51, 33),
    Outline    = rgb(10, 7, 5),
    Accent     = rgb(245, 194, 12),
    AccentHi   = rgb(255, 214, 64),
    AccentSoft = rgb(52, 38, 16),
    OnAccent   = rgb(46, 28, 6),
    Text       = rgb(244, 235, 222),
    Muted      = rgb(176, 156, 134),
    Dim        = rgb(122, 105, 90),
    Success    = rgb(96, 196, 124),
    Warning    = rgb(232, 148, 58),
    Error      = rgb(224, 92, 92),
}

local DEFAULT_LOGO = "rbxassetid://76143769732706"
local SHADOW = "rbxassetid://6014261993"
local DEFAULT_SDK = "https://www.keyforge.win/sdk/client.lua"

local KeySystem = {}
KeySystem.__index = KeySystem
KeySystem.Version = "2.0.0"

local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function"
    and typeof(isfolder) == "function" and typeof(makefolder) == "function"
    and typeof(isfile) == "function"

local function genv()
    local ok, g = pcall(function() return getgenv and getgenv() end)
    return (ok and type(g) == "table") and g or _G
end

local function create(className, props, children)
    local inst = Instance.new(className)
    if inst:IsA("GuiObject") then inst.BorderSizePixel = 0 end
    if inst:IsA("GuiButton") then inst.AutoButtonColor = false end
    if className == "TextLabel" or className == "ImageLabel" then inst.BackgroundTransparency = 1 end
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, props, time, style, dir)
    if not time or time <= 0 then
        for k, v in pairs(props) do obj[k] = v end
        return nil
    end
    local tw = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function dragger(handle, onStart, onMove)
    handle.InputBegan:Connect(function(input)
        if not isPress(input) then return end
        onStart(input)
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseMovement or i == input then onMove(i) end
        end)
        endConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConn:Disconnect()
                endConn:Disconnect()
            end
        end)
    end)
end

local function trim(s) return (tostring(s or ""):match("^%s*(.-)%s*$")) end

local function copy(text)
    local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
    if typeof(fn) == "function" then
        return pcall(fn, text)
    end
    return false
end

-- Arma la paleta: tema de la libreria (si se pasa) + overrides de Theme / Accent
local function buildTheme(opts)
    local Lib = opts.Library
    local base = (Lib and Lib.Theme) or DefaultTheme
    local theme = table.clone(base)
    local custom = opts.Theme
    if type(custom) == "string" and Lib and type(Lib.Themes) == "table" then custom = Lib.Themes[custom] end
    if type(custom) == "table" then
        for k, v in pairs(custom) do theme[k] = v end
    end
    local accent = opts.Accent or (type(custom) == "table" and custom.Accent)
    if typeof(accent) == "Color3" then
        theme.Accent = accent
        if not (type(custom) == "table" and custom.AccentHi) then theme.AccentHi = accent:Lerp(rgb(255, 255, 255), 0.25) end
        if not (type(custom) == "table" and custom.AccentSoft) then theme.AccentSoft = theme.Panel:Lerp(accent, 0.14) end
        if not (type(custom) == "table" and custom.OnAccent) then
            local lum = 0.299 * accent.R + 0.587 * accent.G + 0.114 * accent.B
            theme.OnAccent = lum > 0.55 and rgb(40, 20, 8) or rgb(254, 254, 254)
        end
    end
    return theme
end

function KeySystem.new(opts)
    opts = opts or {}
    local Lib = opts.Library
    local Theme = buildTheme(opts)
    local Fonts = (Lib and Lib.Fonts) or {
        Title = Enum.Font.GothamBold, Body = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold,
    }

    local cfg = {
        Title         = opts.Title or "Cookies Hub",
        Subtitle      = opts.Subtitle or "Key System",
        Logo          = opts.Logo == nil and DEFAULT_LOGO or opts.Logo,
        Description   = opts.Description or "Enter your key to unlock the hub.",
        KeyLink       = opts.KeyLink,
        DiscordLink   = opts.DiscordLink,
        DiscordCode   = opts.DiscordCode,
        Keys          = opts.Keys,
        KeyUrl        = opts.KeyUrl,
        Validate      = opts.Validate,
        KeyForge      = opts.KeyForge,
        LoadScript    = opts.LoadScript,
        SaveKey       = opts.SaveKey ~= false,
        AutoVerify    = opts.AutoVerify ~= false,
        CaseSensitive = opts.CaseSensitive ~= false,
        Folder        = opts.Folder or "CookiesHub",
        FileName      = opts.FileName or "key.txt",
        MaxAttempts   = opts.MaxAttempts or 5,
        Cooldown      = opts.Cooldown or 15,
        Blur          = opts.Blur ~= false,
        Shadow        = opts.Shadow ~= false,
        Note          = opts.Note,
        Steps         = opts.Steps,
        DisplayOrder  = opts.DisplayOrder or 100,
        OnSuccess     = opts.OnSuccess,
        OnFail        = opts.OnFail,
        OnClose       = opts.OnClose,
    }
    -- si no hay Note ni Steps, se muestra la guia de 3 pasos
    if cfg.Steps == nil and cfg.Note == nil then
        cfg.Steps = {
            "Press Get key to copy the link",
            "Complete the steps in your browser",
            "Paste your key and press Verify",
        }
    end

    local getClient
    local keyPath = cfg.Folder .. "/" .. cfg.FileName

    local self = setmetatable({}, KeySystem)
    self.Done, self.Success, self.Key = false, false, nil
    self.Theme = Theme
    self._event = Instance.new("BindableEvent")
    self._attempts = 0
    self._busy = false
    self._locked = false
    self._conns = {}

    local parent = PlayerGui
    pcall(function()
        if typeof(gethui) == "function" then parent = gethui() end
    end)
    local old = parent:FindFirstChild("CookiesKeyUI")
    if old then old:Destroy() end

    local gui = create("ScreenGui", {
        Name = "CookiesKeyUI", ResetOnSpawn = false, DisplayOrder = cfg.DisplayOrder,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    pcall(function() gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets end)
    if not pcall(function() gui.Parent = parent end) then gui.Parent = PlayerGui end
    self.Gui = gui

    local blur
    if cfg.Blur then
        pcall(function()
            local prev = Lighting:FindFirstChild("CookiesKeyBlur")
            if prev then prev:Destroy() end
            blur = Instance.new("BlurEffect")
            blur.Name = "CookiesKeyBlur"
            blur.Size = 0
            blur.Parent = Lighting
            tween(blur, { Size = 12 }, 0.5)
        end)
    end

    local dim = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1, Active = true, Parent = gui,
    })
    tween(dim, { BackgroundTransparency = 0.45 }, 0.4)

    local CARD_W, CARD_H = 600, 340
    local PANEL_W = 200

    -- holder: lleva la escala y la sombra (la sombra no puede ir dentro del CanvasGroup porque se recortaria)
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundTransparency = 1, Parent = gui,
    })
    local uiScale = create("UIScale", { Scale = 0.94, Parent = holder })
    local baseScale = 1
    local shadow
    if cfg.Shadow then
        shadow = create("ImageLabel", {
            Image = SHADOW, ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 1,
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 5),
            Size = UDim2.new(1, 52, 1, 52), Parent = holder,
        })
    end

    local root = create("CanvasGroup", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        GroupTransparency = 1, Parent = holder,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 14) }),
        create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
        create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(200, 200, 200)) }),
    })

    local function getViewport()
        local s = gui.AbsoluteSize
        if s.X < 50 or s.Y < 50 then
            local cam = workspace.CurrentCamera
            s = cam and cam.ViewportSize or Vector2.new(1280, 720)
        end
        return s
    end
    local function fit()
        local vp = getViewport()
        baseScale = math.clamp(math.min((vp.X - 24) / CARD_W, (vp.Y - 24) / CARD_H), 0.4, 1)
        if self._ready then uiScale.Scale = baseScale end
    end
    fit()
    table.insert(self._conns, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit))

    local function corner(r) return create("UICorner", { CornerRadius = UDim.new(0, r) }) end
    local function stroke(c, t, tr)
        return create("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    end
    local function label(props)
        local p = {
            Font = Fonts.Body, TextSize = 13, TextColor3 = Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
            TextTruncate = Enum.TextTruncate.AtEnd,
        }
        for k, v in pairs(props) do p[k] = v end
        return create("TextLabel", p)
    end
    local function checkMark(parent, color, z)
        local f = create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent,
        })
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(3, 7.5),
            Size = UDim2.fromOffset(5, 2), Rotation = 45, BackgroundColor3 = color, ZIndex = z or 1, Parent = f,
        }, { corner(1) })
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7.5, 5.5),
            Size = UDim2.fromOffset(9, 2), Rotation = -45, BackgroundColor3 = color, ZIndex = z or 1, Parent = f,
        }, { corner(1) })
        return f
    end

    ----------------------------------------------------------------
    -- Columna izquierda
    ----------------------------------------------------------------
    local left = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -(PANEL_W + 12), 1, 0), Parent = root,
    })

    local dragBar = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 72), ZIndex = 2, Parent = left,
    })
    local hasLogo = cfg.Logo ~= nil and cfg.Logo ~= false and cfg.Logo ~= ""
    local logoImg
    if hasLogo then
        logoImg = create("ImageLabel", {
            Image = cfg.Logo, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(43, 41),
            Size = UDim2.fromOffset(38, 38), ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = left,
        })
    end
    local tx = hasLogo and 72 or 24
    label({
        Text = cfg.Title, Font = Fonts.Title, TextSize = 18, Position = UDim2.fromOffset(tx, 22),
        Size = UDim2.new(1, -(tx + 12), 0, 22), ZIndex = 3, Parent = left,
    })
    label({
        Text = cfg.Subtitle, TextSize = 11, TextColor3 = Theme.Dim, Position = UDim2.fromOffset(tx, 44),
        Size = UDim2.new(1, -(tx + 12), 0, 14), ZIndex = 3, Parent = left,
    })
    -- linea de acento con degradado (misma firma visual que la libreria)
    create("Frame", {
        Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -48, 0, 1),
        BackgroundColor3 = Theme.Accent, Parent = left,
    }, { create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.4, 0.65),
            NumberSequenceKeypoint.new(1, 1),
        }),
    }) })

    label({
        Text = cfg.Description, TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(24, 84), Size = UDim2.new(1, -48, 0, 30), Parent = left,
    })

    label({
        Text = "KEY", Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.fromOffset(26, 122), Size = UDim2.fromOffset(60, 12), Parent = left,
    })
    local INPUT_Y = 139
    local inputRow = create("Frame", {
        Position = UDim2.fromOffset(24, INPUT_Y), Size = UDim2.new(1, -48, 0, 40),
        BackgroundColor3 = Theme.Input, Parent = left,
    }, { corner(10) })
    local inputStroke = stroke(Theme.Stroke, 1, 0.1)
    inputStroke.Parent = inputRow

    local canPaste = typeof(getclipboard) == "function" or typeof(fromclipboard) == "function"
    local keyBox = create("TextBox", {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, canPaste and -86 or -28, 1, 0),
        BackgroundTransparency = 1, Font = Fonts.Body, TextSize = 13, TextColor3 = Theme.Text,
        PlaceholderText = "Paste your key here", PlaceholderColor3 = Theme.Dim, Text = "",
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = inputRow,
    })
    local pasteBtn
    if canPaste then
        pasteBtn = create("TextButton", {
            Text = "Paste", Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.Muted,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0),
            Size = UDim2.fromOffset(52, 26), BackgroundColor3 = Theme.Row, Parent = inputRow,
        }, { corner(6) })
        pasteBtn.MouseEnter:Connect(function()
            tween(pasteBtn, { BackgroundColor3 = Theme.RowHover, TextColor3 = Theme.Text }, 0.15)
        end)
        pasteBtn.MouseLeave:Connect(function()
            tween(pasteBtn, { BackgroundColor3 = Theme.Row, TextColor3 = Theme.Muted }, 0.15)
        end)
    end
    keyBox.Focused:Connect(function() tween(inputStroke, { Color = Theme.Accent, Transparency = 0 }, 0.18) end)
    keyBox.FocusLost:Connect(function()
        if not self._errorShown then tween(inputStroke, { Color = Theme.Stroke, Transparency = 0.1 }, 0.18) end
    end)

    local verifyBtn = create("TextButton", {
        Text = "", Position = UDim2.fromOffset(24, INPUT_Y + 50), Size = UDim2.new(1, -48, 0, 40),
        BackgroundColor3 = Theme.Accent, ClipsDescendants = true, Parent = left,
    }, { corner(10), create("UIGradient", {
        Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(220, 220, 220)),
    }) })
    local verifyScale = create("UIScale", { Scale = 1, Parent = verifyBtn })
    local verifyLbl = label({
        Text = "Verify", Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.OnAccent,
        TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = verifyBtn,
    })

    -- spinner: aro con degradado en el borde que gira mientras se verifica
    local spinner = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -58, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = verifyBtn,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local spinStroke = create("UIStroke", { Color = Theme.Accent, Thickness = 2, Parent = spinner })
    create("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.4), NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = spinStroke,
    })
    local spinTween
    -- check que aparece al validar la key
    local okMark = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -66, 0.5, 0),
        Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = verifyBtn,
    })
    local okScale = create("UIScale", { Scale = 0, Parent = okMark })
    checkMark(okMark, rgb(255, 255, 255), 3)

    local sheen = create("Frame", {
        Size = UDim2.new(0, 46, 2, 0), Position = UDim2.new(0, -60, -0.5, 0), Rotation = 18,
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, ZIndex = 3, Parent = verifyBtn,
    })

    local optRow = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(24, INPUT_Y + 102), Size = UDim2.new(1, -48, 0, 18),
        Parent = left,
    })
    local checkBtn = create("TextButton", {
        Text = "", BackgroundTransparency = 1, Size = UDim2.new(0, 130, 1, 0), Parent = optRow,
    })
    local boxStroke = stroke(Theme.Stroke, 1, 0.1)
    local box = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Theme.Input, Parent = checkBtn,
    }, { corner(4), boxStroke })
    local boxCheck = checkMark(box, Theme.OnAccent, 2)
    local boxCheckScale = create("UIScale", { Scale = 0, Parent = boxCheck })
    label({
        Text = "Remember key", TextSize = 11, TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -24, 1, 0), Parent = checkBtn,
    })
    local clearBtn = create("TextButton", {
        Text = "Delete saved key", Font = Fonts.Body, TextSize = 11, TextColor3 = Theme.Dim,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.fromOffset(130, 18), BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = optRow,
    })
    clearBtn.MouseEnter:Connect(function() tween(clearBtn, { TextColor3 = Theme.Text }, 0.15) end)
    clearBtn.MouseLeave:Connect(function() tween(clearBtn, { TextColor3 = Theme.Dim }, 0.15) end)
    if not hasFS or not cfg.SaveKey then
        checkBtn.Visible = false
        clearBtn.Visible = false
    end

    local remember = cfg.SaveKey and hasFS
    local function paintCheck(animate)
        local t = animate and 0.18 or 0
        tween(box, { BackgroundColor3 = remember and Theme.Accent or Theme.Input }, t)
        tween(boxStroke, { Color = remember and Theme.Accent or Theme.Stroke }, t)
        tween(boxCheckScale, { Scale = remember and 1 or 0 }, t, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
    paintCheck(false)
    checkBtn.Activated:Connect(function()
        remember = not remember
        paintCheck(true)
    end)

    -- estado: punto de color + mensaje
    local STATUS_Y = INPUT_Y + 130
    local statusRow = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(24, STATUS_Y), Size = UDim2.new(1, -48, 0, 16),
        Parent = left,
    })
    local statusDot = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Theme.Muted, BackgroundTransparency = 1, Parent = statusRow,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local statusLbl = label({
        Text = "", TextSize = 11, TextColor3 = Theme.Muted, TextTransparency = 1,
        Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -12, 1, 0), Parent = statusRow,
    })
    label({
        Text = "v" .. KeySystem.Version, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.new(0, 24, 1, -30), Size = UDim2.fromOffset(120, 14), Parent = left,
    })
    local attemptsLbl = label({
        Text = "", TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 1, -30),
        Size = UDim2.fromOffset(160, 14), Parent = left,
    })

    local function setStatus(text, color)
        statusLbl.Text = text or ""
        statusLbl.TextColor3 = color or Theme.Muted
        statusDot.BackgroundColor3 = color or Theme.Muted
        if text and text ~= "" then
            statusRow.Position = UDim2.fromOffset(24, STATUS_Y + 4)
            statusLbl.TextTransparency = 1
            statusDot.BackgroundTransparency = 1
            tween(statusRow, { Position = UDim2.fromOffset(24, STATUS_Y) }, 0.2)
            tween(statusLbl, { TextTransparency = 0 }, 0.2)
            tween(statusDot, { BackgroundTransparency = 0 }, 0.2)
        else
            statusLbl.TextTransparency = 1
            statusDot.BackgroundTransparency = 1
        end
    end
    local function updateAttempts()
        local left_ = math.max(cfg.MaxAttempts - self._attempts, 0)
        attemptsLbl.Text = self._attempts > 0 and (left_ .. (left_ == 1 and " attempt left" or " attempts left")) or ""
        attemptsLbl.TextColor3 = left_ <= 1 and Theme.Warning or Theme.Dim
    end

    ----------------------------------------------------------------
    -- Panel derecho: guia y enlaces
    ----------------------------------------------------------------
    local panel = create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 52),
        Size = UDim2.new(0, PANEL_W, 1, -64), BackgroundColor3 = Theme.Panel, Parent = root,
    }, { corner(12), stroke(Theme.Stroke, 1, 0.45) })

    label({
        Text = "Need a key?", Font = Fonts.Bold, TextSize = 13,
        Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 18), Parent = panel,
    })
    local btnY = 100
    if type(cfg.Steps) == "table" and #cfg.Steps > 0 then
        local y = 40
        for i, step in ipairs(cfg.Steps) do
            if i > 3 then break end
            create("TextLabel", {
                Text = tostring(i), Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Accent,
                BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentSoft,
                Position = UDim2.fromOffset(16, y + 2), Size = UDim2.fromOffset(18, 18), Parent = panel,
            }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
            label({
                Text = tostring(step), TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true,
                TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
                Position = UDim2.fromOffset(42, y + 3), Size = UDim2.new(1, -56, 0, 26), Parent = panel,
            })
            y = y + 28
        end
        btnY = y + 8
    else
        label({
            Text = cfg.Note or "", TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
            Position = UDim2.fromOffset(16, 38), Size = UDim2.new(1, -32, 0, 56), Parent = panel,
        })
    end

    local function sideButton(y, text, primary)
        local normal = primary and Theme.AccentSoft or Theme.Row
        local over = primary and Theme.AccentSoft:Lerp(Theme.Accent, 0.25) or Theme.RowHover
        local b = create("TextButton", {
            Text = "", Position = UDim2.fromOffset(12, y), Size = UDim2.new(1, -24, 0, 36),
            BackgroundColor3 = normal, Parent = panel,
        }, { corner(9), stroke(primary and Theme.Accent or Theme.Stroke, 1, primary and 0.55 or 0.5) })
        local l = label({
            Text = text, Font = Fonts.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = primary and Theme.Accent or Theme.Text, Size = UDim2.fromScale(1, 1), Parent = b,
        })
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = over }, 0.15) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = normal }, 0.15) end)
        local sc = create("UIScale", { Parent = b })
        b.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.97 }, 0.08) end)
        b.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, 0.15, Enum.EasingStyle.Back) end)
        b.MouseLeave:Connect(function() tween(sc, { Scale = 1 }, 0.15) end)
        return b, l
    end

    local showGet = cfg.KeyLink or cfg.KeyForge
    local showDc = cfg.DiscordLink or cfg.DiscordCode
    local getBtn, getLbl = sideButton(btnY, "Get key", true)
    local dcBtn, dcLbl = sideButton(showGet and btnY + 42 or btnY, "Join Discord", false)
    if not showGet then getBtn.Visible = false end
    if not showDc then dcBtn.Visible = false end

    create("Frame", {
        Position = UDim2.new(0, 16, 1, -44), Size = UDim2.new(1, -32, 0, 1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.55, Parent = panel,
    })
    local avatar = create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 16, 1, -22),
        Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 0, BackgroundColor3 = Theme.Input, Parent = panel,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    task.spawn(function()
        local ok, img = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
        if ok and avatar.Parent then avatar.Image = img end
    end)
    label({
        Text = "@" .. LocalPlayer.Name, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.new(0, 46, 1, -34), Size = UDim2.new(1, -62, 0, 24), Parent = panel,
    })

    local function flashLabel(lbl, text, original)
        lbl.Text = text
        task.delay(1.6, function()
            if lbl.Parent then lbl.Text = original end
        end)
    end

    local function giveLink(link)
        local ok = copy(link)
        flashLabel(getLbl, ok and "Link copied!" or "No clipboard", "Get key")
        setStatus(ok and "Link copied. Paste it in your browser." or ("Open this link: " .. link),
            ok and Theme.Success or Theme.Warning)
    end

    local gettingLink = false
    getBtn.Activated:Connect(function()
        if gettingLink then return end
        if cfg.KeyLink then giveLink(cfg.KeyLink) return end
        if not cfg.KeyForge then return end
        gettingLink = true
        getLbl.Text = "Loading..."
        setStatus("Getting your key link...", Theme.Muted)
        task.spawn(function()
            local link
            local client = getClient()
            if client then
                local okK, url = pcall(function() return (client:getKeyUrl()) end)
                if okK and type(url) == "string" and url ~= "" then link = url end
            end
            gettingLink = false
            if not gui.Parent then return end
            if not link then
                getLbl.Text = "Get key"
                setStatus("Could not get the key link", Theme.Error)
                return
            end
            cfg.KeyLink = link
            giveLink(link)
        end)
    end)

    dcBtn.Activated:Connect(function()
        local joined = false
        local code = cfg.DiscordCode or (cfg.DiscordLink and cfg.DiscordLink:match("discord%.gg/([%w%-_]+)"))
        local req = request or http_request or (syn and syn.request)
        if code and typeof(req) == "function" then
            joined = pcall(function()
                req({
                    Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST",
                    Headers = { ["Content-Type"] = "application/json", Origin = "https://discord.com" },
                    Body = HttpService:JSONEncode({ cmd = "INVITE_BROWSER", nonce = HttpService:GenerateGUID(false),
                        args = { code = code } }),
                })
            end)
        end
        local invite = cfg.DiscordLink or (code and ("https://discord.gg/" .. code))
        local copied = invite and copy(invite)
        flashLabel(dcLbl, (joined and "Opening Discord...") or (copied and "Invite copied!") or "No clipboard",
            "Join Discord")
        if not joined then
            setStatus(copied and "Invite copied. Paste it in Discord." or ("Invite: " .. tostring(invite)),
                Theme.Muted)
        end
    end)

    local closeBtn = create("TextButton", {
        Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Row, BackgroundTransparency = 1,
        ZIndex = 6, Parent = root,
    }, { corner(8) })
    local xBars = {}
    for _, rot in ipairs({ 45, -45 }) do
        table.insert(xBars, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 2), Rotation = rot, BackgroundColor3 = Theme.Muted, ZIndex = 7,
            Parent = closeBtn,
        }, { corner(1) }))
    end
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = rgb(110, 40, 36), BackgroundTransparency = 0 }, 0.15)
        for _, b in ipairs(xBars) do tween(b, { BackgroundColor3 = Theme.Text }, 0.15) end
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundTransparency = 1 }, 0.15)
        for _, b in ipairs(xBars) do tween(b, { BackgroundColor3 = Theme.Muted }, 0.15) end
    end)

    do
        local startInput, startPos, dragTween
        dragger(dragBar, function(input)
            startInput, startPos = input.Position, holder.Position
        end, function(i)
            local d = i.Position - startInput
            local vp = getViewport()
            local nx = math.clamp(startPos.X.Offset + d.X, -vp.X / 2 + 80, vp.X / 2 - 80)
            local ny = math.clamp(startPos.Y.Offset + d.Y, -vp.Y / 2 + 40, vp.Y / 2 - 40)
            if dragTween then dragTween:Cancel() end
            dragTween = tween(holder, { Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny) }, 0.07,
                Enum.EasingStyle.Quad)
        end)
    end

    ----------------------------------------------------------------
    -- Logica
    ----------------------------------------------------------------
    local function cleanup()
        for _, c in ipairs(self._conns) do c:Disconnect() end
        self._conns = {}
        if spinTween then spinTween:Cancel() end
        if blur then
            local b = blur
            blur = nil
            tween(b, { Size = 0 }, 0.3)
            task.delay(0.35, function() b:Destroy() end)
        end
    end

    local function outro(after)
        tween(dim, { BackgroundTransparency = 1 }, 0.3)
        tween(root, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        if shadow then tween(shadow, { ImageTransparency = 1 }, 0.2) end
        tween(uiScale, { Scale = baseScale * 0.95 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        cleanup()
        task.delay(0.32, function()
            if gui then gui:Destroy() end
            if after then after() end
        end)
    end

    local function finish(success, key)
        if self.Done then return end
        self.Done, self.Success, self.Key = true, success, key
        self._event:Fire(success, key)
        local ev = self._event
        task.delay(5, function() ev:Destroy() end)
    end

    local function saveKey(key)
        if not (remember and hasFS) then return end
        pcall(function()
            if not isfolder(cfg.Folder) then makefolder(cfg.Folder) end
            writefile(keyPath, key)
        end)
    end
    local function loadSaved()
        if not hasFS then return nil end
        local ok, data = pcall(function()
            if isfile(keyPath) then return readfile(keyPath) end
        end)
        if ok and data and trim(data) ~= "" then return trim(data) end
        return nil
    end
    local function clearSaved()
        if not hasFS then return end
        pcall(function()
            if typeof(delfile) == "function" and isfile(keyPath) then delfile(keyPath)
            elseif isfile(keyPath) then writefile(keyPath, "") end
        end)
    end

    -- KeyForge: el SDK se descarga una sola vez; llamadas simultaneas esperan a la misma descarga
    local clientLoading, clientErr = false, nil
    function getClient()
        if self.Client then return self.Client end
        if clientLoading then
            while clientLoading do task.wait() end
            return self.Client, clientErr
        end
        clientLoading = true
        local function fail(msg)
            clientErr = msg
            clientLoading = false
            return nil, msg
        end
        local kf = cfg.KeyForge
        local okDl, src = pcall(function() return game:HttpGet(kf.sdkUrl or DEFAULT_SDK, true) end)
        if not okDl or type(src) ~= "string" then return fail("Could not download the KeyForge SDK") end
        if src:find("<!DOCTYPE", 1, true) or src:find("<html", 1, true) then
            return fail("KeyForge returned HTML instead of Lua")
        end
        local compiler = loadstring or load
        if type(compiler) ~= "function" then return fail("Your executor does not support loadstring") end
        local okC, chunk = pcall(compiler, src)
        if not okC or type(chunk) ~= "function" then return fail("Invalid KeyForge SDK") end
        local okI, KeyForge = pcall(chunk)
        if not okI or type(KeyForge) ~= "table" or type(KeyForge.new) ~= "function" then
            return fail("Could not start KeyForge")
        end
        local okN, client = pcall(KeyForge.new, {
            projectId = kf.projectId, scriptId = kf.scriptId, integrationToken = kf.integrationToken,
        })
        if not okN or type(client) ~= "table" then return fail("Invalid KeyForge configuration") end
        self.Client = client
        clientErr = nil
        clientLoading = false
        return client
    end

    -- lista de KeyUrl en cache 30s: reintentos rapidos sin volver a descargarla
    local urlCache, urlCacheAt = nil, 0
    local function norm(k) return cfg.CaseSensitive and k or string.lower(k) end

    local function check(key)
        if cfg.KeyForge then
            local client, err = getClient()
            if not client then return false, err, true end
            local okV, res = pcall(function() return client:verify(key) end)
            if not okV then return false, "Error contacting KeyForge", true end
            if type(res) == "table" and res.ok then return true end
            return false, (type(res) == "table" and res.message) or "Incorrect key"
        end
        if cfg.Validate then
            local ok, a, b = pcall(cfg.Validate, key)
            if not ok then return false, "Error validating the key", true end
            if type(a) == "boolean" then return a, b end
            return false, nil
        end
        local list = cfg.Keys
        if cfg.KeyUrl then
            if urlCache and os.clock() - urlCacheAt < 30 then
                list = urlCache
            else
                local ok, body = pcall(function() return game:HttpGet(cfg.KeyUrl) end)
                if not ok then return false, "Could not connect to the key server", true end
                list = {}
                for line in tostring(body):gmatch("[^\r\n]+") do
                    local k = trim(line)
                    if k ~= "" then table.insert(list, k) end
                end
                urlCache, urlCacheAt = list, os.clock()
            end
        end
        if type(list) ~= "table" then return false, "Key system not configured" end
        local want = norm(key)
        for _, k in ipairs(list) do
            if norm(tostring(k)) == want then return true end
        end
        return false
    end

    local function shake()
        self._errorShown = true
        tween(inputStroke, { Color = Theme.Error, Transparency = 0 }, 0.12)
        local base = UDim2.fromOffset(24, INPUT_Y)
        task.spawn(function()
            for _, dx in ipairs({ 7, -7, 5, -5, 2, 0 }) do
                tween(inputRow, { Position = UDim2.fromOffset(24 + dx, INPUT_Y) }, 0.05, Enum.EasingStyle.Quad)
                task.wait(0.05)
            end
            inputRow.Position = base
            task.wait(0.9)
            self._errorShown = false
            if inputRow.Parent and not keyBox:IsFocused() then
                tween(inputStroke, { Color = Theme.Stroke, Transparency = 0.1 }, 0.25)
            end
        end)
    end

    local function setLoading(on, text)
        self._busy = on
        if on then
            tween(verifyBtn, { BackgroundColor3 = Theme.AccentSoft }, 0.15)
            verifyLbl.TextColor3 = Theme.Accent
            verifyLbl.Text = text or "Verifying..."
            spinner.Visible = true
            spinStroke.Color = Theme.Accent
            spinner.Rotation = 0
            if spinTween then spinTween:Cancel() end
            spinTween = TweenService:Create(spinner, TweenInfo.new(0.75, Enum.EasingStyle.Linear,
                Enum.EasingDirection.In, -1), { Rotation = 360 })
            spinTween:Play()
        else
            if spinTween then spinTween:Cancel() spinTween = nil end
            spinner.Visible = false
            verifyLbl.Text = "Verify"
            verifyLbl.TextColor3 = Theme.OnAccent
            tween(verifyBtn, { BackgroundColor3 = Theme.Accent }, 0.2)
        end
    end

    -- el cooldown sobrevive a re-ejecutar el script en la misma partida
    local G = genv()
    local function startCooldown(seconds)
        self._locked = true
        G.__CookiesKeyLock = os.clock() + seconds
        task.spawn(function()
            local endAt = os.clock() + seconds
            while os.clock() < endAt do
                if self.Done or not gui.Parent then return end
                local s = math.ceil(endAt - os.clock())
                setStatus("Too many attempts. Wait " .. s .. "s", Theme.Warning)
                verifyLbl.Text = "Wait " .. s .. "s"
                tween(verifyBtn, { BackgroundColor3 = Theme.Row }, 0.15)
                verifyLbl.TextColor3 = Theme.Muted
                task.wait(math.min(1, math.max(endAt - os.clock(), 0.05)))
            end
            self._locked = false
            self._attempts = 0
            G.__CookiesKeyLock = nil
            updateAttempts()
            verifyLbl.Text = "Verify"
            verifyLbl.TextColor3 = Theme.OnAccent
            tween(verifyBtn, { BackgroundColor3 = Theme.Accent }, 0.2)
            setStatus("You can try again now", Theme.Muted)
        end)
    end

    local function submit(key, silent)
        if self._busy or self._locked or self.Done then return end
        key = trim(key)
        if key == "" then
            setStatus("Enter your key first", Theme.Warning)
            shake()
            return
        end
        keyBox:ReleaseFocus()
        setLoading(true, silent and "Checking..." or "Verifying...")
        setStatus(silent and "Checking saved key..." or "Checking key...", Theme.Muted)
        task.spawn(function()
            local ok, msg, transient = check(key)
            if self.Done or not gui.Parent then return end
            setLoading(false)
            if ok then
                self._busy = true
                saveKey(key)
                verifyLbl.Text = "Access granted"
                verifyLbl.TextColor3 = rgb(255, 255, 255)
                verifyLbl.Position = UDim2.fromOffset(10, 0)
                okMark.Visible = true
                tween(okScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                tween(verifyBtn, { BackgroundColor3 = Theme.Success }, 0.2)
                tween(inputStroke, { Color = Theme.Success, Transparency = 0 }, 0.2)
                setStatus(msg or "Access granted. Welcome!", Theme.Success)
                task.wait(0.9)
                outro(function()
                    finish(true, key)
                    if cfg.LoadScript and self.Client then
                        task.spawn(function()
                            local okL, loaded = pcall(function() return self.Client:loadScript() end)
                            if not okL then warn("[CookiesKey] loadScript:", loaded)
                            elseif type(loaded) == "table" and not loaded.ok then
                                warn("[CookiesKey]", loaded.code, loaded.message)
                            end
                        end)
                    end
                    if cfg.OnSuccess then task.spawn(cfg.OnSuccess, key) end
                end)
            else
                if cfg.OnFail then task.spawn(cfg.OnFail, key, msg) end
                if silent then
                    if transient then
                        setStatus(msg or "Could not check the saved key", Theme.Warning)
                    else
                        clearSaved()
                        setStatus("The saved key is no longer valid", Theme.Warning)
                    end
                    return
                end
                if transient then
                    -- errores de red no cuentan como intento fallido
                    setStatus(msg or "Connection error. Try again", Theme.Warning)
                    return
                end
                self._attempts += 1
                updateAttempts()
                shake()
                setStatus(msg or "Incorrect key. Check it and try again", Theme.Error)
                if self._attempts >= cfg.MaxAttempts then startCooldown(cfg.Cooldown) end
            end
        end)
    end
    self.Submit = function(_, k) submit(k or keyBox.Text) end

    verifyBtn.MouseEnter:Connect(function()
        if not self._busy and not self._locked then tween(verifyBtn, { BackgroundColor3 = Theme.AccentHi }, 0.15) end
    end)
    verifyBtn.MouseLeave:Connect(function()
        tween(verifyScale, { Scale = 1 }, 0.15)
        if not self._busy and not self._locked and not self.Done then
            tween(verifyBtn, { BackgroundColor3 = Theme.Accent }, 0.15)
        end
    end)
    verifyBtn.MouseButton1Down:Connect(function() tween(verifyScale, { Scale = 0.98 }, 0.08) end)
    verifyBtn.MouseButton1Up:Connect(function() tween(verifyScale, { Scale = 1 }, 0.15, Enum.EasingStyle.Back) end)
    verifyBtn.Activated:Connect(function() submit(keyBox.Text) end)
    keyBox.FocusLost:Connect(function(enter) if enter then submit(keyBox.Text) end end)

    if pasteBtn then
        pasteBtn.Activated:Connect(function()
            local ok, text = pcall(function()
                return (getclipboard or fromclipboard)()
            end)
            if ok and type(text) == "string" and trim(text) ~= "" then
                keyBox.Text = trim(text)
                setStatus("Key pasted. Press Verify", Theme.Muted)
            else
                setStatus("Clipboard is empty", Theme.Warning)
            end
        end)
    end

    clearBtn.Activated:Connect(function()
        clearSaved()
        keyBox.Text = ""
        setStatus("Saved key deleted", Theme.Muted)
    end)

    closeBtn.Activated:Connect(function() self:Close() end)

    function self:Close()
        if self.Done then return end
        outro(function()
            finish(false, nil)
            if cfg.OnClose then task.spawn(cfg.OnClose) end
        end)
    end
    function self:Wait()
        if self.Done then return self.Success, self.Key end
        return self._event.Event:Wait()
    end
    function self:SetStatus(text, kind)
        local colors = { Success = Theme.Success, Warning = Theme.Warning, Error = Theme.Error }
        setStatus(text, colors[kind] or Theme.Muted)
    end
    function self:Destroy()
        if not self.Done then finish(false, nil) end
        cleanup()
        if gui then gui:Destroy() end
    end

    local saved = loadSaved()
    if saved then keyBox.Text = saved end
    updateAttempts()

    -- precarga el SDK de KeyForge mientras el usuario lee la ventana (verificar se siente instantaneo)
    if cfg.KeyForge then task.spawn(getClient) end

    self._ready = true
    tween(root, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
    if shadow then tween(shadow, { ImageTransparency = 0.4 }, 0.4, Enum.EasingStyle.Quad) end
    tween(holder, { Position = UDim2.fromScale(0.5, 0.5) }, 0.45, Enum.EasingStyle.Quart)
    tween(uiScale, { Scale = baseScale }, 0.4, Enum.EasingStyle.Quart)
    if logoImg then
        logoImg.Rotation = -12
        tween(logoImg, { Rotation = 0 }, 0.6, Enum.EasingStyle.Back)
    end
    task.delay(0.5, function()
        if sheen.Parent then
            tween(sheen, { Position = UDim2.new(1, 20, -0.5, 0) }, 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        end
    end)

    local lockLeft = (G.__CookiesKeyLock or 0) - os.clock()
    if lockLeft > 0.5 then
        self._attempts = cfg.MaxAttempts
        startCooldown(lockLeft)
    elseif saved and cfg.AutoVerify then
        task.delay(0.6, function()
            if gui.Parent then submit(saved, true) end
        end)
    end

    return self
end

-- Atajo bloqueante: local ok, key = KeySystem.Prompt({ ... })
function KeySystem.Prompt(opts)
    local ks = KeySystem.new(opts)
    return ks:Wait()
end

return KeySystem
