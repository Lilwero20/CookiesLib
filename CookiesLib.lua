local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
Library.Version = "3.5.0"
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

-- Temas listos para usar. Se generan a partir de 4 colores (fondo, tinte, acento y texto)
-- para que todos mantengan el mismo contraste que el tema Cookies original.
local function deriveTheme(bg, tint, accent, text)
    local function m(a) return bg:Lerp(tint, a) end
    local black = rgb(0, 0, 0)
    return {
        Background = bg, Panel = m(0.04), Element = m(0.075), Row = m(0.115), RowHover = m(0.17),
        Input = bg:Lerp(black, 0.18), Stroke = m(0.3), Outline = bg:Lerp(black, 0.5),
        Accent = accent, Text = text, Muted = text:Lerp(bg, 0.32), Dim = text:Lerp(bg, 0.52),
        Success = rgb(96, 196, 124), Warning = rgb(232, 148, 58), Error = rgb(224, 92, 92),
    }
end

local DEFAULT_THEME = table.clone(Theme)
Library.Themes = {
    Cookies    = DEFAULT_THEME,
    Mocha      = deriveTheme(rgb(24, 18, 15), rgb(210, 170, 140), rgb(232, 140, 70), rgb(246, 236, 226)),
    Midnight   = deriveTheme(rgb(12, 14, 20), rgb(140, 160, 210), rgb(98, 146, 255), rgb(230, 236, 248)),
    Ocean      = deriveTheme(rgb(9, 16, 20), rgb(120, 190, 210), rgb(64, 200, 230), rgb(228, 244, 248)),
    Matcha     = deriveTheme(rgb(11, 17, 13), rgb(130, 190, 140), rgb(120, 214, 140), rgb(232, 244, 234)),
    Strawberry = deriveTheme(rgb(20, 11, 14), rgb(220, 130, 150), rgb(255, 105, 140), rgb(248, 234, 238)),
    Grape      = deriveTheme(rgb(15, 11, 22), rgb(170, 140, 220), rgb(170, 120, 255), rgb(240, 234, 250)),
    Graphite   = deriveTheme(rgb(16, 16, 18), rgb(170, 170, 180), rgb(245, 194, 12), rgb(236, 236, 240)),
}
Library.ThemeOrder = { "Cookies", "Mocha", "Midnight", "Ocean", "Matcha", "Strawberry", "Grape", "Graphite" }
Library.CurrentTheme = "Cookies"

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
local DEFAULT_INTRO_LOGO = "rbxassetid://114238631794878"

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
        Searchable = true,         -- boton de lupa (busqueda global) en la barra superior
        ShowProfile = true,
        AutoScale = true,
        DisplayOrder = 50,
        Corner = 12,
        Shadow = true,             -- sombra suave detras de la ventana
        AccentLine = true,         -- linea de acento con degradado bajo la barra superior
        SmoothDrag = true,         -- arrastre con interpolacion (se siente mas fluido)
        RememberLayout = true,     -- recuerda tamano, posicion, tab, tema y ajustes entre ejecuciones
        UIScale = 1,               -- escala extra elegida por el usuario (0.6 - 1.4)
        SearchShortcut = true,     -- Ctrl+F abre la busqueda global
    },
    Tab = { Columns = 2, Padding = 12, Gap = 10, IconSize = 20, IconTint = true, SingleColumnBelow = 440 },
    Section = {
        Collapsible = true, Minimized = false, Columns = 1, MaxHeight = nil,
        Gap = 6, ColumnGap = 8, Corner = 10,
    },
    Element = { Height = 32, Corner = 7 },
    Notify = {
        Duration = 4, Width = 290,
        Position = "BottomRight",  -- BottomRight | TopRight | BottomLeft | TopLeft
        Max = 5,                   -- maximo de notificaciones visibles a la vez
        PauseOnHover = true,       -- el tiempo se detiene mientras el mouse esta encima
    },
    Tooltip = {
        Enabled = true,
        Delay = 0.55,              -- segundos con el mouse encima antes de mostrarse
        MaxWidth = 250,
    },
    Dropdown = {
        SearchThreshold = 7,       -- con esta cantidad de opciones (o mas) aparece el buscador
        MaxVisible = 5,
    },
    Search = {
        MaxResults = 40,
        Placeholder = "Search the whole menu...",
    },
    Intro = {
        Enabled = true,
        Duration = 2,              -- segundos totales que dura la intro
        Logo = DEFAULT_INTRO_LOGO, -- logo de Cookies (PNG sin fondo)
        Width = 300, Height = 180,
        ShowBar = true,            -- barra de carga debajo del logo
        Skippable = true,          -- click / tap para saltarla
        OncePerSession = true,     -- al re-ejecutar el script en la misma partida no se repite
    },
}

local SUB_CONFIGS = { "Tab", "Section", "Element", "Notify", "Tooltip", "Dropdown", "Search", "Intro" }
local SUB_SET = {}
for _, k in ipairs(SUB_CONFIGS) do SUB_SET[k] = true end

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

----------------------------------------------------------------
-- Temas en vivo: cada color del tema que se asigna al crear un objeto queda registrado,
-- asi Library:SetTheme() puede repintar toda la interfaz sin recrearla.
----------------------------------------------------------------
local THEME_KEYS = {
    "Accent", "AccentHi", "AccentSoft", "OnAccent", "Text", "Muted", "Dim",
    "Background", "Panel", "Element", "Row", "RowHover", "Input", "Stroke", "Outline",
    "Success", "Warning", "Error",
}
local themed = setmetatable({}, { __mode = "k" })

local function themeKeyOf(c)
    for i = 1, #THEME_KEYS do
        local k = THEME_KEYS[i]
        if Theme[k] == c then return k end
    end
    return nil
end

local function applyTheme(t)
    local accent = t.Accent
    merge(Theme, t)
    if accent then
        if not t.AccentHi then Theme.AccentHi = accent:Lerp(rgb(255, 255, 255), 0.25) end
        if not t.AccentSoft then Theme.AccentSoft = Theme.Panel:Lerp(accent, 0.14) end
        if not t.OnAccent then
            local lum = 0.299 * accent.R + 0.587 * accent.G + 0.114 * accent.B
            Theme.OnAccent = lum > 0.55 and rgb(40, 20, 8) or rgb(254, 254, 254)
        end
    end
end

local function repaintAll()
    for inst, map in pairs(themed) do
        if inst.Parent then
            for prop, key in pairs(map) do
                local c = Theme[key]
                if c then pcall(function() inst[prop] = c end) end
            end
        end
    end
    for _, win in ipairs(Library.Windows) do
        if win._repaint then pcall(win._repaint) end
    end
end

-- t puede ser el nombre de un tema ("Midnight") o una tabla con colores ({ Accent = ... })
function Library:SetTheme(t)
    if type(t) == "string" then
        local preset = Library.Themes[t]
        if not preset then return false end
        Library.CurrentTheme = t
        applyTheme(preset)
    elseif type(t) == "table" then
        applyTheme(t)
    else
        return false
    end
    if #Library.Windows > 0 then repaintAll() end
    return true
end

function Library:SetAccent(color)
    if typeof(color) ~= "Color3" then return end
    applyTheme({ Accent = color })
    if #Library.Windows > 0 then repaintAll() end
end

function Library:AddTheme(name, t)
    if type(name) ~= "string" or type(t) ~= "table" then return end
    Library.Themes[name] = t
    if not table.find(Library.ThemeOrder, name) then table.insert(Library.ThemeOrder, name) end
end

function Library:GetThemes() return table.clone(Library.ThemeOrder) end

function Library:Configure(t)
    if type(t) ~= "table" then return end
    for k, v in pairs(t) do
        if k == "Theme" then Library:SetTheme(v)
        elseif type(v) == "table" and type(Library.Config[k]) == "table" then merge(Library.Config[k], v)
        else Library.Config[k] = v end
    end
end

-- cache por clase: evita llamar IsA() en cada instancia creada
local classInfo = {}
local function infoOf(className, inst)
    local info = classInfo[className]
    if not info then
        info = {
            gui = inst:IsA("GuiObject"),
            button = inst:IsA("GuiButton"),
            clear = className == "TextLabel" or className == "ImageLabel",
        }
        classInfo[className] = info
    end
    return info
end

-- props.ThemeIgnore = true evita que los colores de ese objeto se repinten al cambiar de tema
local function create(className, props, children)
    local inst = Instance.new(className)
    local info = infoOf(className, inst)
    if info.gui then inst.BorderSizePixel = 0 end
    if info.button then inst.AutoButtonColor = false end
    if info.clear then inst.BackgroundTransparency = 1 end
    local parent, map
    local ignore = props and props.ThemeIgnore
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then
                parent = v
            elseif k ~= "ThemeIgnore" then
                inst[k] = v
                if not ignore and typeof(v) == "Color3" then
                    local key = themeKeyOf(v)
                    if key then
                        map = map or {}
                        map[k] = key
                    end
                end
            end
        end
    end
    if map then themed[inst] = map end
    if children then
        for _, child in ipairs(children) do child.Parent = inst end
    end
    if parent then inst.Parent = parent end
    return inst
end

-- registra a mano un color del tema (para objetos cuyo color se asigna despues de crearlos)
local function bindTheme(inst, prop, key)
    local map = themed[inst]
    if not map then map = {} themed[inst] = map end
    map[prop] = key
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

-- normal / over pueden ser Color3 o el nombre de un color del tema ("Row"), que se lee en vivo
local function hover(obj, normal, over, prop)
    prop = prop or "BackgroundColor3"
    local function col(c) return type(c) == "string" and Theme[c] or c end
    obj.MouseEnter:Connect(function() tween(obj, { [prop] = col(over) }, 0.12) end)
    obj.MouseLeave:Connect(function() tween(obj, { [prop] = col(normal) }, 0.12) end)
end

-- brillo vertical sutil para superficies de acento (botones Primary, pastilla seleccionada...)
local function sheen(parent, amount)
    local c = 255 - math.floor((amount or 0.16) * 255)
    return create("UIGradient", {
        Rotation = 90, Color = ColorSequence.new(rgb(255, 255, 255), rgb(c, c, c)), Parent = parent,
    })
end

-- reduce a escala (pressed) y rebota al soltar: feedback tactil para botones
local function pressFx(btn, target, amount)
    local sc = create("UIScale", { Parent = target or btn })
    btn.MouseButton1Down:Connect(function() tween(sc, { Scale = amount or 0.97 }, 0.08) end)
    local function up() tween(sc, { Scale = 1 }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out) end
    btn.MouseButton1Up:Connect(up)
    btn.MouseLeave:Connect(up)
    return sc
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

-- Iconos dibujados con frames (no dependen de assets): lupa, check y "x"
local function searchIcon(parent, size, color, z)
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size), BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent,
    })
    local rs = math.floor(size * 0.64 + 0.5)
    local ring = stroke(color, 1.6)
    create("Frame", {
        Size = UDim2.fromOffset(rs, rs), BackgroundTransparency = 1, ZIndex = z or 1, Parent = holder,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), ring })
    local handle = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(size * 0.74, size * 0.74),
        Size = UDim2.fromOffset(math.max(size * 0.42, 4), 2), Rotation = 45,
        BackgroundColor3 = color, ZIndex = z or 1, Parent = holder,
    }, { corner(1) })
    return {
        Frame = holder,
        set = function(c, t)
            tween(ring, { Color = c }, t or 0)
            tween(handle, { BackgroundColor3 = c }, t or 0)
        end,
    }
end

local function checkIcon(parent, color, z)
    local f = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1, ZIndex = z or 1, Parent = parent,
    })
    local parts = {
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(3, 7.5),
            Size = UDim2.fromOffset(5, 2), Rotation = 45, BackgroundColor3 = color,
            BackgroundTransparency = 1, ZIndex = z or 1, Parent = f,
        }, { corner(1) }),
        create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(7.5, 5.5),
            Size = UDim2.fromOffset(9, 2), Rotation = -45, BackgroundColor3 = color,
            BackgroundTransparency = 1, ZIndex = z or 1, Parent = f,
        }, { corner(1) }),
    }
    return {
        Frame = f,
        show = function(v, c, t)
            for _, p in ipairs(parts) do
                tween(p, { BackgroundTransparency = v and 0 or 1, BackgroundColor3 = c or p.BackgroundColor3 }, t or 0)
            end
        end,
    }
end

local function crossIcon(parent, size, color, z)
    local bars = {}
    for _, rot in ipairs({ 45, -45 }) do
        table.insert(bars, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(size, 2), Rotation = rot, BackgroundColor3 = color,
            ZIndex = z or 1, Parent = parent,
        }, { corner(1) }))
    end
    return function(c, t)
        for _, b in ipairs(bars) do tween(b, { BackgroundColor3 = c }, t or 0) end
    end
end

local hasFS = typeof(writefile) == "function" and typeof(readfile) == "function"
    and typeof(isfolder) == "function" and typeof(makefolder) == "function"

local function fileExists(path)
    if typeof(isfile) == "function" then
        local ok, r = pcall(isfile, path)
        return ok and r
    end
    local ok = pcall(readfile, path)
    return ok
end

local function ensureFolder(folder)
    if not hasFS then return false end
    local ok = pcall(function()
        if not isfolder(folder) then makefolder(folder) end
    end)
    return ok
end

local function readJSON(path)
    if not hasFS or not fileExists(path) then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
    if ok and type(data) == "table" then return data end
    return nil
end

local function writeJSON(path, data)
    if not hasFS then return false end
    local ok = pcall(function() writefile(path, HttpService:JSONEncode(data)) end)
    return ok
end

local function genv()
    local ok, g = pcall(function() return getgenv and getgenv() end)
    return (ok and type(g) == "table") and g or _G
end

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

-- Devuelve (titulo, cuerpo) para el tooltip, o nil si no hace falta (nada cortado y sin Tooltip manual)
local function tipInfo(win, scope, o)
    local labels, cut = {}, {}
    local any = false
    local s = math.max(win._scale and win._scale.Scale or 1, 0.05)
    for _, d in ipairs(scope:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            table.insert(labels, d)
            -- TextBounds ya viene recortado con TextTruncate, asi que medimos el texto completo
            local c = false
            if d.TextTruncate == Enum.TextTruncate.AtEnd then
                local okM, full = pcall(TextService.GetTextSize, TextService, d.Text, d.TextSize, d.Font, Vector2.new(10000, 10000))
                c = okM and full.X > d.AbsoluteSize.X / s + 1
            end
            cut[#labels] = c
            if c then any = true end
        end
    end
    if not any and not o.Tooltip then return nil end
    local title = labels[1] and labels[1].Text or o.Name
    local body = o.Tooltip or o.Description
    if body == nil or body == "" then
        for i = 2, #labels do
            if cut[i] then body = labels[i].Text break end
        end
    end
    return title, body
end

local function decorate(section, obj, frame, o, scope)
    obj.Frame = frame
    obj.Section = section
    obj.Enabled = true
    obj._listeners = obj._listeners or {}
    local win = section.Window
    local entry = { kind = "Element", type = obj.Type, frame = frame, section = section._main, tab = section.Tab, o = o }
    table.insert(win._index, entry)
    table.insert(win._objects, obj)
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
        local ei = table.find(win._index, entry)
        if ei then table.remove(win._index, ei) end
        local oi = table.find(win._objects, obj)
        if oi then table.remove(win._objects, oi) end
        frame:Destroy()
    end
    if o.Enabled == false or o.Disabled == true then obj:SetEnabled(false) end
    if o.Visible == false then frame.Visible = false end
    local tipScope = scope or frame
    win:_bindTip(tipScope, function() return tipInfo(win, tipScope, o) end)
    return obj
end

-- nombre actual de una entrada del indice de busqueda
local function entryName(e)
    if e.kind == "Tab" then return tostring(e.tab.Name) end
    if e.kind == "Section" then return tostring(e.section.Name) end
    -- el primer TextLabel con texto es el nombre del elemento; se guarda para no recorrer
    -- todos los descendientes en cada tecla de la busqueda
    local l = e._label
    if l and l.Parent and l.Text ~= "" then return l.Text end
    for _, d in ipairs(e.frame:GetDescendants()) do
        if d:IsA("TextLabel") and d.Text ~= "" then
            e._label = d
            return d.Text
        end
    end
    return tostring(e.o and e.o.Name or "")
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
    for _, k in ipairs(SUB_CONFIGS) do
        if type(opts[k]) == "table" then merge(cfg[k], opts[k]) end
    end
    for k, v in pairs(opts) do
        if k ~= "Theme" and k ~= "Config" and not SUB_SET[k] then
            cfg.Window[k] = v
        end
    end
    if type(opts.Theme) == "table" then
        applyTheme(opts.Theme)
    elseif type(opts.Theme) == "string" and Library.Themes[opts.Theme] then
        Library.CurrentTheme = opts.Theme
        applyTheme(Library.Themes[opts.Theme])
    end
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
    self._index = {}
    self._objects = {}
    self._unload = {}
    self._navOrder = 0
    self._minId = 0
    self._minShift = 0
    self._ready = false
    self._intro = false
    self._searchOpen = false
    self._tipId, self._tipSeq, self._tipShown = 0, 0, false
    self._w, self._h = W.Width, W.Height
    self._userScale = math.clamp(tonumber(W.UIScale) or 1, 0.6, 1.4)

    -- estado guardado de la interfaz (tamano, posicion, tab, tema...) de la ultima vez
    self._statePath = tostring(W.ConfigFolder) .. "/_ui_state.txt"
    self._remember = W.RememberLayout ~= false and hasFS
    local state = self._remember and readJSON(self._statePath) or {}
    self._state = state
    if type(state.w) == "number" and type(state.h) == "number" then
        self._w = math.clamp(state.w, W.MinWidth, 2000)
        self._h = math.clamp(state.h, W.MinHeight, 1400)
    end
    if type(state.scale) == "number" then self._userScale = math.clamp(state.scale, 0.6, 1.4) end
    if type(state.key) == "string" and Enum.KeyCode[state.key] then self.ToggleKey = Enum.KeyCode[state.key] end
    if type(state.anim) == "boolean" then Library.Config.Animations = state.anim end
    if type(state.speed) == "number" then Library.Config.AnimationSpeed = state.speed end
    if type(state.tips) == "boolean" then cfg.Tooltip.Enabled = state.tips end
    if type(state.theme) == "string" and Library.Themes[state.theme] then
        Library.CurrentTheme = state.theme
        applyTheme(Library.Themes[state.theme])
    end
    if type(state.accent) == "string" then
        local r, g, b = state.accent:match("^#?(%x%x)(%x%x)(%x%x)$")
        if r then applyTheme({ Accent = rgb(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) }) end
    end
    self._ew, self._eh = self._w, self._h

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
    self._getViewport = getViewport

    local root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(self._w, self._h), BackgroundTransparency = 1, Parent = gui,
    })
    local uiScale = create("UIScale", { Scale = 0.96, Parent = root })
    local baseScale = 1
    self._root, self._scale = root, uiScale
    self._baseScale = function() return baseScale end

    if W.Shadow ~= false then
        -- sombra 9-slice (se dibuja debajo de la ventana porque se crea antes que el shell)
        create("ImageLabel", {
            Image = "rbxassetid://6014261993", ImageColor3 = rgb(0, 0, 0), ImageTransparency = 0.45,
            ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(49, 49, 450, 450),
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 4),
            Size = UDim2.new(1, 44, 1, 44), ThemeIgnore = true, Parent = root,
        })
    end

    local shell = create("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        ClipsDescendants = true, Parent = root,
    }, { corner(W.Corner), stroke(Theme.Outline, 1), padding(SHELL_PAD, SHELL_PAD, SHELL_PAD, SHELL_PAD) })
    -- leve degradado vertical: le da profundidad al fondo sin cambiar el color base
    create("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 205, 205)),
        Parent = shell,
    })

    local top = create("Frame", {
        Size = UDim2.new(1, 0, 0, TOP_H), BackgroundTransparency = 1, ZIndex = 5, Parent = shell,
    })
    create("Frame", {
        Position = UDim2.fromOffset(14, TOP_H + 5), Size = UDim2.new(1, -28, 0, 1),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.55, Parent = shell,
    })
    if W.AccentLine ~= false then
        create("Frame", {
            Position = UDim2.fromOffset(14, TOP_H + 5), Size = UDim2.new(1, -28, 0, 1), ZIndex = 2,
            BackgroundColor3 = Theme.Accent, Parent = shell,
        }, { create("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.05), NumberSequenceKeypoint.new(0.35, 0.6),
                NumberSequenceKeypoint.new(1, 1),
            }),
        }) })
    end

    local nBtns = (W.Searchable ~= false and 1 or 0) + (W.Minimizable and 1 or 0) + (W.Closable and 1 or 0)
    local btnsW = math.max(nBtns, 1) * 28 + math.max(nBtns - 1, 0) * 4

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
        Size = UDim2.new(1, -(titleX + btnsW + 32), 1, 0), ZIndex = 6, Parent = top,
    }, { listLayout(0, { VerticalAlignment = Enum.VerticalAlignment.Center }) })
    self._title = label({
        Text = W.Title, Font = Fonts.Title, TextSize = 17, ZIndex = 6,
        Size = UDim2.new(1, 0, 0, 20), LayoutOrder = 1, Parent = titleBox,
    })
    self._subtitle = label({
        Text = W.Subtitle or ("v" .. Library.Version), TextSize = 11, ZIndex = 6,
        TextColor3 = Theme.Dim, Size = UDim2.new(1, 0, 0, 12), LayoutOrder = 2, Parent = titleBox,
    })

    local btnHolder = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0), ZIndex = 6,
        Size = UDim2.fromOffset(btnsW, 28), Parent = top,
    }, { listLayout(4, { FillDirection = Enum.FillDirection.Horizontal }) })

    local function iconButton(kind, order, hoverColor)
        local b = create("TextButton", {
            Text = "", Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Row,
            BackgroundTransparency = 1, LayoutOrder = order, ZIndex = 7, Parent = btnHolder,
        }, { corner(8) })
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
            tween(b, { BackgroundColor3 = hoverColor or Theme.Row, BackgroundTransparency = 0 }, 0.15)
            for _, f in ipairs(bars) do tween(f, { BackgroundColor3 = Theme.Text }, 0.15) end
        end)
        b.MouseLeave:Connect(function()
            tween(b, { BackgroundTransparency = 1 }, 0.15)
            for _, f in ipairs(bars) do tween(f, { BackgroundColor3 = Theme.Muted }, 0.15) end
        end)
        pressFx(b, nil, 0.9)
        return b
    end
    local searchBtn, searchBtnIcon
    if W.Searchable ~= false then
        searchBtn = create("TextButton", {
            Text = "", Size = UDim2.fromOffset(28, 28), BackgroundTransparency = 1, BackgroundColor3 = Theme.Row,
            LayoutOrder = 0, ZIndex = 7, Parent = btnHolder,
        }, { corner(8) })
        searchBtnIcon = searchIcon(searchBtn, 14, Theme.Muted, 8)
        searchBtn.MouseEnter:Connect(function() tween(searchBtn, { BackgroundTransparency = 0 }, 0.15) end)
        searchBtn.MouseLeave:Connect(function() tween(searchBtn, { BackgroundTransparency = 1 }, 0.15) end)
        pressFx(searchBtn, nil, 0.9)
    end
    local minBtn = W.Minimizable and iconButton("min", 1, nil) or nil
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
            Size = UDim2.new(1, -16, 0, 44), BackgroundColor3 = Theme.Panel, Parent = sidebar,
        }, { corner(9), stroke(Theme.Stroke, 1, 0.6) })
        avatar = create("ImageLabel", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0.5, 0),
            Size = UDim2.fromOffset(28, 28), BackgroundColor3 = Theme.Input, BackgroundTransparency = 0,
            Parent = profile,
        }, { corner(14), stroke(Theme.Stroke, 1, 0.4) })
        create("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 1, 1, 1), Size = UDim2.fromOffset(9, 9),
            BackgroundColor3 = Theme.Success, ZIndex = 2, Parent = avatar,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(Theme.Panel, 2) })
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

    -- el contenido vive en un panel propio, un tono mas claro que el fondo
    local content = create("Frame", {
        Position = UDim2.fromOffset(SB + 10, 0), Size = UDim2.new(1, -(SB + 10), 1, 0),
        BackgroundColor3 = Theme.Panel, ClipsDescendants = true, Parent = body,
    }, { corner(10), stroke(Theme.Stroke, 1, 0.65) })
    self._content = content

    do
        local pos = tostring(cfg.Notify.Position or "BottomRight")
        local right = not pos:find("Left")
        local topSide = pos:find("Top") ~= nil
        self._notifRight = right
        self._notifs = create("Frame", {
            BackgroundTransparency = 1, AnchorPoint = Vector2.new(right and 1 or 0, topSide and 0 or 1),
            Position = UDim2.new(right and 1 or 0, right and -16 or 16, topSide and 0 or 1, topSide and 16 or -16),
            Size = UDim2.new(0, cfg.Notify.Width, 1, -32), ZIndex = 150, Parent = gui,
        }, { listLayout(8, {
            VerticalAlignment = topSide and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
        }) })
        self._toasts = {}
    end

    -- Tooltip (una sola instancia por ventana, se reutiliza)
    do
        local maxW = cfg.Tooltip.MaxWidth or 250
        local function limit() return create("UISizeConstraint", { MaxSize = Vector2.new(maxW - 24, math.huge) }) end
        local c1, c2 = limit(), limit()
        local group = create("CanvasGroup", {
            Visible = false, GroupTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0), BackgroundColor3 = Theme.Element, ZIndex = 200,
            Active = false, Parent = gui,
        }, { corner(8), stroke(Theme.Stroke, 1, 0.2), padding(12, 9, 12, 9), listLayout(3) })
        pcall(function() group.Interactable = false end)
        local tTitle = label({
            Text = "", Font = Fonts.Bold, TextSize = 12, TextWrapped = true, TextTruncate = Enum.TextTruncate.None,
            AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), LayoutOrder = 1, Parent = group,
        })
        c1.Parent = tTitle
        local tBody = label({
            Text = "", TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.XY,
            Size = UDim2.fromOffset(0, 0), LayoutOrder = 2, Parent = group,
        })
        c2.Parent = tBody
        self._tip = { group = group, title = tTitle, body = tBody, limits = { c1, c2 } }
    end

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
            if not moved then self:Toggle() else self:_saveState() end
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
    if type(state.float) == "boolean" then floating.Visible = state.float end
    if type(state.fx) == "number" and type(state.fy) == "number" then
        floating.Position = UDim2.fromOffset(state.fx, state.fy)
    end

    ----------------------------------------------------------------
    -- Busqueda global (boton de lupa en la barra superior)
    ----------------------------------------------------------------
    local searchPage, sbox, runSearch
    if searchBtn then
        local ecr = cfg.Element.Corner
        searchPage = create("CanvasGroup", {
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Panel, ZIndex = 20,
            Visible = false, GroupTransparency = 1, Active = true, Parent = content,
        }, { corner(10) })
        local barStroke = stroke(Theme.Stroke, 1, 0.3)
        local bar = create("Frame", {
            Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 36),
            BackgroundColor3 = Theme.Row, Parent = searchPage,
        }, { corner(ecr), barStroke })
        local ibox = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
            Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Parent = bar,
        })
        searchIcon(ibox, 14, Theme.Accent)
        sbox = create("TextBox", {
            Position = UDim2.fromOffset(36, 0), Size = UDim2.new(1, -72, 1, 0), BackgroundTransparency = 1,
            Font = Fonts.Body, TextSize = 13, TextColor3 = Theme.Text, ClearTextOnFocus = false, Text = "",
            PlaceholderText = cfg.Search.Placeholder or "Search...", PlaceholderColor3 = Theme.Dim,
            TextXAlignment = Enum.TextXAlignment.Left, Parent = bar,
        })
        local clearBtn = create("TextButton", {
            Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.fromOffset(24, 24), BackgroundColor3 = Theme.Input, Parent = bar,
        }, { corner(6) })
        local paintCross = crossIcon(clearBtn, 9, Theme.Muted)
        clearBtn.MouseEnter:Connect(function()
            tween(clearBtn, { BackgroundColor3 = Theme.RowHover }, 0.12)
            paintCross(Theme.Text, 0.12)
        end)
        clearBtn.MouseLeave:Connect(function()
            tween(clearBtn, { BackgroundColor3 = Theme.Input }, 0.12)
            paintCross(Theme.Muted, 0.12)
        end)
        sbox.Focused:Connect(function() tween(barStroke, { Color = Theme.Accent, Transparency = 0 }, 0.15) end)
        sbox.FocusLost:Connect(function() tween(barStroke, { Color = Theme.Stroke, Transparency = 0.3 }, 0.15) end)

        local countLbl = label({
            Text = "", TextSize = 11, TextColor3 = Theme.Dim, Position = UDim2.fromOffset(14, 52),
            Size = UDim2.new(1, -28, 0, 14), Parent = searchPage,
        })
        local results = create("ScrollingFrame", {
            BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 72), Size = UDim2.new(1, -24, 1, -82),
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = IS_TOUCH and 4 or 3, ScrollBarImageColor3 = Theme.Dim,
            ScrollBarImageTransparency = 0.5, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = searchPage,
        }, { padding(0, 0, 6, 0), listLayout(4) })
        local emptyLbl = label({
            Text = "", TextSize = 12, TextColor3 = Theme.Dim, TextWrapped = true,
            TextTruncate = Enum.TextTruncate.None, TextXAlignment = Enum.TextXAlignment.Center,
            Position = UDim2.fromOffset(24, 100), Size = UDim2.new(1, -48, 0, 40), Parent = searchPage,
        })

        local function makeRow(item, order)
            local e = item.e
            local typ = e.kind == "Element" and e.type or e.kind
            local path
            if e.kind == "Tab" then path = "Open tab"
            elseif e.kind == "Section" then path = tostring(e.tab.Name)
            else path = tostring(e.tab.Name) .. " / " .. tostring(e.section and e.section.Name or "") end
            local row = create("TextButton", {
                Text = "", Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Row,
                LayoutOrder = order, Parent = results,
            }, { corner(ecr) })
            local ind = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(2, 18),
                BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = row,
            }, { corner(1) })
            label({ Text = item.name, Font = Fonts.Bold, TextSize = 13, Position = UDim2.fromOffset(14, 6),
                Size = UDim2.new(1, -110, 0, 18), Parent = row })
            label({ Text = path, TextSize = 11, TextColor3 = Theme.Dim, Position = UDim2.fromOffset(14, 24),
                Size = UDim2.new(1, -110, 0, 14), Parent = row })
            local chip = label({
                Text = typ, Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Center, BackgroundTransparency = 0,
                BackgroundColor3 = Theme.Input, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(0, 18),
                AutomaticSize = Enum.AutomaticSize.X, TextTruncate = Enum.TextTruncate.None, Parent = row,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = chip })
            create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = chip })
            row.MouseEnter:Connect(function()
                tween(row, { BackgroundColor3 = Theme.RowHover }, 0.12)
                tween(ind, { BackgroundTransparency = 0 }, 0.12)
            end)
            row.MouseLeave:Connect(function()
                tween(row, { BackgroundColor3 = Theme.Row }, 0.12)
                tween(ind, { BackgroundTransparency = 1 }, 0.12)
            end)
            row.Activated:Connect(function() self:_goTo(e) end)
        end

        runSearch = function()
            for _, c in ipairs(results:GetChildren()) do
                if c:IsA("GuiObject") then c:Destroy() end
            end
            results.CanvasPosition = Vector2.new(0, 0)
            local q = string.lower(sbox.Text)
            q = q:match("^%s*(.-)%s*$") or ""
            if q == "" then
                self._firstResult = nil
                countLbl.Text = ""
                emptyLbl.Text = "Type to search every tab, section and option"
                emptyLbl.Visible = true
                return
            end
            local tokens = {}
            for t in q:gmatch("%S+") do table.insert(tokens, t) end
            local found = {}
            for idx, e in ipairs(self._index) do
                local tab = e.tab
                local alive = tab and tab._btn and tab._btn.Parent and tab._btn.Visible ~= false
                if alive and (e.kind == "Tab" or (e.frame and e.frame.Parent and e.frame.Visible ~= false)) then
                    local name = entryName(e)
                    local desc = e.o and e.o.Description or ""
                    local typ = e.kind == "Element" and e.type or e.kind
                    local hay = string.lower(name .. " " .. tostring(desc) .. " " .. tostring(tab.Name) .. " "
                        .. tostring(e.section and e.section.Name or "") .. " " .. tostring(typ))
                    local match = true
                    for _, t in ipairs(tokens) do
                        if not hay:find(t, 1, true) then match = false break end
                    end
                    if match then
                        local ln = string.lower(name)
                        local sc = 3
                        if ln == q then sc = 0
                        elseif ln:sub(1, #q) == q then sc = 1
                        elseif ln:find(q, 1, true) then sc = 2 end
                        table.insert(found, { e = e, name = name, score = sc, idx = idx })
                    end
                end
            end
            table.sort(found, function(a, b)
                if a.score ~= b.score then return a.score < b.score end
                return a.idx < b.idx
            end)
            local maxR = cfg.Search.MaxResults or 40
            self._firstResult = found[1] and found[1].e or nil
            for i = 1, math.min(#found, maxR) do makeRow(found[i], i) end
            if #found == 0 then
                countLbl.Text = ""
                emptyLbl.Text = 'No results for "' .. sbox.Text .. '"'
                emptyLbl.Visible = true
            else
                emptyLbl.Visible = false
                countLbl.Text = #found .. (#found == 1 and " result" or " results")
                    .. (#found > maxR and (" (showing first " .. maxR .. ")") or "")
            end
        end

        -- debounce: con menus grandes no se reconstruyen los resultados en cada tecla
        local searchSeq = 0
        sbox:GetPropertyChangedSignal("Text"):Connect(function()
            searchSeq = searchSeq + 1
            local seq = searchSeq
            task.delay(0.08, function()
                if seq == searchSeq and self._searchOpen then runSearch() end
            end)
        end)
        -- Enter abre el primer resultado
        sbox.FocusLost:Connect(function(enter)
            if enter and self._searchOpen and self._firstResult then self:_goTo(self._firstResult) end
        end)
        clearBtn.Activated:Connect(function()
            if sbox.Text ~= "" then
                sbox.Text = ""
                sbox:CaptureFocus()
            else
                self:CloseSearch()
            end
        end)

        local function paintSearchBtn(hoverOn)
            local open = self._searchOpen
            searchBtnIcon.set(open and Theme.Accent or (hoverOn and Theme.Text or Theme.Muted), 0.15)
        end
        searchBtn.MouseEnter:Connect(function() paintSearchBtn(true) end)
        searchBtn.MouseLeave:Connect(function() paintSearchBtn(false) end)
        searchBtn.Activated:Connect(function() self:ToggleSearch() end)

        self._searchBox = sbox
        self._setSearchOpen = function(state)
            state = state and true or false
            if state == self._searchOpen then return end
            self._searchOpen = state
            paintSearchBtn(false)
            if state then
                searchPage.Visible = true
                searchPage.Position = UDim2.fromOffset(0, -10)
                tween(searchPage, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) }, 0.22,
                    Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
                runSearch()
                task.delay(0.05, function()
                    if self._searchOpen and sbox.Parent then sbox:CaptureFocus() end
                end)
            else
                sbox:ReleaseFocus()
                tween(searchPage, { GroupTransparency = 1, Position = UDim2.fromOffset(0, -10) }, 0.16,
                    Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                task.delay(0.18, function()
                    if not self._searchOpen and searchPage.Parent then searchPage.Visible = false end
                end)
            end
        end
        table.insert(self._conns, UserInputService.InputBegan:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.Escape and self._searchOpen and self.Visible then
                self._setSearchOpen(false)
            elseif input.KeyCode == Enum.KeyCode.F and W.SearchShortcut ~= false and self.Visible
                and not self.Minimized and not Library._binding
                and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
                    or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then
                self._setSearchOpen(not self._searchOpen)
            end
        end))
    end

    local function clampRoot(pos)
        local vp = getViewport()
        local s = uiScale.Scale
        local w = self._ew * s
        local h = (self.Minimized and MIN_H or self._eh) * s
        -- con anclaje superior (ventana minimizada) se pasa a coordenadas de centro y luego se vuelve
        local topA = root.AnchorPoint.Y == 0
        local cx = pos.X.Scale * vp.X + pos.X.Offset
        local cy = pos.Y.Scale * vp.Y + pos.Y.Offset + (topA and h / 2 or 0)
        local loX, hiX = 100 - w / 2, vp.X - 100 + w / 2
        local loY, hiY = h / 2, vp.Y - 48 + h / 2
        if loX > hiX then loX, hiX = vp.X / 2, vp.X / 2 end
        if loY > hiY then loY, hiY = vp.Y / 2, vp.Y / 2 end
        cx = math.clamp(cx, loX, hiX)
        cy = math.clamp(cy, loY, hiY) - (topA and h / 2 or 0)
        return UDim2.new(pos.X.Scale, cx - pos.X.Scale * vp.X, pos.Y.Scale, cy - pos.Y.Scale * vp.Y)
    end

    if W.Draggable then
        local startInput, startPos, dragTween
        dragger(top, function(input)
            startInput, startPos = input.Position, root.Position
            self:_hideTip()
        end, function(i)
            local d = i.Position - startInput
            local goal = clampRoot(UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y))
            if W.SmoothDrag ~= false and Library.Config.Animations then
                if dragTween then dragTween:Cancel() end
                dragTween = TweenService:Create(root, TweenInfo.new(0.07, Enum.EasingStyle.Quad,
                    Enum.EasingDirection.Out), { Position = goal })
                dragTween:Play()
            else
                root.Position = goal
            end
        end, function()
            task.delay(0.1, function() self:_saveState() end)
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
        -- escala elegida por el usuario, sin salirse nunca de la pantalla
        local us = self._userScale or 1
        if us ~= 1 then
            sc = math.clamp(math.min(sc * us, availX / ew, availY / eh), 0.3, 1.4)
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
        end, function()
            self:_saveState()
        end)
        grip.MouseEnter:Connect(function()
            for _, m in ipairs(grip:GetDescendants()) do
                if m:IsA("Frame") and m.BackgroundTransparency < 1 then
                    tween(m, { BackgroundColor3 = Theme.Accent }, 0.15)
                end
            end
        end)
        grip.MouseLeave:Connect(function()
            for _, m in ipairs(grip:GetDescendants()) do
                if m:IsA("Frame") and m.BackgroundTransparency < 1 then
                    tween(m, { BackgroundColor3 = Theme.Dim }, 0.15)
                end
            end
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

    -- repinta lo que depende de un estado (tabs activas, toggles encendidos, etc.) tras cambiar el tema
    self._repaint = function()
        for _, t in ipairs(self.Tabs) do
            if t._repaint then pcall(t._repaint) end
        end
        for _, obj in ipairs(self._objects) do
            if obj._repaint then
                pcall(obj._repaint)
            elseif obj.Set and obj.Value ~= nil and obj.Type ~= "Button" then
                pcall(obj.Set, obj, obj.Value, true)
            end
        end
        if searchBtnIcon then searchBtnIcon.set(self._searchOpen and Theme.Accent or Theme.Muted, 0) end
    end

    fit()
    if type(state.x) == "number" and type(state.y) == "number" then
        root.Position = clampRoot(UDim2.new(0.5, state.x, 0.5, state.y))
    end
    self._ready = true
    table.insert(Library.Windows, self)

    local G = genv()
    if cfg.Intro and cfg.Intro.OncePerSession ~= false and G.__CookiesIntroShown then
        cfg.Intro.Enabled = false
    end
    if cfg.Intro and cfg.Intro.Enabled ~= false then
        G.__CookiesIntroShown = true
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

    local overlay = create("TextButton", {
        Text = "", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1, Active = true, ZIndex = 100, Parent = gui,
    })
    local skipped = false
    if I.Skippable ~= false then
        overlay.Activated:Connect(function() skipped = true end)
    end
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
        while not loaded and not skipped and os.clock() - t0 < 2 do task.wait() end
        if not gui.Parent then return end

        local dur = math.max(I.Duration or 2, 1)
        tw(overlay, { BackgroundTransparency = 0.1 }, 0.35, Enum.EasingStyle.Quad)
        tw(img, { ImageTransparency = 0 }, 0.45)
        tw(imgScale, { Scale = base }, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        if track then
            tw(track, { BackgroundTransparency = 0 }, 0.4)
            tw(fill, { Size = UDim2.fromScale(1, 1) }, dur - 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        end
        local tEnd = os.clock() + dur - 0.45
        while os.clock() < tEnd and not skipped do task.wait() end
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

----------------------------------------------------------------
-- Tooltips
----------------------------------------------------------------
function WindowMT:_showTip(inst, title, body)
    local T = self._tip
    if not T or not inst.Parent then return end
    self._tipSeq = self._tipSeq + 1
    local seq = self._tipSeq
    local vp = self._getViewport()
    local maxW = math.min(self.Config.Tooltip.MaxWidth or 250, vp.X - 24)
    for _, c in ipairs(T.limits) do c.MaxSize = Vector2.new(math.max(maxW - 24, 60), math.huge) end
    T.title.Text = title or ""
    T.title.Visible = title ~= nil and title ~= ""
    T.body.Text = body or ""
    T.body.Visible = body ~= nil and body ~= ""
    T.group.GroupTransparency = 1
    T.group.Visible = true
    self._tipShown = true
    task.spawn(function()
        for _ = 1, 3 do
            task.wait()
            if T.group.AbsoluteSize.X > 0 then break end
        end
        if self._tipSeq ~= seq or not inst.Parent or not self.Gui.Parent then return end
        local origin = self.Gui.AbsolutePosition
        local ap, as = inst.AbsolutePosition - origin, inst.AbsoluteSize
        local sz = T.group.AbsoluteSize
        local m, edge = 8, 6
        local x, y, dx = ap.X + as.X + m, 0, -6
        if x + sz.X > vp.X - edge then
            x = ap.X - m - sz.X
            dx = 6
        end
        if x < edge then
            -- no cabe a los lados: arriba o abajo del elemento
            x = math.clamp(ap.X, edge, math.max(vp.X - sz.X - edge, edge))
            y = ap.Y + as.Y + m
            if y + sz.Y > vp.Y - edge then y = ap.Y - m - sz.Y end
            dx = 0
        else
            y = ap.Y + as.Y / 2 - sz.Y / 2
        end
        y = math.clamp(y, edge, math.max(vp.Y - sz.Y - edge, edge))
        T.group.Position = UDim2.fromOffset(x + dx, y)
        tween(T.group, { GroupTransparency = 0, Position = UDim2.fromOffset(x, y) }, 0.16,
            Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    end)
end

function WindowMT:_hideTip()
    local T = self._tip
    if not T or not self._tipShown then return end
    self._tipShown = false
    self._tipOwner = nil
    self._tipSeq = self._tipSeq + 1
    local seq = self._tipSeq
    tween(T.group, { GroupTransparency = 1 }, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    task.delay(0.12, function()
        if self._tipSeq == seq and T.group.Parent then T.group.Visible = false end
    end)
end

-- Enlaza un tooltip a un objeto (y a sus hijos, para que no parpadee al pasar por encima de ellos).
-- getInfo() devuelve titulo, cuerpo; si devuelve nil no se muestra nada.
function WindowMT:_bindTip(scope, getInfo)
    local win = self
    local function enter()
        if win.Config.Tooltip.Enabled == false then return end
        win._tipId = win._tipId + 1
        if win._tipShown then
            if win._tipOwner == scope then return end
            win:_hideTip()
        end
        local id = win._tipId
        task.delay(win.Config.Tooltip.Delay or 0.55, function()
            if win._tipId ~= id or not win.Visible or win.Minimized or win._searchOpen then return end
            if not scope.Parent then return end
            local ok, title, body = pcall(getInfo)
            if not ok or not title then return end
            win._tipOwner = scope
            win:_showTip(scope, title, body)
        end)
    end
    local function leave()
        win._tipId = win._tipId + 1
        local id = win._tipId
        task.delay(0.06, function()
            if win._tipId == id then win:_hideTip() end
        end)
    end
    local function bind(g)
        if g:IsA("GuiObject") then
            g.MouseEnter:Connect(enter)
            g.MouseLeave:Connect(leave)
        end
    end
    bind(scope)
    for _, d in ipairs(scope:GetDescendants()) do bind(d) end
    scope.InputBegan:Connect(function(input)
        if isPress(input) then
            win._tipId = win._tipId + 1
            win:_hideTip()
        end
    end)
end

----------------------------------------------------------------
-- Busqueda global
----------------------------------------------------------------
function WindowMT:OpenSearch(text)
    if not self._setSearchOpen then return end
    self._setSearchOpen(true)
    if text ~= nil and self._searchBox then self._searchBox.Text = tostring(text) end
end
function WindowMT:CloseSearch()
    if self._setSearchOpen then self._setSearchOpen(false) end
end
function WindowMT:ToggleSearch()
    if self._setSearchOpen then self._setSearchOpen(not self._searchOpen) end
end
function WindowMT:SetSearch(text)
    if self._searchBox then self._searchBox.Text = tostring(text or "") end
end

-- navega hasta un resultado: abre la tab, expande la seccion, hace scroll y resalta el elemento
function WindowMT:_goTo(e)
    self:CloseSearch()
    local tab = e.tab
    if not tab or not tab._btn or not tab._btn.Parent then return end
    self:SelectTab(tab)
    local sec = e.section
    if sec and not sec.Open then sec:SetOpen(true) end
    if e.kind == "Tab" then return end
    local target = e.frame
    task.delay(0.32, function()
        if not target or not target.Parent then return end
        local s = math.max(self._scale.Scale, 0.05)
        local anchor = target
        local sc = sec and sec._scroller
        if sc and e.kind == "Element" and target:IsDescendantOf(sc) then
            local y2 = (target.AbsolutePosition.Y - sc.AbsolutePosition.Y) / s + sc.CanvasPosition.Y - 4
            tween(sc, { CanvasPosition = Vector2.new(0, math.max(y2, 0)) }, 0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            anchor = sec._frame
        end
        local page = tab._page
        local y = (anchor.AbsolutePosition.Y - page.AbsolutePosition.Y) / s + page.CanvasPosition.Y - 10
        tween(page, { CanvasPosition = Vector2.new(0, math.max(y, 0)) }, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

        local st = create("UIStroke", {
            Color = Theme.Accent, Thickness = 1.5, Transparency = 0,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = target,
        })
        task.delay(0.5, function()
            if st.Parent then tween(st, { Transparency = 1 }, 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In) end
        end)
        task.delay(1.6, function() if st.Parent then st:Destroy() end end)
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
        self:_hideTip()
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

    -- Mientras se minimiza la ventana se ancla por arriba: asi solo se anima el tamano y la barra
    -- superior queda quieta (con anclaje central habia que mover y redimensionar a la vez, y el
    -- redondeo de pixeles la hacia temblar).
    local function anchorTop(top)
        if (self._topAnchored or false) == top then return end
        local p = root.Position
        if top then
            local shift = self._eh * self._scale.Scale / 2
            self._minShift = shift
            root.AnchorPoint = Vector2.new(0.5, 0)
            root.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset - shift)
        else
            local shift = self._eh * self._scale.Scale / 2
            self._minShift = 0
            root.AnchorPoint = Vector2.new(0.5, 0.5)
            root.Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset + shift)
        end
        self._topAnchored = top
    end

    anchorTop(true)
    if state then
        self:CloseSearch()
        self:_hideTip()
        self._grip.Visible = false
        tween(root, { Size = UDim2.fromOffset(self._ew, MIN_H) }, dur, SOFT, SOFT_DIR)
        tweenThen(clip, { Size = UDim2.new(1, 0, 0, 0) }, dur, function()
            if id == self._minId and self.Minimized then clip.Visible = false end
        end, SOFT, SOFT_DIR)
    else
        clip.Visible = true
        tween(root, { Size = UDim2.fromOffset(self._ew, self._eh) }, dur, SOFT, SOFT_DIR)
        tweenThen(clip, { Size = UDim2.new(1, 0, 0, bh) }, dur, function()
            if id == self._minId and not self.Minimized then
                anchorTop(false)
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
function WindowMT:SetToggleKey(k)
    self.ToggleKey = keyFromValue(k)
    self:_saveState()
end
function WindowMT:SetFloatingButton(v)
    self._floating.Visible = v and true or false
    self:_saveState()
end
function WindowMT:ResetPosition()
    local shift = self.Minimized and (self._minShift or 0) or 0
    tween(self._root, { Position = UDim2.new(0.5, 0, 0.5, -shift) }, 0.3, SOFT, SOFT_DIR)
    task.delay(0.35, function() self:_saveState() end)
end

-- escala extra de la interfaz (0.6 - 1.4), se guarda entre ejecuciones
function WindowMT:SetUIScale(s)
    self._userScale = math.clamp(tonumber(s) or 1, 0.6, 1.4)
    self._fit()
    self:_saveState()
end

-- Guarda (con debounce) el estado de la interfaz para la proxima vez que se ejecute el script
function WindowMT:_saveState(patch)
    if not self._remember then return end
    local st = self._state
    if type(patch) == "table" then
        for k, v in pairs(patch) do st[k] = v end
    end
    self._saveSeq = (self._saveSeq or 0) + 1
    local seq = self._saveSeq
    task.delay(0.6, function()
        if seq ~= self._saveSeq or not self.Gui or not self.Gui.Parent then return end
        local p = self._root.Position
        st.w, st.h = math.floor(self._w + 0.5), math.floor(self._h + 0.5)
        st.x, st.y = math.floor(p.X.Offset + 0.5), math.floor(p.Y.Offset + (self._minShift or 0) + 0.5)
        local fp = self._floating.Position
        st.fx, st.fy = math.floor(fp.X.Offset + 0.5), math.floor(fp.Y.Offset + 0.5)
        st.float = self._floating.Visible
        st.key = keyName(self.ToggleKey)
        st.scale = self._userScale
        if ensureFolder(self.ConfigFolder) then writeJSON(self._statePath, st) end
    end)
end

-- borra el estado guardado (tamano, posicion, tema...) y vuelve a los valores del script
function WindowMT:ResetLayout()
    self._state = {}
    if hasFS and typeof(delfile) == "function" and fileExists(self._statePath) then
        pcall(delfile, self._statePath)
    end
    local W = self.Config.Window
    self._userScale = math.clamp(tonumber(W.UIScale) or 1, 0.6, 1.4)
    self:Resize(W.Width, W.Height)
    self:ResetPosition()
end

-- fn se ejecuta al descargar la interfaz (util para detener loops del script)
function WindowMT:OnUnload(fn)
    if type(fn) == "function" then table.insert(self._unload, fn) end
end

function WindowMT:Destroy()
    if self._destroyed then return end
    self._destroyed = true
    for _, fn in ipairs(self._unload) do pcall(fn) end
    for _, c in ipairs(self._conns) do c:Disconnect() end
    for _, flag in ipairs(self._flags) do Library.Flags[flag] = nil end
    local i = table.find(Library.Windows, self)
    if i then table.remove(Library.Windows, i) end
    Library._binding = false
    if self.Gui then self.Gui:Destroy() end
end
WindowMT.Unload = WindowMT.Destroy

function Library:OnUnload(fn)
    local w = Library.Windows[#Library.Windows]
    if w then w:OnUnload(fn) end
end

function Library:Unload()
    for i = #Library.Windows, 1, -1 do Library.Windows[i]:Destroy() end
end

----------------------------------------------------------------
-- Dialogo modal (confirmaciones). Buttons = { { Name, Style = "Primary"|"Danger"|"Default", Callback } }
----------------------------------------------------------------
function WindowMT:Dialog(o)
    o = o or {}
    if self._dialog then self._dialog.Close() end
    if self.Minimized then self:Minimize(false) end
    if not self.Visible then self:SetVisible(true) end
    self:_hideTip()

    local overlay = create("TextButton", {
        Text = "", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Outline,
        BackgroundTransparency = 1, ZIndex = 60, Parent = self._root,
    }, { corner(self.Config.Window.Corner) })
    local card = create("CanvasGroup", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 10),
        Size = UDim2.fromOffset(math.min(o.Width or 320, self._ew - 40), 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Element, GroupTransparency = 1, ZIndex = 61, Parent = overlay,
    }, { corner(10), stroke(Theme.Stroke, 1, 0.2), padding(18, 16, 18, 16), listLayout(10) })
    label({
        Text = o.Title or "Confirm", Font = Fonts.Title, TextSize = 15, ZIndex = 62,
        TextTruncate = Enum.TextTruncate.None, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 1, Parent = card,
    })
    if o.Content and o.Content ~= "" then
        label({
            Text = o.Content, TextSize = 12, TextColor3 = Theme.Muted, ZIndex = 62, RichText = true,
            TextTruncate = Enum.TextTruncate.None, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0), LayoutOrder = 2, Parent = card,
        })
    end
    local row = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), LayoutOrder = 3, ZIndex = 62, Parent = card,
    }, { listLayout(8, { FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right }) })

    local closed = false
    local dlg = {}
    local function close()
        if closed then return end
        closed = true
        if self._dialog == dlg then self._dialog = nil end
        tween(overlay, { BackgroundTransparency = 1 }, 0.15)
        tween(card, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, 8) }, 0.15)
        task.delay(0.18, function() overlay:Destroy() end)
    end
    dlg.Close = close

    local buttons = o.Buttons or { { Name = "Cancel" }, { Name = "Confirm", Style = "Primary", Callback = o.Callback } }
    for i, b in ipairs(buttons) do
        local style = b.Style or (b.Primary and "Primary") or "Default"
        local fillKey = style == "Danger" and "Error" or (style == "Primary" and "Accent" or "Row")
        local hiKey = style == "Primary" and "AccentHi" or (style == "Danger" and "Error" or "RowHover")
        local btn = create("TextButton", {
            Text = tostring(b.Name or "OK"), Font = Fonts.Bold, TextSize = 12,
            TextColor3 = style == "Default" and Theme.Text or (style == "Danger" and Theme.Text or Theme.OnAccent),
            BackgroundColor3 = Theme[fillKey], Size = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.X,
            LayoutOrder = i, ZIndex = 63, Parent = row,
        }, { corner(7), padding(16, 0, 16, 0) })
        hover(btn, fillKey, hiKey)
        pressFx(btn)
        btn.Activated:Connect(function()
            close()
            if b.Callback then task.spawn(b.Callback) end
        end)
    end
    overlay.InputBegan:Connect(function(input)
        if o.Dismissible == false or not isPress(input) then return end
        -- solo cierra con clicks fuera de la tarjeta (InputObject.Position usa el mismo espacio que AbsolutePosition)
        local m = input.Position
        local p, s = card.AbsolutePosition, card.AbsoluteSize
        local inside = m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
        if not inside then close() end
    end)

    tween(overlay, { BackgroundTransparency = 0.35 }, 0.2)
    tween(card, { GroupTransparency = 0, Position = UDim2.fromScale(0.5, 0.5) }, 0.25,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    self._dialog = dlg
    return dlg
end

function Library:Dialog(o)
    local w = Library.Windows[#Library.Windows]
    if w then return w:Dialog(o) end
end

function WindowMT:GetTab(name)
    for _, t in ipairs(self.Tabs) do if t.Name == name then return t end end
    return nil
end

function WindowMT:Notify(o)
    if type(o) == "string" then o = { Title = o } end
    local ncfg = self.Config.Notify
    local kind = o.Type or "Info"
    local colorKeys = { Info = "Accent", Success = "Success", Warning = "Warning", Error = "Error" }
    local color = o.Color or Theme[colorKeys[kind] or "Accent"]
    local duration = pick(o.Duration, ncfg.Duration)
    local right = self._notifRight ~= false
    local hidden = UDim2.new(right and 1 or -1, right and 40 or -40, 0, 0)

    -- limite de notificaciones visibles: se cierra la mas vieja
    local toasts = self._toasts
    while #toasts >= math.max(ncfg.Max or 5, 1) do
        local oldest = table.remove(toasts, 1)
        oldest.Close()
    end

    self._notifOrder = (self._notifOrder or 0) + 1
    local wrap = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = self._notifOrder, Parent = self._notifs,
    })
    local toast = create("TextButton", {
        Text = "", Position = hidden, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Element, ZIndex = 151, Parent = wrap,
    }, { corner(9), stroke(Theme.Stroke, 1, 0.3) })

    -- icono del tipo: circulo tenue del color + simbolo
    local badge = create("Frame", {
        Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(24, 24), BackgroundColor3 = color,
        BackgroundTransparency = 0.82, ZIndex = 152, Parent = toast,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    if kind == "Success" then
        checkIcon(badge, color, 153).show(true, color, 0)
    elseif kind == "Error" then
        crossIcon(badge, 9, color, 153)
    else
        label({
            Text = kind == "Warning" and "!" or "i", Font = Fonts.Title, TextSize = 14, TextColor3 = color,
            TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 153, Parent = badge,
        })
    end

    local content = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 152, Parent = toast,
    }, { padding(46, 11, 14, 11), listLayout(3) })

    local titleLbl = label({ Text = o.Title or "Cookies Hub", Font = Fonts.Bold, TextSize = 13,
        TextTruncate = Enum.TextTruncate.None, TextWrapped = true, RichText = true, ZIndex = 152,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = content })
    local bodyLbl = label({ Text = o.Content or "", TextSize = 12, TextColor3 = Theme.Muted,
        TextTruncate = Enum.TextTruncate.None, TextWrapped = true, RichText = true, ZIndex = 152,
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        Visible = o.Content ~= nil and o.Content ~= "", LayoutOrder = 2, Parent = content })
    local fill, fillTween
    if duration and duration > 0 then
        local track = create("Frame", {
            Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Theme.Input, LayoutOrder = 3, ZIndex = 152, Parent = content,
        }, { corner(1) })
        fill = create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color, ZIndex = 153, Parent = track },
            { corner(1) })
    end

    local closed, hovered = false, false
    local handle = {}
    local function close()
        if closed then return end
        closed = true
        local i = table.find(toasts, handle)
        if i then table.remove(toasts, i) end
        if not toast.Parent then return end
        tweenThen(toast, { Position = hidden }, 0.28, function() wrap:Destroy() end,
            Enum.EasingStyle.Quart, Enum.EasingDirection.In)
    end
    handle.Close = close
    function handle:SetTitle(t) titleLbl.Text = tostring(t) end
    function handle:SetContent(t)
        bodyLbl.Text = tostring(t or "")
        bodyLbl.Visible = bodyLbl.Text ~= ""
    end
    table.insert(toasts, handle)

    toast.Activated:Connect(function()
        if o.Callback then task.spawn(o.Callback) end
        close()
    end)
    toast.MouseEnter:Connect(function()
        hovered = true
        tween(toast, { BackgroundColor3 = Theme.Row }, 0.12)
        if fillTween and ncfg.PauseOnHover ~= false then fillTween:Pause() end
    end)
    toast.MouseLeave:Connect(function()
        hovered = false
        tween(toast, { BackgroundColor3 = Theme.Element }, 0.12)
        if fillTween and not closed then fillTween:Play() end
    end)

    tween(toast, { Position = UDim2.new(0, 0, 0, 0) }, 0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    if fill then
        fillTween = TweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })
        fillTween:Play()
        task.spawn(function()
            local left = duration
            while left > 0 and not closed do
                local dt = task.wait(0.1)
                if not (hovered and ncfg.PauseOnHover ~= false) then left = left - dt end
            end
            close()
        end)
    end
    return handle
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

local function cleanName(name)
    name = tostring(name or ""):gsub("[\\/:%*%?\"<>|]", ""):match("^%s*(.-)%s*$")
    return name
end

function WindowMT:SaveConfig(name)
    if not hasFS then return false, "Tu executor no soporta writefile" end
    name = cleanName(name)
    if name == "" then return false, "Escribe un nombre" end
    if not ensureFolder(self.ConfigFolder) then return false, "No se pudo crear la carpeta" end
    local data = {}
    for flag, obj in pairs(Library.Flags) do
        if obj.Savable ~= false then data[flag] = serialize(obj) end
    end
    if not writeJSON(self.ConfigFolder .. "/" .. name .. ".json", data) then
        return false, "No se pudo escribir el archivo"
    end
    return true
end

function WindowMT:LoadConfig(name)
    if not hasFS then return false, "Tu executor no soporta readfile" end
    local path = self.ConfigFolder .. "/" .. cleanName(name) .. ".json"
    if not fileExists(path) then return false, "No existe esa config" end
    local data = readJSON(path)
    if not data then return false, "Config dañada" end
    for flag, value in pairs(data) do
        local obj = Library.Flags[flag]
        if obj and obj.Savable ~= false then pcall(deserialize, obj, value) end
    end
    return true
end

function WindowMT:DeleteConfig(name)
    if not hasFS or typeof(delfile) ~= "function" then return false, "Tu executor no soporta delfile" end
    local path = self.ConfigFolder .. "/" .. cleanName(name) .. ".json"
    if not fileExists(path) then return false, "No existe esa config" end
    local ok = pcall(delfile, path)
    if ok and self._state.autoload == cleanName(name) then self:SetAutoload(nil) end
    return ok, not ok and "No se pudo borrar" or nil
end

-- config que se carga sola al abrir el script (nil para desactivar)
function WindowMT:SetAutoload(name)
    self._state.autoload = name and cleanName(name) or nil
    self:_saveState()
end
function WindowMT:GetAutoload() return self._state.autoload end

function WindowMT:LoadAutoloadConfig()
    local name = self._state.autoload
    if not name or self._autoloaded then return false end
    self._autoloaded = true
    local ok, err = self:LoadConfig(name)
    if ok then
        self:Notify({ Title = "Config loaded", Content = "Auto-loaded <b>" .. name .. "</b>", Type = "Success" })
    else
        self:Notify({ Title = "Auto-load failed", Content = tostring(err), Type = "Warning" })
    end
    return ok
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
    local function iconColor() return o.IconColor or Theme.Accent end

    self._navOrder = self._navOrder + 1
    local btn = create("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Row,
        BackgroundTransparency = 1, LayoutOrder = self._navOrder, Parent = self._nav,
    }, { corner(8) })
    local indicator = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(3, 6), BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1, Parent = btn,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })

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
            if tint then c = active and iconColor() or Theme.Dim end
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
        ScrollBarThickness = IS_TOUCH and 4 or 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.55,
        ScrollingDirection = Enum.ScrollingDirection.Y, Parent = self._content,
    }, { padding(pad, pad, pad + 2, pad), listLayout(gap) })
    page:GetPropertyChangedSignal("CanvasPosition"):Connect(function() win:_hideTip() end)

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
        tween(btn, { BackgroundTransparency = active and 0 or 1, BackgroundColor3 = active and Theme.AccentSoft or Theme.Row }, 0.18)
        tween(indicator, { BackgroundTransparency = active and 0 or 1, Size = UDim2.fromOffset(3, active and 18 or 6) }, 0.25,
            Enum.EasingStyle.Back, Enum.EasingDirection.Out)
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

    tab._repaint = function()
        btn.BackgroundColor3 = tab.Active and Theme.AccentSoft or Theme.Row
        btn.BackgroundTransparency = tab.Active and 0 or 1
        indicator.BackgroundTransparency = tab.Active and 0 or 1
        indicator.Size = UDim2.fromOffset(3, tab.Active and 18 or 6)
        nameLabel.TextColor3 = tab.Active and Theme.Text or Theme.Dim
        paintIcon(tab.Active, false)
    end

    function tab:Refresh()
        for _, s in ipairs(self._sections) do s:_apply() end
    end
    function tab:Select() win:SelectTab(self) end
    function tab:SetIcon(spec) buildIcon(spec) end
    function tab:SetName(n) self.Name = tostring(n) nameLabel.Text = self.Name end
    function tab:SetVisible(v) btn.Visible = v ~= false end
    -- etiqueta pequena a la derecha de la tab ("NEW", 3...). nil o "" la quita
    local badge
    function tab:SetBadge(text)
        local show = text ~= nil and tostring(text) ~= ""
        if not badge then
            if not show then return end
            badge = label({
                Text = "", Font = Fonts.Bold, TextSize = 10, TextColor3 = Theme.OnAccent,
                TextXAlignment = Enum.TextXAlignment.Center, TextTruncate = Enum.TextTruncate.None,
                BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent, AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(0, 16),
                AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3, Parent = btn,
            })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = badge })
            create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), Parent = badge })
        end
        badge.Text = show and tostring(text) or ""
        badge.Visible = show
        nameLabel.Size = UDim2.new(1, show and -80 or -50, 1, 0)
    end
    if o.Badge then tab:SetBadge(o.Badge) end
    function tab:ScrollToTop() page.CanvasPosition = Vector2.new(0, 0) end

    local tabEntry = { kind = "Tab", tab = tab }
    table.insert(self._index, tabEntry)
    function tab:Destroy()
        local i = table.find(win.Tabs, self)
        if i then table.remove(win.Tabs, i) end
        local ei = table.find(win._index, tabEntry)
        if ei then table.remove(win._index, ei) end
        for k = #win._index, 1, -1 do
            if win._index[k].tab == self then table.remove(win._index, k) end
        end
        btn:Destroy() page:Destroy()
        if win.ActiveTab == self then win.ActiveTab = nil if win.Tabs[1] then win:SelectTab(win.Tabs[1]) end end
    end

    btn.MouseEnter:Connect(function()
        if not tab.Active then tween(btn, { BackgroundTransparency = 0.6 }, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        if not tab.Active then tween(btn, { BackgroundTransparency = 1 }, 0.15) end
    end)
    btn.Activated:Connect(function()
        win:SelectTab(tab)
        win:_saveState({ tab = tab.Name })
    end)
    pressFx(btn, iconHolder, 0.88)
    -- en modo compacto solo se ve el icono: el tooltip muestra el nombre de la tab
    self:_bindTip(btn, function()
        if win._compact then return tab.Name end
        return nil
    end)

    table.insert(self.Tabs, tab)
    tab:_setCompact(self._compact == true)
    if self._single then tab:_setSingle(true) end
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    elseif not self._tabRestored and self._state.tab == name then
        -- vuelve a abrir la ultima tab que el usuario tenia seleccionada
        self._tabRestored = true
        self:SelectTab(tab)
    end
    return tab
end

function WindowMT:SelectTab(tab)
    if type(tab) == "string" then
        for _, t in ipairs(self.Tabs) do if t.Name == tab then tab = t break end end
    end
    if type(tab) ~= "table" then return end
    if self._searchOpen then self:CloseSearch() end
    self:_hideTip()
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
    }, { corner(scfg.Corner), stroke(Theme.Stroke, 1, 0.45), padding(10, 10, 10, 10), listLayout(0),
        create("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.new(1, 1, 1), rgb(222, 222, 222)) }) })
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
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 1, 0.5, 0),
            Size = UDim2.fromOffset(3, 14), BackgroundColor3 = accent, Parent = header,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
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
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.35,
        LayoutOrder = 1, Parent = inner,
    }, { create("UIGradient", { Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.5), NumberSequenceKeypoint.new(1, 1),
    }) }) })
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
    local secEntry = { kind = "Section", tab = self, section = section, frame = frame }
    table.insert(win._index, secEntry)
    function section:Destroy()
        local i = table.find(self.Tab._sections, self)
        if i then table.remove(self.Tab._sections, i) end
        for k = #win._index, 1, -1 do
            local e = win._index[k]
            if e == secEntry or e.section == self then table.remove(win._index, k) end
        end
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

-- borde sutil de las filas: les da definicion sobre el fondo de la seccion y se ilumina con el hover
local ROW_STROKE = 0.72
local function rowStroke(parent)
    local s = stroke(Theme.Stroke, 1, ROW_STROKE)
    s.Parent = parent
    return s
end

-- noHover: el elemento maneja su propio hover (p.ej. botones Primary/Danger)
function SectionMT:_row(height, clickable, o, noHover)
    local parent, order = self:_slot(o)
    local props = {
        Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Row,
        LayoutOrder = order, Parent = parent,
    }
    if clickable then props.Text = "" end
    local r = create(clickable and "TextButton" or "Frame", props, { corner(self.Window.Config.Element.Corner) })
    local st = rowStroke(r)
    if clickable and not noHover then hover(r, "Row", "RowHover") end
    r.MouseEnter:Connect(function() tween(st, { Transparency = 0.45 }, 0.12) end)
    r.MouseLeave:Connect(function() tween(st, { Transparency = ROW_STROKE }, 0.12) end)
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
        RichText = o.RichText == true, Font = o.Bold and Fonts.Bold or Fonts.Body,
        TextXAlignment = o.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
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
    }, { corner(self.Window.Config.Element.Corner), padding(12, 10, 12, 10), listLayout(3), rowStroke() })
    local t = label({ Text = o.Title or "", Font = Fonts.Bold, TextSize = 13,
        TextTruncate = Enum.TextTruncate.None, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 1, Parent = box })
    local c = label({ Text = o.Content or "", TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true,
        RichText = o.RichText == true,
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
    -- colores leidos en vivo para que sigan al tema actual
    local function normal()
        if style == "Danger" then return Theme.Error end
        return primary and Theme.Accent or Theme.Row
    end
    local function over()
        if style == "Danger" then return Theme.Error:Lerp(rgb(255, 255, 255), 0.18) end
        return primary and Theme.AccentHi or Theme.RowHover
    end
    local function textColor() return style == "Danger" and Theme.Text or (primary and Theme.OnAccent or Theme.Text) end

    local hasDesc = o.Description and o.Description ~= ""
    local b = self:_row(hasDesc and 46 or self:_eh(o), true, o, true)
    b.BackgroundColor3 = normal()
    bindTheme(b, "BackgroundColor3", style == "Danger" and "Error" or (primary and "Accent" or "Row"))

    local name = o.Name or "Button"
    local nameLbl = label({
        Text = name, Font = Fonts.Bold, TextSize = 13, TextColor3 = textColor(),
        TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(8, hasDesc and 5 or 0), Size = UDim2.new(1, -16, hasDesc and 0 or 1, hasDesc and 20 or 0),
        Parent = b,
    })
    if hasDesc then
        label({ Text = o.Description, TextSize = 11, TextColor3 = primary and textColor() or Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(8, 25),
            Size = UDim2.new(1, -16, 0, 14), Parent = b })
    end
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = over() }, 0.15) end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = normal() }, 0.15) end)
    pressFx(b, nil, 0.98)
    if primary then sheen(b, 0.14) end

    local obj = { Type = "Button" }
    decorate(self, obj, b, o)

    -- Confirm = true (o un texto) pide un segundo click antes de ejecutar el callback
    local armed, armId = false, 0
    local confirmText = type(o.Confirm) == "string" and o.Confirm or "Click again to confirm"
    local function disarm()
        armed = false
        nameLbl.Text = name
        tween(b, { BackgroundColor3 = normal() }, 0.2)
    end
    function obj:Click()
        if obj.Enabled == false then return end
        if o.Confirm and not armed then
            armed = true
            armId = armId + 1
            local id = armId
            nameLbl.Text = confirmText
            b.BackgroundColor3 = over()
            task.delay(2.5, function() if armed and id == armId then disarm() end end)
            return
        end
        if armed then disarm() end
        b.BackgroundColor3 = over()
        tween(b, { BackgroundColor3 = normal() }, 0.25)
        fire(obj, o)
    end
    function obj:SetText(t)
        name = tostring(t)
        if not armed then nameLbl.Text = name end
    end
    obj._repaint = function()
        b.BackgroundColor3 = normal()
        nameLbl.TextColor3 = textColor()
    end
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
    local section = self
    local function onColor() return o.Color or Theme.Accent end
    local checkbox = o.Style == "Checkbox"
    local sw, knob, check, swStroke
    if checkbox then
        -- variante compacta: casilla con check
        swStroke = stroke(Theme.Stroke, 1, 0.2)
        sw = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Theme.Input, Parent = r,
        }, { corner(5), swStroke })
        check = checkIcon(sw, Theme.OnAccent)
    else
        sw = create("Frame", {
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(38, 20), BackgroundColor3 = Theme.Input, Parent = r,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(Theme.Stroke, 1, 0.4) })
        knob = create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0),
            Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Theme.Muted, Parent = sw,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    end

    local obj = { Type = "Toggle", Value = false }
    decorate(self, obj, r, o)
    function obj:Set(v, silent)
        v = v and true or false
        local animate = obj._ready and 0.22 or 0
        obj.Value = v
        tween(sw, { BackgroundColor3 = v and onColor() or Theme.Input }, animate)
        if checkbox then
            tween(swStroke, { Color = v and onColor() or Theme.Stroke }, animate)
            check.show(v, Theme.OnAccent, animate)
        else
            tween(knob, {
                AnchorPoint = Vector2.new(v and 1 or 0, 0.5),
                Position = v and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                BackgroundColor3 = v and Theme.Text or Theme.Muted,
            }, animate, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:Toggle(silent) obj:Set(not obj.Value, silent) end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    -- toggle:AddKeybind({ Default = "F", Mode = "Toggle" | "Hold", Flag = "..." })
    -- agrega una tecla dentro de la misma fila que enciende/apaga el toggle
    function obj:AddKeybind(ko)
        if obj.Keybind then return obj.Keybind end
        ko = type(ko) == "table" and ko or { Default = ko }
        local swW = checkbox and 18 or 38
        local chip = create("TextButton", {
            Text = "None", Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.Muted,
            BackgroundColor3 = Theme.Input, AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -(swW + 18), 0.5, 0), Size = UDim2.fromOffset(0, 20),
            AutomaticSize = Enum.AutomaticSize.X, ZIndex = 3, Parent = r,
        }, { corner(5), stroke(Theme.Stroke, 1, 0.3), padding(8, 0, 8, 0) })
        nameLbl.Size = UDim2.new(1, -(swW + 92), nameLbl.Size.Y.Scale, nameLbl.Size.Y.Offset)
        local kb = {
            Type = "Keybind", Value = Enum.KeyCode.Unknown, Mode = ko.Mode == "Hold" and "Hold" or "Press",
            Active = false, Enabled = true, Frame = chip, Name = o.Name or "Toggle", Toggle = obj,
        }
        kb._callback = function(state)
            if not obj.Enabled then return end
            if kb.Mode == "Hold" then obj:Set(state == true) else obj:Toggle() end
        end
        function kb:Set(key)
            kb.Value = keyFromValue(key)
            chip.Text = keyName(kb.Value)
            chip.TextColor3 = kb.Value == Enum.KeyCode.Unknown and Theme.Dim or Theme.Muted
            if ko.Changed then emit(ko.Changed, kb.Value) end
        end
        function kb:Get() return kb.Value end
        function kb:SetMode(m) kb.Mode = m == "Hold" and "Hold" or "Press" end
        chip.MouseEnter:Connect(function() tween(chip, { TextColor3 = Theme.Text }, 0.12) end)
        chip.MouseLeave:Connect(function()
            if not Library._binding then tween(chip, { TextColor3 = Theme.Muted }, 0.12) end
        end)
        chip.Activated:Connect(function()
            if not obj.Enabled or Library._binding then return end
            Library._binding = true
            chip.Text = "..."
            chip.TextColor3 = Theme.Accent
            local conn
            conn = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                conn:Disconnect()
                if input.KeyCode == Enum.KeyCode.Escape then kb:Set(kb.Value)
                elseif input.KeyCode == Enum.KeyCode.Backspace then kb:Set(Enum.KeyCode.Unknown)
                else kb:Set(input.KeyCode) end
                task.defer(function() Library._binding = false end)
            end)
        end)
        kb:Set(ko.Default or Enum.KeyCode.Unknown)
        table.insert(section.Window._keybinds, kb)
        if ko.Flag then section:_register(ko.Flag, kb) end
        obj.Keybind = kb
        return kb
    end

    obj:Set(o.Default or false, true)
    obj._ready = true
    r.Activated:Connect(function() if obj.Enabled then obj:Set(not obj.Value) end end)
    if knob then
        r.MouseButton1Down:Connect(function()
            if obj.Enabled then tween(knob, { Size = UDim2.fromOffset(19, 14) }, 0.12) end
        end)
        local function release() tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.2, Enum.EasingStyle.Back) end
        r.MouseButton1Up:Connect(release)
        r.MouseLeave:Connect(release)
    else
        pressFx(r, sw, 0.85)
    end
    self:_register(o.Flag, obj)
    if o.Keybind ~= nil then obj:AddKeybind(o.Keybind) end
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
        Position = UDim2.fromOffset(12, 37), Size = UDim2.new(1, -24, 0, 4),
        BackgroundColor3 = Theme.Input, Parent = r,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local fill = create("Frame", {
        Size = UDim2.fromScale(0, 1), BackgroundColor3 = o.Color or Theme.Accent, Parent = track,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), create("UIGradient", {
        Transparency = NumberSequence.new(0.45, 0),
    }) })
    local knobRing = stroke(o.Color or Theme.Accent, 2)
    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(1, 0.5),
        Size = UDim2.fromOffset(12, 12), BackgroundColor3 = Theme.Text, ZIndex = 2, Parent = fill,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), knobRing })
    local hit = create("TextButton", {
        Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 26),
        Size = UDim2.new(1, -12, 0, 26), Parent = r,
    })

    local obj = { Type = "Slider", Value = min }
    decorate(self, obj, r, o)
    hit.MouseEnter:Connect(function() if not obj._dragging then tween(knob, { Size = UDim2.fromOffset(14, 14) }, 0.12) end end)
    hit.MouseLeave:Connect(function() if not obj._dragging then tween(knob, { Size = UDim2.fromOffset(12, 12) }, 0.12) end end)
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
        tween(knob, { Size = UDim2.fromOffset(16, 16) }, 0.12)
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

-- Dropdown: caja de seleccion con "chip" + flecha, lista con check/checkbox y buscador automatico.
-- Opciones: Name, Options, Default, Multi, Placeholder, Searchable (nil = automatico segun cantidad), MaxVisible
function SectionMT:AddDropdown(o)
    o = o or {}
    local multi = o.Multi == true
    local options = o.Options or {}
    local dcfg = self.Window.Config.Dropdown or {}
    local ITEM_H = IS_TOUCH and 30 or 26
    local SEARCH_H = 26
    local MAX_VISIBLE = o.MaxVisible or dcfg.MaxVisible or 5
    local H = self:_eh(o)
    local ecorner = self.Window.Config.Element.Corner
    local placeholder = o.Placeholder or "Select..."
    local filter = ""

    local function hasSearch()
        if o.Searchable ~= nil then return o.Searchable == true end
        return #options >= (dcfg.SearchThreshold or 7)
    end

    local parent, order = self:_slot(o)
    local holder = create("Frame", {
        Size = UDim2.new(1, 0, 0, H), BackgroundColor3 = Theme.Row, ClipsDescendants = true,
        LayoutOrder = order, Parent = parent,
    }, { corner(ecorner), rowStroke() })
    local head = create("TextButton", {
        Text = "", Size = UDim2.new(1, 0, 0, H), BackgroundTransparency = 1, Parent = holder,
    })
    local nameLbl = label({ Text = o.Name or "Dropdown", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.44, -12, 1, 0), Parent = head })

    -- "caja" de seleccion: deja claro que es un desplegable
    local chipStroke = stroke(Theme.Stroke, 1, 0.2)
    local chip = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(0.56, -8, 0, H - 10), BackgroundColor3 = Theme.Input, Parent = head,
    }, { corner(5), chipStroke })
    local valueLabel = label({
        Text = placeholder, TextSize = 12, TextColor3 = Theme.Dim, Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -34, 1, 0), Parent = chip,
    })
    create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0.5, 0), Size = UDim2.new(0, 1, 1, -10),
        BackgroundColor3 = Theme.Stroke, BackgroundTransparency = 0.4, Parent = chip,
    })
    local arrow = create("Frame", {
        BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(12, 12), Parent = chip,
    })
    local arrowBars = {}
    for _, s in ipairs({ { 45, -2 }, { -45, 2 } }) do
        table.insert(arrowBars, create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, s[2], 0.5, 0),
            Size = UDim2.fromOffset(7, 2), Rotation = s[1], BackgroundColor3 = Theme.Muted, Parent = arrow,
        }, { corner(1) }))
    end

    -- panel desplegable
    local panel = create("Frame", {
        Position = UDim2.fromOffset(8, H + 6), Size = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = Theme.Input, Parent = holder,
    }, { corner(6), stroke(Theme.Stroke, 1, 0.5) })
    local sStroke = stroke(Theme.Stroke, 1, 0.3)
    local searchBar = create("Frame", {
        Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, SEARCH_H),
        BackgroundColor3 = Theme.Row, Visible = false, Parent = panel,
    }, { corner(5), sStroke })
    local sIcoBox = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 6, 0.5, 0),
        Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Parent = searchBar,
    })
    local sIco = searchIcon(sIcoBox, 12, Theme.Dim)
    local sbox = create("TextBox", {
        Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1,
        Font = Fonts.Body, TextSize = 12, TextColor3 = Theme.Text, ClearTextOnFocus = false, Text = "",
        PlaceholderText = "Search...", PlaceholderColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = searchBar,
    })
    local sclear = create("TextButton", {
        Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0),
        Size = UDim2.fromOffset(18, 18), BackgroundTransparency = 1, Visible = false, Parent = searchBar,
    })
    local paintX = crossIcon(sclear, 7, Theme.Muted)
    sclear.MouseEnter:Connect(function() paintX(Theme.Text, 0.12) end)
    sclear.MouseLeave:Connect(function() paintX(Theme.Muted, 0.12) end)
    sbox.Focused:Connect(function()
        tween(sStroke, { Color = Theme.Accent, Transparency = 0 }, 0.15)
        sIco.set(Theme.Accent, 0.15)
    end)
    sbox.FocusLost:Connect(function()
        tween(sStroke, { Color = Theme.Stroke, Transparency = 0.3 }, 0.15)
        sIco.set(Theme.Dim, 0.15)
    end)

    local list = create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, 0),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Dim, ScrollBarImageTransparency = 0.5, Parent = panel,
    }, { listLayout(3) })
    local emptyLbl = label({
        Text = "No options", TextSize = 12, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(4, 4), Size = UDim2.new(1, -8, 0, ITEM_H), Visible = false, Parent = panel,
    })

    local obj = { Type = "Dropdown", Value = multi and {} or nil, Options = options, Open = false }
    decorate(self, obj, holder, o, head)
    local buttons = {}

    local function visibleCount()
        local n = 0
        for _, opt in ipairs(options) do
            local b = buttons[opt]
            if b and b.button.Visible then n = n + 1 end
        end
        return n
    end
    local function listHeight()
        local n = math.min(math.max(visibleCount(), 1), MAX_VISIBLE)
        return n * ITEM_H + (n - 1) * 3
    end
    local function resize()
        local searching = hasSearch()
        local sh = searching and (SEARCH_H + 4) or 0
        local lh = listHeight()
        local ph = 8 + sh + lh
        searchBar.Visible = searching
        list.Position = UDim2.fromOffset(4, 4 + sh)
        emptyLbl.Position = UDim2.fromOffset(4, 4 + sh)
        tween(holder, { Size = UDim2.new(1, 0, 0, obj.Open and (H + 6 + ph + 8) or H) }, 0.22, SOFT, SOFT_DIR)
        tween(panel, { Size = UDim2.new(1, -16, 0, ph) }, 0.22, SOFT, SOFT_DIR)
        tween(list, { Size = UDim2.new(1, -8, 0, lh) }, 0.22, SOFT, SOFT_DIR)
        tween(arrow, { Rotation = obj.Open and 180 or 0 }, 0.22, SOFT, SOFT_DIR)
        tween(chipStroke, { Color = obj.Open and Theme.Accent or Theme.Stroke, Transparency = obj.Open and 0 or 0.2 }, 0.2)
        for _, bar in ipairs(arrowBars) do
            tween(bar, { BackgroundColor3 = obj.Open and Theme.Accent or Theme.Muted }, 0.2)
        end
    end
    local function applyFilter()
        local q = string.lower(filter)
        for _, opt in ipairs(options) do
            local b = buttons[opt]
            if b then
                b.button.Visible = q == "" or string.find(string.lower(tostring(opt)), q, 1, true) ~= nil
            end
        end
        list.CanvasPosition = Vector2.new(0, 0)
        local none = visibleCount() == 0
        emptyLbl.Text = (#options > 0 and q ~= "") and "No results" or "No options"
        emptyLbl.Visible = none
        resize()
    end
    sbox:GetPropertyChangedSignal("Text"):Connect(function()
        filter = sbox.Text:match("^%s*(.-)%s*$") or ""
        sclear.Visible = sbox.Text ~= ""
        applyFilter()
    end)
    sclear.Activated:Connect(function()
        sbox.Text = ""
        sbox:CaptureFocus()
    end)

    local function isSelected(opt)
        if multi then return table.find(obj.Value, opt) ~= nil end
        return obj.Value == opt
    end
    local function paintItem(b, sel)
        tween(b.button, { BackgroundTransparency = sel and 0 or 1, BackgroundColor3 = sel and Theme.AccentSoft or Theme.RowHover }, 0.15)
        tween(b.bar, { BackgroundTransparency = sel and 0 or 1 }, 0.15)
        tween(b.label, { TextColor3 = sel and Theme.Accent or Theme.Text }, 0.15)
        if b.markBox then
            tween(b.markBox, { BackgroundColor3 = sel and Theme.Accent or Theme.Input }, 0.15)
            tween(b.markStroke, { Color = sel and Theme.Accent or Theme.Stroke }, 0.15)
        end
        b.check.show(sel, multi and Theme.OnAccent or Theme.Accent, 0.15)
    end
    local function paint()
        for opt, b in pairs(buttons) do paintItem(b, isSelected(opt)) end
        if multi then
            local names = {}
            for _, v in ipairs(obj.Value) do table.insert(names, tostring(v)) end
            valueLabel.Text = #names > 0 and table.concat(names, ", ") or placeholder
            valueLabel.TextColor3 = #names > 0 and Theme.Text or Theme.Dim
        else
            valueLabel.Text = obj.Value ~= nil and tostring(obj.Value) or placeholder
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
        if not obj.Open then
            sbox:ReleaseFocus()
            if sbox.Text ~= "" then sbox.Text = "" end -- reinicia el filtro al cerrar
        end
        resize()
        if obj.Open and hasSearch() and not IS_TOUCH then
            task.defer(function() if obj.Open then sbox:CaptureFocus() end end)
        end
    end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    local function toggleOption(opt)
        if multi then
            local idx = table.find(obj.Value, opt)
            if idx then table.remove(obj.Value, idx) else table.insert(obj.Value, opt) end
            paint()
            fire(obj, o, current())
        else
            -- AllowNull = true: hacer click en la opcion ya elegida la deselecciona
            if o.AllowNull and obj.Value == opt then obj:Set(nil) else obj:Set(opt) end
            obj:SetOpen(false)
        end
    end
    function obj:Clear(silent) obj:Set(multi and {} or nil, silent) end

    function obj:Refresh(newOptions, keepValue)
        for _, b in pairs(buttons) do b.button:Destroy() end
        buttons = {}
        options = newOptions or {}
        obj.Options = options
        if sbox.Text ~= "" then sbox.Text = "" end
        filter = ""
        for i, opt in ipairs(options) do
            local btn = create("TextButton", {
                Text = "", Size = UDim2.new(1, 0, 0, ITEM_H), BackgroundColor3 = Theme.RowHover,
                BackgroundTransparency = 1, LayoutOrder = i, Parent = list,
            }, { corner(5) })
            local bar = create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(2, 12),
                BackgroundColor3 = Theme.Accent, BackgroundTransparency = 1, Parent = btn,
            }, { corner(1) })
            local lbl = label({ Text = tostring(opt), TextSize = 12, Position = UDim2.fromOffset(12, 0),
                Size = UDim2.new(1, -38, 1, 0), Parent = btn })
            local mark = create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
                Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, Parent = btn,
            })
            local markBox, markStroke
            if multi then
                markBox = mark
                markBox.BackgroundTransparency = 0
                markBox.BackgroundColor3 = Theme.Input
                markStroke = stroke(Theme.Stroke, 1, 0)
                corner(4).Parent = markBox
                markStroke.Parent = markBox
            end
            local check = checkIcon(mark, Theme.Accent)
            local item = { button = btn, label = lbl, bar = bar, markBox = markBox, markStroke = markStroke, check = check }
            btn.MouseEnter:Connect(function()
                if not isSelected(opt) then tween(btn, { BackgroundTransparency = 0 }, 0.12) end
            end)
            btn.MouseLeave:Connect(function()
                if not isSelected(opt) then tween(btn, { BackgroundTransparency = 1 }, 0.12) end
            end)
            btn.Activated:Connect(function() toggleOption(opt) end)
            buttons[opt] = item
        end
        if keepValue then obj:Set(obj.Value, true) else obj:Set(multi and {} or nil, true) end
        applyFilter()
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
        obj:SetOpen(not obj.Open)
    end)
    head.MouseEnter:Connect(function()
        tween(holder, { BackgroundColor3 = Theme.RowHover }, 0.15)
        if not obj.Open then tween(chipStroke, { Color = Theme.Dim }, 0.15) end
    end)
    head.MouseLeave:Connect(function()
        tween(holder, { BackgroundColor3 = Theme.Row }, 0.15)
        if not obj.Open then tween(chipStroke, { Color = Theme.Stroke }, 0.15) end
    end)

    obj:Refresh(options)
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
        Type = "Keybind", Value = Enum.KeyCode.Unknown, Mode = o.Mode or "Press", Name = o.Name or "Keybind",
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
    }, { corner(ecorner), rowStroke() })
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
    decorate(self, obj, holder, o, head)

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

----------------------------------------------------------------
-- Elementos extra
----------------------------------------------------------------
local RunService = game:GetService("RunService")

local function toClipboard(text)
    local fn = setclipboard or toclipboard or (syn and syn.write_clipboard)
    if typeof(fn) ~= "function" then return false end
    return (pcall(fn, tostring(text)))
end

-- Segmented: grupo de opciones tipo "pastillas" con indicador deslizante
-- Opciones: Name, Options, Default, Flag, Callback
function SectionMT:AddSegmented(o)
    o = o or {}
    local options = o.Options or { "A", "B" }
    local hasName = o.Name ~= nil and o.Name ~= ""
    local barY = hasName and 30 or 6
    local r = self:_row(barY + 32, false, o)
    local nameLbl
    if hasName then
        nameLbl = label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 0, 30), Parent = r })
    end
    local bar = create("Frame", {
        Position = UDim2.fromOffset(8, barY), Size = UDim2.new(1, -16, 0, 26),
        BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(6) })
    local pill = create("Frame", {
        Size = UDim2.new(1 / math.max(#options, 1), -4, 1, -4), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.AccentSoft, Parent = bar,
    }, { corner(5), stroke(Theme.Accent, 1, 0.55) })
    sheen(pill, 0.1)
    local labels = {}

    local obj = { Type = "Segmented", Value = nil, Options = options }
    decorate(self, obj, r, o)
    local function paint(animate)
        local n = math.max(#options, 1)
        local idx = table.find(options, obj.Value)
        pill.Visible = idx ~= nil
        if idx then
            tween(pill, { Position = UDim2.new((idx - 1) / n, 2, 0, 2), Size = UDim2.new(1 / n, -4, 1, -4) },
                animate and 0.22 or 0, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        end
        for i, l in ipairs(labels) do
            tween(l, { TextColor3 = i == idx and Theme.Accent or Theme.Muted }, animate and 0.15 or 0)
        end
    end
    local function build()
        for _, l in ipairs(labels) do l.Parent:Destroy() end
        labels = {}
        local n = math.max(#options, 1)
        for i, opt in ipairs(options) do
            local b = create("TextButton", {
                Text = "", BackgroundTransparency = 1, Size = UDim2.new(1 / n, 0, 1, 0),
                Position = UDim2.fromScale((i - 1) / n, 0), ZIndex = 2, Parent = bar,
            })
            labels[i] = label({
                Text = tostring(opt), Font = Fonts.Bold, TextSize = 12, TextColor3 = Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = b,
            })
            b.MouseEnter:Connect(function()
                if obj.Value ~= opt then tween(labels[i], { TextColor3 = Theme.Text }, 0.12) end
            end)
            b.MouseLeave:Connect(function()
                if obj.Value ~= opt then tween(labels[i], { TextColor3 = Theme.Muted }, 0.12) end
            end)
            b.Activated:Connect(function()
                if obj.Enabled and obj.Value ~= opt then obj:Set(opt) end
            end)
        end
    end
    function obj:Set(v, silent)
        if not table.find(options, v) then return end
        obj.Value = v
        paint(obj._ready)
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:SetText(t) if nameLbl then nameLbl.Text = tostring(t) end end
    function obj:Refresh(newOptions)
        options = newOptions or {}
        obj.Options = options
        build()
        if not table.find(options, obj.Value) then obj.Value = options[1] end
        paint(false)
    end
    build()
    obj:Set(o.Default ~= nil and o.Default or options[1], true)
    obj._ready = true
    self:_register(o.Flag, obj)
    return obj
end

-- RangeSlider: dos manijas (minimo y maximo). Value = { min, max }
-- Opciones: Name, Min, Max, Increment, Default = { a, b }, Suffix, Flag, Callback
function SectionMT:AddRangeSlider(o)
    o = o or {}
    local min, max = o.Min or 0, o.Max or 100
    local inc = o.Increment or 1
    local suffix = o.Suffix or ""
    local decimals = (tostring(inc):match("%.(%d+)") or ""):len()
    local fmt = "%." .. decimals .. "f"

    local r = self:_row(self:_eh(o) + 16, false, o)
    local nameLbl = label({ Text = o.Name or "Range", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -130, 0, 30), Parent = r })
    local valLbl = label({
        Text = "", Font = Fonts.Bold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0), Size = UDim2.fromOffset(120, 30), Parent = r,
    })
    local track = create("Frame", {
        Position = UDim2.fromOffset(12, 37), Size = UDim2.new(1, -24, 0, 4), BackgroundColor3 = Theme.Input, Parent = r,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local fill = create("Frame", { BackgroundColor3 = o.Color or Theme.Accent, Parent = track },
        { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local function makeKnob()
        return create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(12, 12),
            BackgroundColor3 = Theme.Text, ZIndex = 2, Parent = track,
        }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }), stroke(o.Color or Theme.Accent, 2) })
    end
    local k1, k2 = makeKnob(), makeKnob()
    local hit = create("TextButton", {
        Text = "", BackgroundTransparency = 1, Position = UDim2.fromOffset(6, 26), Size = UDim2.new(1, -12, 0, 26), Parent = r,
    })

    local obj = { Type = "RangeSlider", Value = { min, max } }
    decorate(self, obj, r, o)
    local function snap(v)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        return tonumber(string.format(fmt, math.clamp(v, min, max)))
    end
    local function alpha(v) return (max == min) and 0 or (v - min) / (max - min) end
    local function render()
        local a, b = alpha(obj.Value[1]), alpha(obj.Value[2])
        local t = obj._dragging and 0.05 or (obj._ready and 0.15 or 0)
        tween(fill, { Position = UDim2.fromScale(a, 0), Size = UDim2.fromScale(b - a, 1) }, t, Enum.EasingStyle.Quad)
        tween(k1, { Position = UDim2.fromScale(a, 0.5) }, t, Enum.EasingStyle.Quad)
        tween(k2, { Position = UDim2.fromScale(b, 0.5) }, t, Enum.EasingStyle.Quad)
        valLbl.Text = string.format(fmt, obj.Value[1]) .. suffix .. "  -  " .. string.format(fmt, obj.Value[2]) .. suffix
    end
    function obj:Set(v, silent)
        if type(v) ~= "table" then return end
        local a, b = snap(tonumber(v[1]) or min), snap(tonumber(v[2]) or max)
        if a > b then a, b = b, a end
        obj.Value = { a, b }
        render()
        if not silent then fire(obj, o, { a, b }) end
    end
    function obj:Get() return { obj.Value[1], obj.Value[2] } end
    function obj:SetText(t) nameLbl.Text = tostring(t) end

    local active -- 1 o 2: manija que se esta arrastrando
    local function fromPos(pos)
        local a = math.clamp((pos.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = snap(min + (max - min) * a)
        local cur = obj.Value
        if active == 1 then
            v = math.min(v, cur[2])
            if v ~= cur[1] then obj:Set({ v, cur[2] }) end
        else
            v = math.max(v, cur[1])
            if v ~= cur[2] then obj:Set({ cur[1], v }) end
        end
    end
    dragger(hit, function(input)
        if not obj.Enabled then return end
        local a = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local d1, d2 = math.abs(a - alpha(obj.Value[1])), math.abs(a - alpha(obj.Value[2]))
        active = (d1 < d2 or (d1 == d2 and a < alpha(obj.Value[1]))) and 1 or 2
        obj._dragging = true
        self:_lockScroll(true)
        tween(active == 1 and k1 or k2, { Size = UDim2.fromOffset(16, 16) }, 0.12)
        fromPos(input.Position)
    end, function(i)
        if obj._dragging then fromPos(i.Position) end
    end, function()
        obj._dragging = false
        self:_lockScroll(false)
        tween(k1, { Size = UDim2.fromOffset(12, 12) }, 0.12)
        tween(k2, { Size = UDim2.fromOffset(12, 12) }, 0.12)
    end)

    local d = type(o.Default) == "table" and o.Default or { min, max }
    obj:Set(d, true)
    obj._ready = true
    self:_register(o.Flag, obj)
    return obj
end

-- Number: campo numerico con botones - / + (mantener presionado repite)
-- Opciones: Name, Min, Max, Increment, Default, Suffix, Flag, Callback
function SectionMT:AddNumber(o)
    o = o or {}
    local min, max = o.Min or -math.huge, o.Max or math.huge
    local inc = o.Increment or 1
    local suffix = o.Suffix or ""
    local decimals = (tostring(inc):match("%.(%d+)") or ""):len()
    local fmt = "%." .. decimals .. "f"

    local r = self:_row(self:_eh(o), false, o)
    local nameLbl = label({ Text = o.Name or "Number", Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -150, 1, 0), Parent = r })
    local holder = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(128, 24),
        BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(6), stroke(Theme.Stroke, 1, 0.3) })
    local function stepBtn(sign)
        local b = create("TextButton", {
            Text = sign > 0 and "+" or "-", Font = Fonts.Bold, TextSize = 14, TextColor3 = Theme.Muted,
            AnchorPoint = Vector2.new(sign > 0 and 1 or 0, 0), Position = UDim2.fromScale(sign > 0 and 1 or 0, 0),
            Size = UDim2.new(0, 26, 1, 0), BackgroundColor3 = Theme.Row, BackgroundTransparency = 1, Parent = holder,
        }, { corner(6) })
        b.MouseEnter:Connect(function() tween(b, { BackgroundTransparency = 0, TextColor3 = Theme.Accent }, 0.12) end)
        b.MouseLeave:Connect(function() tween(b, { BackgroundTransparency = 1, TextColor3 = Theme.Muted }, 0.12) end)
        return b
    end
    local minus, plus = stepBtn(-1), stepBtn(1)
    local box = create("TextBox", {
        Position = UDim2.fromOffset(26, 0), Size = UDim2.new(1, -52, 1, 0), BackgroundTransparency = 1,
        Font = Fonts.Bold, TextSize = 12, TextColor3 = Theme.Text, ClearTextOnFocus = false, Text = "", Parent = holder,
    })

    local obj = { Type = "Number", Value = 0 }
    decorate(self, obj, r, o)
    local function clean(v)
        v = math.clamp(tonumber(v) or obj.Value or 0, min, max)
        return tonumber(string.format(fmt, v))
    end
    function obj:Set(v, silent)
        v = clean(v)
        obj.Value = v
        if not box:IsFocused() then box.Text = string.format(fmt, v) .. suffix end
        if not silent then fire(obj, o, v) end
    end
    function obj:Get() return obj.Value end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    local function hold(btn, sign)
        local holding = 0
        btn.MouseButton1Down:Connect(function()
            if not obj.Enabled then return end
            holding = holding + 1
            local id = holding
            obj:Set(obj.Value + inc * sign)
            task.delay(0.35, function()
                while holding == id and obj.Enabled do
                    obj:Set(obj.Value + inc * sign)
                    task.wait(0.06)
                end
            end)
        end)
        local function stop() holding = holding + 1 end
        btn.MouseButton1Up:Connect(stop)
        btn.MouseLeave:Connect(stop)
    end
    hold(minus, -1)
    hold(plus, 1)
    box.Focused:Connect(function() box.Text = tostring(obj.Value) end)
    box.FocusLost:Connect(function()
        local n = tonumber(box.Text:match("-?%d+%.?%d*"))
        obj:Set(n or obj.Value)
        box.Text = string.format(fmt, obj.Value) .. suffix
    end)
    obj:Set(o.Default or (min > -math.huge and min or 0), true)
    self:_register(o.Flag, obj)
    return obj
end

-- PlayerDropdown: dropdown con los jugadores del servidor, se actualiza solo al entrar/salir alguien
-- Opciones: las mismas de AddDropdown + IncludeSelf (false), DisplayNames (false)
function SectionMT:AddPlayerDropdown(o)
    o = o or {}
    local function names()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if o.IncludeSelf or p ~= LocalPlayer then table.insert(list, p.Name) end
        end
        table.sort(list, function(a, b) return a:lower() < b:lower() end)
        return list
    end
    local opts = table.clone(o)
    opts.Options = names()
    opts.Name = o.Name or "Player"
    opts.Placeholder = o.Placeholder or "Select a player"
    local dd = self:AddDropdown(opts)
    dd.Type = "PlayerDropdown"
    dd.Savable = o.Savable == true -- los jugadores cambian entre servidores: no se guarda por defecto
    local win = self.Window
    local pending = false
    local function refresh()
        if pending then return end
        pending = true
        task.delay(0.25, function()
            pending = false
            if dd.Frame.Parent then dd:Refresh(names(), true) end
        end)
    end
    table.insert(win._conns, Players.PlayerAdded:Connect(refresh))
    table.insert(win._conns, Players.PlayerRemoving:Connect(refresh))
    function dd:GetPlayer()
        local v = dd.Value
        if type(v) == "table" then
            local list = {}
            for _, n in ipairs(v) do
                local p = Players:FindFirstChild(n)
                if p then table.insert(list, p) end
            end
            return list
        end
        return v and Players:FindFirstChild(v) or nil
    end
    return dd
end

-- Stat: fila de solo lectura "nombre ........ valor" (dinero, nivel, estado...)
-- Opciones: Name, Value, Color. Metodos: Set(valor), SetColor(color)
function SectionMT:AddStat(o)
    o = type(o) == "table" and o or { Name = o }
    local r = self:_row(self:_eh(o) - 4, false, o)
    local nameLbl = label({ Text = o.Name or "Stat", TextColor3 = Theme.Muted, Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.5, -12, 1, 0), Parent = r })
    local valLbl = label({
        Text = tostring(o.Value or "-"), Font = Fonts.Bold, TextColor3 = o.Color or Theme.Text, RichText = true,
        TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 0), Size = UDim2.new(0.5, -12, 1, 0), Parent = r,
    })
    local obj = { Type = "Stat", Value = o.Value, Savable = false }
    decorate(self, obj, r, o)
    function obj:Set(v)
        obj.Value = v
        valLbl.Text = tostring(v)
    end
    obj._repaint = function() end -- el valor no depende del tema
    function obj:Get() return obj.Value end
    function obj:SetColor(c) valLbl.TextColor3 = c end
    function obj:SetText(t) nameLbl.Text = tostring(t) end
    return obj
end

-- Alert: aviso destacado con color segun el tipo (Info, Success, Warning, Error)
-- Opciones: Type, Title, Content
function SectionMT:AddAlert(o)
    o = o or {}
    local parent, order = self:_slot(o)
    local keys = { Info = "Accent", Success = "Success", Warning = "Warning", Error = "Error" }
    local kind = keys[o.Type or "Info"] and (o.Type or "Info") or "Info"
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Row,
        LayoutOrder = order, Parent = parent,
    }, { corner(self.Window.Config.Element.Corner) })
    local st = stroke(Theme.Accent, 1, 0.55)
    st.Parent = box
    local bar = create("Frame", {
        Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = Theme.Accent, Parent = box,
    }, { corner(2) })
    local icon = label({
        Text = "i", Font = Fonts.Title, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center,
        Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 0.82,
        BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Accent, Parent = box,
    }, nil)
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = icon })
    local okMark = checkIcon(icon, Theme.Success)
    local textBox = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Parent = box,
    }, { padding(42, 10, 12, 10), listLayout(2) })
    local t = label({ Text = o.Title or "", Font = Fonts.Bold, TextSize = 13, TextWrapped = true,
        TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
        Visible = (o.Title or "") ~= "", LayoutOrder = 1, Parent = textBox })
    local c = label({ Text = o.Content or "", TextSize = 12, TextColor3 = Theme.Muted, TextWrapped = true, RichText = true,
        TextTruncate = Enum.TextTruncate.None, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0),
        Visible = (o.Content or "") ~= "", LayoutOrder = 2, Parent = textBox })

    local obj = { Frame = box, Type = "Alert" }
    local function paint()
        local col = Theme[keys[kind]]
        box.BackgroundColor3 = Theme.Row:Lerp(col, 0.08)
        st.Color = col
        bar.BackgroundColor3 = col
        icon.BackgroundColor3 = col
        icon.TextColor3 = col
        icon.Text = (kind == "Warning" or kind == "Error") and "!" or (kind == "Success" and "" or "i")
        okMark.show(kind == "Success", col, 0)
    end
    function obj:Set(title, content)
        if title ~= nil then t.Text = tostring(title) t.Visible = t.Text ~= "" end
        if content ~= nil then c.Text = tostring(content) c.Visible = c.Text ~= "" end
    end
    function obj:SetType(k) if keys[k] then kind = k paint() end end
    function obj:SetVisible(v) box.Visible = v ~= false end
    function obj:Destroy() box:Destroy() end
    paint()
    -- se repinta junto con el resto al cambiar de tema
    table.insert(self.Window._objects, { _repaint = paint })
    return obj
end

-- Image: imagen con texto opcional debajo. Opciones: Image, Height, ScaleType, Caption, Corner
function SectionMT:AddImage(o)
    o = type(o) == "table" and o or { Image = o }
    local parent, order = self:_slot(o)
    local kind, value = resolveIcon(o.Image, "")
    local box = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
        LayoutOrder = order, Parent = parent,
    }, { listLayout(4) })
    local img = create("ImageLabel", {
        Image = kind == "image" and value or "", Size = UDim2.new(1, 0, 0, o.Height or 120),
        ScaleType = o.ScaleType or Enum.ScaleType.Crop, BackgroundTransparency = 0,
        BackgroundColor3 = Theme.Input, LayoutOrder = 1, Parent = box,
    }, { corner(o.Corner or self.Window.Config.Element.Corner) })
    local cap
    if o.Caption then
        cap = label({ Text = o.Caption, TextSize = 11, TextColor3 = Theme.Dim, TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.new(1, 0, 0, 14), LayoutOrder = 2, Parent = box })
    end
    return {
        Frame = box, Image = img,
        SetImage = function(_, id)
            local k, v = resolveIcon(id, "")
            img.Image = k == "image" and v or ""
        end,
        SetCaption = function(_, t) if cap then cap.Text = tostring(t) end end,
        SetVisible = function(_, v) box.Visible = v ~= false end,
        Destroy = function() box:Destroy() end,
    }
end

-- CopyField: texto (link, codigo, id...) con boton para copiarlo al portapapeles
-- Opciones: Name, Text
function SectionMT:AddCopyField(o)
    o = o or {}
    local r = self:_row(self:_eh(o), false, o)
    local hasName = o.Name ~= nil and o.Name ~= ""
    if hasName then
        label({ Text = o.Name, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.35, -12, 1, 0), Parent = r })
    end
    local field = create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.new(hasName and 0.65 or 1, hasName and -8 or -16, 0, 24), BackgroundColor3 = Theme.Input, Parent = r,
    }, { corner(6), stroke(Theme.Stroke, 1, 0.3) })
    local txt = label({ Text = tostring(o.Text or ""), TextSize = 12, TextColor3 = Theme.Muted,
        Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -70, 1, 0), Parent = field })
    local btn = create("TextButton", {
        Text = "Copy", Font = Fonts.Bold, TextSize = 11, TextColor3 = Theme.OnAccent,
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -3, 0.5, 0), Size = UDim2.fromOffset(56, 18),
        BackgroundColor3 = Theme.Accent, Parent = field,
    }, { corner(5) })
    hover(btn, "Accent", "AccentHi")
    pressFx(btn)
    sheen(btn, 0.14)
    local obj = { Type = "CopyField", Value = tostring(o.Text or ""), Savable = false }
    decorate(self, obj, r, o)
    function obj:Set(t)
        obj.Value = tostring(t)
        txt.Text = obj.Value
    end
    obj._repaint = function() end
    function obj:Get() return obj.Value end
    btn.Activated:Connect(function()
        local ok = toClipboard(obj.Value)
        btn.Text = ok and "Copied!" or "Error"
        task.delay(1.2, function() if btn.Parent then btn.Text = "Copy" end end)
        emit(o.Callback, obj.Value)
    end)
    return obj
end

----------------------------------------------------------------
-- Extras de la ventana: marca de agua (FPS / ping) y lista de keybinds
----------------------------------------------------------------
-- key: nombre con el que se guarda su posicion en el estado de la interfaz
local function floatingPanel(win, pos, key)
    local saved = key and win._state[key]
    if type(saved) == "table" and type(saved[1]) == "number" and type(saved[2]) == "number" then
        -- se limita a la pantalla actual por si la resolucion cambio desde la ultima vez
        local vp = win._getViewport()
        pos = UDim2.fromOffset(math.clamp(saved[1], 0, math.max(vp.X - 60, 0)), math.clamp(saved[2], 0, math.max(vp.Y - 30, 0)))
    end
    local f = create("Frame", {
        Position = pos, Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Theme.Element, ZIndex = 120, Parent = win.Gui,
    }, { corner(8), stroke(Theme.Stroke, 1, 0.25) })
    -- linea de acento arriba, misma firma que la ventana
    create("Frame", {
        Size = UDim2.new(1, -16, 0, 1), Position = UDim2.fromOffset(8, 0), BackgroundColor3 = Theme.Accent,
        ZIndex = 121, Parent = f,
    }, { create("UIGradient", { Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(0.6, 0.7), NumberSequenceKeypoint.new(1, 1),
    }) }) })
    local startInput, startPos
    dragger(f, function(input)
        startInput, startPos = input.Position, f.Position
    end, function(i)
        local d = i.Position - startInput
        local vp = win._getViewport()
        local x = math.clamp(startPos.X.Offset + d.X, 0, math.max(vp.X - f.AbsoluteSize.X, 0))
        local y = math.clamp(startPos.Y.Offset + d.Y, 0, math.max(vp.Y - f.AbsoluteSize.Y, 0))
        f.Position = UDim2.fromOffset(x, y)
    end, function()
        if key then win:_saveState({ [key] = { math.floor(f.Position.X.Offset), math.floor(f.Position.Y.Offset) } }) end
    end)
    f.Active = true
    return f
end

-- Watermark: { Text = "Cookies Hub", ShowFPS = true, ShowPing = true, ShowTime = false }
function WindowMT:CreateWatermark(o)
    o = o or {}
    if self._watermark then self._watermark:Destroy() end
    local f = floatingPanel(self, o.Position or UDim2.fromOffset(16, 64), "wmPos")
    create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12), Parent = f })
    local row = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 28), AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 121, Parent = f,
    }, { listLayout(8, { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center }) })
    create("Frame", {
        Size = UDim2.fromOffset(6, 6), BackgroundColor3 = Theme.Accent, LayoutOrder = 0, ZIndex = 121, Parent = row,
    }, { create("UICorner", { CornerRadius = UDim.new(1, 0) }) })
    local title = label({
        Text = tostring(o.Text or self.Config.Window.Title), Font = Fonts.Bold, TextSize = 12, ZIndex = 121,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 28), TextTruncate = Enum.TextTruncate.None,
        LayoutOrder = 1, Parent = row,
    })
    local info = label({
        Text = "", TextSize = 12, TextColor3 = Theme.Muted, ZIndex = 121, AutomaticSize = Enum.AutomaticSize.X,
        Size = UDim2.fromOffset(0, 28), TextTruncate = Enum.TextTruncate.None, LayoutOrder = 2, Parent = row,
    })
    local frames, last, alive = 0, os.clock(), true
    local conn = RunService.Heartbeat:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - last < 0.5 then return end
        local parts = {}
        if o.ShowFPS ~= false then table.insert(parts, math.floor(frames / (now - last) + 0.5) .. " fps") end
        if o.ShowPing ~= false then
            local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
            if ok and ping then table.insert(parts, math.floor(ping * 1000 + 0.5) .. " ms") end
        end
        if o.ShowTime then table.insert(parts, os.date("%H:%M")) end
        info.Text = #parts > 0 and ("|  " .. table.concat(parts, "  |  ")) or ""
        frames, last = 0, now
    end)
    table.insert(self._conns, conn)
    local wm = { Frame = f }
    function wm:SetText(t) title.Text = tostring(t) end
    function wm:SetVisible(v) f.Visible = v ~= false end
    function wm:Destroy()
        if not alive then return end
        alive = false
        conn:Disconnect()
        f:Destroy()
    end
    self._watermark = wm
    return wm
end

-- KeybindList: panel flotante con las teclas asignadas y si estan activas
function WindowMT:CreateKeybindList(o)
    o = o or {}
    if self._kbList then self._kbList:Destroy() end
    local vp = self._getViewport()
    local f = floatingPanel(self, o.Position or UDim2.fromOffset(16, math.floor(vp.Y / 2 - 60)), "kbPos")
    local body = create("Frame", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(180, 0), AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 121, Parent = f,
    }, { padding(10, 8, 10, 8), listLayout(4) })
    label({ Text = o.Title or "Keybinds", Font = Fonts.Bold, TextSize = 12, ZIndex = 121,
        Size = UDim2.new(1, 0, 0, 18), LayoutOrder = 0, Parent = body })
    local rows = {}
    local win, alive = self, true
    local function rowFor(i)
        local r = rows[i]
        if r then return r end
        local fr = create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18), LayoutOrder = i,
            ZIndex = 121, Parent = body })
        r = {
            frame = fr,
            name = label({ Text = "", TextSize = 11, ZIndex = 121, Size = UDim2.new(1, -60, 1, 0), Parent = fr }),
            key = label({ Text = "", Font = Fonts.Bold, TextSize = 10, ZIndex = 121, TextXAlignment = Enum.TextXAlignment.Center,
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(52, 16),
                BackgroundTransparency = 0, BackgroundColor3 = Theme.Input, Parent = fr }),
        }
        create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = r.key })
        rows[i] = r
        return r
    end
    local function update()
        local n = 0
        for _, kb in ipairs(win._keybinds) do
            if kb.Value and kb.Value ~= Enum.KeyCode.Unknown and (o.ShowAll or kb.Toggle or kb.Mode ~= "Press") then
                n = n + 1
                local r = rowFor(n)
                local on
                if kb.Toggle then on = kb.Toggle.Value == true else on = kb.Active == true end
                r.frame.Visible = true
                r.name.Text = tostring(kb.Name or "Keybind")
                r.name.TextColor3 = on and Theme.Text or Theme.Dim
                r.key.Text = keyName(kb.Value)
                r.key.TextColor3 = on and Theme.Accent or Theme.Muted
            end
        end
        for i = n + 1, #rows do rows[i].frame.Visible = false end
        f.Visible = alive and (n > 0 or o.ShowEmpty == true) and (o.Visible ~= false)
    end
    local t0 = 0
    local conn = RunService.Heartbeat:Connect(function(dt)
        t0 = t0 + dt
        if t0 >= 0.2 then t0 = 0 update() end
    end)
    table.insert(self._conns, conn)
    update()
    local list = { Frame = f }
    function list:SetVisible(v) o.Visible = v ~= false update() end
    function list:Destroy()
        if not alive then return end
        alive = false
        conn:Disconnect()
        f:Destroy()
    end
    self._kbList = list
    return list
end

function WindowMT:CreateSettingsTab(name, icon)
    local win = self
    local tab = self:CreateTab(name or "Settings", icon or "S")

    ----------------------------------------------------------------
    -- Apariencia: tema, color de acento y escala
    ----------------------------------------------------------------
    local look = tab:CreateSection("Appearance")
    local accentPicker
    look:AddDropdown({
        Name = "Theme", Options = Library:GetThemes(), Default = Library.CurrentTheme,
        Tooltip = "Cambia los colores de toda la interfaz al instante",
        Callback = function(v)
            if not v then return end
            Library:SetTheme(v)
            win._state.accent = nil
            win:_saveState({ theme = v })
            if accentPicker then accentPicker:Set(Theme.Accent, true) end
        end,
    })
    local accentSeq = 0
    accentPicker = look:AddColorPicker({
        Name = "Accent Color", Default = Theme.Accent,
        Presets = {
            rgb(245, 194, 12), rgb(232, 140, 70), rgb(255, 105, 140), rgb(170, 120, 255),
            rgb(98, 146, 255), rgb(64, 200, 230), rgb(120, 214, 140),
        },
        Callback = function(c)
            -- debounce: repintar todo en cada movimiento del selector seria muy pesado
            accentSeq = accentSeq + 1
            local seq = accentSeq
            task.delay(0.08, function()
                if seq ~= accentSeq then return end
                Library:SetAccent(c)
                win:_saveState({ accent = toHex(c) })
            end)
        end,
    })
    local scaleSeq = 0
    look:AddSlider({
        Name = "UI Scale", Min = 0.6, Max = 1.4, Increment = 0.05, Suffix = "x",
        Default = win._userScale or 1,
        Callback = function(v)
            scaleSeq = scaleSeq + 1
            local seq = scaleSeq
            task.delay(0.3, function()
                if seq == scaleSeq then win:SetUIScale(v) end
            end)
        end,
    })

    ----------------------------------------------------------------
    -- Interfaz
    ----------------------------------------------------------------
    local ui = tab:CreateSection("Interface")
    ui:AddKeybind({
        Name = "Menu Key", Default = self.ToggleKey,
        Changed = function(key)
            if key ~= Enum.KeyCode.Unknown then win:SetToggleKey(key) end
        end,
    })
    ui:AddToggle({
        Name = "Floating Button", Default = self._floating.Visible,
        Callback = function(v) win:SetFloatingButton(v) end,
    })
    ui:AddToggle({
        Name = "Animations", Default = Library.Config.Animations,
        Callback = function(v)
            Library.Config.Animations = v
            win:_saveState({ anim = v })
        end,
    })
    ui:AddToggle({
        Name = "Tooltips", Default = win.Config.Tooltip.Enabled ~= false,
        Description = "Muestra la descripción completa al dejar el mouse encima",
        Callback = function(v)
            win.Config.Tooltip.Enabled = v
            if not v then win:_hideTip() end
            win:_saveState({ tips = v })
        end,
    })
    ui:AddToggle({
        Name = "Watermark", Default = win._state.watermark == true,
        Tooltip = "Muestra FPS y ping en una etiqueta flotante",
        Callback = function(v)
            if v then win:CreateWatermark() elseif win._watermark then win._watermark:Destroy() win._watermark = nil end
            win:_saveState({ watermark = v })
        end,
    })
    ui:AddToggle({
        Name = "Keybind List", Default = win._state.kblist == true,
        Tooltip = "Muestra las teclas asignadas y si estan activas",
        Callback = function(v)
            if v then win:CreateKeybindList() elseif win._kbList then win._kbList:Destroy() win._kbList = nil end
            win:_saveState({ kblist = v })
        end,
    })
    if win._state.watermark == true then win:CreateWatermark() end
    if win._state.kblist == true then win:CreateKeybindList() end
    ui:AddSlider({
        Name = "Animation Speed", Min = 0.25, Max = 3, Increment = 0.25, Suffix = "x",
        Default = Library.Config.AnimationSpeed,
        Callback = function(v)
            Library.Config.AnimationSpeed = v
            win:_saveState({ speed = v })
        end,
    })
    local a, b = ui:AddColumns(2)
    a:AddButton({
        Name = "Reset Position",
        Callback = function()
            win:ResetPosition()
            win:Notify({ Title = "Layout", Content = "Window position reset" })
        end,
    })
    b:AddButton({
        Name = "Reset Layout",
        Tooltip = "Vuelve al tamaño, posición y escala originales",
        Callback = function()
            win:ResetLayout()
            win:Notify({ Title = "Layout", Content = "Size, position and scale restored" })
        end,
    })
    ui:AddButton({
        Name = "Unload UI", Style = "Danger",
        Callback = function()
            win:Dialog({
                Title = "Unload Cookies Hub?",
                Content = "The menu will close and every feature will stop. You will need to run the script again.",
                Buttons = {
                    { Name = "Cancel" },
                    { Name = "Unload", Style = "Danger", Callback = function() win:Destroy() end },
                },
            })
        end,
    })

    ----------------------------------------------------------------
    -- Configs
    ----------------------------------------------------------------
    local cfg = tab:CreateSection("Configs")
    local cfgName = ""
    local picker, nameBox, autoLbl
    local function refreshAuto()
        if autoLbl then
            local n = win:GetAutoload()
            autoLbl:SetText(n and ("Auto-load: <b>" .. n .. "</b>") or "Auto-load: none")
        end
    end
    local function notifyResult(ok, okTitle, content, err)
        win:Notify({ Title = ok and okTitle or "Error", Content = ok and content or err,
            Type = ok and "Success" or "Error" })
    end

    nameBox = cfg:AddTextBox({ Name = "Name", Placeholder = "my config", Callback = function(t) cfgName = t end })
    cfg:AddButton({
        Name = "Save Config", Primary = true,
        Callback = function()
            local ok, err = win:SaveConfig(cfgName)
            notifyResult(ok, "Config saved", cfgName, err)
            if ok and picker then picker:Refresh(win:GetConfigs(), true) end
        end,
    })
    picker = cfg:AddDropdown({
        Name = "Configs", Options = win:GetConfigs(), Placeholder = "Select a config",
        Callback = function(v)
            if v and nameBox then
                nameBox:Set(v, true)
                cfgName = v
            end
        end,
    })
    local function selected()
        local sel = picker:Get()
        if not sel then win:Notify({ Title = "Config", Content = "Select a config first", Type = "Warning" }) end
        return sel
    end
    local c1, c2 = cfg:AddColumns(2)
    c1:AddButton({
        Name = "Load",
        Callback = function()
            local sel = selected()
            if not sel then return end
            local ok, err = win:LoadConfig(sel)
            notifyResult(ok, "Config loaded", sel, err)
        end,
    })
    c2:AddButton({
        Name = "Delete", Style = "Danger", Confirm = "Confirm delete",
        Callback = function()
            local sel = selected()
            if not sel then return end
            local ok, err = win:DeleteConfig(sel)
            notifyResult(ok, "Config deleted", sel, err)
            if ok then
                picker:Refresh(win:GetConfigs())
                refreshAuto()
            end
        end,
    })
    c1:AddButton({
        Name = "Set Auto-load",
        Tooltip = "Esta config se cargará sola cada vez que ejecutes el script",
        Callback = function()
            local sel = selected()
            if not sel then return end
            win:SetAutoload(sel)
            refreshAuto()
            win:Notify({ Title = "Auto-load", Content = "<b>" .. sel .. "</b> will load automatically", Type = "Success" })
        end,
    })
    c2:AddButton({
        Name = "Clear Auto-load",
        Callback = function()
            win:SetAutoload(nil)
            refreshAuto()
        end,
    })
    autoLbl = cfg:AddLabel({ Text = "", RichText = true })
    refreshAuto()
    cfg:AddButton({
        Name = "Refresh List",
        Callback = function() picker:Refresh(win:GetConfigs(), true) end,
    })
    if not hasFS then
        cfg:AddLabel("Tu executor no soporta archivos: guardar/cargar está desactivado.")
    end

    -- la pestaña de ajustes suele crearse al final: en ese punto todos los flags ya existen
    task.delay(0.5, function()
        if not win._destroyed then win:LoadAutoloadConfig() end
    end)
    return tab
end

Library.new = function(opts) return Library:CreateWindow(opts) end

return Library
