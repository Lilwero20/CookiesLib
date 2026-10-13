# 🍪 Cookies Hub

Librería de UI para Roblox escrita en Luau, más un **Key System** opcional que usa el mismo tema visual.

| Archivo | Qué es | Versión |
| --- | --- | --- |
| `CookiesLib.lua` | Librería de UI (ventana, pestañas, secciones, elementos, configs, búsqueda, notificaciones) | **3.4.0** |
| `Cookieskeysystem.lua` | Ventana de verificación de keys (lista local, URL remota, función propia o KeyForge) | **1.0.0** |

**Lo que incluye la UI:** ventana arrastrable y redimensionable · intro animada · pestañas con icono · secciones minimizables · búsqueda global · tooltips automáticos · dropdowns con buscador · guardado de configs · notificaciones · diseño adaptable a PC y móvil.

---

## Contenido

1. [Requisitos](#requisitos)
2. [Inicio rápido](#inicio-rápido)
3. [Ventana](#ventana)
4. [Pestañas](#pestañas)
5. [Iconos (Lucide y otros)](#iconos-lucide-y-otros)
6. [Secciones](#secciones)
7. [Elementos](#elementos)
8. [Flags y configs](#flags-y-configs)
9. [Notificaciones](#notificaciones)
10. [Búsqueda global](#búsqueda-global)
11. [Tooltips](#tooltips)
12. [Tema y configuración global](#tema-y-configuración-global)
13. [Pestaña de ajustes](#pestaña-de-ajustes)
14. [Key System](#key-system)
15. [Ejemplo completo](#ejemplo-completo)
16. [Notas y solución de problemas](#notas-y-solución-de-problemas)
17. [Créditos y licencias](#créditos-y-licencias)

---

## Requisitos

La librería está pensada para ejecutarse en un **executor** del lado del cliente (LocalScript). Necesita `game:HttpGet` y `loadstring` para cargarse desde una URL. El resto de funciones del executor son **opcionales** y la librería se adapta si no existen:

| Función del executor | Para qué se usa | Si no existe |
| --- | --- | --- |
| `gethui` | Colocar la UI en un contenedor oculto | Usa `PlayerGui` |
| `writefile`, `readfile`, `isfolder`, `makefolder` | Guardar/cargar configs | Guardar/cargar se desactiva (devuelve `false, mensaje`) |
| `listfiles` | Listar configs (`Window:GetConfigs()`) | La lista sale vacía |
| `isfile`, `delfile` | Key System: key recordada | Se desactiva "Remember key" |
| `setclipboard` / `toclipboard` | Key System: copiar enlaces | Muestra el enlace en texto |
| `getclipboard` / `fromclipboard` | Key System: botón **Paste** | El botón no aparece |
| `request` / `http_request` | Key System: abrir invitación de Discord | Solo copia el enlace |

La UI se crea con el nombre `CookiesHubUI` (y `CookiesKeyUI` el Key System). Si ya existe una con ese nombre, se destruye antes de crear la nueva.

---

## Inicio rápido

```lua
local Library = loadstring(game:HttpGet("URL_RAW_DE_CookiesLib.lua"))()

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
    Callback = function(value)
        print("Auto Farm:", value)
    end,
})

Window:CreateSettingsTab()
```

Qué ocurre al ejecutarlo:

1. Se reproduce la **intro** (logo + barra de carga) y después aparece la ventana.
2. Se muestra el **botón flotante** (logo) en el borde izquierdo. Un clic abre/cierra la ventana; también se puede arrastrar.
3. `RightShift` muestra/oculta la ventana.
4. La ventana oculta con la `x` **no se destruye**: se vuelve a abrir con la tecla o el botón flotante.

`Library.new(opts)` es un alias de `Library:CreateWindow(opts)`.

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
    Intro   = { Enabled = true, Duration = 2.4 },
    Tab     = { IconSize = 20 },
    Section = { Collapsible = true },
    Notify  = { Duration = 4 },

    -- Tema (se aplica a toda la librería, ver "Tema")
    Theme = { Accent = Color3.fromRGB(245, 194, 12) },
})
```

Las opciones que no son `Theme`, `Config` ni una sub-configuración (`Tab`, `Section`, `Element`, `Notify`, `Tooltip`, `Dropdown`, `Search`, `Intro`) se interpretan como opciones de ventana. También puedes pasar `Config = { ... }` para sobrescribir cualquier valor de [`Library.Config`](#tema-y-configuración-global) solo en esa ventana.

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
| `ToggleKey` | `RightShift` | Tecla para mostrar/ocultar |
| `FloatingButton` | `true` | Botón flotante. Con `false` se oculta también en táctil |
| `Resizable` | `true` | Asa de redimensionado (esquina inferior derecha). Máx. 2000×1400 |
| `Draggable` | `true` | Arrastrar desde la barra superior |
| `Minimizable` | `true` | Botón `-` |
| `Closable` | `true` | Botón `x` (oculta, no destruye) |
| `Searchable` | `true` | Botón de lupa (búsqueda global) |
| `ShowProfile` | `true` | Tarjeta con avatar y nombre en la barra lateral |
| `DisplayOrder` | `50` | `DisplayOrder` del `ScreenGui` |
| `Corner` | `10` | Radio de las esquinas de la ventana |
| `ConfigFolder` | `"CookiesHub"` | Carpeta donde se guardan las configs |

### Intro

Al crear la ventana se reproduce una intro: la ventana permanece oculta hasta que termina y entonces se abre con su animación normal. Mientras dura, `Window:SetVisible/Show/Hide/Toggle` no hacen nada.

| Opción (`Intro = {...}`) | Por defecto | Descripción |
| --- | --- | --- |
| `Enabled` | `true` | `false` para omitir la intro |
| `Duration` | `2.4` | Duración total en segundos (mínimo efectivo: 1) |
| `Logo` | logo de intro | Imagen (PNG sin fondo recomendado) |
| `Width`, `Height` | `300`, `180` | Tamaño de la imagen |
| `ShowBar` | `true` | Barra de carga bajo el logo |

### Métodos de `Window`

```lua
Window:Toggle()   Window:Show()   Window:Hide()
Window:SetVisible(true)
Window:Minimize()               -- alterna; Window:Minimize(true / false) para forzar
Window:Resize(800, 520)         -- respeta MinWidth/MinHeight
Window:SetTitle("Nuevo título")
Window:SetSubtitle("Texto")
Window:SetToggleKey(Enum.KeyCode.K)   -- acepta Enum.KeyCode o su nombre como string
Window:SetFloatingButton(false)
Window:ResetPosition()
Window:AddTabCategory("Combat") -- separador de texto en la barra lateral (se oculta en modo compacto)
Window:CreateTab(...)           -- ver "Pestañas"
Window:CreateSettingsTab()      -- ver "Pestaña de ajustes"
Window:GetTab("Main")           -- devuelve la pestaña o nil
Window:SelectTab("Main")        -- acepta nombre o el objeto pestaña
Window:Notify({ ... })          -- ver "Notificaciones"
Window:SaveConfig("nombre")  Window:LoadConfig("nombre")  Window:GetConfigs()
Window:OpenSearch("texto")  Window:CloseSearch()  Window:ToggleSearch()  Window:SetSearch("texto")
Window:Destroy()                -- elimina la UI y libera los flags de esta ventana
```

Campos útiles: `Window.Tabs`, `Window.ActiveTab`, `Window.Visible`, `Window.Minimized`, `Window.Gui`, `Window.Config`.

### Comportamiento adaptable

- **Modo compacto:** si el ancho efectivo es menor que `CompactBelow`, la barra lateral muestra solo iconos (el nombre de la pestaña aparece como tooltip) y se ocultan las categorías.
- **Una sola columna:** si el área de contenido es más estrecha que `Tab.SingleColumnBelow` (440), las pestañas pasan a 1 columna.
- **AutoScale:** en pantallas pequeñas la ventana se escala para caber. Se vuelve a calcular cuando cambia el tamaño de la pantalla.
- La ventana y el botón flotante se mantienen dentro de la pantalla al arrastrarlos.
- Al **minimizar**, queda visible solo la barra superior.

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

La primera pestaña creada se selecciona automáticamente.

Métodos de `Tab`:

```lua
Tab:Select()
Tab:SetName("Inicio")
Tab:SetIcon(Lucide.GetAsset("flame", 48))
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

local Home    = Window:CreateTab("Home", icon("house"))
local Combat  = Window:CreateTab("Combat", icon("swords"))

local Section = Combat:CreateSection({
    Name = "Aimbot",
    Icon = icon("crosshair"),
    IconColor = Color3.fromRGB(245, 194, 12),   -- opcional, por defecto el acento
})

Combat:SetIcon(icon("flame"))                   -- cambiarlo después
```

Los nombres son los de Lucide en minúsculas con guiones (`"house"`, `"server-crash"`, `"user-round"`…). Lista completa: [icon-index](https://github.com/latte-soft/lucide-roblox/blob/master/md/icon-index.md) o `Lucide.IconNames`.

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
Tab:CreateSection({ Name = "Ancha",     Full = true })      -- ocupa todo el ancho
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

### Métodos comunes (Button, Toggle, Slider, Dropdown, Keybind, TextBox, ColorPicker, Progress)

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
    Callback = function() print("clic") end,
})
btn:Click()                      -- dispara el botón por código
btn:SetText("Otro texto")
```

### Toggle

```lua
local t = Section:AddToggle({
    Name = "ESP", Description = "Muestra jugadores",
    Default = false, Color = Color3.fromRGB(96, 196, 124),
    Flag = "ESP",
    Callback = function(v) end,       -- v: boolean
})
t:Set(true)   t:Toggle()   t:Get()
```

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

### Dropdown

```lua
local d = Section:AddDropdown({
    Name = "Objetivo", Options = { "Head", "Torso", "Legs" },
    Default = "Head", Multi = false,
    Placeholder = "Select...",
    Searchable = nil,         -- nil = el buscador aparece solo con 7+ opciones
    MaxVisible = 5,
    Flag = "Target",
    Callback = function(v) end,       -- v: valor, o tabla (copia) si Multi = true
})

d:Set("Torso")                -- con Multi: d:Set({ "Head", "Torso" })
d:Get()
d:SetOpen(true)
d:Refresh({ "A", "B" }, true) -- reemplaza opciones; 2º argumento = conservar valor (alias: SetOptions)
d:AddOption("Nueva")
d:RemoveOption("A")
```

Las opciones se muestran con `tostring`, pero el valor devuelto es el original (puedes usar números u otros valores). Con `Multi = true`, `Default` y `Set` reciben una tabla; opciones que no existan se ignoran. El buscador se reinicia al cerrar.

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

### Elementos de texto y diseño

```lua
local lbl = Section:AddLabel("Texto informativo")
Section:AddLabel({ Text = "Aviso", Color = Color3.fromRGB(232, 148, 58), Size = 12 })
lbl:SetText("Nuevo texto")   lbl:SetColor(Color3.new(1, 1, 1))   lbl:SetVisible(false)   lbl:Destroy()

local para = Section:AddParagraph({ Title = "Título", Content = "Descripción más larga" })
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
local lista   = Window:GetConfigs()              -- { "mi-config", ... }
```

- Las configs son JSON; **no hay guardado automático**, solo cuando llamas a `SaveConfig`.
- Se guardan **todos** los flags registrados en `Library` (de todas las ventanas) salvo los que no son guardables (`Progress`).
- Formato: `ColorPicker` → `{R, G, B}`; `Keybind` → nombre de la tecla; `Dropdown` múltiple → lista; el resto, su valor.
- **`LoadConfig` ejecuta los callbacks** de cada elemento (aplica el valor sin modo silencioso).
- Los flags que no existan al cargar se ignoran.
- Los elementos sin `Flag` (incluida la [pestaña de ajustes](#pestaña-de-ajustes)) no se guardan.
- Si el executor no soporta archivos, `SaveConfig`/`LoadConfig` devuelven `false` y un mensaje.

---

## Notificaciones

```lua
Window:Notify({
    Title = "Cookies Hub",
    Content = "Config cargada",
    Type = "Success",        -- Info | Success | Warning | Error
    Duration = 4,            -- 0 = no se cierra sola (clic para cerrar)
    Color = Color3.fromRGB(245, 194, 12),   -- opcional: sustituye el color del tipo
})

Window:Notify("Solo título")        -- atajo con string
Library:Notify({ Title = "Hola" })  -- usa la ventana creada más recientemente

local n = Window:Notify({ Title = "Cargando...", Duration = 0 })
n.Close()
```

Un clic sobre la notificación la cierra. Config global: `Notify = { Duration = 4, Width = 290 }`.

---

## Búsqueda global

El botón de **lupa** de la barra superior abre un buscador que indexa pestañas, secciones y elementos (por nombre, descripción, pestaña, sección y tipo). Escribir varias palabras exige que **todas** coincidan. Al elegir un resultado se abre la pestaña, se despliega la sección, se hace scroll y se resalta el elemento. `Esc` cierra la búsqueda.

```lua
Window:OpenSearch("speed")   -- abre con texto
Window:SetSearch("")         -- cambia el texto
Window:ToggleSearch()
Window:CloseSearch()
```

Se desactiva con `Searchable = false`. Config: `Search = { MaxResults = 40, Placeholder = "Search the whole menu..." }`.

Los elementos y pestañas ocultos (`SetVisible(false)`) no aparecen en los resultados.

---

## Tooltips

Los tooltips se generan **automáticamente**: aparecen al dejar el cursor sobre un elemento cuando algún texto está cortado, o siempre que el elemento tenga `Tooltip`. Si no hay `Tooltip`, el cuerpo es la `Description` o el texto que está cortado. En modo compacto, las pestañas muestran su nombre como tooltip.

```lua
Section:AddToggle({ Name = "Auto Farm", Tooltip = "Farmea automáticamente el mob más cercano" })
```

Config: `Tooltip = { Enabled = true, Delay = 0.55, MaxWidth = 250 }`. También se puede desactivar desde la pestaña de ajustes.

---

## Tema y configuración global

### Tema

```lua
Library:SetTheme({ Accent = Color3.fromRGB(245, 194, 12) })
-- o al crear la ventana: Library:CreateWindow({ Theme = { ... } })
-- o: Library:Configure({ Theme = { ... } })
```

Llámalo **antes de `CreateWindow`**: los colores se leen al construir la UI y no se repintan los elementos ya creados.

| Clave | Uso |
| --- | --- |
| `Background`, `Panel`, `Element`, `Row`, `RowHover`, `Input` | Fondos |
| `Stroke`, `Outline` | Bordes |
| `Accent`, `AccentHi`, `AccentSoft`, `OnAccent` | Color de acento, su versión clara, su fondo suave y el color del texto sobre el acento |
| `Text`, `Muted`, `Dim` | Textos |
| `Success`, `Warning`, `Error` | Estados |

Al cambiar `Accent`, `AccentHi`, `AccentSoft` y `OnAccent` se recalculan solos si no los defines.

### Configuración global

`Library:Configure(tabla)` modifica `Library.Config`, que es la plantilla que copia cada `CreateWindow`.

```lua
Library:Configure({
    Animations = true,
    AnimationSpeed = 1,
    EasingStyle = Enum.EasingStyle.Quint,
    EasingDirection = Enum.EasingDirection.Out,

    Window  = { Width = 740, Height = 500 },
    Tab     = { Columns = 2, Padding = 12, Gap = 10, IconSize = 20, IconTint = true, SingleColumnBelow = 440 },
    Section = { Collapsible = true, Minimized = false, Columns = 1, MaxHeight = nil, Gap = 6, ColumnGap = 8, Corner = 8 },
    Element = { Height = 32, Corner = 6 },
    Notify  = { Duration = 4, Width = 290 },
    Tooltip = { Enabled = true, Delay = 0.55, MaxWidth = 250 },
    Dropdown = { SearchThreshold = 7, MaxVisible = 5 },
    Search  = { MaxResults = 40, Placeholder = "Search the whole menu..." },
    Intro   = { Enabled = true, Duration = 2.4, ShowBar = true },
})
```

Otros campos públicos: `Library.Version`, `Library.Theme`, `Library.Fonts`, `Library.Windows`.

---

## Pestaña de ajustes

`Window:CreateSettingsTab(nombre, icono)` crea una pestaña lista para usar (por defecto `"Settings"` con icono `"S"`):

- **Interface:** tecla del menú, botón flotante, animaciones, tooltips, velocidad de animación, restablecer posición y *Unload UI*.
- **Configs:** nombre, *Save Config*, selector de configs, *Load Selected* y *Refresh List*.

```lua
Window:CreateSettingsTab("Settings", icon("settings"))
```

---

## Key System

`Cookieskeysystem.lua` muestra una ventana para pedir una key antes de cargar tu hub. Comparte el estilo de la librería; si le pasas `Library`, usa su tema y fuentes.

```lua
local KeySystem = loadstring(game:HttpGet("URL_RAW_DE_Cookieskeysystem.lua"))()
local Library   = loadstring(game:HttpGet("URL_RAW_DE_CookiesLib.lua"))()

local ks = KeySystem.new({
    Library = Library,                         -- opcional: hereda tema y fuentes
    Title = "Cookies Hub",
    Subtitle = "Key System",
    KeyLink = "https://tu-enlace-de-keys",     -- botón "Get key" (copia el enlace)
    DiscordLink = "https://discord.gg/xxxxxx", -- botón "Join Discord"
    Keys = { "COOKIE-1234", "COOKIE-5678" },   -- lista local de keys válidas
})

local ok, key = ks:Wait()   -- espera a que termine (éxito o cierre)
if not ok then return end

-- ...aquí cargas tu hub / creas la ventana
```

### Cómo se valida la key

Se usa **el primer método disponible**, en este orden:

1. **`KeyForge`** (servicio externo, ver abajo).
2. **`Validate`**: tu propia función.
3. **`KeyUrl`**: URL con una key por línea (se descarga con `HttpGet` en cada intento).
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

> ⚠️ Una lista `Keys` dentro del script es visible para cualquiera que lo lea. Para algo más serio usa `KeyUrl`, `Validate` contra tu backend o KeyForge.

### Opciones

| Opción | Por defecto | Descripción |
| --- | --- | --- |
| `Library` | `nil` | Librería para heredar `Theme` y `Fonts` |
| `Title` / `Subtitle` | `"Cookies Hub"` / `"Key System"` | Textos de cabecera |
| `Logo` | logo de Cookies | Imagen; `false` o `""` para quitarla |
| `Description` | `"Enter your key to unlock the hub."` | Texto bajo el título |
| `Note` | texto de ayuda | Texto del panel derecho "Need a key?" |
| `KeyLink` | `nil` | Enlace del botón **Get key** |
| `DiscordLink` / `DiscordCode` | `nil` | Botón **Join Discord**. El código se deduce de `discord.gg/<código>` si no lo das |
| `Keys` | `nil` | Lista local de keys |
| `KeyUrl` | `nil` | URL con keys remotas |
| `Validate` | `nil` | Función de validación propia |
| `KeyForge` | `nil` | Configuración de KeyForge |
| `LoadScript` | `nil` | Con KeyForge: ejecuta el script protegido tras validar |
| `SaveKey` | `true` | Permite recordar la key en disco |
| `AutoVerify` | `true` | Verifica automáticamente la key guardada al abrir |
| `Folder` / `FileName` | `"CookiesHub"` / `"key.txt"` | Dónde se guarda la key |
| `MaxAttempts` | `5` | Intentos fallidos antes del bloqueo temporal |
| `Cooldown` | `15` | Segundos de bloqueo |
| `Blur` | `true` | Desenfoque de fondo |
| `DisplayOrder` | `100` | `DisplayOrder` del `ScreenGui` |
| `OnSuccess` | `nil` | `function(key)` al validar |
| `OnClose` | `nil` | `function()` si el usuario cierra sin validar |

### Objeto devuelto

```lua
ks:Wait()            -- bloquea hasta terminar; devuelve (success, key)
ks:Submit("key")     -- envía una key por código (sin argumento usa el texto escrito)
ks:Close()           -- cierra sin validar (success = false)
ks:Destroy()         -- cierra y limpia todo
```

Campos: `ks.Done`, `ks.Success`, `ks.Key`, `ks.Gui`, `ks.Client` (cliente de KeyForge, si se usó).

También puedes usar callbacks en vez de `Wait()`:

```lua
KeySystem.new({
    Keys = { "abc" },
    OnSuccess = function(key) loadstring(game:HttpGet("URL_DEL_HUB"))() end,
    OnClose = function() warn("Key system cerrado") end,
})
```

### Comportamiento de la interfaz

- **Key recordada:** si el executor soporta archivos, aparece la casilla *Remember key* y el botón *Delete saved key*. Al abrir, la key guardada se rellena y, con `AutoVerify`, se verifica sola. Si deja de ser válida se borra; si falla por un error de conexión se conserva.
- **Intentos:** se muestra cuántos quedan. Al agotar `MaxAttempts` el botón se bloquea `Cooldown` segundos.
- **Botones condicionales:** *Get key* solo aparece con `KeyLink` o `KeyForge`; *Join Discord* con `DiscordLink` o `DiscordCode`; *Paste* solo si el executor tiene portapapeles.
- La ventana se puede arrastrar desde su parte superior y se escala en pantallas pequeñas.

### KeyForge

Integración opcional con [KeyForge](https://www.keyforge.win). El SDK se descarga en tiempo de ejecución (por defecto `https://www.keyforge.win/sdk/client.lua`; se puede cambiar con `sdkUrl`) y requiere `loadstring`.

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

Con KeyForge, el botón **Get key** obtiene el enlace desde el servicio (`getKeyUrl`) y lo copia al portapapeles. Con `LoadScript = true`, tras validar se llama a `loadScript()` del cliente; los errores se muestran con `warn("[CookiesKey] ...")`.

---

## Ejemplo completo

```lua
local Library = loadstring(game:HttpGet("URL_RAW_DE_CookiesLib.lua"))()
local KeySystem = loadstring(game:HttpGet("URL_RAW_DE_Cookieskeysystem.lua"))()
local Lucide = loadstring(game:HttpGet(
    "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"
))()

local function icon(name)
    local ok, asset = pcall(Lucide.GetAsset, name, 48)
    return ok and asset or nil
end

-- 1) Key system
local ks = KeySystem.new({
    Library = Library,
    KeyLink = "https://tu-enlace-de-keys",
    DiscordLink = "https://discord.gg/xxxxxx",
    Keys = { "COOKIE-1234" },
})
local ok = ks:Wait()
if not ok then return end

-- 2) Ventana
local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    ToggleKey = Enum.KeyCode.RightShift,
    Theme = { Accent = Color3.fromRGB(245, 194, 12) },
})

Window:AddTabCategory("Game")
local Combat  = Window:CreateTab("Combat", icon("swords"))
local Visuals = Window:CreateTab("Visuals", icon("eye"))

local Aim = Combat:CreateSection({ Name = "Aimbot", Icon = icon("crosshair"), Column = "Left" })
Aim:AddToggle({ Name = "Enabled", Flag = "Aim", Callback = function(v) print("Aim", v) end })
Aim:AddKeybind({ Name = "Aim key", Default = Enum.KeyCode.E, Mode = "Hold", Flag = "AimKey",
    Callback = function(down) print("Hold", down) end })
Aim:AddSlider({ Name = "FOV", Min = 10, Max = 360, Default = 90, Suffix = "°", Flag = "FOV" })
Aim:AddDropdown({ Name = "Target", Options = { "Head", "Torso", "Legs" }, Default = "Head", Flag = "Target" })

local Esp = Visuals:CreateSection({ Name = "ESP", Icon = icon("eye"), Minimized = false })
Esp:AddToggle({ Name = "Boxes", Description = "Dibuja cajas", Flag = "Boxes" })
Esp:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(245, 194, 12), Flag = "EspColor" })
Esp:AddButton({ Name = "Probar notificación", Style = "Primary", Callback = function()
    Window:Notify({ Title = "ESP", Content = "Funcionando", Type = "Success" })
end })

Window:CreateSettingsTab("Settings", icon("settings"))
```

---

## Notas y solución de problemas

- **No veo la ventana al ejecutar:** la intro mantiene el menú oculto 2–3 segundos. Si usas `Intro = { Enabled = false }` aparece de inmediato.
- **Cerré la ventana y no puedo volver a abrirla:** usa la `ToggleKey` o el botón flotante. En móvil no pongas `FloatingButton = false` salvo que tengas otra forma de abrirla.
- **El tema no cambia:** llama a `SetTheme`/`Theme` antes de `CreateWindow`.
- **Mi callback se ejecuta al cargar una config:** es el comportamiento normal de `LoadConfig`. Dentro del callback puedes comprobar tu propio estado, o usar `:Set(valor, true)` para cambios silenciosos por código.
- **`Lucide.GetAsset` falla:** el nombre del icono no existe; usa el helper con `pcall` de la sección de iconos.
- **El Key System no recuerda la key:** el executor debe soportar `writefile/readfile/isfolder/makefolder/isfile`, y la casilla *Remember key* debe estar marcada al validar.
- **Dos ventanas:** `Library.Flags` es global, así que los nombres de `Flag` deben ser únicos entre ventanas.

---

## Créditos y licencias

- **Lucide Icons** — set de iconos de [lucide.dev](https://lucide.dev), licencia ISC.
- **lucide-roblox** — conversión de Lucide a Roblox por **latte-soft**: <https://github.com/latte-soft/lucide-roblox> (licencia MIT).
- **KeyForge** — servicio opcional de keys usado por el Key System: <https://www.keyforge.win>
- **Cookies Hub / CookiesLib** — repositorio: <https://github.com/Lilwero20/CookiesLib>
