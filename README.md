# 🍪 Cookies Hub

Librería de UI para Roblox escrita en Luau, más un **Key System** opcional que usa el mismo tema visual.

| Archivo | Qué es | Versión |
| --- | --- | --- |
| `CookiesLib.lua` | Librería de UI (ventana, pestañas, secciones, elementos, temas, configs, búsqueda, notificaciones, diálogos) | **3.5.0** |
| `Cookieskeysystem.lua` | Ventana de verificación de keys (lista local, URL remota, función propia o KeyForge) | **2.0.0** |
| `CookiesDemo.lua` | Menú de prueba con todos los elementos | — |

**Lo que incluye la UI:** ventana arrastrable y redimensionable · intro animada · **8 temas con cambio en vivo** · color de acento personalizable · pestañas con icono y badges · secciones minimizables · búsqueda global (`Ctrl+F`) · tooltips automáticos · 20 tipos de elementos · diálogos de confirmación · notificaciones con iconos · guardado y **auto-carga** de configs · **recuerda tamaño, posición, pestaña y ajustes** entre ejecuciones · marca de agua con FPS/ping · lista de keybinds · diseño adaptable a PC y móvil.

---

## Contenido

1. [Novedades](#novedades)
2. [Requisitos](#requisitos)
3. [Inicio rápido](#inicio-rápido)
4. [Menú de prueba](#menú-de-prueba)
5. [Ventana](#ventana)
6. [Pestañas](#pestañas)
7. [Iconos (Lucide y otros)](#iconos-lucide-y-otros)
8. [Secciones](#secciones)
9. [Elementos](#elementos)
10. [Flags y configs](#flags-y-configs)
11. [Notificaciones](#notificaciones)
12. [Diálogos](#diálogos)
13. [Marca de agua y lista de keybinds](#marca-de-agua-y-lista-de-keybinds)
14. [Búsqueda global](#búsqueda-global)
15. [Tooltips](#tooltips)
16. [Temas](#temas)
17. [Configuración global](#configuración-global)
18. [Estado guardado de la interfaz](#estado-guardado-de-la-interfaz)
19. [Pestaña de ajustes](#pestaña-de-ajustes)
20. [Key System](#key-system)
21. [Ejemplo completo](#ejemplo-completo)
22. [Notas y solución de problemas](#notas-y-solución-de-problemas)
23. [Créditos y licencias](#créditos-y-licencias)

---

## Novedades

### CookiesLib 3.5.0

- **Temas en vivo:** `Library:SetTheme("Midnight")` repinta toda la interfaz al instante, sin recrearla. 8 temas incluidos y `Library:SetAccent(color)` para cambiar solo el acento.
- **Elementos nuevos:** `AddSegmented`, `AddRangeSlider`, `AddNumber`, `AddPlayerDropdown`, `AddStat`, `AddAlert`, `AddImage`, `AddCopyField`.
- **Mejoras de elementos:** botones con confirmación (`Confirm`), toggles tipo casilla (`Style = "Checkbox"`), toggles con tecla propia (`Keybind`), dropdowns con `AllowNull` y `:Clear()`, labels con `RichText`.
- **Diálogos** modales (`Window:Dialog`) y **notificaciones** rediseñadas: icono por tipo, pausa al pasar el mouse, máximo en pantalla, posición configurable y `SetTitle`/`SetContent`.
- **Recuerda la interfaz:** tamaño, posición, pestaña abierta, tema, acento, escala, tecla del menú y más se guardan entre ejecuciones.
- **Configs:** borrar configs y **auto-cargar** una al ejecutar el script.
- **Extras de ventana:** `CreateWatermark` (FPS/ping/hora), `CreateKeybindList`, badges en pestañas (`Tab:SetBadge`), escala de UI (`SetUIScale`), `OnUnload` para detener tus loops al descargar.
- **Estética más moderna:** el contenido vive en su propio panel (look por capas), esquinas más suaves, botones de la barra superior limpios, pestaña activa con fondo de acento e indicador que crece, cabeceras de sección con pastilla de acento, interruptores estilo iOS que se estiran al presionarlos, botones principales con brillo, slider con manija de aro, bordes sutiles en cada fila, scroll del color de acento, punto de "en línea" en el perfil, sombra y línea de acento con degradado.
- **Fluidez:** arrastre suavizado, búsqueda con debounce y nombres en caché, creación de instancias más rápida, intro que se puede saltar y que solo aparece una vez por partida.
- **Arreglos:** el botón rojo (`Danger`) ya no pierde el color al pasar el mouse; el menú ya no tiembla al minimizar.

Es **compatible** con los scripts hechos para la 3.4.0: no hace falta cambiar nada para actualizar.

### Key System 2.0.0

- Nuevo diseño: sombra, línea de acento, guía de 3 pasos, spinner al verificar, check animado al validar, avatar del jugador.
- `CaseSensitive`, `Steps`, `Theme`, `Accent`, `Shadow`, `OnFail`, `KeySystem.Prompt()` y `ks:SetStatus()`.
- El SDK de KeyForge se **precarga** al abrir (verificar es casi instantáneo) y nunca se descarga dos veces.
- La lista de `KeyUrl` se guarda en caché 30 s.
- Los errores de conexión **no cuentan** como intento fallido.
- El bloqueo por intentos **sobrevive** a re-ejecutar el script en la misma partida.

---

## Requisitos

La librería está pensada para ejecutarse en un **executor** del lado del cliente. Necesita `game:HttpGet` y `loadstring` para cargarse desde una URL. El resto de funciones del executor son **opcionales** y la librería se adapta si no existen:

| Función del executor | Para qué se usa | Si no existe |
| --- | --- | --- |
| `gethui` | Colocar la UI en un contenedor oculto | Usa `PlayerGui` |
| `writefile`, `readfile`, `isfolder`, `makefolder` | Configs, estado guardado de la interfaz, key recordada | Se desactivan (devuelven `false, mensaje`) |
| `isfile` | Comprobar si existe un archivo | Se intenta leer directamente |
| `listfiles` | Listar configs (`Window:GetConfigs()`) | La lista sale vacía |
| `delfile` | Borrar configs, `ResetLayout`, borrar key guardada | Borrar se desactiva |
| `getgenv` | Intro una vez por partida, bloqueo del Key System | Usa `_G` |
| `setclipboard` / `toclipboard` | `AddCopyField`, copiar enlaces del Key System | Muestra el texto |
| `getclipboard` / `fromclipboard` | Key System: botón **Paste** | El botón no aparece |
| `request` / `http_request` | Key System: abrir invitación de Discord | Solo copia el enlace |

La UI se crea con el nombre `CookiesHubUI` (y `CookiesKeyUI` el Key System). Si ya existe una con ese nombre, se destruye antes de crear la nueva.

---

## Inicio rápido

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/CookiesLib.lua"))()

local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main", "H")          -- "H" = icono de letra
local Section = Main:CreateSection("Combat")

Section:AddToggle({
    Name = "Auto Farm",
    Flag = "AutoFarm",
    Default = false,
    Keybind = "F",                                  -- opcional: F lo enciende/apaga
    Callback = function(value)
        print("Auto Farm:", value)
    end,
})

Window:CreateSettingsTab()   -- tema, color, escala, configs, etc.
```

Qué ocurre al ejecutarlo:

1. Se reproduce la **intro** (logo + barra de carga; un clic la salta) y después aparece la ventana.
2. Se muestra el **botón flotante** (logo) en el borde izquierdo. Un clic abre/cierra la ventana; también se puede arrastrar.
3. `RightShift` muestra/oculta la ventana y `Ctrl+F` abre la búsqueda.
4. La ventana oculta con la `x` **no se destruye**: se vuelve a abrir con la tecla o el botón flotante.
5. La próxima vez que ejecutes el script, la ventana aparece con el mismo tamaño, posición, pestaña y tema que dejaste.

`Library.new(opts)` es un alias de `Library:CreateWindow(opts)`.

---

## Menú de prueba

Un menú con **todos** los elementos conectados a notificaciones, para probar la librería sin escribir nada. Copia y pega en tu executor:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/CookiesDemo.lua"))()
```

**Qué puedes probar:**

| Pestaña | Contenido |
| --- | --- |
| **Inicio** | Aviso de bienvenida, estadísticas en vivo (FPS, ping, jugadores, hora, clicks), párrafo, label con colores, campo para copiar e imagen |
| **Controles** | Botones (normal, principal, con confirmación, en columnas, desactivado), toggles (simple, con tecla **F**, mantener **G**, casillas), sliders (uno cambia tu velocidad), cajas de texto, keybinds **K** y **J**, dropdowns (simple, opcional, múltiple, con buscador y de jugadores) |
| **Avanzado** | Selector de pastillas, slider de rango, campos numéricos, barra de progreso, selector de color, alertas, divisores, sección con scroll y sección cerrada |
| **Avisos** | Los 4 tipos de notificación, una que se actualiza sola, diálogos, marca de agua, lista de keybinds y badges |
| **Personalizar** | Tema, color de acento, título, tamaño de la ventana y botón para abrir el **Key System** de prueba (key: `COOKIES-DEMO`) |
| **Ajustes** | La pestaña de ajustes de la librería: tema, acento, escala, tecla del menú, configs y auto-carga |

Atajos: **RightShift** oculta o muestra el menú y **Ctrl+F** abre la búsqueda.

También sirve como ejemplo de código: cada elemento muestra cómo se usa. El script completo es este (es el mismo que `CookiesDemo.lua`):

<details>
<summary><b>Ver el script completo del menú de prueba</b></summary>

```lua
-- Menu de prueba de CookiesLib: todos los elementos y opciones
-- Carga la libreria y el key system desde GitHub
local BASE = "https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/"
local Library = loadstring(game:HttpGet(BASE .. "CookiesLib.lua"))()
local KeySystem = loadstring(game:HttpGet(BASE .. "Cookieskeysystem.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- que se vea la intro aunque ya se haya mostrado en esta partida
pcall(function() getgenv().__CookiesIntroShown = nil end)
if getgenv().__CookiesDemo then pcall(function() getgenv().__CookiesDemo:Destroy() end) end

local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "Demo  •  v" .. Library.Version,
    ConfigFolder = "CookiesDemo",
    Width = 760, Height = 520,
})
getgenv().__CookiesDemo = Window

local function say(title, content, kind)
    Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3 })
end

----------------------------------------------------------------
-- Inicio
----------------------------------------------------------------
Window:AddTabCategory("General")
local home = Window:CreateTab({ Name = "Inicio", Icon = "I" })

local welcome = home:CreateSection({ Name = "Bienvenido", Side = "Full" })
welcome:AddAlert({
    Type = "Info", Title = "Menú de prueba",
    Content = "Prueba cada elemento. Ctrl+F abre la búsqueda, <b>RightShift</b> oculta el menú y en <b>Ajustes</b> puedes cambiar tema, color y escala.",
})

local stats = home:CreateSection({ Name = "En vivo", Side = "Left" })
local sFps = stats:AddStat({ Name = "FPS", Value = "-" })
local sPing = stats:AddStat({ Name = "Ping", Value = "-" })
local sPlayers = stats:AddStat({ Name = "Jugadores", Value = #Players:GetPlayers() })
local sTime = stats:AddStat({ Name = "Hora", Value = os.date("%H:%M:%S") })
local sClicks = stats:AddStat({ Name = "Clicks en botones", Value = 0, Color = Library.Theme.Accent })

local info = home:CreateSection({ Name = "Información", Side = "Right" })
info:AddParagraph({ Title = "Párrafo", Content = "Texto largo que se ajusta solo. Ideal para explicar qué hace cada función del hub." })
info:AddLabel({ Text = "Label con <b>negrita</b> y <font color='#F5C20C'>color</font>", RichText = true })
info:AddCopyField({ Name = "Discord", Text = "discord.gg/cookieshub", Callback = function() say("Copiado", "Link copiado al portapapeles", "Success") end })
info:AddImage({ Image = 76143769732706, Height = 90, ScaleType = Enum.ScaleType.Fit, Caption = "AddImage" })

-- actualizacion de las estadisticas (se detiene al descargar la UI)
local running = true
Window:OnUnload(function() running = false end)
task.spawn(function()
    local RS = game:GetService("RunService")
    while running do
        local t0, frames = os.clock(), 0
        while os.clock() - t0 < 0.5 do RS.RenderStepped:Wait() frames = frames + 1 end
        if not running then break end
        sFps:Set(math.floor(frames / (os.clock() - t0) + 0.5))
        local ok, ping = pcall(function() return LocalPlayer:GetNetworkPing() end)
        sPing:Set(ok and (math.floor(ping * 1000 + 0.5) .. " ms") or "-")
        sPlayers:Set(#Players:GetPlayers())
        sTime:Set(os.date("%H:%M:%S"))
    end
end)

----------------------------------------------------------------
-- Controles básicos
----------------------------------------------------------------
Window:AddTabCategory("Elementos")
local basic = Window:CreateTab({ Name = "Controles", Icon = "C" })
local clicks = 0

local btns = basic:CreateSection("Botones")
btns:AddButton({ Name = "Botón normal", Tooltip = "Cada click suma al contador de Inicio", Callback = function()
    clicks = clicks + 1 sClicks:Set(clicks) say("Botón", "Click #" .. clicks)
end })
btns:AddButton({ Name = "Botón principal", Primary = true, Description = "Estilo Primary con descripción",
    Callback = function() say("Primary", "Botón destacado", "Success") end })
btns:AddButton({ Name = "Borrar todo", Style = "Danger", Confirm = true, Description = "Pide un segundo click para confirmar",
    Callback = function() say("Danger", "Acción confirmada", "Error") end })
local c1, c2 = btns:AddColumns(2)
c1:AddButton({ Name = "Columna A", Callback = function() say("Columnas", "Columna A") end })
c2:AddButton({ Name = "Columna B", Callback = function() say("Columnas", "Columna B") end })
local disabled = btns:AddButton({ Name = "Botón desactivado" })
disabled:SetEnabled(false)

local toggles = basic:CreateSection("Toggles")
toggles:AddToggle({ Name = "Toggle simple", Flag = "demo_toggle", Callback = function(v) say("Toggle", v and "Encendido" or "Apagado", v and "Success" or "Warning") end })
toggles:AddToggle({ Name = "Toggle con tecla", Description = "Presiona F o cambia la tecla en el chip", Flag = "demo_toggle_key",
    Keybind = { Default = "F", Flag = "demo_toggle_key_bind" },
    Callback = function(v) say("Toggle con tecla", v and "Activado" or "Desactivado") end })
toggles:AddToggle({ Name = "Mantener (Hold)", Description = "Activo solo mientras mantienes G",
    Keybind = { Default = "G", Mode = "Hold" }, Callback = function(v) if v then say("Hold", "Mantienes G") end end })
local cb1, cb2 = toggles:AddColumns(2)
cb1:AddToggle({ Name = "Casilla 1", Style = "Checkbox", Default = true, Flag = "demo_cb1" })
cb2:AddToggle({ Name = "Casilla 2", Style = "Checkbox", Flag = "demo_cb2" })

local inputs = basic:CreateSection("Entradas")
inputs:AddSlider({ Name = "Velocidad", Min = 16, Max = 200, Default = 16, Suffix = " ws", Flag = "demo_speed",
    Tooltip = "Escribe en la caja o arrastra",
    Callback = function(v) local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.WalkSpeed = v end end })
inputs:AddSlider({ Name = "Decimales", Min = 0, Max = 1, Increment = 0.05, Default = 0.5, Flag = "demo_dec" })
inputs:AddTextBox({ Name = "Texto", Placeholder = "escribe algo...", Flag = "demo_text",
    Callback = function(t) if t ~= "" then say("TextBox", t) end end })
inputs:AddTextBox({ Name = "Solo números", Numeric = true, Default = 10, Flag = "demo_numeric" })
inputs:AddKeybind({ Name = "Tecla de acción", Default = "K", Flag = "demo_bind",
    Callback = function() say("Keybind", "Presionaste la tecla de acción") end })
inputs:AddKeybind({ Name = "Tecla tipo toggle", Default = "J", Mode = "Toggle",
    Callback = function(active) say("Keybind Toggle", active and "Activo" or "Inactivo") end })

local lists = basic:CreateSection("Listas")
lists:AddDropdown({ Name = "Arma", Options = { "Espada", "Arco", "Lanza", "Hacha" }, Default = "Espada", Flag = "demo_weapon",
    Callback = function(v) say("Dropdown", tostring(v)) end })
lists:AddDropdown({ Name = "Opcional", Options = { "Uno", "Dos", "Tres" }, AllowNull = true, Placeholder = "Ninguno",
    Tooltip = "Click en la opción elegida para quitarla" })
lists:AddDropdown({ Name = "Mascotas", Multi = true, Options = { "Perro", "Gato", "Dragón", "Pez", "Búho" },
    Default = { "Gato" }, Flag = "demo_pets" })
local many = {}
for i = 1, 30 do many[i] = "Huevo " .. i end
lists:AddDropdown({ Name = "Con buscador", Options = many, Flag = "demo_eggs", Tooltip = "Con 7+ opciones aparece el buscador" })
lists:AddPlayerDropdown({ Name = "Jugador", IncludeSelf = true, Callback = function(v) if v then say("Jugador", v) end end })

----------------------------------------------------------------
-- Avanzado
----------------------------------------------------------------
local adv = Window:CreateTab({ Name = "Avanzado", Icon = "A", Badge = "NEW" })

local newEl = adv:CreateSection("Elementos nuevos")
newEl:AddSegmented({ Name = "Modo", Options = { "Seguro", "Normal", "Rápido" }, Default = "Normal", Flag = "demo_mode",
    Callback = function(v) say("Segmented", v) end })
newEl:AddRangeSlider({ Name = "Rango de nivel", Min = 1, Max = 100, Default = { 10, 60 }, Flag = "demo_range",
    Callback = function(v) end })
newEl:AddNumber({ Name = "Cantidad", Min = 0, Max = 99, Default = 5, Flag = "demo_amount", Tooltip = "Mantén presionado + o - para repetir" })
newEl:AddNumber({ Name = "Multiplicador", Min = 0.5, Max = 5, Increment = 0.5, Default = 1, Suffix = "x" })
local prog = newEl:AddProgress({ Name = "Progreso", Default = 35 })
newEl:AddButton({ Name = "Avanzar progreso", Callback = function()
    prog:Set((prog.Value + 15) % 115)
end })

local colors = adv:CreateSection("Colores")
colors:AddColorPicker({ Name = "Color de ESP", Default = Color3.fromRGB(245, 194, 12), Flag = "demo_color",
    Presets = { Color3.fromRGB(255, 80, 80), Color3.fromRGB(80, 200, 120), Color3.fromRGB(90, 140, 255), Color3.fromRGB(255, 255, 255) } })

local alerts = adv:CreateSection("Avisos")
alerts:AddAlert({ Type = "Success", Title = "Todo listo", Content = "Alerta de éxito" })
alerts:AddAlert({ Type = "Warning", Title = "Cuidado", Content = "Alerta de advertencia" })
alerts:AddAlert({ Type = "Error", Title = "Error", Content = "Alerta de error" })
alerts:AddDivider("Divisor con texto")
alerts:AddDivider()
alerts:AddSpacer(4)
alerts:AddLabel("Label normal")

local layout = adv:CreateSection({ Name = "Sección con scroll", MaxHeight = 120 })
for i = 1, 10 do layout:AddToggle({ Name = "Opción " .. i, Style = "Checkbox" }) end
local col = adv:CreateSection({ Name = "Sección cerrada", Minimized = true })
col:AddLabel("Esta sección empieza cerrada: click en el título para abrirla.")

----------------------------------------------------------------
-- Avisos y diálogos
----------------------------------------------------------------
local fx = Window:CreateTab({ Name = "Avisos", Icon = "N" })
local nt = fx:CreateSection("Notificaciones")
for _, k in ipairs({ "Info", "Success", "Warning", "Error" }) do
    nt:AddButton({ Name = "Notificación " .. k, Callback = function()
        Window:Notify({ Title = k, Content = "Pasa el mouse encima para pausarla. Click para cerrarla.", Type = k, Duration = 5 })
    end })
end
nt:AddButton({ Name = "Notificación que se actualiza", Callback = function()
    local n = Window:Notify({ Title = "Descargando...", Content = "0%", Duration = 6 })
    task.spawn(function()
        for i = 1, 5 do task.wait(0.8) n:SetContent((i * 20) .. "%") end
        n:SetTitle("Listo")
    end)
end })

local dl = fx:CreateSection("Diálogos")
dl:AddButton({ Name = "Diálogo simple", Callback = function()
    Window:Dialog({ Title = "¿Continuar?", Content = "Ejemplo de confirmación.", Callback = function() say("Diálogo", "Confirmado", "Success") end })
end })
dl:AddButton({ Name = "Diálogo con 3 botones", Callback = function()
    Window:Dialog({
        Title = "Elige una opción", Content = "Los diálogos aceptan cualquier cantidad de botones.",
        Buttons = {
            { Name = "Cancelar" },
            { Name = "Borrar", Style = "Danger", Callback = function() say("Diálogo", "Borrar", "Error") end },
            { Name = "Guardar", Style = "Primary", Callback = function() say("Diálogo", "Guardar", "Success") end },
        },
    })
end })

local extras = fx:CreateSection("Extras")
extras:AddToggle({ Name = "Marca de agua (FPS)", Callback = function(v)
    if v then Window:CreateWatermark({ ShowTime = true }) elseif Window._watermark then Window._watermark:Destroy() Window._watermark = nil end
end })
extras:AddToggle({ Name = "Lista de keybinds", Callback = function(v)
    if v then Window:CreateKeybindList() elseif Window._kbList then Window._kbList:Destroy() Window._kbList = nil end
end })
extras:AddButton({ Name = "Badge en esta pestaña", Callback = function() fx:SetBadge(math.random(1, 9)) end })
extras:AddButton({ Name = "Quitar badge", Callback = function() fx:SetBadge(nil) end })

----------------------------------------------------------------
-- Personalizar
----------------------------------------------------------------
Window:AddTabCategory("Personalizar")
local cust = Window:CreateTab({ Name = "Personalizar", Icon = "P" })

local themes = cust:CreateSection("Temas rápidos")
themes:AddDropdown({ Name = "Tema", Options = Library:GetThemes(), Default = Library.CurrentTheme,
    Callback = function(v) if v then Library:SetTheme(v) end end })
themes:AddSegmented({ Name = "Acento rápido", Options = { "Dorado", "Rosa", "Azul", "Verde" },
    Callback = function(v)
        local c = ({ Dorado = Color3.fromRGB(245, 194, 12), Rosa = Color3.fromRGB(255, 105, 140),
            Azul = Color3.fromRGB(98, 146, 255), Verde = Color3.fromRGB(120, 214, 140) })[v]
        Library:SetAccent(c)
    end })
themes:AddLabel({ Text = "El tema y el color que elijas en Ajustes se guardan para la próxima vez." })

local win = cust:CreateSection("Ventana")
win:AddTextBox({ Name = "Título", Default = "Cookies Hub", Callback = function(t) Window:SetTitle(t) end })
win:AddTextBox({ Name = "Subtítulo", Default = "Demo", Callback = function(t) Window:SetSubtitle(t) end })
win:AddNumber({ Name = "Ancho", Min = 480, Max = 1200, Increment = 20, Default = 760, Callback = function(v) Window:Resize(v, nil) end })
win:AddNumber({ Name = "Alto", Min = 320, Max = 900, Increment = 20, Default = 520, Callback = function(v) Window:Resize(nil, v) end })
win:AddButton({ Name = "Minimizar / restaurar", Callback = function() Window:Minimize() end })
win:AddButton({ Name = "Abrir búsqueda", Callback = function() Window:OpenSearch("toggle") end })

local ks = cust:CreateSection("Key System")
ks:AddParagraph({ Title = "Probar el key system", Content = "La key de prueba es COOKIES-DEMO (no distingue mayúsculas). Con 3 errores se activa una espera de 10 s." })
ks:AddCopyField({ Name = "Key", Text = "COOKIES-DEMO" })
ks:AddButton({ Name = "Abrir key system", Primary = true, Callback = function()
    Window:Hide()
    local k = KeySystem.new({
        Library = Library, Title = "Cookies Hub", Subtitle = "Key System • demo",
        Keys = { "COOKIES-DEMO" }, CaseSensitive = false, MaxAttempts = 3, Cooldown = 10,
        KeyLink = "https://example.com/get-key", DiscordLink = "https://discord.gg/cookieshub",
        Folder = "CookiesDemo", FileName = "demo_key.txt", SaveKey = false,
    })
    task.spawn(function()
        local ok = k:Wait()
        Window:Show()
        say("Key System", ok and "Key válida" or "Cerrado sin key", ok and "Success" or "Warning")
    end)
end })

Window:CreateSettingsTab("Ajustes", "S")

say("Cookies Hub " .. Library.Version, "Menú de prueba cargado. ¡Pruébalo todo!", "Success")
```

</details>

---

## Ventana

```lua
local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "v1.0",
    Logo = "rbxassetid://76143769732706",
    Width = 740, Height = 500,
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "CookiesHub",

    -- Sub-configuraciones opcionales (solo para esta ventana)
    Intro   = { Enabled = true, Duration = 2 },
    Tab     = { IconSize = 20 },
    Section = { Collapsible = true },
    Notify  = { Duration = 4, Position = "TopRight" },

    -- Tema: nombre de un tema o tabla de colores (ver "Temas")
    Theme = { Accent = Color3.fromRGB(245, 194, 12) },
})
```

Las opciones que no son `Theme`, `Config` ni una sub-configuración (`Tab`, `Section`, `Element`, `Notify`, `Tooltip`, `Dropdown`, `Search`, `Intro`) se interpretan como opciones de ventana. También puedes pasar `Config = { ... }` para sobrescribir cualquier valor de [`Library.Config`](#configuración-global) solo en esa ventana.

### Opciones de ventana

| Opción | Por defecto | Descripción |
| --- | --- | --- |
| `Title` | `"Cookies Hub"` | Título de la barra superior |
| `Subtitle` | `"v" .. Library.Version` | Texto pequeño bajo el título |
| `Logo` | logo de Cookies | Imagen del título y del botón flotante. `false` para quitarlo (el botón flotante muestra una "C") |
| `Width`, `Height` | `740`, `500` | Tamaño inicial |
| `MinWidth`, `MinHeight` | `480`, `320` | Tamaño mínimo al redimensionar |
| `SidebarWidth` | `160` | Ancho de la barra lateral |
| `CompactSidebarWidth` | `58` | Ancho de la barra lateral en modo compacto |
| `CompactBelow` | `600` | Por debajo de este ancho, la barra lateral pasa a modo compacto (solo iconos) |
| `AutoScale` | `true` | Escala la ventana para que quepa en pantallas pequeñas |
| `MinScale` | `0.7` | Escala mínima antes de reducir el tamaño lógico de la ventana |
| `UIScale` | `1` | Escala extra (0.6 – 1.4). El usuario la cambia desde Ajustes |
| `ToggleKey` | `RightShift` | Tecla para mostrar/ocultar |
| `FloatingButton` | `true` | Botón flotante. Con `false` se oculta también en táctil |
| `Resizable` | `true` | Asa de redimensionado (esquina inferior derecha). Máx. 2000×1400 |
| `Draggable` | `true` | Arrastrar desde la barra superior |
| `SmoothDrag` | `true` | Arrastre suavizado (más fluido) |
| `Minimizable` | `true` | Botón `-` |
| `Closable` | `true` | Botón `x` (oculta, no destruye) |
| `Searchable` | `true` | Botón de lupa (búsqueda global) |
| `SearchShortcut` | `true` | `Ctrl+F` abre/cierra la búsqueda |
| `ShowProfile` | `true` | Tarjeta con avatar y nombre en la barra lateral |
| `Shadow` | `true` | Sombra suave detrás de la ventana |
| `AccentLine` | `true` | Línea de acento con degradado bajo la barra superior |
| `RememberLayout` | `true` | Recuerda la interfaz entre ejecuciones (ver [Estado guardado](#estado-guardado-de-la-interfaz)) |
| `DisplayOrder` | `50` | `DisplayOrder` del `ScreenGui` |
| `Corner` | `12` | Radio de las esquinas de la ventana |
| `ConfigFolder` | `"CookiesHub"` | Carpeta de configs y del estado guardado |

### Intro

Al crear la ventana se reproduce una intro: la ventana permanece oculta hasta que termina y entonces se abre con su animación normal. Mientras dura, `Window:SetVisible/Show/Hide/Toggle` no hacen nada.

| Opción (`Intro = {...}`) | Por defecto | Descripción |
| --- | --- | --- |
| `Enabled` | `true` | `false` para omitir la intro |
| `Duration` | `2` | Duración total en segundos (mínimo efectivo: 1) |
| `Skippable` | `true` | Un clic (o toque) la salta |
| `OncePerSession` | `true` | Si re-ejecutas el script en la misma partida, no se repite |
| `Logo` | logo de intro | Imagen (PNG sin fondo recomendado) |
| `Width`, `Height` | `300`, `180` | Tamaño de la imagen |
| `ShowBar` | `true` | Barra de carga bajo el logo |

### Métodos de `Window`

```lua
-- Visibilidad
Window:Toggle()   Window:Show()   Window:Hide()
Window:SetVisible(true)
Window:Minimize()                     -- alterna; Window:Minimize(true / false) para forzar

-- Tamaño y posición
Window:Resize(800, 520)               -- respeta MinWidth/MinHeight (nil = no cambiar ese lado)
Window:SetUIScale(1.2)                -- escala extra 0.6 – 1.4 (se guarda)
Window:ResetPosition()                -- vuelve al centro
Window:ResetLayout()                  -- borra el estado guardado: tamaño, posición y escala originales

-- Textos y controles
Window:SetTitle("Nuevo título")
Window:SetSubtitle("Texto")
Window:SetToggleKey(Enum.KeyCode.K)   -- acepta Enum.KeyCode o su nombre como string
Window:SetFloatingButton(false)

-- Pestañas
Window:AddTabCategory("Combat")       -- separador de texto en la barra lateral
Window:CreateTab(...)                 -- ver "Pestañas"
Window:CreateSettingsTab()            -- ver "Pestaña de ajustes"
Window:GetTab("Main")                 -- devuelve la pestaña o nil
Window:SelectTab("Main")              -- acepta nombre o el objeto pestaña

-- Avisos
Window:Notify({ ... })                -- ver "Notificaciones"
Window:Dialog({ ... })                -- ver "Diálogos"
Window:CreateWatermark({ ... })       -- ver "Marca de agua"
Window:CreateKeybindList({ ... })

-- Configs
Window:SaveConfig("nombre")   Window:LoadConfig("nombre")   Window:DeleteConfig("nombre")
Window:GetConfigs()
Window:SetAutoload("nombre")  Window:GetAutoload()  Window:LoadAutoloadConfig()

-- Búsqueda
Window:OpenSearch("texto")  Window:CloseSearch()  Window:ToggleSearch()  Window:SetSearch("texto")

-- Descargar
Window:OnUnload(function() running = false end)   -- se ejecuta al descargar la UI
Window:Destroy()                      -- alias: Window:Unload()
```

Campos útiles: `Window.Tabs`, `Window.ActiveTab`, `Window.Visible`, `Window.Minimized`, `Window.Gui`, `Window.Config`.

A nivel de librería también existen `Library:Notify`, `Library:Dialog`, `Library:OnUnload` (usan la última ventana creada) y `Library:Unload()` (destruye todas las ventanas).

### Detener tus loops al descargar

```lua
local running = true
Window:OnUnload(function() running = false end)

task.spawn(function()
    while running do
        -- tu auto farm...
        task.wait(0.1)
    end
end)
```

`OnUnload` se ejecuta cuando el usuario pulsa **Unload UI** en Ajustes o cuando llamas a `Window:Destroy()`.

### Comportamiento adaptable

- **Modo compacto:** si el ancho efectivo es menor que `CompactBelow`, la barra lateral muestra solo iconos (el nombre de la pestaña aparece como tooltip) y se ocultan las categorías.
- **Una sola columna:** si el área de contenido es más estrecha que `Tab.SingleColumnBelow` (440), las pestañas pasan a 1 columna.
- **AutoScale:** en pantallas pequeñas la ventana se escala para caber. Se vuelve a calcular cuando cambia el tamaño de la pantalla.
- La ventana y el botón flotante se mantienen dentro de la pantalla al arrastrarlos.
- Al **minimizar**, queda visible solo la barra superior (que se queda fija, sin moverse).

---

## Pestañas

```lua
local Tab = Window:CreateTab("Main", "H")   -- (nombre, icono)

-- o con tabla de opciones
local Tab = Window:CreateTab({
    Name = "Combat",
    Icon = Lucide.GetAsset("swords", 48),
    IconColor = Color3.fromRGB(245, 194, 12),  -- color del icono cuando está activa
    IconSize = 20,
    IconTint = true,
    Columns = 2,
    Gap = 10,
    Padding = 12,
    Badge = "NEW",                             -- etiqueta junto al nombre
})
```

| Opción | Por defecto | Descripción |
| --- | --- | --- |
| `Name` | `"Tab"` | Nombre |
| `Icon` | primera letra del nombre | Ver [Iconos](#iconos-lucide-y-otros) |
| `IconColor` | acento | Color del icono activo |
| `IconSize` | `20` | Tamaño del icono |
| `IconTint` | `true` | Tiñe el icono según el estado (ver Iconos) |
| `Columns` | `2` | Columnas de la pestaña |
| `Gap` | `10` | Separación entre secciones |
| `Padding` | `12` | Margen interior |
| `Badge` | `nil` | Etiqueta pequeña a la derecha (`"NEW"`, `3`...) |

La primera pestaña creada se selecciona automáticamente. Si el usuario tenía otra pestaña abierta la última vez, se vuelve a abrir esa.

Métodos de `Tab`:

```lua
Tab:Select()
Tab:SetName("Inicio")
Tab:SetIcon(Lucide.GetAsset("flame", 48))
Tab:SetBadge("NEW")        -- SetBadge(nil) la quita
Tab:SetVisible(true)       -- muestra/oculta el botón de la pestaña
Tab:ScrollToTop()
Tab:Refresh()
Tab:Destroy()
Tab:CreateSection({ ... })  -- ver "Secciones"
```

---

## Iconos (Lucide y otros)

Las **pestañas** y las **secciones** aceptan iconos. Los iconos de [Lucide](https://lucide.dev) se usan con la librería **lucide-roblox**: `Library` entiende el formato que devuelve (`Id`, `ImageRectSize`, `ImageRectOffset`), así que se pasa tal cual.

> **Fuente de los iconos:** [latte-soft/lucide-roblox](https://github.com/latte-soft/lucide-roblox). Todo el crédito de la conversión de Lucide a Roblox es de sus autores.

### 1. Obtener lucide-roblox

Desde la página de [releases](https://github.com/latte-soft/lucide-roblox/releases) puedes descargar `lucide-roblox.luau`. Si tu executor soporta `loadstring` y `HttpGet`:

```lua
local Lucide = loadstring(game:HttpGet(
    "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"
))()
```

> ⚠️ El repositorio de lucide-roblox está archivado (solo lectura). Sigue funcionando, pero ya no recibe actualizaciones. Para no depender de la descarga en línea, guarda una copia local del archivo.

### 2. Usar un icono

`Lucide.GetAsset(nombre, tamaño)` devuelve una tabla con el asset. Usa tamaño **48** para iconos de pestaña (el valor por defecto, 256, es más pesado de lo necesario).

```lua
local function icon(name)
    local ok, asset = pcall(Lucide.GetAsset, name, 48)   -- un nombre inválido lanza error
    return ok and asset or nil                            -- nil = se usa la letra por defecto
end

local Home    = Window:CreateTab("Home", icon("home"))
local Combat  = Window:CreateTab("Combat", icon("swords"))

local Section = Combat:CreateSection({
    Name = "Aimbot",
    Icon = icon("crosshair"),
    IconColor = Color3.fromRGB(245, 194, 12),   -- opcional, por defecto el acento
})

Combat:SetIcon(icon("flame"))                   -- cambiarlo después
```

Los nombres son los de Lucide en minúsculas con guiones (`"home"`, `"swords"`, `"settings"`…). Ojo: lucide-roblox usa nombres antiguos de Lucide (`"home"` en vez de `"house"`, `"line-chart"` en vez de `"chart-line"`). Lista completa: [icon-index](https://github.com/latte-soft/lucide-roblox/blob/master/md/icon-index.md) o `Lucide.IconNames`.

### Formatos admitidos

| Valor de `Icon` | Resultado |
| --- | --- |
| `Lucide.GetAsset("home", 48)` | Icono de Lucide (recomendado) |
| `123456789` (número) | Asset id → `rbxassetid://123456789` |
| `"rbxassetid://123456789"` | Asset id como texto (también `rbxthumb://`, `rbxasset://` y `http(s)://`) |
| `"123456789"` | Texto numérico de más de 4 dígitos → asset id |
| `"H"` | Letra (máx. 2 caracteres) dentro de un recuadro |
| `{ Text = "AB" }` | Letra(s) mediante tabla |
| `{ Image = id, ImageRectSize = v2, ImageRectOffset = v2 }` | Spritesheet manual (`Image` también puede llamarse `Asset`, `AssetId` o `Id`) |
| `nil` | Pestañas: primera letra del nombre. Secciones: punto de color |

Los mismos formatos sirven para `AddImage`.

### Tinte

Los iconos de Lucide son blancos, así que se tiñen con el tema:

- **Pestañas** con `IconTint = true` (por defecto): icono apagado cuando está inactiva y color de acento (o `IconColor`) cuando está activa. Con `IconTint = false` se muestra con sus colores originales.
- **Secciones**: el icono se tiñe con `IconColor` o, si no se indica, con el color de la sección (`Color`) / acento.

```lua
Library:Configure({ Tab = { IconTint = true, IconSize = 20 } })
```

---

## Secciones

Una pestaña tiene **2 columnas** por defecto (1 en pantallas estrechas). Las secciones se reparten solas entre columnas, o puedes elegir:

```lua
Tab:CreateSection({ Name = "Izquierda", Column = "Left" })
Tab:CreateSection({ Name = "Derecha",   Column = "Right" })
Tab:CreateSection({ Name = "Ancha",     Full = true })      -- ocupa todo el ancho (o Column = "Full")
Tab:CreateSection({ Name = "Col 2",     Column = 2 })       -- por número
Tab:CreateSection("Solo nombre")                            -- atajo con string
```

(`Tab:AddSection` es un alias de `CreateSection`; `Side` es un alias de `Column`.)

```lua
local Section = Tab:CreateSection({
    Name = "Aimbot",
    Icon = icon("crosshair"),
    Color = Color3.fromRGB(245, 194, 12),  -- color del punto / icono
    Minimized = true,       -- empieza plegada (alias: Collapsed)
    Collapsible = true,     -- false = no se puede plegar
    MaxHeight = 220,        -- el contenido hace scroll al superar esta altura
    Columns = 1,            -- columnas internas
    Gap = 6, ColumnGap = 8,
})
```

Se pliegan pulsando la cabecera (flecha a la derecha).

```lua
Section:Minimize()    Section:Expand()    Section:Toggle()
Section:SetOpen(true, instant)          -- `instant = true` sin animación
Section:OnToggle(function(open) print(open) end)   -- un único callback (reemplaza al anterior)
Section:SetTitle("Otro nombre")
Section:SetColor(Color3.fromRGB(255, 0, 0))        -- recolorea el punto
Section:SetMaxHeight(300)                          -- solo si se creó con MaxHeight
Section:SetVisible(true)
Section:Destroy()
```

Campos: `Section.Name`, `Section.Open`, `Section.Frame`.

### Varias columnas dentro de una sección

```lua
-- columnas internas fijas
local S = Tab:CreateSection({ Name = "Grid", Columns = 2 })
S:AddButton({ Name = "A" })                 -- se reparte solo
S:AddButton({ Name = "B", Column = 2 })     -- o elige columna con Column

-- varios elementos en una misma fila
local left, right = S:AddColumns(2)
left:AddButton({ Name = "A" })
right:AddButton({ Name = "B" })
```

---

## Elementos

Todos se crean desde una sección: `Section:AddXxx({ ... })`.

| Elemento | Para qué | Guarda en configs |
| --- | --- | --- |
| [`AddButton`](#button) | Ejecutar una acción | — |
| [`AddToggle`](#toggle) | Encendido / apagado (interruptor o casilla, con tecla opcional) | ✅ |
| [`AddSlider`](#slider) | Número arrastrando | ✅ |
| [`AddRangeSlider`](#rangeslider) 🆕 | Rango mínimo – máximo | ✅ |
| [`AddNumber`](#number) 🆕 | Número con botones − / + | ✅ |
| [`AddDropdown`](#dropdown) | Elegir una o varias opciones | ✅ |
| [`AddPlayerDropdown`](#playerdropdown) 🆕 | Elegir jugadores del servidor | — (opcional) |
| [`AddSegmented`](#segmented) 🆕 | Elegir entre pocas opciones con pastillas | ✅ |
| [`AddKeybind`](#keybind) | Asignar una tecla | ✅ |
| [`AddTextBox`](#textbox) | Escribir texto o números | ✅ |
| [`AddColorPicker`](#colorpicker) | Elegir un color | ✅ |
| [`AddProgress`](#progress) | Barra de progreso | — |
| [`AddStat`](#stat) 🆕 | Mostrar un valor (dinero, nivel...) | — |
| [`AddAlert`](#alert) 🆕 | Aviso destacado con color | — |
| [`AddCopyField`](#copyfield) 🆕 | Texto con botón de copiar | — |
| [`AddImage`](#image) 🆕 | Imagen con texto opcional | — |
| [`AddLabel`, `AddParagraph`, `AddDivider`, `AddSpacer`](#elementos-de-texto-y-diseño) | Texto y diseño | — |

### Opciones comunes

| Opción | Descripción |
| --- | --- |
| `Name` | Texto del elemento |
| `Flag` | Nombre de flag: registra el elemento en `Library.Flags` y lo incluye en las configs |
| `Callback` | Función que se ejecuta al cambiar (cada elemento define sus argumentos) |
| `Description` | Texto secundario (en Button/Toggle se dibuja bajo el nombre) y cuerpo del tooltip |
| `Tooltip` | Texto de tooltip manual |
| `Height` | Altura del elemento (por defecto `32`) |
| `Visible` | `false` para crearlo oculto |
| `Enabled` / `Disabled` | `Enabled = false` o `Disabled = true` lo crea desactivado |
| `Column` | Columna (número) cuando la sección tiene varias columnas |

### Métodos comunes

Disponibles en Button, Toggle, Slider, RangeSlider, Number, Dropdown, PlayerDropdown, Segmented, Keybind, TextBox, ColorPicker, Progress, Stat y CopyField:

```lua
element:Set(value, silent)   -- silent = true no ejecuta callbacks
element:Get()
element:SetText("Nuevo nombre")
element:SetVisible(true)
element:SetEnabled(false)    -- bloquea la interacción (capa semitransparente)
element:SetCallback(fn)
element:OnChanged(fn)        -- listener extra; devuelve { Disconnect = function() end }
element:Destroy()
```

Campos: `element.Type`, `element.Value`, `element.Frame`, `element.Section`, `element.Enabled`.

> `OnChanged` y `Callback` se ejecutan con `task.spawn`, así que un error en tu función no rompe la UI.

---

### Button

```lua
local btn = Section:AddButton({
    Name = "Ejecutar",
    Description = "Texto opcional",
    Style = "Primary",           -- Default | Primary | Danger   (o Primary = true)
    Confirm = true,              -- pide un 2º clic antes de ejecutar (o un texto: Confirm = "¿Seguro?")
    Callback = function() print("clic") end,
})
btn:Click()                      -- dispara el botón por código (respeta Confirm)
btn:SetText("Otro texto")
```

Con `Confirm`, el primer clic cambia el texto a *"Click again to confirm"* (o tu texto) durante 2,5 s; el callback solo se ejecuta si se vuelve a pulsar en ese tiempo. Ideal para acciones peligrosas.

### Toggle

```lua
local t = Section:AddToggle({
    Name = "ESP", Description = "Muestra jugadores",
    Default = false, Color = Color3.fromRGB(96, 196, 124),
    Style = "Switch",                 -- Switch (por defecto) | Checkbox
    Keybind = { Default = "F", Mode = "Toggle", Flag = "ESPKey" },   -- opcional
    Flag = "ESP",
    Callback = function(v) end,       -- v: boolean
})
t:Set(true)   t:Toggle()   t:Get()
```

**Toggle con tecla:** `Keybind` añade un chip con la tecla dentro de la misma fila. Se puede pasar como tabla, como nombre (`Keybind = "F"`) o añadirlo después:

```lua
local kb = t:AddKeybind({ Default = Enum.KeyCode.F, Mode = "Hold", Flag = "ESPKey" })
kb:Set(Enum.KeyCode.G)   kb:Get()   kb:SetMode("Toggle")
-- también accesible como t.Keybind
```

| `Mode` | Qué hace la tecla |
| --- | --- |
| `Toggle` (por defecto) | Cada pulsación enciende/apaga el toggle |
| `Hold` | Encendido solo mientras la mantienes pulsada |

Para cambiar la tecla, clic en el chip y pulsa otra (`Esc` cancela, `Backspace` la quita). Con `Flag`, la tecla se guarda en las configs. `Changed = function(key) end` se ejecuta al reasignarla.

**Casilla:** `Style = "Checkbox"` dibuja una casilla con check en lugar del interruptor; ocupa menos y queda bien en columnas.

### Slider

```lua
local s = Section:AddSlider({
    Name = "Velocidad", Min = 16, Max = 100, Increment = 1, Default = 16,
    Suffix = " st", Color = Color3.fromRGB(245, 194, 12),
    Flag = "Speed",
    Callback = function(v) end,       -- v: number (se llama mientras arrastras)
})
s:Set(50)   s:SetRange(0, 200)
```

La caja numérica de la derecha es editable. Los decimales mostrados se deducen de `Increment` (`0.25` → 2 decimales).

### RangeSlider

Slider con dos manijas para elegir un rango. El valor es una tabla `{ min, max }`.

```lua
local r = Section:AddRangeSlider({
    Name = "Nivel de enemigos", Min = 1, Max = 100, Increment = 1,
    Default = { 10, 60 }, Suffix = "",
    Flag = "LevelRange",
    Callback = function(v) print(v[1], v[2]) end,
})
r:Set({ 20, 80 })            -- si los pasas al revés se ordenan solos
local lo, hi = table.unpack(r:Get())
```

Al hacer clic, se mueve la manija más cercana. Una manija no puede pasar a la otra.

### Number

Campo numérico con botones `−` y `+`. Mantener presionado un botón repite el cambio.

```lua
local n = Section:AddNumber({
    Name = "Cantidad", Min = 0, Max = 99, Increment = 1, Default = 5,
    Suffix = "x",
    Flag = "Amount",
    Callback = function(v) end,
})
n:Set(10)   n:Get()
```

El número también se puede escribir directamente. `Min`/`Max` son opcionales (sin límite si no se indican).

### Dropdown

```lua
local d = Section:AddDropdown({
    Name = "Objetivo", Options = { "Head", "Torso", "Legs" },
    Default = "Head", Multi = false,
    Placeholder = "Select...",
    AllowNull = false,        -- true: clic en la opción elegida la deselecciona
    Searchable = nil,         -- nil = el buscador aparece solo con 7+ opciones
    MaxVisible = 5,
    Flag = "Target",
    Callback = function(v) end,       -- v: valor, o tabla (copia) si Multi = true
})

d:Set("Torso")                -- con Multi: d:Set({ "Head", "Torso" })
d:Get()
d:Clear()                     -- sin selección
d:SetOpen(true)
d:Refresh({ "A", "B" }, true) -- reemplaza opciones; 2º argumento = conservar valor (alias: SetOptions)
d:AddOption("Nueva")
d:RemoveOption("A")
```

Las opciones se muestran con `tostring`, pero el valor devuelto es el original (puedes usar números u otros valores). Con `Multi = true`, `Default` y `Set` reciben una tabla; opciones que no existan se ignoran. El buscador se reinicia al cerrar.

### PlayerDropdown

Dropdown con los jugadores del servidor. Se actualiza solo cuando alguien entra o sale.

```lua
local p = Section:AddPlayerDropdown({
    Name = "Objetivo",
    IncludeSelf = false,      -- true: te incluye en la lista
    Multi = false,            -- acepta las mismas opciones que AddDropdown
    Callback = function(name) print("Elegido:", name) end,
})

local player = p:GetPlayer()  -- objeto Player (o lista de Players si Multi = true)
```

El valor es el **nombre** del jugador. No se guarda en configs por defecto (los jugadores cambian entre servidores); usa `Savable = true` si lo necesitas.

### Segmented

Grupo de opciones tipo "pastillas" con un indicador que se desliza. Mejor que un dropdown cuando hay 2–5 opciones.

```lua
local seg = Section:AddSegmented({
    Name = "Modo",                         -- opcional
    Options = { "Seguro", "Normal", "Rápido" },
    Default = "Normal",                    -- por defecto la primera
    Flag = "Mode",
    Callback = function(v) print(v) end,
})
seg:Set("Rápido")
seg:Refresh({ "A", "B" })                  -- cambia las opciones
```

### Keybind

```lua
local k = Section:AddKeybind({
    Name = "Tecla", Default = Enum.KeyCode.E,
    Mode = "Press",                   -- Press | Toggle | Hold
    Flag = "AimKey",
    Callback = function(state) end,   -- se ejecuta al PULSAR la tecla
    Changed = function(key) end,      -- se ejecuta al CAMBIAR la tecla asignada
})
k:Set(Enum.KeyCode.Q)   k:Get()   k:SetMode("Hold")   k:Press()
```

| Modo | `Callback` recibe |
| --- | --- |
| `Press` | nada (se llama una vez al pulsar) |
| `Toggle` | `true/false` alternando en cada pulsación (`k.Active`) |
| `Hold` | `true` al pulsar y `false` al soltar |

Para reasignar, haz clic en el elemento y pulsa una tecla. `Esc` cancela y `Backspace` quita la tecla (`None`). Las teclas no se disparan mientras escribes en una caja de texto. Ojo: `OnChanged` **no** se ejecuta en Keybind; usa `Callback` (pulsación) o `Changed` (reasignación).

> Si solo quieres una tecla que encienda/apague un toggle, es más simple usar la opción `Keybind` del [Toggle](#toggle).

### TextBox

```lua
local tb = Section:AddTextBox({
    Name = "Mensaje", Placeholder = "...", Default = "",
    Numeric = false,                  -- true: el valor es number
    ClearOnFocus = false,
    CallbackOnBlur = true,            -- false: solo dispara con Enter
    Flag = "Msg",
    Callback = function(text) end,
})
```

### ColorPicker

```lua
local cp = Section:AddColorPicker({
    Name = "Color", Default = Color3.fromRGB(245, 194, 12),
    Presets = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0) },
    PanelHeight = 96,
    Flag = "ESPColor",
    Callback = function(c) end,       -- Color3
})
cp:Set(Color3.new(1, 0, 0))   cp:SetHex("#FF0000")   cp:GetHex()   cp:SetOpen(true)
```

Incluye selector saturación/brillo, barra de tono y caja hexadecimal (`#RRGGBB`).

### Progress

```lua
local p = Section:AddProgress({
    Name = "Carga", Min = 0, Max = 100, Default = 40,
    ShowPercent = true,               -- false muestra el valor en bruto
    Color = Color3.fromRGB(96, 196, 124),
})
p:Set(75)
```

Solo visualización: **no se guarda** en las configs.

### Stat

Fila de solo lectura con nombre a la izquierda y valor a la derecha. Útil para mostrar dinero, nivel, estado del farm, etc.

```lua
local money = Section:AddStat({ Name = "Dinero", Value = "$0", Color = Color3.fromRGB(96, 196, 124) })

task.spawn(function()
    while running do
        money:Set("$" .. LocalPlayer.leaderstats.Money.Value)
        task.wait(1)
    end
end)

money:SetColor(Color3.fromRGB(224, 92, 92))   -- cambia el color del valor
```

El valor acepta `RichText`. No se guarda en configs.

### Alert

Aviso destacado con borde, icono y fondo del color del tipo.

```lua
local a = Section:AddAlert({
    Type = "Warning",          -- Info | Success | Warning | Error
    Title = "Cuidado",
    Content = "Esta opción puede causar <b>kick</b>.",   -- acepta RichText
})
a:Set("Nuevo título", "Nuevo contenido")   -- nil = no cambiar ese texto
a:SetType("Success")
a:SetVisible(false)   a:Destroy()
```

### CopyField

Texto (link, código, ID...) con un botón **Copy** que lo copia al portapapeles.

```lua
local cf = Section:AddCopyField({
    Name = "Discord",                       -- opcional
    Text = "discord.gg/cookieshub",
    Callback = function(text) end,          -- tras copiar
})
cf:Set("otro texto")
```

### Image

```lua
local img = Section:AddImage({
    Image = 76143769732706,               -- mismos formatos que los iconos
    Height = 120,
    ScaleType = Enum.ScaleType.Fit,       -- por defecto Crop
    Caption = "Texto debajo",             -- opcional
    Corner = 6,
})
img:SetImage("rbxassetid://123")   img:SetCaption("Otro")   img:SetVisible(false)
```

### Elementos de texto y diseño

```lua
local lbl = Section:AddLabel("Texto informativo")
Section:AddLabel({
    Text = "Aviso con <b>negrita</b>", RichText = true,
    Color = Color3.fromRGB(232, 148, 58), Size = 12,
    Bold = false, Center = false,
})
lbl:SetText("Nuevo texto")   lbl:SetColor(Color3.new(1, 1, 1))   lbl:SetVisible(false)   lbl:Destroy()

local para = Section:AddParagraph({ Title = "Título", Content = "Descripción más larga", RichText = false })
para:Set("Nuevo título", "Nuevo contenido")

Section:AddDivider()              -- línea
Section:AddDivider("Opciones")    -- línea con texto
Section:AddSpacer(8)              -- espacio en px
```

Estos elementos no usan `Flag`/`Callback` ni tienen tooltip.

---

## Flags y configs

Un elemento con `Flag` queda registrado en `Library.Flags` (alias: `Library.Options`) y se incluye al guardar una config.

```lua
Library:GetFlag("ESP")              -- valor (alias: Library:Get)
Library:SetFlag("ESP", true)        -- cambia el valor (alias: Library:Set); 3er argumento = silent
Library:GetObject("ESP")            -- el elemento completo (alias: Library.Flags.ESP)
```

```lua
local ok, err = Window:SaveConfig("mi-config")   -- ConfigFolder/mi-config.json
local ok, err = Window:LoadConfig("mi-config")
local ok, err = Window:DeleteConfig("mi-config")
local lista   = Window:GetConfigs()              -- { "mi-config", ... }
```

### Auto-carga

Una config marcada como auto-carga se aplica sola cada vez que el usuario ejecuta el script:

```lua
Window:SetAutoload("mi-config")    -- nil para desactivarla
Window:GetAutoload()               -- "mi-config" o nil
Window:LoadAutoloadConfig()        -- cárgala manualmente
```

`CreateSettingsTab` llama a `LoadAutoloadConfig()` medio segundo después de crearse, así que **créala al final**, cuando todos tus elementos con `Flag` ya existan. Si no usas la pestaña de ajustes, llama tú a `Window:LoadAutoloadConfig()` al terminar de construir el menú.

### Detalles

- Las configs son JSON; se guardan cuando llamas a `SaveConfig` (o con el botón de Ajustes).
- Se guardan **todos** los flags registrados en `Library` (de todas las ventanas) salvo los no guardables (`Progress`, `Stat`, `CopyField`, `PlayerDropdown`).
- Formato: `ColorPicker` → `{R, G, B}`; `Keybind` → nombre de la tecla; `Dropdown` múltiple y `RangeSlider` → lista; el resto, su valor.
- **`LoadConfig` ejecuta los callbacks** de cada elemento (aplica el valor sin modo silencioso).
- Los flags que no existan al cargar se ignoran.
- Los caracteres no válidos en nombres de archivo (`\ / : * ? " < > |`) se quitan del nombre.
- Si el executor no soporta archivos, las funciones devuelven `false` y un mensaje.

---

## Notificaciones

```lua
Window:Notify({
    Title = "Cookies Hub",
    Content = "Config <b>cargada</b>",       -- acepta RichText
    Type = "Success",        -- Info | Success | Warning | Error  (cada uno con su icono)
    Duration = 4,            -- 0 = no se cierra sola (clic para cerrar)
    Color = Color3.fromRGB(245, 194, 12),    -- opcional: sustituye el color del tipo
    Callback = function() end,               -- opcional: al hacer clic en ella
})

Window:Notify("Solo título")        -- atajo con string
Library:Notify({ Title = "Hola" })  -- usa la ventana creada más recientemente
```

La notificación devuelve un objeto para actualizarla:

```lua
local n = Window:Notify({ Title = "Descargando...", Content = "0%", Duration = 0 })
for i = 1, 10 do
    task.wait(0.3)
    n:SetContent(i * 10 .. "%")
end
n:SetTitle("Listo")
n.Close()
```

- Un clic la cierra (y ejecuta `Callback` si lo tiene).
- Con el mouse encima, el tiempo **se pausa**.
- Si hay más de `Max` en pantalla, se cierra la más antigua.

Config: `Notify = { Duration = 4, Width = 290, Position = "BottomRight", Max = 5, PauseOnHover = true }`. `Position` acepta `BottomRight`, `TopRight`, `BottomLeft` y `TopLeft`.

---

## Diálogos

Ventana modal para confirmar acciones. Oscurece el menú y se cierra al pulsar un botón o al hacer clic fuera.

```lua
-- confirmación simple: botones "Cancel" y "Confirm"
Window:Dialog({
    Title = "¿Teletransportar?",
    Content = "Irás al jefe final.",
    Callback = function() teleport() end,    -- al pulsar Confirm
})

-- botones personalizados
Window:Dialog({
    Title = "Guardar cambios",
    Content = "Tienes cambios sin guardar.",  -- acepta RichText
    Width = 340,
    Dismissible = false,                      -- no se cierra al hacer clic fuera
    Buttons = {
        { Name = "Cancelar" },
        { Name = "Descartar", Style = "Danger",  Callback = function() end },
        { Name = "Guardar",   Style = "Primary", Callback = function() end },
    },
})
```

`Style` de cada botón: `Default`, `Primary` o `Danger`. Devuelve `{ Close = function }`. Si la ventana estaba minimizada u oculta, se abre antes de mostrar el diálogo.

---

## Marca de agua y lista de keybinds

Paneles flotantes que se pueden arrastrar. **Recuerdan la posición** donde los deja el usuario.

```lua
local wm = Window:CreateWatermark({
    Text = "Cookies Hub",     -- por defecto el título de la ventana
    ShowFPS = true,
    ShowPing = true,
    ShowTime = false,
})
wm:SetText("Otro texto")   wm:SetVisible(false)   wm:Destroy()

local list = Window:CreateKeybindList({
    Title = "Keybinds",
    ShowAll = false,          -- true: incluye también los Keybind en modo Press
    ShowEmpty = false,        -- true: se ve aunque no haya teclas
})
list:SetVisible(false)   list:Destroy()
```

La lista muestra las teclas de los toggles (y de los Keybind en modo `Toggle`/`Hold`); la fila se ilumina cuando están activos. Ambos se pueden activar también desde la [pestaña de ajustes](#pestaña-de-ajustes).

---

## Búsqueda global

El botón de **lupa** de la barra superior (o `Ctrl+F`) abre un buscador que indexa pestañas, secciones y elementos (por nombre, descripción, pestaña, sección y tipo). Escribir varias palabras exige que **todas** coincidan. Al elegir un resultado se abre la pestaña, se despliega la sección, se hace scroll y se resalta el elemento. `Enter` abre el primer resultado y `Esc` cierra la búsqueda.

```lua
Window:OpenSearch("speed")   -- abre con texto
Window:SetSearch("")         -- cambia el texto
Window:ToggleSearch()
Window:CloseSearch()
```

Se desactiva con `Searchable = false` (y el atajo con `SearchShortcut = false`). Config: `Search = { MaxResults = 40, Placeholder = "Search the whole menu..." }`.

Los elementos y pestañas ocultos (`SetVisible(false)`) no aparecen en los resultados.

---

## Tooltips

Los tooltips se generan **automáticamente**: aparecen al dejar el cursor sobre un elemento cuando algún texto está cortado, o siempre que el elemento tenga `Tooltip`. Si no hay `Tooltip`, el cuerpo es la `Description` o el texto que está cortado. En modo compacto, las pestañas muestran su nombre como tooltip.

```lua
Section:AddToggle({ Name = "Auto Farm", Tooltip = "Farmea automáticamente el mob más cercano" })
```

Config: `Tooltip = { Enabled = true, Delay = 0.55, MaxWidth = 250 }`. También se puede desactivar desde la pestaña de ajustes.

---

## Temas

Los temas se aplican **en vivo**: puedes cambiarlos en cualquier momento y toda la interfaz se repinta sin recrearse.

### Temas incluidos

| Tema | Estilo |
| --- | --- |
| `Cookies` | Marrón chocolate con acento dorado (por defecto) |
| `Mocha` | Café claro con acento naranja |
| `Midnight` | Azul noche con acento azul |
| `Ocean` | Verde azulado con acento cian |
| `Matcha` | Verde oscuro con acento verde |
| `Strawberry` | Vino con acento rosa |
| `Grape` | Morado con acento violeta |
| `Graphite` | Gris neutro con acento dorado |

```lua
Library:SetTheme("Midnight")                           -- por nombre
Library:SetTheme({ Accent = Color3.fromRGB(255, 80, 80) })   -- solo algunos colores
Library:SetAccent(Color3.fromRGB(170, 120, 255))       -- solo el acento

local temas = Library:GetThemes()     -- { "Cookies", "Mocha", ... }
local actual = Library.CurrentTheme   -- nombre del tema actual
```

También al crear la ventana: `Library:CreateWindow({ Theme = "Ocean" })` o `Library:Configure({ Theme = { ... } })`.

> Si el usuario eligió un tema o un acento en **Ajustes**, esa elección se guarda y tiene prioridad sobre el tema del script la próxima vez que lo ejecute.

### Crear tu propio tema

```lua
Library:AddTheme("Lava", {
    Background = Color3.fromRGB(20, 10, 8),  Panel = Color3.fromRGB(30, 14, 10),
    Element = Color3.fromRGB(38, 18, 12),    Row = Color3.fromRGB(48, 22, 14),
    RowHover = Color3.fromRGB(60, 28, 18),   Input = Color3.fromRGB(16, 8, 6),
    Stroke = Color3.fromRGB(90, 40, 24),     Outline = Color3.fromRGB(10, 5, 4),
    Accent = Color3.fromRGB(255, 110, 40),
    Text = Color3.fromRGB(250, 236, 228),    Muted = Color3.fromRGB(190, 150, 130),
    Dim = Color3.fromRGB(130, 100, 86),
    Success = Color3.fromRGB(96, 196, 124),  Warning = Color3.fromRGB(232, 148, 58),
    Error = Color3.fromRGB(224, 92, 92),
})
Library:SetTheme("Lava")   -- también aparece en el selector de Ajustes
```

| Clave | Uso |
| --- | --- |
| `Background`, `Panel`, `Element`, `Row`, `RowHover`, `Input` | Fondos |
| `Stroke`, `Outline` | Bordes |
| `Accent`, `AccentHi`, `AccentSoft`, `OnAccent` | Color de acento, su versión clara, su fondo suave y el color del texto sobre el acento |
| `Text`, `Muted`, `Dim` | Textos |
| `Success`, `Warning`, `Error` | Estados |

Al cambiar `Accent`, `AccentHi`, `AccentSoft` y `OnAccent` se recalculan solos si no los defines.

> Usa colores distintos para cada clave. Si dos claves comparten exactamente el mismo color, la librería no puede saber cuál de las dos repintar al cambiar de tema.

---

## Configuración global

`Library:Configure(tabla)` modifica `Library.Config`, que es la plantilla que copia cada `CreateWindow`.

```lua
Library:Configure({
    Animations = true,
    AnimationSpeed = 1,
    EasingStyle = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,

    Window  = { Width = 740, Height = 500, Shadow = true, AccentLine = true, SmoothDrag = true,
                RememberLayout = true, UIScale = 1, SearchShortcut = true },
    Tab     = { Columns = 2, Padding = 12, Gap = 10, IconSize = 20, IconTint = true, SingleColumnBelow = 440 },
    Section = { Collapsible = true, Minimized = false, Columns = 1, MaxHeight = nil, Gap = 6, ColumnGap = 8, Corner = 10 },
    Element = { Height = 32, Corner = 7 },
    Notify  = { Duration = 4, Width = 290, Position = "BottomRight", Max = 5, PauseOnHover = true },
    Tooltip = { Enabled = true, Delay = 0.55, MaxWidth = 250 },
    Dropdown = { SearchThreshold = 7, MaxVisible = 5 },
    Search  = { MaxResults = 40, Placeholder = "Search the whole menu..." },
    Intro   = { Enabled = true, Duration = 2, ShowBar = true, Skippable = true, OncePerSession = true },
})
```

Otros campos públicos: `Library.Version`, `Library.Theme`, `Library.Themes`, `Library.CurrentTheme`, `Library.Fonts`, `Library.Windows`.

---

## Estado guardado de la interfaz

Con `RememberLayout = true` (por defecto) y un executor con archivos, la librería guarda en `ConfigFolder/_ui_state.txt`:

| Se recuerda | Cuándo se guarda |
| --- | --- |
| Tamaño y posición de la ventana | Al soltar el arrastre o el asa de tamaño |
| Pestaña abierta | Al hacer clic en una pestaña |
| Posición y visibilidad del botón flotante | Al moverlo o cambiarlo en Ajustes |
| Tecla del menú | Al cambiarla |
| Tema, acento y escala de UI | Al cambiarlos en Ajustes |
| Animaciones, velocidad y tooltips | Al cambiarlos en Ajustes |
| Marca de agua y lista de keybinds (activas y posición) | Al cambiarlas o moverlas |
| Config de auto-carga | Al marcarla |

Este archivo **no** es una config: no aparece en la lista de configs. `Window:ResetLayout()` (o el botón *Reset Layout* de Ajustes) lo borra y vuelve a los valores del script. Con `RememberLayout = false` no se lee ni se escribe.

---

## Pestaña de ajustes

`Window:CreateSettingsTab(nombre, icono)` crea una pestaña lista para usar (por defecto `"Settings"` con icono `"S"`):

- **Appearance:** selector de tema, color de acento (con presets) y escala de la UI.
- **Interface:** tecla del menú, botón flotante, animaciones, tooltips, marca de agua, lista de keybinds, velocidad de animación, *Reset Position*, *Reset Layout* y *Unload UI* (con diálogo de confirmación).
- **Configs:** nombre, *Save Config*, selector de configs, *Load*, *Delete* (con confirmación), *Set Auto-load* / *Clear Auto-load* y *Refresh List*.

```lua
Window:CreateSettingsTab("Settings", icon("settings"))
```

Créala **al final** del script: así la auto-carga encuentra todos tus flags.

---

## Key System

`Cookieskeysystem.lua` muestra una ventana para pedir una key antes de cargar tu hub. Comparte el estilo de la librería; si le pasas `Library`, usa su tema (incluido el que eligió el usuario) y sus fuentes.

```lua
local Library   = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/CookiesLib.lua"))()
local KeySystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/Cookieskeysystem.lua"))()

local ok, key = KeySystem.Prompt({
    Library = Library,                         -- opcional: hereda tema y fuentes
    Title = "Cookies Hub",
    Subtitle = "Key System",
    KeyLink = "https://tu-enlace-de-keys",     -- botón "Get key" (copia el enlace)
    DiscordLink = "https://discord.gg/xxxxxx", -- botón "Join Discord"
    Keys = { "COOKIE-1234", "COOKIE-5678" },   -- lista local de keys válidas
})
if not ok then return end   -- el usuario cerró sin key

-- ...aquí cargas tu hub / creas la ventana
```

`KeySystem.Prompt(opts)` es un atajo de `KeySystem.new(opts):Wait()`.

### Cómo se valida la key

Se usa **el primer método disponible**, en este orden:

1. **`KeyForge`** (servicio externo, ver abajo).
2. **`Validate`**: tu propia función.
3. **`KeyUrl`**: URL con una key por línea (se guarda en caché 30 s).
4. **`Keys`**: lista local.

```lua
-- Función propia: devuelve (válida: boolean, mensaje: string?)
Validate = function(key)
    if key == "secreta" then return true, "Bienvenido" end
    return false, "Key incorrecta"
end

-- Lista remota (una key por línea, se ignoran líneas vacías)
KeyUrl = "https://raw.githubusercontent.com/usuario/repo/main/keys.txt"
```

Los espacios al inicio y al final de la key se ignoran. Con `CaseSensitive = false`, `cookie-1234` y `COOKIE-1234` son la misma key (aplica a `Keys` y `KeyUrl`).

> ⚠️ Una lista `Keys` dentro del script es visible para cualquiera que lo lea. Para algo más serio usa `KeyUrl`, `Validate` contra tu backend o KeyForge.

### Opciones

| Opción | Por defecto | Descripción |
| --- | --- | --- |
| `Library` | `nil` | Librería para heredar `Theme` y `Fonts` |
| `Theme` | `nil` | Tabla de colores, o nombre de un tema de `Library.Themes` (requiere `Library`) |
| `Accent` | `nil` | Color de acento solo para el Key System |
| `Title` / `Subtitle` | `"Cookies Hub"` / `"Key System"` | Textos de cabecera |
| `Logo` | logo de Cookies | Imagen; `false` o `""` para quitarla |
| `Description` | `"Enter your key to unlock the hub."` | Texto bajo el título |
| `Steps` | 3 pasos en inglés | Lista de hasta 3 pasos en el panel "Need a key?" |
| `Note` | `nil` | Texto libre en lugar de los pasos (si das `Note` y no `Steps`) |
| `KeyLink` | `nil` | Enlace del botón **Get key** |
| `DiscordLink` / `DiscordCode` | `nil` | Botón **Join Discord**. El código se deduce de `discord.gg/<código>` si no lo das |
| `Keys` | `nil` | Lista local de keys |
| `KeyUrl` | `nil` | URL con keys remotas |
| `Validate` | `nil` | Función de validación propia |
| `CaseSensitive` | `true` | `false` ignora mayúsculas/minúsculas (`Keys` y `KeyUrl`) |
| `KeyForge` | `nil` | Configuración de KeyForge |
| `LoadScript` | `nil` | Con KeyForge: ejecuta el script protegido tras validar |
| `SaveKey` | `true` | Permite recordar la key en disco |
| `AutoVerify` | `true` | Verifica automáticamente la key guardada al abrir |
| `Folder` / `FileName` | `"CookiesHub"` / `"key.txt"` | Dónde se guarda la key |
| `MaxAttempts` | `5` | Intentos fallidos antes del bloqueo temporal |
| `Cooldown` | `15` | Segundos de bloqueo |
| `Blur` | `true` | Desenfoque de fondo |
| `Shadow` | `true` | Sombra detrás de la ventana |
| `DisplayOrder` | `100` | `DisplayOrder` del `ScreenGui` |
| `OnSuccess` | `nil` | `function(key)` al validar |
| `OnFail` | `nil` | `function(key, mensaje)` en cada intento fallido |
| `OnClose` | `nil` | `function()` si el usuario cierra sin validar |

```lua
-- pasos y textos propios (por ejemplo en español)
KeySystem.new({
    Library = Library,
    Description = "Escribe tu key para desbloquear el hub.",
    Steps = {
        "Pulsa Get key para copiar el enlace",
        "Completa los pasos en tu navegador",
        "Pega tu key y pulsa Verify",
    },
    Accent = Color3.fromRGB(255, 105, 140),
    Keys = { "COOKIE-1234" },
    CaseSensitive = false,
})
```

### Objeto devuelto

```lua
local ks = KeySystem.new({ ... })
ks:Wait()                     -- bloquea hasta terminar; devuelve (success, key)
ks:Submit("key")              -- envía una key por código (sin argumento usa el texto escrito)
ks:SetStatus("Texto", "Warning")   -- mensaje bajo el botón: Success | Warning | Error | nil
ks:Close()                    -- cierra sin validar (success = false)
ks:Destroy()                  -- cierra y limpia todo
```

Campos: `ks.Done`, `ks.Success`, `ks.Key`, `ks.Gui`, `ks.Theme`, `ks.Client` (cliente de KeyForge, si se usó).

También puedes usar callbacks en vez de `Wait()`:

```lua
KeySystem.new({
    Keys = { "abc" },
    OnSuccess = function(key) loadstring(game:HttpGet("URL_DEL_HUB"))() end,
    OnFail = function(key, msg) warn("Key incorrecta:", key) end,
    OnClose = function() warn("Key system cerrado") end,
})
```

### Comportamiento de la interfaz

- **Key recordada:** si el executor soporta archivos, aparece la casilla *Remember key* y el botón *Delete saved key*. Al abrir, la key guardada se rellena y, con `AutoVerify`, se verifica sola. Si deja de ser válida se borra; si falla por un error de conexión se conserva.
- **Intentos:** se muestra cuántos quedan (en naranja cuando queda uno). Al agotar `MaxAttempts` el botón se bloquea `Cooldown` segundos. El bloqueo **sigue activo** aunque se vuelva a ejecutar el script en la misma partida.
- **Errores de conexión** (KeyUrl caído, KeyForge sin respuesta, error en `Validate`) no cuentan como intento fallido.
- **Botones condicionales:** *Get key* solo aparece con `KeyLink` o `KeyForge`; *Join Discord* con `DiscordLink` o `DiscordCode`; *Paste* solo si el executor tiene portapapeles.
- La ventana se puede arrastrar desde su parte superior y se escala en pantallas pequeñas.

### KeyForge

Integración opcional con [KeyForge](https://www.keyforge.win). El SDK se descarga **al abrir la ventana** (en segundo plano, así verificar es casi instantáneo) desde `https://www.keyforge.win/sdk/client.lua` (se puede cambiar con `sdkUrl`) y requiere `loadstring`.

```lua
KeySystem.new({
    Library = Library,
    DiscordLink = "https://discord.gg/xxxxxx",
    KeyForge = {
        projectId = "TU_PROJECT_ID",
        scriptId = "TU_SCRIPT_ID",
        integrationToken = "TU_TOKEN",
        -- sdkUrl = "https://...",   -- opcional
    },
    LoadScript = true,   -- ejecuta el script protegido de KeyForge al validar
})
```

Los IDs y el token firmado (`integrationToken`) los da el dashboard de KeyForge: edita un script con key, abre **In-game UI** y elige **Custom Lua GUI**. Guía oficial: <https://www.keyforge.win/en/docs/custom-lua-gui>

El Key System usa las tres llamadas del SDK de KeyForge:

| Botón / momento | Llamada | Qué hace la ventana |
| --- | --- | --- |
| **Get key** | `client:getKeyUrl()` | Copia el enlace. Si no hay página de keys enlazada, muestra el `message` de KeyForge |
| **Verify** | `client:verify(key)` | Si `ok`, la key es válida; si no, muestra el `message` de KeyForge |
| Justo después de validar (`LoadScript = true`) | `client:loadScript()` | Muestra *"Loading securely..."*. Si falla, la ventana **no se cierra** y muestra el motivo; el jugador puede volver a pulsar **Verify** (el token de acceso es de un solo uso) |

Códigos de resultado y cómo los trata la ventana:

| Código | Significado | ¿Gasta un intento? |
| --- | --- | --- |
| `KEY_INVALID` | La key no existe o el campo está vacío | Sí |
| `KEY_EXPIRED` | La key caducó | Sí (y se borra la key guardada) |
| `KEY_REVOKED` | La key fue revocada | Sí (y se borra la key guardada) |
| `KEY_SCRIPT_MISMATCH` | La key es de otro script | Sí |
| `HWID_MISMATCH` | La key está ligada a otro dispositivo | Sí |
| `RATE_LIMITED` | Demasiados intentos en KeyForge | No |
| `SESSION_EXPIRED` | La verificación caducó | No |
| `NETWORK_ERROR` | El executor no pudo conectar con KeyForge | No |
| `PROJECT_DISABLED` | Proyecto desactivado o entrega pausada | No |

> KeyForge se encarga del estado de las keys, los límites, el HWID y la entrega del script. No pongas secretos, código fuente ni reglas de validación en tu GUI: un script volcado se puede leer.

---

## Ejemplo completo

Hub de ejemplo con key system, iconos, elementos nuevos, estadísticas en vivo y loops que se detienen al descargar.

```lua
local BASE = "https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/"
local Library   = loadstring(game:HttpGet(BASE .. "CookiesLib.lua"))()
local KeySystem = loadstring(game:HttpGet(BASE .. "Cookieskeysystem.lua"))()
local Lucide = loadstring(game:HttpGet(
    "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"
))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function icon(name)
    local ok, asset = pcall(Lucide.GetAsset, name, 48)
    return ok and asset or nil
end

----------------------------------------------------------------
-- 1) Key system
----------------------------------------------------------------
local ok = KeySystem.Prompt({
    Library = Library,
    KeyLink = "https://tu-enlace-de-keys",
    DiscordLink = "https://discord.gg/xxxxxx",
    Keys = { "COOKIE-1234" },
    CaseSensitive = false,
})
if not ok then return end

----------------------------------------------------------------
-- 2) Ventana
----------------------------------------------------------------
local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "Blox Fruits",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = "Cookies",
    Notify = { Position = "TopRight" },
})

local running = true
Window:OnUnload(function() running = false end)

----------------------------------------------------------------
-- 3) Inicio
----------------------------------------------------------------
Window:AddTabCategory("General")
local Home = Window:CreateTab("Home", icon("home"))

local Info = Home:CreateSection({ Name = "Bienvenido", Full = true })
Info:AddAlert({ Type = "Info", Title = "Cookies Hub", Content = "Pulsa <b>RightShift</b> para ocultar el menú." })

local Stats = Home:CreateSection({ Name = "Estadísticas", Icon = icon("line-chart"), Column = "Left" })
local sLevel = Stats:AddStat({ Name = "Nivel", Value = "-" })
local sMoney = Stats:AddStat({ Name = "Dinero", Value = "-", Color = Color3.fromRGB(96, 196, 124) })

local Links = Home:CreateSection({ Name = "Comunidad", Icon = icon("users"), Column = "Right" })
Links:AddCopyField({ Name = "Discord", Text = "discord.gg/xxxxxx" })

task.spawn(function()
    while running do
        local ls = LocalPlayer:FindFirstChild("leaderstats")
        if ls then
            local lvl, money = ls:FindFirstChild("Level"), ls:FindFirstChild("Money")
            if lvl then sLevel:Set(lvl.Value) end
            if money then sMoney:Set("$" .. money.Value) end
        end
        task.wait(1)
    end
end)

----------------------------------------------------------------
-- 4) Farm
----------------------------------------------------------------
Window:AddTabCategory("Game")
local Farm = Window:CreateTab({ Name = "Farm", Icon = icon("swords"), Badge = "NEW" })

local Auto = Farm:CreateSection({ Name = "Auto Farm", Icon = icon("bot"), Column = "Left" })
Auto:AddToggle({
    Name = "Auto Farm", Description = "Ataca al mob más cercano", Flag = "AutoFarm",
    Keybind = { Default = "F", Flag = "AutoFarmKey" },
    Callback = function(v) print("Auto Farm", v) end,
})
Auto:AddSegmented({ Name = "Modo", Options = { "Seguro", "Normal", "Rápido" }, Default = "Normal", Flag = "FarmMode" })
Auto:AddRangeSlider({ Name = "Nivel de mobs", Min = 1, Max = 2550, Default = { 1, 700 }, Flag = "MobRange" })
Auto:AddNumber({ Name = "Distancia", Min = 5, Max = 50, Default = 15, Suffix = " st", Flag = "FarmDistance" })

local Pvp = Farm:CreateSection({ Name = "PvP", Icon = icon("crosshair"), Column = "Right" })
local target = Pvp:AddPlayerDropdown({ Name = "Objetivo" })
Pvp:AddButton({ Name = "Ir al objetivo", Primary = true, Callback = function()
    local p = target:GetPlayer()
    if not p then return Window:Notify({ Title = "PvP", Content = "Elige un jugador", Type = "Warning" }) end
    Window:Dialog({
        Title = "¿Teletransportar?",
        Content = "Irás junto a <b>" .. p.DisplayName .. "</b>.",
        Callback = function()
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local theirRoot = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if myRoot and theirRoot then myRoot.CFrame = theirRoot.CFrame * CFrame.new(0, 0, 3) end
        end,
    })
end })
Pvp:AddButton({ Name = "Resetear personaje", Style = "Danger", Confirm = true, Callback = function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.Health = 0 end
end })

----------------------------------------------------------------
-- 5) Visuales
----------------------------------------------------------------
local Visuals = Window:CreateTab("Visuals", icon("eye"))
local Esp = Visuals:CreateSection({ Name = "ESP", Icon = icon("scan-eye") })
local b1, b2 = Esp:AddColumns(2)
b1:AddToggle({ Name = "Cajas", Style = "Checkbox", Flag = "EspBoxes" })
b2:AddToggle({ Name = "Nombres", Style = "Checkbox", Flag = "EspNames" })
Esp:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(245, 194, 12), Flag = "EspColor" })
Esp:AddSlider({ Name = "Distancia máx.", Min = 100, Max = 5000, Increment = 100, Default = 1000, Suffix = " st", Flag = "EspDist" })

----------------------------------------------------------------
-- 6) Ajustes (siempre al final: la auto-carga encuentra todos los flags)
----------------------------------------------------------------
Window:CreateSettingsTab("Settings", icon("settings"))

Window:Notify({ Title = "Cookies Hub", Content = "Cargado correctamente", Type = "Success" })
```

---

## Notas y solución de problemas

- **No veo la ventana al ejecutar:** la intro mantiene el menú oculto ~2 segundos (un clic la salta). Si usas `Intro = { Enabled = false }` aparece de inmediato.
- **La intro no sale al re-ejecutar:** es intencional (`OncePerSession = true`). Pon `Intro = { OncePerSession = false }` para verla siempre.
- **Cerré la ventana y no puedo volver a abrirla:** usa la `ToggleKey` o el botón flotante. En móvil no pongas `FloatingButton = false` salvo que tengas otra forma de abrirla.
- **La ventana aparece en otro lugar / otro tamaño / otro tema:** la librería recuerda lo que dejó el usuario. Usa *Reset Layout* en Ajustes, `Window:ResetLayout()` o `RememberLayout = false`.
- **Mi tema no se aplica:** si el usuario eligió otro tema en Ajustes, su elección tiene prioridad. *Reset Layout* no lo cambia; elige el tema de nuevo en Ajustes.
- **Mi callback se ejecuta al cargar una config:** es el comportamiento normal de `LoadConfig` (y de la auto-carga). Dentro del callback puedes comprobar tu propio estado, o usar `:Set(valor, true)` para cambios silenciosos por código.
- **La auto-carga no aplica algunas opciones:** crea la pestaña de ajustes al final, o llama a `Window:LoadAutoloadConfig()` cuando ya existan todos tus elementos.
- **Mis loops siguen después de *Unload UI*:** detenlos con `Window:OnUnload(function() running = false end)`.
- **`Lucide.GetAsset` falla:** el nombre del icono no existe; usa el helper con `pcall` de la sección de iconos.
- **El Key System no recuerda la key:** el executor debe soportar `writefile/readfile/isfolder/makefolder/isfile`, y la casilla *Remember key* debe estar marcada al validar.
- **Dos ventanas:** `Library.Flags` es global, así que los nombres de `Flag` deben ser únicos entre ventanas.

---

## Créditos y licencias

- **Lucide Icons** — set de iconos de [lucide.dev](https://lucide.dev), licencia ISC.
- **lucide-roblox** — conversión de Lucide a Roblox por **latte-soft**: <https://github.com/latte-soft/lucide-roblox> (licencia MIT).
- **KeyForge** — servicio opcional de keys usado por el Key System: <https://www.keyforge.win>
- **Cookies Hub / CookiesLib** — repositorio: <https://github.com/Lilwero20/CookiesLib>
