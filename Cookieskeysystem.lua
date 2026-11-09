local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

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
    -- estilo "galleta glaseada" (igual que CookiesLib): base dorada, contorno chocolate y sombra calida
    AccentDeep = rgb(214, 150, 4),
    Chocolate  = rgb(92, 46, 16),
    Shadow     = rgb(14, 6, 2),
}

local DEFAULT_LOGO = "rbxassetid://76143769732706"
local SHADOW = "rbxassetid://6014261993"
local DEFAULT_SDK = "https://www.keyforge.win/sdk/client.lua"

local KeySystem = {}
KeySystem.__index = KeySystem
KeySystem.Version = "2.2.0"

local GuiService = game:GetService("GuiService")
local BLACK, WHITE = rgb(0, 0, 0), rgb(255, 255, 255)
local TAU = math.pi * 2

local function tryFont(name)
    local ok, f = pcall(function() return Enum.Font[name] end)
    return ok and f or nil
end

local function nseq(points)
    local kps = {}
    for i, p in ipairs(points) do kps[i] = NumberSequenceKeypoint.new(p[1], p[2]) end
    return NumberSequence.new(kps)
end

-- Textura de resplandor radial: UNA sola imagen (circulo suave) tenida con ImageColor3, sin capas
-- apiladas ni escalones. 1) asset propio (opts.GlowAsset o Library.Config.Assets.Glow);
-- 2) si no, se genera una vez con EditableImage; 3) si el juego no lo permite, el glow no aparece.
local GLOW_TEX
local function glowTexture(asset)
    if type(asset) == "string" and asset ~= "" then return asset end
    if GLOW_TEX ~= nil then return GLOW_TEX end
    GLOW_TEX = false
    pcall(function()
        local N = 128
        local img = game:GetService("AssetService"):CreateEditableImage({ Size = Vector2.new(N, N) })
        local buf = buffer.create(N * N * 4)
        for y = 0, N - 1 do
            for x = 0, N - 1 do
                local dx, dy = (x + 0.5) / N * 2 - 1, (y + 0.5) / N * 2 - 1
                local t = math.clamp(1 - math.sqrt(dx * dx + dy * dy), 0, 1)
                local a = (t * t * (3 - 2 * t)) ^ 1.5
                local i = (y * N + x) * 4
                buffer.writeu8(buf, i, 255)
                buffer.writeu8(buf, i + 1, 255)
                buffer.writeu8(buf, i + 2, 255)
                buffer.writeu8(buf, i + 3, math.floor(a * 255 + 0.5))
            end
        end
        img:WritePixelsBuffer(Vector2.zero, Vector2.new(N, N), buf)
        GLOW_TEX = Content.fromObject(img)
    end)
    return GLOW_TEX
end

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

-- hash corto y estable (djb2) para derivar un id a partir de una URL o una lista de keys
local function shortHash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + string.byte(s, i)) % 4294967296 end
    return string.format("%08x", h)
end

-- Id de cada key system: separa la key guardada y el bloqueo por intentos de cada script,
-- para que varios scripts con key system no se pisen entre si
local function scriptId(opts)
    local id = opts.Id
    if id == nil and type(opts.KeyForge) == "table" and opts.KeyForge.scriptId then id = "kf_" .. tostring(opts.KeyForge.scriptId) end
    if id == nil and type(opts.KeyUrl) == "string" then id = "url_" .. shortHash(opts.KeyUrl) end
    if id == nil and type(opts.Keys) == "table" then
        local list = {}
        for _, k in ipairs(opts.Keys) do table.insert(list, tostring(k)) end
        table.sort(list)
        id = "keys_" .. shortHash(table.concat(list, "\n"))
    end
    if id == nil then id = tostring(opts.Title or "default") end
    id = tostring(id):gsub("[^%w%-_]", "_"):sub(1, 48)
    return id
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
    -- tokens de galleta: si el tema no los trae (o se cambio el acento) se derivan del acento
    local changed = typeof(accent) == "Color3"
    local function given(k) return type(custom) == "table" and custom[k] ~= nil end
    if not theme.AccentDeep or (changed and not given("AccentDeep")) then
        theme.AccentDeep = theme.Accent:Lerp(BLACK, 0.22)
    end
    if not theme.Chocolate or (changed and not given("Chocolate")) then
        theme.Chocolate = rgb(64, 30, 10):Lerp(theme.Accent, 0.15)
    end
    if not theme.Shadow or (type(custom) == "table" and custom.Background and not given("Shadow")) then
        theme.Shadow = theme.Background:Lerp(BLACK, 0.6)
    end
    theme.AccentHi = theme.AccentHi or theme.Accent:Lerp(WHITE, 0.25)
    theme.AccentSoft = theme.AccentSoft or theme.Panel:Lerp(theme.Accent, 0.14)
    theme.OnAccent = theme.OnAccent or rgb(40, 20, 8)
    return theme
end

function KeySystem.new(opts)
    opts = opts or {}
    local Lib = opts.Library
    local Theme = buildTheme(opts)
    local Fonts = table.clone((Lib and Lib.Fonts) or {
        Title = tryFont("BuilderSansBold") or Enum.Font.GothamBold,
        Body = tryFont("BuilderSans") or Enum.Font.GothamMedium,
        Bold = tryFont("BuilderSansBold") or Enum.Font.GothamBold,
    })
    -- letras redondas del wordmark de Cookies (igual que el titulo de la libreria)
    Fonts.Brand = Fonts.Brand or tryFont("FredokaOne") or Fonts.Title

    -- Juice: "Full" (todo), "Subtle" (sin particulas) u "Off" (sin animaciones decorativas).
    -- Si no se pasa, se usa el de la libreria (si viene en opts.Library) o "Full".
    local juiceName = opts.Juice
    if juiceName == nil and Lib then
        pcall(function()
            local c = Lib.Config
            if c and c.Animations == false then juiceName = "Off" else juiceName = c and c.Juice end
        end)
    end
    juiceName = tostring(juiceName or "Full"):lower()
    local J = (juiceName == "off" and 0) or (juiceName == "subtle" and 1) or 2
    local glowAsset = opts.GlowAsset
    if glowAsset == nil and Lib then
        pcall(function() glowAsset = Lib.Config.Assets.Glow end)
    end

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
        Id            = scriptId(opts),
        FileName      = opts.FileName,
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
    -- Style = "Glass": tarjeta translucida con tinte, reflejo y borde de luz que sigue al mouse
    local glass = tostring(opts.Style or ""):lower() == "glass"
    -- si no hay Note ni Steps, se muestra la guia de 3 pasos
    if cfg.Steps == nil and cfg.Note == nil then
        cfg.Steps = {
            "Press Get key to copy the link",
            "Complete the steps in your browser",
            "Paste your key and press Verify",
        }
    end

    local getClient
    -- cada script tiene su archivo (keys/<Id>.txt). Si FileName se da a mano, se respeta.
    local keyPath = opts.FileName and (cfg.Folder .. "/" .. opts.FileName)
        or (cfg.Folder .. "/keys/" .. cfg.Id .. ".txt")
    -- archivo comun de la version 2.0 (lo compartian todos los scripts): solo se lee para migrar
    local legacyPath = (not opts.FileName) and (cfg.Folder .. "/key.txt") or nil
    local savedFromLegacy = false

    local self = setmetatable({}, KeySystem)
    self.Done, self.Success, self.Key = false, false, nil
    self.Theme = Theme
    self.Id = cfg.Id -- separa key guardada y bloqueo de cada script
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

    -- sin desenfoque: solo se oscurece el juego detras de la tarjeta (se borra el blur de versiones viejas)
    local blur
    pcall(function()
        local prev = Lighting:FindFirstChild("CookiesKeyBlur")
        if prev then prev:Destroy() end
    end)

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
        create("UICorner", { CornerRadius = UDim.new(0, 12) }),
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

    -- lo decorativo nunca recibe clicks ni tapa controles
    local function noInput(inst)
        pcall(function() inst.Interactable = false end)
        pcall(function() inst.Active = false end)
        return inst
    end
    -- franja de luz (gloss) en la mitad de arriba, como el brillo del logo
    local function gloss(parent, radius, strength, z)
        local s = strength or 0.25
        return noInput(create("Frame", {
            Size = UDim2.new(1, 0, 0.55, 0), BackgroundColor3 = WHITE, ZIndex = z or 1, Parent = parent,
        }, {
            corner(radius or 8),
            create("UIGradient", { Rotation = 90, Transparency = nseq({ { 0, 1 - s }, { 0.55, 1 - s * 0.3 }, { 1, 1 } }) }),
        }))
    end
    -- contorno chocolate estilo sticker (el borde grueso del logo)
    local function sticker(parent, thickness, transparency)
        local s = stroke(Theme.Chocolate, thickness or 1.5, transparency or 0)
        s.Parent = parent
        return s
    end
    -- brillo que cruza la superficie. Devuelve la funcion que lo dispara (no se encima consigo mismo).
    local function shine(host, radius, strength, z)
        local s = strength or 0.28
        local f = noInput(create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, ZIndex = z or 1, Parent = host,
        }, { corner(radius or 8) }))
        local g = create("UIGradient", {
            Rotation = 18, Offset = Vector2.new(-1, 0),
            Transparency = nseq({ { 0, 1 }, { 0.38, 1 }, { 0.5, 1 - s }, { 0.62, 1 }, { 1, 1 } }), Parent = f,
        })
        local busy = false
        return function()
            if busy or J == 0 or not f.Parent then return end
            busy = true
            g.Offset = Vector2.new(-1, 0)
            local tw = tween(g, { Offset = Vector2.new(1, 0) }, 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
            tw.Completed:Once(function() busy = false end)
        end
    end
    -- onda desde el punto del click (host con ClipsDescendants; queda debajo del texto)
    local function ripple(host, input, color, z)
        if J == 0 or not host.Parent then return end
        local a, s = host.AbsolutePosition, host.AbsoluteSize
        local rx, ry = 0.5, 0.5
        if input and input.Position then
            local inset = Vector2.zero
            pcall(function() inset = GuiService:GetGuiInset() end)
            local p = Vector2.new(input.Position.X, input.Position.Y) + inset
            rx = math.clamp((p.X - a.X) / math.max(s.X, 1), 0, 1)
            ry = math.clamp((p.Y - a.Y) / math.max(s.Y, 1), 0, 1)
        end
        local dot = noInput(create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(rx, ry), Size = UDim2.fromScale(0, 0),
            SizeConstraint = Enum.SizeConstraint.RelativeXX, BackgroundColor3 = color or WHITE,
            BackgroundTransparency = 0.6, ZIndex = z or 1, Parent = host,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) }))
        tween(dot, { Size = UDim2.fromScale(2.4, 2.4), BackgroundTransparency = 1 }, 0.55, Enum.EasingStyle.Quad)
        task.delay(0.6, function() dot:Destroy() end)
    end
    -- glow radial suave: un solo ImageLabel (si no hay textura posible, queda oculto)
    local function glowBlob(parent, pos, size, color, strength, z)
        local img = noInput(create("ImageLabel", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, ImageColor3 = color,
            ImageTransparency = 1 - strength, ZIndex = z or 1, Parent = parent,
        }))
        local tex = glowTexture(glowAsset)
        if type(tex) == "string" then
            img.Image = tex
        elseif tex then
            if not pcall(function() img.ImageContent = tex end) then img.Visible = false end
        else
            img.Visible = false
        end
        return img
    end

    -- Particulas (chispas, migajas y sprinkles): pool de 24 que se reutilizan, nada se crea por frame.
    -- Solo con Juice "Full". Van en una capa encima de la tarjeta para poder salirse de ella.
    local fxLayer, fxFree, fxCount = nil, {}, 0
    local function particle()
        local p = table.remove(fxFree)
        if p then return p end
        if fxCount >= 24 then return nil end
        if not fxLayer then
            fxLayer = noInput(create("Frame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 20, Parent = gui,
            }))
        end
        fxCount = fxCount + 1
        return noInput(create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 21, Visible = false, Parent = fxLayer,
        }, { corner(2) }))
    end
    local SPRINKLE_KEYS = { "Text", "Error", "Success", "Chocolate" }
    local function burst(inst, n, kind)
        if J < 2 or not inst or not inst.Parent or not gui.Parent then return end
        local c = inst.AbsolutePosition + inst.AbsoluteSize / 2 - gui.AbsolutePosition
        local crumb, spr = kind == "crumb", kind == "sprinkle"
        local t = crumb and 0.62 or (spr and 0.6 or 0.45)
        for i = 1, n do
            local p = particle()
            if not p then break end
            local ang = (i / n) * TAU + math.random() * 0.9
            local dist = (crumb and 30 or (spr and 34 or 20)) + math.random() * 14
            local col
            if crumb then
                col = (i % 2 == 0) and Theme.Chocolate or Theme.AccentDeep
            elseif spr then
                col = Theme[SPRINKLE_KEYS[(i - 1) % #SPRINKLE_KEYS + 1]]
            else
                col = (i % 3 == 0) and Theme.AccentDeep or ((i % 2 == 0) and Theme.AccentHi or Theme.Accent)
            end
            local sz = crumb and math.random(4, 7) or math.random(3, 5)
            p.BackgroundColor3, p.BackgroundTransparency = col, 0
            p.Size = spr and UDim2.fromOffset(8, 3) or UDim2.fromOffset(sz, sz)
            p.Rotation = math.random(0, 180)
            p.Position = UDim2.fromOffset(c.X, c.Y)
            p.Visible = true
            -- migajas y sprinkles caen un poco (gravedad); las chispas salen casi rectas
            local gx = math.cos(ang) * dist
            local gy = math.sin(ang) * dist + (crumb and 18 or (spr and 12 or 3))
            tween(p, {
                Position = UDim2.fromOffset(c.X + gx, c.Y + gy), Rotation = p.Rotation + math.random(-160, 160),
                Size = UDim2.fromOffset(1, 1), BackgroundTransparency = 1,
            }, t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            task.delay(t + 0.03, function()
                p.Visible = false
                table.insert(fxFree, p)
            end)
        end
    end
    -- presion elastica: encoge al bajar y vuelve con rebote suave al soltar
    -- target: lo que se encoge (por defecto el mismo boton)
    local function pressScale(btn, down, target)
        local sc = create("UIScale", { Parent = target or btn })
        btn.MouseButton1Down:Connect(function()
            tween(sc, { Scale = down or 0.96 }, 0.08, Enum.EasingStyle.Quad)
        end)
        local function up() tween(sc, { Scale = 1 }, J > 0 and 0.32 or 0.12, Enum.EasingStyle.Back) end
        btn.MouseButton1Up:Connect(up)
        btn.MouseLeave:Connect(up)
        return sc
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
    -- luz interna de 1 px arriba de la tarjeta (borde biselado)
    noInput(create("Frame", {
        Position = UDim2.fromOffset(14, 1), Size = UDim2.new(1, -28, 0, 1), BackgroundColor3 = WHITE,
        BackgroundTransparency = 0.88, ZIndex = 4, Parent = root,
    }, { create("UIGradient", { Transparency = nseq({ { 0, 1 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 1 } }) }) }))

    local hasLogo = cfg.Logo ~= nil and cfg.Logo ~= false and cfg.Logo ~= ""
    local logoImg, logoScale, logoGlow
    local GLOW_REST, GLOW_SIZE = 0.68, 84
    if hasLogo then
        -- resplandor dorado suave detras de la galleta (una sola imagen, sin anillos)
        logoGlow = glowBlob(left, UDim2.fromOffset(43, 41), UDim2.fromOffset(GLOW_SIZE, GLOW_SIZE),
            Theme.Accent, 0, 2)
        logoImg = create("ImageButton", {
            Image = cfg.Logo, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(43, 41),
            Size = UDim2.fromOffset(40, 40), ScaleType = Enum.ScaleType.Fit, BackgroundTransparency = 1,
            ZIndex = 3, Parent = left,
        })
        logoScale = create("UIScale", { Scale = 1, Parent = logoImg })
        logoImg.MouseEnter:Connect(function()
            if J == 0 then return end
            tween(logoScale, { Scale = 1.07 }, 0.25, Enum.EasingStyle.Back)
            tween(logoGlow, { ImageTransparency = GLOW_REST - 0.12 }, 0.25)
        end)
        logoImg.MouseLeave:Connect(function()
            tween(logoScale, { Scale = 1 }, 0.25, Enum.EasingStyle.Quad)
            tween(logoGlow, { ImageTransparency = GLOW_REST }, 0.3)
        end)
        -- easter egg: 5 clicks rapidos en la galleta y da una vuelta soltando migajas
        local clicks, lastClick, spinning = 0, 0, false
        logoImg.Activated:Connect(function()
            local now = os.clock()
            clicks = (now - lastClick < 0.6) and clicks + 1 or 1
            lastClick = now
            if J == 0 then return end
            logoScale.Scale = 0.9
            tween(logoScale, { Scale = 1.07 }, 0.3, Enum.EasingStyle.Back)
            if clicks >= 5 and not spinning then
                clicks, spinning = 0, true
                logoImg.Rotation = 0
                local tw = tween(logoImg, { Rotation = 360 }, 0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                tw.Completed:Once(function() logoImg.Rotation = 0 spinning = false end)
                burst(logoImg, 10, "crumb")
                task.delay(0.12, function() burst(logoImg, 8, "sprinkle") end)
            end
        end)
    end
    local tx = hasLogo and 74 or 24
    label({
        Text = cfg.Title, Font = Fonts.Brand, TextSize = 20, Position = UDim2.fromOffset(tx, 21),
        Size = UDim2.new(1, -(tx + 12), 0, 24), ZIndex = 3, Parent = left,
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
    }, { corner(8) })
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
        pressScale(pasteBtn, 0.92)
    end
    -- foco: el borde se pone dorado y un poco mas grueso
    keyBox.Focused:Connect(function()
        tween(inputStroke, { Color = Theme.Accent, Transparency = 0, Thickness = 1.6 }, 0.18)
    end)
    keyBox.FocusLost:Connect(function()
        tween(inputStroke, { Thickness = 1 }, 0.2)
        if not self._errorShown then tween(inputStroke, { Color = Theme.Stroke, Transparency = 0.1 }, 0.18) end
    end)

    -- Boton Verify estilo "galleta gruesa": la base oscura se ve debajo de la cara glaseada.
    -- Al presionar, la cara baja y tapa la base (como una galleta que se hunde).
    local DEPTH = 3
    local verifyBtn = create("TextButton", {
        Text = "", Position = UDim2.fromOffset(24, INPUT_Y + 50), Size = UDim2.new(1, -48, 0, 42),
        BackgroundColor3 = Theme.AccentDeep, Parent = left,
    }, { corner(8) })
    sticker(verifyBtn, 1.5, 0.2)
    local face = create("Frame", {
        Size = UDim2.new(1, 0, 1, -DEPTH), BackgroundColor3 = Theme.Accent, ClipsDescendants = true, Parent = verifyBtn,
    }, { corner(8), create("UIGradient", {
        Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(222, 222, 222)),
    }) })
    noInput(face)
    gloss(face, 8, 0.22, 1)
    local playShine = shine(face, 8, 0.32, 3)
    local verifyScale = create("UIScale", { Scale = 1, Parent = verifyBtn })
    local verifyLbl = label({
        Text = "Verify", Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.OnAccent,
        TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = face,
    })
    -- color de la cara y de su base (la base siempre un tono mas oscuro)
    local faceColor = Theme.Accent
    local function setFace(color, t)
        faceColor = color
        local deep = (color == Theme.Accent or color == Theme.AccentHi) and Theme.AccentDeep or color:Lerp(BLACK, 0.3)
        tween(face, { BackgroundColor3 = color }, t or 0.15)
        tween(verifyBtn, { BackgroundColor3 = deep }, t or 0.15)
    end
    -- cara hundida (mientras carga) o arriba
    local function setSunk(on)
        tween(face, { Position = UDim2.fromOffset(0, on and DEPTH - 1 or 0) }, on and 0.08 or 0.3,
            on and Enum.EasingStyle.Quad or Enum.EasingStyle.Back)
    end

    -- spinner: aro con degradado en el borde que gira mientras se verifica
    local spinner = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -58, 0.5, 0),
        Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = face,
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
        Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, Visible = false, ZIndex = 2, Parent = face,
    })
    local okScale = create("UIScale", { Scale = 0, Parent = okMark })
    checkMark(okMark, rgb(255, 255, 255), 3)

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
        -- marcado: contorno chocolate de sticker, como el logo
        tween(boxStroke, { Color = remember and Theme.Chocolate or Theme.Stroke }, t)
        if animate and remember and J > 0 then
            boxCheckScale.Scale = 0.3
            tween(boxCheckScale, { Scale = 1 }, 0.34, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            tween(boxCheckScale, { Scale = remember and 1 or 0 }, t, Enum.EasingStyle.Quad)
        end
    end
    paintCheck(false)
    pressScale(checkBtn, 0.85, box)
    checkBtn.Activated:Connect(function()
        remember = not remember
        paintCheck(true)
        if remember then burst(box, 6, "sprinkle") end
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
    local dotScale = create("UIScale", { Scale = 1, Parent = statusDot })
    local dotTween
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
    }, { corner(10), stroke(Theme.Stroke, 1, 0.45) })
    noInput(create("Frame", {
        Position = UDim2.fromOffset(10, 1), Size = UDim2.new(1, -20, 0, 1), BackgroundColor3 = WHITE,
        BackgroundTransparency = 0.92, Parent = panel,
    }, { create("UIGradient", { Transparency = nseq({ { 0, 1 }, { 0.25, 0 }, { 0.75, 0 }, { 1, 1 } }) }) }))

    label({
        Text = "Need a key?", Font = Fonts.Bold, TextSize = 13,
        Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 18), Parent = panel,
    })
    local btnY = 100
    if type(cfg.Steps) == "table" and #cfg.Steps > 0 then
        local y = 40
        for i, step in ipairs(cfg.Steps) do
            if i > 3 then break end
            -- numero en "chispa de chocolate": dorado con contorno chocolate, como el logo
            create("TextLabel", {
                Text = tostring(i), Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.OnAccent,
                BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent,
                Position = UDim2.fromOffset(16, y + 2), Size = UDim2.fromOffset(18, 18), Parent = panel,
            }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }),
                stroke(Theme.Chocolate, 1.2, 0.1) })
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
            BackgroundColor3 = normal, ClipsDescendants = true, Parent = panel,
        }, { corner(8), stroke(primary and Theme.Accent or Theme.Stroke, 1, primary and 0.55 or 0.5) })
        gloss(b, 8, primary and 0.1 or 0.06, 1)
        local playB = shine(b, 8, primary and 0.18 or 0.1, 1)
        local l = label({
            Text = text, Font = Fonts.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
            TextColor3 = primary and Theme.Accent or Theme.Text, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = b,
        })
        b.MouseEnter:Connect(function()
            tween(b, { BackgroundColor3 = over }, 0.15)
            playB()
        end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = normal }, 0.15) end)
        b.InputBegan:Connect(function(input)
            if isPress(input) then ripple(b, input, primary and Theme.Accent or WHITE, 1) end
        end)
        pressScale(b, 0.96)
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
            local link, why
            local client, err = getClient()
            if client then
                -- KeyForge: getKeyUrl() -> url, response (response.message explica por que no hay link)
                local okK, url, response = pcall(function() return client:getKeyUrl() end)
                if okK and type(url) == "string" and url ~= "" then
                    link = url
                elseif okK and type(response) == "table" and response.message then
                    why = tostring(response.message)
                end
            else
                why = err
            end
            gettingLink = false
            if not gui.Parent then return end
            if not link then
                getLbl.Text = "Get key"
                setStatus(why or "Could not get the key link", Theme.Error)
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
    }, { corner(6) })
    local xBars = {}
    for _, rot in ipairs({ 45, -45 }) do
        table.insert(xBars, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(10, 2), Rotation = rot, BackgroundColor3 = Theme.Muted, ZIndex = 7,
            Parent = closeBtn,
        }, { corner(1) }))
    end
    -- hover: fondo rojo del tema y la X da un cuarto de vuelta
    closeBtn.MouseEnter:Connect(function()
        tween(closeBtn, { BackgroundColor3 = Theme.Error:Lerp(Theme.Background, 0.45), BackgroundTransparency = 0 }, 0.15)
        for i, b in ipairs(xBars) do
            tween(b, { BackgroundColor3 = Theme.Text, Rotation = (i == 1 and 45 or -45) + (J > 0 and 90 or 0) }, 0.3,
                Enum.EasingStyle.Back)
        end
    end)
    closeBtn.MouseLeave:Connect(function()
        tween(closeBtn, { BackgroundTransparency = 1 }, 0.15)
        for i, b in ipairs(xBars) do
            tween(b, { BackgroundColor3 = Theme.Muted, Rotation = i == 1 and 45 or -45 }, 0.25, Enum.EasingStyle.Quad)
        end
    end)
    pressScale(closeBtn, 0.88)

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
            local dir = keyPath:match("^(.*)/[^/]+$")
            if dir and not isfolder(dir) then makefolder(dir) end
            writefile(keyPath, key)
        end)
        savedFromLegacy = false
    end
    local function readKey(path)
        local ok, data = pcall(function()
            if isfile(path) then return readfile(path) end
        end)
        if ok and data and trim(data) ~= "" then return trim(data) end
        return nil
    end
    local function loadSaved()
        if not hasFS then return nil end
        local key = readKey(keyPath)
        if key then return key end
        -- migracion: la key del archivo comun antiguo se prueba, pero no se borra si no sirve
        -- (puede ser de otro script); si es valida se copia al archivo propio de este script
        if legacyPath then
            key = readKey(legacyPath)
            if key then savedFromLegacy = true end
        end
        return key
    end
    -- solo borra el archivo de ESTE script; nunca toca la key de otro
    local function clearSaved()
        if not hasFS or savedFromLegacy then savedFromLegacy = false return end
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

    -- codigos de KeyForge que no son culpa del jugador: no gastan intentos ni borran la key guardada
    local KF_TRANSIENT = {
        NETWORK_ERROR = true, RATE_LIMITED = true, SESSION_EXPIRED = true, PROJECT_DISABLED = true,
    }

    local function check(key)
        if cfg.KeyForge then
            local client, err = getClient()
            if not client then return false, err, true end
            local okV, res = pcall(function() return client:verify(key) end)
            if not okV then return false, "Error contacting KeyForge", true end
            if type(res) ~= "table" then return false, "Unexpected KeyForge response", true end
            if res.ok then return true end
            return false, res.message or "Incorrect key", KF_TRANSIENT[res.code] == true
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
        -- la galleta se desmorona un poco: migajas desde el input
        burst(inputRow, 6, "crumb")
        -- la cara del boton parpadea en rojo y vuelve sola
        if not self._locked then
            setFace(Theme.Error, 0.1)
            task.delay(0.4, function()
                if not self._busy and not self._locked and not self.Done and faceColor == Theme.Error then
                    setFace(Theme.Accent, 0.35)
                end
            end)
        end
        task.spawn(function()
            -- sacudida amortiguada continua (seno que se apaga): suave, sin saltos entre pasos
            if J > 0 then
                local t0, DUR = os.clock(), 0.42
                while true do
                    local t = os.clock() - t0
                    if t >= DUR or not inputRow.Parent then break end
                    local dx = math.sin(t * 46) * 8 * math.exp(-t * 7.5)
                    inputRow.Position = UDim2.fromOffset(24 + dx, INPUT_Y)
                    RunService.Heartbeat:Wait()
                end
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
        if dotTween then dotTween:Cancel() dotTween = nil end
        dotScale.Scale = 1
        if on then
            setFace(Theme.AccentSoft, 0.15)
            setSunk(true)
            verifyLbl.TextColor3 = Theme.Accent
            verifyLbl.Text = text or "Verifying..."
            spinner.Visible = true
            spinStroke.Color = Theme.Accent
            spinner.Rotation = 0
            if spinTween then spinTween:Cancel() end
            spinTween = TweenService:Create(spinner, TweenInfo.new(0.75, Enum.EasingStyle.Linear,
                Enum.EasingDirection.In, -1), { Rotation = 360 })
            spinTween:Play()
            -- el punto de estado "respira" mientras se espera
            if J > 0 then
                dotTween = TweenService:Create(dotScale, TweenInfo.new(0.5, Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut, -1, true), { Scale = 1.6 })
                dotTween:Play()
            end
        else
            if spinTween then spinTween:Cancel() spinTween = nil end
            spinner.Visible = false
            verifyLbl.Text = "Verify"
            verifyLbl.TextColor3 = Theme.OnAccent
            setFace(Theme.Accent, 0.2)
            setSunk(false)
        end
    end

    -- el cooldown sobrevive a re-ejecutar el script en la misma partida
    local G = genv()
    G.__CookiesKeyLocks = type(G.__CookiesKeyLocks) == "table" and G.__CookiesKeyLocks or {}
    local locks = G.__CookiesKeyLocks
    local function startCooldown(seconds)
        self._locked = true
        locks[cfg.Id] = os.clock() + seconds
        task.spawn(function()
            local endAt = os.clock() + seconds
            while os.clock() < endAt do
                if self.Done or not gui.Parent then return end
                local s = math.ceil(endAt - os.clock())
                setStatus("Too many attempts. Wait " .. s .. "s", Theme.Warning)
                verifyLbl.Text = "Wait " .. s .. "s"
                if faceColor ~= Theme.Row then setFace(Theme.Row, 0.25) end
                verifyLbl.TextColor3 = Theme.Muted
                task.wait(math.min(1, math.max(endAt - os.clock(), 0.05)))
            end
            self._locked = false
            self._attempts = 0
            locks[cfg.Id] = nil
            updateAttempts()
            verifyLbl.Text = "Verify"
            verifyLbl.TextColor3 = Theme.OnAccent
            setFace(Theme.Accent, 0.25)
            playShine()
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
            if ok and cfg.LoadScript and self.Client then
                setLoading(true, "Loading...")
                setStatus("Loading securely...", Theme.Muted)
                local result, finished = nil, false
                task.spawn(function()
                    local okL, loaded = pcall(function() return self.Client:loadScript() end)
                    if not okL then loaded = { ok = false, message = tostring(loaded) } end
                    result, finished = loaded, true
                    if self.Done and type(loaded) == "table" and loaded.ok == false then
                        warn("[CookiesKey]", loaded.code, loaded.message)
                    end
                end)
                -- si el script entregado sigue corriendo tras unos segundos, se da por cargado
                local t0 = os.clock()
                while not finished and os.clock() - t0 < 4 do task.wait() end
                if self.Done or not gui.Parent then return end
                setLoading(false)
                if finished and type(result) == "table" and result.ok == false then
                    -- el token ya se gasto: el jugador puede pulsar Verify de nuevo
                    setStatus(result.message or "Could not load the script", Theme.Error)
                    return
                end
            end
            if ok then
                self._busy = true
                saveKey(key)
                verifyLbl.Text = "Access granted"
                verifyLbl.TextColor3 = rgb(255, 255, 255)
                verifyLbl.Position = UDim2.fromOffset(10, 0)
                okMark.Visible = true
                tween(okScale, { Scale = 1 }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                setFace(Theme.Success, 0.2)
                tween(inputStroke, { Color = Theme.Success, Transparency = 0 }, 0.2)
                setStatus(msg or "Access granted. Welcome!", Theme.Success)
                -- celebracion: sprinkles desde el boton, la galleta salta y su glow se pone verde
                playShine()
                burst(face, 14, "sprinkle")
                task.delay(0.08, function() burst(face, 8, "spark") end)
                if logoImg and J > 0 then
                    logoScale.Scale = 1.18
                    tween(logoScale, { Scale = 1 }, 0.5, Enum.EasingStyle.Back)
                    tween(logoGlow, { ImageColor3 = Theme.Success, ImageTransparency = GLOW_REST - 0.18 }, 0.3)
                end
                task.wait(0.9)
                outro(function()
                    finish(true, key)
                    if cfg.OnSuccess then task.spawn(cfg.OnSuccess, key) end
                end)
            else
                if cfg.OnFail then task.spawn(cfg.OnFail, key, msg) end
                if silent then
                    if transient then
                        setStatus(msg or "Could not check the saved key", Theme.Warning)
                    else
                        local legacy = savedFromLegacy
                        clearSaved()
                        keyBox.Text = ""
                        setStatus(legacy and "Enter your key for this script" or "The saved key is no longer valid", Theme.Warning)
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

    local function idleFace() return not self._busy and not self._locked and not self.Done end
    verifyBtn.MouseEnter:Connect(function()
        if idleFace() and faceColor == Theme.Accent then
            setFace(Theme.AccentHi, 0.15)
            playShine()
        end
    end)
    verifyBtn.MouseLeave:Connect(function()
        tween(verifyScale, { Scale = 1 }, 0.2, Enum.EasingStyle.Quad)
        if idleFace() then
            setSunk(false)
            if faceColor == Theme.AccentHi then setFace(Theme.Accent, 0.15) end
        end
    end)
    verifyBtn.InputBegan:Connect(function(input)
        if not isPress(input) or not idleFace() then return end
        setSunk(true)
        tween(verifyScale, { Scale = 0.99 }, 0.08)
        ripple(face, input, WHITE, 1)
    end)
    verifyBtn.MouseButton1Up:Connect(function()
        tween(verifyScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
        if idleFace() then setSunk(false) end
    end)
    verifyBtn.Activated:Connect(function()
        if idleFace() then burst(verifyBtn, 7, "crumb") end
        submit(keyBox.Text)
    end)
    -- cada tanto un brillo cruza el boton (solo en reposo; con Juice Off no corre)
    if J > 0 then
        task.spawn(function()
            while face.Parent and not self.Done do
                task.wait(5)
                if face.Parent and idleFace() and faceColor == Theme.Accent then playShine() end
            end
        end)
    end
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

    if glass then
        -- el fondo es vidrio oscuro y todo lo de encima son velos blancos muy tenues (o pozos
        -- oscuros para el input): capas neutras que no se ensucian con los colores del juego
        local surf = {
            { Theme.Panel, WHITE, 0.965 }, { Theme.Element, WHITE, 0.955 }, { Theme.Row, WHITE, 0.94 },
            { Theme.RowHover, WHITE, 0.89 }, { Theme.Input, BLACK, 0.72 }, { Theme.Stroke, WHITE, 0.9 },
        }
        local function find(c)
            for _, p in ipairs(surf) do
                if c == p[1] then return p end
            end
        end
        root.BackgroundTransparency = 0.14
        -- bordes de luz: un gradiente que gira hacia el mouse (brillo de un lado, rebote enfrente)
        local lights = {}
        local function light(stroke, strength, host)
            local s = strength
            local g = create("UIGradient", {
                Rotation = 225, Parent = stroke,
                Transparency = nseq({ { 0, 1 - 0.9 * s }, { 0.3, 1 - 0.22 * s }, { 0.7, 1 - 0.14 * s }, { 1, 1 - 0.55 * s } }),
            })
            table.insert(lights, { g = g, host = host or stroke.Parent, angle = 225 })
        end
        local rootStroke = root:FindFirstChildOfClass("UIStroke")
        for _, d in ipairs(root:GetDescendants()) do
            if d ~= rootStroke and d:IsA("UIStroke") and (d.Color == Theme.Stroke or d.Color == Theme.Outline) then
                local base = math.max(d.Transparency, 0.45)
                d.Color, d.Transparency = WHITE, base
                light(d, 1)
                -- al perder el foco el input vuelve al color del borde: se reaplica la luz
                d:GetPropertyChangedSignal("Color"):Connect(function()
                    if d.Color == Theme.Stroke then d.Color, d.Transparency = WHITE, base end
                end)
            elseif d:IsA("GuiObject") and d.BackgroundTransparency < 0.05 and find(d.BackgroundColor3) then
                local p = find(d.BackgroundColor3)
                d.BackgroundColor3, d.BackgroundTransparency = p[2], p[3]
                -- los hovers ponen colores del tema: se convierten en velo al terminar
                d:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
                    local q = find(d.BackgroundColor3)
                    if q then tween(d, { BackgroundColor3 = q[2], BackgroundTransparency = q[3] }, 0.12) end
                end)
            end
        end
        -- tinte de acento por la esquina y reflejo en la parte superior (detras del contenido)
        create("Frame", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Accent, ZIndex = 0, Parent = root,
        }, { corner(12), create("UIGradient", { Rotation = 35, Transparency = nseq({ { 0, 0.8 }, { 0.5, 1 }, { 1, 1 } }) }) })
        create("Frame", {
            Size = UDim2.new(1, 0, 0, 150), BackgroundColor3 = WHITE, ZIndex = 0, Parent = root,
        }, { corner(12), create("UIGradient", { Rotation = 90, Transparency = nseq({ { 0, 0.88 }, { 1, 1 } }) }) })
        -- el borde pasa a ser de luz: brillo fuerte del lado del mouse y rebote suave enfrente
        if rootStroke then
            rootStroke.Color, rootStroke.Transparency, rootStroke.Thickness = WHITE, 0, 1.5
            light(rootStroke, 1, root)
        end
        table.insert(self._conns, RunService.RenderStepped:Connect(function()
            local m = UserInputService:GetMouseLocation()
            for _, l in ipairs(lights) do
                local h = l.host
                if h.Parent and h.AbsoluteSize.X > 0 then
                    local c = h.AbsolutePosition + h.AbsoluteSize / 2
                    local target = math.deg(math.atan2(m.Y - c.Y, m.X - c.X)) + 180
                    l.angle = l.angle + ((target - l.angle + 180) % 360 - 180) * 0.12
                    l.g.Rotation = l.angle
                end
            end
        end))
    end

    self._ready = true
    tween(root, { GroupTransparency = 0 }, 0.3, Enum.EasingStyle.Quad)
    if shadow then tween(shadow, { ImageTransparency = 0.4 }, 0.4, Enum.EasingStyle.Quad) end
    tween(holder, { Position = UDim2.fromScale(0.5, 0.5) }, 0.45, Enum.EasingStyle.Quart)
    -- en cristal la tarjeta entra con un pequeno rebote, como una gota
    tween(uiScale, { Scale = baseScale }, glass and 0.55 or 0.4, glass and Enum.EasingStyle.Back or Enum.EasingStyle.Quart)
    if logoImg then
        if J > 0 then
            -- la galleta entra girando un poco y con un pop; luego su glow aparece y "respira" lento
            logoImg.Rotation = -14
            logoScale.Scale = 0.7
            tween(logoImg, { Rotation = 0 }, 0.7, Enum.EasingStyle.Back)
            tween(logoScale, { Scale = 1 }, 0.6, Enum.EasingStyle.Back)
            task.delay(0.15, function()
                if not logoGlow.Parent then return end
                local tw = tween(logoGlow, { ImageTransparency = GLOW_REST }, 0.6, Enum.EasingStyle.Quad)
                tw.Completed:Once(function(state)
                    if state ~= Enum.PlaybackState.Completed or not logoGlow.Parent or self.Done then return end
                    TweenService:Create(logoGlow, TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                        -1, true), { Size = UDim2.fromOffset(GLOW_SIZE + 8, GLOW_SIZE + 8) }):Play()
                end)
            end)
        else
            logoGlow.ImageTransparency = GLOW_REST
        end
    end
    task.delay(0.5, function() playShine() end)

    local lockLeft = (locks[cfg.Id] or 0) - os.clock()
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
