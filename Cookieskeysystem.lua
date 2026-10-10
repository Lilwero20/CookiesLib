--[[
    Cookies Hub - Key System
    Modulo independiente que reutiliza el Theme/Fonts de CookiesLib (si se lo pasas).

    USO RAPIDO:
        local Library   = loadstring(game:HttpGet("URL_DE_CookiesLib.lua"))()
        local KeySystem = loadstring(game:HttpGet("URL_DE_CookiesKeySystem.lua"))()

        local ks = KeySystem.new({
            Library     = Library,                         -- para heredar colores y fuentes
            KeyLink     = "https://tu-link-de-key.com",    -- boton Get Key
            DiscordLink = "https://discord.gg/tuinvite",   -- boton Discord
            Keys        = { "COOKIES-1234", "COOKIES-ABCD" },
            -- o: KeyUrl = "https://.../keys.txt" (una key por linea)
            -- o: Validate = function(key) return key == "x", "mensaje opcional" end
        })

        if not ks:Wait() then return end   -- se cerro sin validar
        -- aqui ya puedes crear tu ventana: Library:CreateWindow(...)
]]

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

local KeySystem = {}
KeySystem.__index = KeySystem
KeySystem.Version = "1.0.0"

local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function"
    and typeof(isfolder) == "function" and typeof(makefolder) == "function"
    and typeof(isfile) == "function"

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

function KeySystem.new(opts)
    opts = opts or {}
    local Lib = opts.Library
    local Theme = (Lib and Lib.Theme) or DefaultTheme
    local Fonts = (Lib and Lib.Fonts) or {
        Title = Enum.Font.GothamBold, Body = Enum.Font.GothamMedium, Bold = Enum.Font.GothamBold,
    }

    local cfg = {
        Title        = opts.Title or "Cookies Hub",
        Subtitle     = opts.Subtitle or "Key System",
        Logo         = opts.Logo == nil and DEFAULT_LOGO or opts.Logo,
        Description  = opts.Description or "Introduce tu key para desbloquear el hub.",
        KeyLink      = opts.KeyLink,
        DiscordLink  = opts.DiscordLink,
        DiscordCode  = opts.DiscordCode, -- opcional: solo el codigo del invite (para unirse directo si el executor lo permite)
        Keys         = opts.Keys,
        KeyUrl       = opts.KeyUrl,
        Validate     = opts.Validate,
        SaveKey      = opts.SaveKey ~= false,
        AutoVerify   = opts.AutoVerify ~= false,
        Folder       = opts.Folder or "CookiesHub",
        FileName     = opts.FileName or "key.txt",
        MaxAttempts  = opts.MaxAttempts or 5,
        Cooldown     = opts.Cooldown or 15,
        Blur         = opts.Blur ~= false,
        Note         = opts.Note or "Las keys son gratuitas. Completa los pasos del enlace y vuelve aqui.",
        DisplayOrder = opts.DisplayOrder or 100,
        OnSuccess    = opts.OnSuccess,
        OnClose      = opts.OnClose,
    }
    local keyPath = cfg.Folder .. "/" .. cfg.FileName

    local self = setmetatable({}, KeySystem)
    self.Done, self.Success, self.Key = false, false, nil
    self._event = Instance.new("BindableEvent")
    self._attempts = 0
    self._busy = false
    self._locked = false
    self._conns = {}

    ---------------------------------------------------------------- GUI
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
            blur = Instance.new("BlurEffect")
            blur.Name = "CookiesKeyBlur"
            blur.Size = 0
            blur.Parent = Lighting
            tween(blur, { Size = 10 }, 0.5)
        end)
    end

    local dim = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1, Active = true, Parent = gui,
    })
    tween(dim, { BackgroundTransparency = 0.5 }, 0.4)

    local CARD_W, CARD_H = 600, 330
    local PANEL_W = 190

    local root = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(CARD_W, CARD_H), BackgroundColor3 = Theme.Background,
        GroupTransparency = 1, Parent = gui,
    }, {
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
        create("UIStroke", { Color = Theme.Stroke, Thickness = 1, Transparency = 0.1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
    })
    local uiScale = create("UIScale", { Scale = 0.94, Parent = root })
    local baseScale = 1

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

    -- linea de acento superior (sutil)
    local topLine = create("Frame", {
        Size = UDim2.new(0, 0, 0, 2), Position = UDim2.fromOffset(24, 0),
        BackgroundColor3 = Theme.Accent, ZIndex = 5, Parent = root,
    }, { corner(1) })

    ---------------------------------------------------------------- Header
    local left = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -(PANEL_W + 12), 1, 0), Parent = root,
    })

    local dragBar = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 68), ZIndex = 2, Parent = left,
    })
    local hasLogo = cfg.Logo ~= nil and cfg.Logo ~= false and cfg.Logo ~= ""
    local logoImg
    if hasLogo then
        logoImg = create("ImageLabel", {
            Image = cfg.Logo, Position = UDim2.fromOffset(24, 20), Size = UDim2.fromOffset(38, 38),
            ScaleType = Enum.ScaleType.Fit, ZIndex = 3, Parent = left,
        })
    end
    local tx = hasLogo and 72 or 24
    label({
        Text = cfg.Title, Font = Fonts.Title, TextSize = 18, Position = UDim2.fromOffset(tx, 20),
        Size = UDim2.new(1, -(tx + 12), 0, 22), ZIndex = 3, Parent = left,
    })
    label({
        Text = cfg.Subtitle, TextSize = 11, TextColor3 = Theme.Dim, Position = UDim2.fromOffset(tx, 42),
        Size = UDim2.new(1, -(tx + 12), 0, 14), ZIndex = 3, Parent = left,
    })

    label({
        Text = cfg.Description, TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(24, 80), Size = UDim2.new(1, -48, 0, 30), Parent = left,
    })

    ---------------------------------------------------------------- Input
    label({
        Text = "KEY", Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.fromOffset(26, 120), Size = UDim2.fromOffset(60, 12), Parent = left,
    })
    local inputRow = create("Frame", {
        Position = UDim2.fromOffset(24, 137), Size = UDim2.new(1, -48, 0, 38),
        BackgroundColor3 = Theme.Input, Parent = left,
    }, { corner(8) })
    local inputStroke = stroke(Theme.Stroke, 1, 0.1)
    inputStroke.Parent = inputRow

    local canPaste = typeof(getclipboard) == "function" or typeof(fromclipboard) == "function"
    local keyBox = create("TextBox", {
        Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, canPaste and -86 or -28, 1, 0),
        BackgroundTransparency = 1, Font = Fonts.Body, TextSize = 13, TextColor3 = Theme.Text,
        PlaceholderText = "Introduce tu key", PlaceholderColor3 = Theme.Dim, Text = "",
        ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = inputRow,
    })
    local pasteBtn
    if canPaste then
        pasteBtn = create("TextButton", {
            Text = "Pegar", Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.Muted,
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -7, 0.5, 0),
            Size = UDim2.fromOffset(52, 24), BackgroundColor3 = Theme.Row, Parent = inputRow,
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

    ---------------------------------------------------------------- Verify
    local verifyBtn = create("TextButton", {
        Text = "", Position = UDim2.fromOffset(24, 185), Size = UDim2.new(1, -48, 0, 40),
        BackgroundColor3 = Theme.Accent, ClipsDescendants = true, Parent = left,
    }, { corner(8) })
    local verifyScale = create("UIScale", { Scale = 1, Parent = verifyBtn })
    local verifyLbl = label({
        Text = "Verificar", Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.OnAccent,
        TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = verifyBtn,
    })
    -- brillo que cruza el boton una sola vez al abrir
    local sheen = create("Frame", {
        Size = UDim2.new(0, 46, 2, 0), Position = UDim2.new(0, -60, -0.5, 0), Rotation = 18,
        BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.85, ZIndex = 3, Parent = verifyBtn,
    })

    ---------------------------------------------------------------- Options row
    local optRow = create("Frame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 235), Size = UDim2.new(1, -48, 0, 18),
        Parent = left,
    })
    local checkBtn = create("TextButton", {
        Text = "", BackgroundTransparency = 1, Size = UDim2.new(0, 130, 1, 0), Parent = optRow,
    })
    local box = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(15, 15), BackgroundColor3 = Theme.Input, Parent = checkBtn,
    }, { corner(4), stroke(Theme.Stroke, 1, 0.1) })
    local boxFill = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Accent, Parent = box,
    }, { corner(2) })
    label({
        Text = "Recordar key", TextSize = 11, TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(23, 0), Size = UDim2.new(1, -23, 1, 0), Parent = checkBtn,
    })
    local clearBtn = create("TextButton", {
        Text = "Borrar key guardada", Font = Fonts.Body, TextSize = 11, TextColor3 = Theme.Dim,
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
        local t = animate and 0.15 or 0
        tween(boxFill, { Size = remember and UDim2.fromOffset(9, 9) or UDim2.fromOffset(0, 0) }, t,
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end
    paintCheck(false)
    checkBtn.Activated:Connect(function()
        remember = not remember
        paintCheck(true)
    end)

    ---------------------------------------------------------------- Status
    local statusLbl = label({
        Text = "", TextSize = 11, TextColor3 = Theme.Muted, TextTransparency = 1,
        Position = UDim2.fromOffset(24, 264), Size = UDim2.new(1, -48, 0, 16), Parent = left,
    })
    label({
        Text = "v" .. KeySystem.Version, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.fromOffset(24, 300), Size = UDim2.fromOffset(120, 14), Parent = left,
    })
    local attemptsLbl = label({
        Text = "", TextSize = 10, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 300),
        Size = UDim2.fromOffset(160, 14), Parent = left,
    })

    local function setStatus(text, color)
        statusLbl.Text = text or ""
        statusLbl.TextColor3 = color or Theme.Muted
        if text and text ~= "" then
            statusLbl.Position = UDim2.fromOffset(24, 268)
            statusLbl.TextTransparency = 1
            tween(statusLbl, { TextTransparency = 0, Position = UDim2.fromOffset(24, 264) }, 0.2)
        else
            statusLbl.TextTransparency = 1
        end
    end
    local function updateAttempts()
        local left_ = math.max(cfg.MaxAttempts - self._attempts, 0)
        attemptsLbl.Text = self._attempts > 0 and (left_ .. " intentos restantes") or ""
    end

    ---------------------------------------------------------------- Right panel
    local panel = create("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 52),
        Size = UDim2.new(0, PANEL_W, 1, -64), BackgroundColor3 = Theme.Panel, Parent = root,
    }, { corner(10), stroke(Theme.Stroke, 1, 0.45) })

    label({
        Text = "¿Necesitas una key?", Font = Fonts.Bold, TextSize = 13,
        Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 18), Parent = panel,
    })
    label({
        Text = cfg.Note, TextSize = 11, TextColor3 = Theme.Muted, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, TextYAlignment = Enum.TextYAlignment.Top,
        Position = UDim2.fromOffset(16, 36), Size = UDim2.new(1, -32, 0, 56), Parent = panel,
    })

    local function sideButton(y, text, accent)
        local b = create("TextButton", {
            Text = "", Position = UDim2.fromOffset(12, y), Size = UDim2.new(1, -24, 0, 36),
            BackgroundColor3 = Theme.Row, Parent = panel,
        }, { corner(8), stroke(Theme.Stroke, 1, 0.5) })
        create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.fromOffset(3, 16), BackgroundColor3 = accent, Parent = b,
        }, { corner(2) })
        local l = label({
            Text = text, Font = Fonts.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1), Parent = b,
        })
        b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = Theme.RowHover }, 0.15) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = Theme.Row }, 0.15) end)
        local sc = create("UIScale", { Parent = b })
        b.MouseButton1Down:Connect(function() tween(sc, { Scale = 0.97 }, 0.08) end)
        b.MouseButton1Up:Connect(function() tween(sc, { Scale = 1 }, 0.15, Enum.EasingStyle.Back) end)
        return b, l
    end

    local getBtn, getLbl = sideButton(100, "Obtener key", Theme.Accent)
    local dcBtn, dcLbl = sideButton(142, "Unirse al Discord", rgb(88, 101, 242))
    if not cfg.KeyLink then getBtn.Visible = false end
    if not cfg.DiscordLink and not cfg.DiscordCode then dcBtn.Visible = false end

    create("Frame", {
        Position = UDim2.new(0, 16, 1, -44), Size = UDim2.new(1, -32, 0, 1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.55, Parent = panel,
    })
    label({
        Text = "@" .. LocalPlayer.Name, TextSize = 10, TextColor3 = Theme.Dim,
        Position = UDim2.new(0, 16, 1, -34), Size = UDim2.new(1, -32, 0, 24), Parent = panel,
    })

    local function flashLabel(lbl, text, original)
        lbl.Text = text
        task.delay(1.6, function()
            if lbl.Parent then lbl.Text = original end
        end)
    end

    getBtn.Activated:Connect(function()
        local ok = copy(cfg.KeyLink)
        flashLabel(getLbl, ok and "Link copiado" or "Sin portapapeles", "Obtener key")
        setStatus(ok and "Enlace copiado. Pegalo en tu navegador." or ("Abre este enlace: " .. cfg.KeyLink),
            ok and Theme.Muted or Theme.Warning)
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
        local copied = cfg.DiscordLink and copy(cfg.DiscordLink)
        flashLabel(dcLbl, (joined and "Abriendo Discord...") or (copied and "Invite copiado") or "Sin portapapeles",
            "Unirse al Discord")
        if not joined then
            setStatus(copied and "Invite copiado. Pegalo en Discord." or ("Invite: " .. tostring(cfg.DiscordLink)),
                Theme.Muted)
        end
    end)

    ---------------------------------------------------------------- Close + drag
    local closeBtn = create("TextButton", {
        Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Theme.Row, ZIndex = 6, Parent = root,
    }, { corner(6) })
    local xBars = {}
    for _, rot in ipairs({ 45, -45 }) do
        table.insert(xBars, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 2), Rotation = rot, BackgroundColor3 = Theme.Muted, ZIndex = 7,
            Parent = closeBtn,
        }, { corner(1) }))
    end
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = rgb(110, 40, 36) }, 0.15)
        for _, b in ipairs(xBars) do tween(b, { BackgroundColor3 = Theme.Text }, 0.15) end
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.Row }, 0.15)
        for _, b in ipairs(xBars) do tween(b, { BackgroundColor3 = Theme.Muted }, 0.15) end
    end)

    do
        local startInput, startPos
        dragger(dragBar, function(input)
            startInput, startPos = input.Position, root.Position
        end, function(i)
            local d = i.Position - startInput
            local vp = getViewport()
            local nx = math.clamp(startPos.X.Offset + d.X, -vp.X / 2 + 80, vp.X / 2 - 80)
            local ny = math.clamp(startPos.Y.Offset + d.Y, -vp.Y / 2 + 40, vp.Y / 2 - 40)
            root.Position = UDim2.new(startPos.X.Scale, nx, startPos.Y.Scale, ny)
        end)
    end

    ---------------------------------------------------------------- Logic
    local function cleanup()
        for _, c in ipairs(self._conns) do c:Disconnect() end
        self._conns = {}
        if blur then
            tween(blur, { Size = 0 }, 0.3)
            task.delay(0.35, function() if blur then blur:Destroy() end end)
        end
    end

    local function outro(after)
        tween(dim, { BackgroundTransparency = 1 }, 0.3)
        tween(root, { GroupTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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

    local function check(key)
        if cfg.Validate then
            local ok, a, b = pcall(cfg.Validate, key)
            if not ok then return false, "Error al validar la key" end
            if type(a) == "boolean" then return a, b end
            return false, nil
        end
        local list = cfg.Keys
        if cfg.KeyUrl then
            local ok, body = pcall(function() return game:HttpGet(cfg.KeyUrl) end)
            if not ok then return false, "No se pudo conectar con el servidor de keys" end
            list = {}
            for line in tostring(body):gmatch("[^\r\n]+") do
                local k = trim(line)
                if k ~= "" then table.insert(list, k) end
            end
        end
        if type(list) ~= "table" then return false, "Key system sin configurar" end
        return table.find(list, key) ~= nil
    end

    local function shake()
        self._errorShown = true
        tween(inputStroke, { Color = Theme.Error, Transparency = 0 }, 0.12)
        local base = inputRow.Position
        task.spawn(function()
            for _, dx in ipairs({ 6, -6, 4, -4, 2, 0 }) do
                local tw = tween(inputRow, { Position = UDim2.new(base.X.Scale, base.X.Offset + dx, base.Y.Scale, base.Y.Offset) }, 0.05,
                    Enum.EasingStyle.Quad)
                task.wait(0.05)
            end
            task.wait(0.9)
            self._errorShown = false
            if not keyBox:IsFocused() then tween(inputStroke, { Color = Theme.Stroke, Transparency = 0.1 }, 0.25) end
        end)
    end

    local loadingId = 0
    local function setLoading(on)
        self._busy = on
        loadingId += 1
        local id = loadingId
        if on then
            tween(verifyBtn, { BackgroundColor3 = Theme.AccentSoft }, 0.15)
            verifyLbl.TextColor3 = Theme.Accent
            task.spawn(function()
                local n = 0
                while self._busy and id == loadingId and verifyLbl.Parent do
                    verifyLbl.Text = "Verificando" .. string.rep(".", n % 4)
                    n += 1
                    task.wait(0.28)
                end
            end)
        else
            verifyLbl.Text = "Verificar"
            verifyLbl.TextColor3 = Theme.OnAccent
            tween(verifyBtn, { BackgroundColor3 = Theme.Accent }, 0.2)
        end
    end

    local function startCooldown()
        self._locked = true
        task.spawn(function()
            for s = cfg.Cooldown, 1, -1 do
                if self.Done or not gui.Parent then return end
                setStatus("Demasiados intentos. Espera " .. s .. "s", Theme.Warning)
                verifyLbl.Text = "Espera " .. s .. "s"
                task.wait(1)
            end
            self._locked = false
            self._attempts = 0
            updateAttempts()
            verifyLbl.Text = "Verificar"
            setStatus("Ya puedes intentarlo de nuevo", Theme.Muted)
        end)
    end

    local function submit(key, silent)
        if self._busy or self._locked or self.Done then return end
        key = trim(key)
        if key == "" then
            setStatus("Escribe tu key primero", Theme.Warning)
            shake()
            return
        end
        setLoading(true)
        setStatus(silent and "Comprobando key guardada..." or "Comprobando key...", Theme.Muted)
        task.spawn(function()
            local ok, msg = check(key)
            if self.Done or not gui.Parent then return end
            setLoading(false)
            if ok then
                self._busy = true -- bloquea mas clicks
                saveKey(key)
                verifyLbl.Text = "Key valida"
                verifyLbl.TextColor3 = Color3.new(1, 1, 1)
                tween(verifyBtn, { BackgroundColor3 = Theme.Success }, 0.2)
                tween(inputStroke, { Color = Theme.Success, Transparency = 0 }, 0.2)
                setStatus(msg or "Acceso concedido. Bienvenido!", Theme.Success)
                task.wait(0.9)
                outro(function()
                    finish(true, key)
                    if cfg.OnSuccess then task.spawn(cfg.OnSuccess, key) end
                end)
            else
                if silent then
                    clearSaved()
                    setStatus("La key guardada ya no es valida", Theme.Warning)
                    return
                end
                self._attempts += 1
                updateAttempts()
                shake()
                setStatus(msg or "Key incorrecta. Revisa e intenta de nuevo", Theme.Error)
                if self._attempts >= cfg.MaxAttempts then startCooldown() end
            end
        end)
    end
    self.Submit = function(_, k) submit(k or keyBox.Text) end

    -- eventos
    verifyBtn.MouseEnter:Connect(function()
        if not self._busy and not self._locked then tween(verifyBtn, { BackgroundColor3 = Theme.AccentHi }, 0.15) end
    end)
    verifyBtn.MouseLeave:Connect(function()
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
            if ok and text then keyBox.Text = trim(text) end
        end)
    end

    clearBtn.Activated:Connect(function()
        clearSaved()
        keyBox.Text = ""
        setStatus("Key guardada eliminada", Theme.Muted)
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
    function self:Destroy()
        if not self.Done then finish(false, nil) end
        cleanup()
        if gui then gui:Destroy() end
    end

    ---------------------------------------------------------------- Intro
    local saved = loadSaved()
    if saved then keyBox.Text = saved end
    updateAttempts()

    self._ready = true
    tween(root, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
    tween(uiScale, { Scale = baseScale }, 0.4, Enum.EasingStyle.Quart)
    tween(topLine, { Size = UDim2.new(0, 56, 0, 2) }, 0.7, Enum.EasingStyle.Quart)
    task.delay(0.5, function()
        if sheen.Parent then
            tween(sheen, { Position = UDim2.new(1, 20, -0.5, 0) }, 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        end
    end)

    if saved and cfg.AutoVerify then
        task.delay(0.6, function()
            if gui.Parent then submit(saved, true) end
        end)
    end

    return self
end

return KeySystem
