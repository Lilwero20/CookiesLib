# 🍪 Cookies Hub UI Library

Librería de interfaz para Roblox (Lua) con estética **amarillo galleta + chocolate**. Pensada para ser fácil de usar, totalmente controlable por código y adaptable a PC y celular.

**Versión:** `3.1.0`

## ✨ Características

- Ventana **arrastrable**, **redimensionable**, **minimizable** y con botón flotante
- **Responsive / mobile friendly**: se adapta a la pantalla, sidebar compacto y columnas que se apilan
- Tabs con **icono por AssetId** (si no das icono, usa la letra)
- Secciones (tarjetas) **minimizables** con animación, scroll opcional (`MaxHeight`) y columnas internas
- Elementos: `Label`, `Paragraph`, `Divider`, `Spacer`, `Button`, `Toggle`, `Slider`, `Dropdown` (simple / multi), `Keybind`, `TextBox`, `ColorPicker`, `Progress`
- Todo se controla por código: `:Set()` `:Get()` `:SetVisible()` `:SetEnabled()` `:OnChanged()`
- **Flags**: lee y cambia cualquier elemento por nombre, sin tocar la UI
- **Guardar / cargar configs** en archivos JSON
- **Notificaciones** con barra de progreso
- Tema y configuración 100 % personalizables

---

## 📑 Índice

1. [Instalación](#-instalación)
2. [Inicio rápido](#-inicio-rápido)
3. [Library](#-library)
4. [Window](#-window)
5. [Tab](#-tab)
6. [Section](#-section)
7. [Elementos](#-elementos)
8. [Flags](#-flags)
9. [Configs (guardar / cargar)](#-configs-guardar--cargar)
10. [Notificaciones](#-notificaciones)
11. [Personalización](#-personalización)
12. [Mobile / Responsive](#-mobile--responsive)
13. [Ejemplo completo](#-ejemplo-completo)

---

## 📦 Instalación

Guarda `CookiesLib.lua` en la carpeta de workspace de tu executor y cárgalo:

```lua
local Library = loadstring(readfile("CookiesLib.lua"))()
```

Si lo subes a GitHub, también puedes cargarlo desde el link *raw*:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Lilwero20/CookiesLib/main/CookiesLib.lua"))()
```

> **Nota:** la UI se coloca en `gethui()` si tu executor lo soporta; si no, en `PlayerGui`. Guardar/cargar configs requiere `writefile`, `readfile`, `isfolder` y `makefolder`.

---

## 🚀 Inicio rápido

```lua
local Library = loadstring(readfile("CookiesLib.lua"))()

local Window = Library:CreateWindow({ Title = "Cookies Hub" })

local Tab = Window:CreateTab("Home", 123456789)   -- icono por asset id
local Section = Tab:CreateSection("Main")

local AutoFarm = Section:AddToggle({
    Name = "Auto Farm",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(value)
        print("AutoFarm:", value)
    end,
})

AutoFarm:Set(true)                  -- cambia el estado por código (dispara Callback)
AutoFarm:Set(false, true)           -- 2º argumento = silent (NO dispara Callback)
Library:SetFlag("AutoFarm", true)   -- lo mismo, por nombre de flag
```

---

## 📚 Library

Funciones del objeto principal que devuelve `loadstring(...)()`.

| Función | Descripción |
|---|---|
| `Library:CreateWindow(opts)` | Crea una ventana. Alias: `Library.new(opts)` |
| `Library:Configure(tabla)` | Cambia la configuración global (y el tema) |
| `Library:SetTheme(tabla)` | Cambia solo los colores del tema |
| `Library:GetFlag(flag)` | Devuelve el valor de un elemento. Alias: `Library:Get` |
| `Library:SetFlag(flag, valor, silent)` | Cambia el valor de un elemento. Alias: `Library:Set` |
| `Library:GetObject(flag)` | Devuelve el objeto del elemento (con todos sus métodos) |
| `Library:Notify(opts)` | Muestra una notificación en la última ventana creada |
| `Library.Flags` | Tabla con todos los elementos registrados por flag |
| `Library.Windows` | Lista de ventanas creadas |
| `Library.Theme` / `Library.Fonts` / `Library.Config` | Tema, fuentes y configuración |

```lua
Library:Configure({ Animations = true, AnimationSpeed = 1.5 })

print(Library:GetFlag("AutoFarm"))      --> true / false
Library:GetObject("AutoFarm"):Toggle()  --> invierte el toggle
```

---

## 🪟 Window

### `Library:CreateWindow(opts)`

```lua
local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "by Cookie",        -- por defecto muestra la versión
    Logo = "rbxassetid://123456",  -- false para ocultar el logo
    Width = 740, Height = 500,
    ToggleKey = Enum.KeyCode.RightShift,
})
```

**Opciones de la ventana**

| Opción | Tipo | Por defecto | Descripción |
|---|---|---|---|
| `Title` | string | `"Cookies Hub"` | Título |
| `Subtitle` | string | versión | Texto pequeño bajo el título |
| `Logo` | string / false | logo de Cookies Hub | Imagen del logo y del botón flotante |
| `Width` / `Height` | number | `740` / `500` | Tamaño inicial |
| `MinWidth` / `MinHeight` | number | `480` / `320` | Tamaño mínimo al redimensionar |
| `SidebarWidth` | number | `160` | Ancho del sidebar |
| `CompactSidebarWidth` | number | `58` | Ancho del sidebar compacto (pantallas angostas) |
| `CompactBelow` | number | `600` | Ancho bajo el cual el sidebar es solo iconos |
| `MinScale` | number | `0.7` | Escala mínima antes de achicar el tamaño lógico |
| `ToggleKey` | KeyCode | `RightShift` | Tecla para mostrar / ocultar |
| `ConfigFolder` | string | `"CookiesHub"` | Carpeta donde se guardan las configs |
| `FloatingButton` | bool | `true` | Botón flotante (en táctil siempre se muestra) |
| `Resizable` | bool | `true` | Permite redimensionar |
| `Draggable` | bool | `true` | Permite arrastrar |
| `Minimizable` | bool | `true` | Botón de minimizar (`-`) |
| `Closable` | bool | `true` | Botón de cerrar (`x`) |
| `ShowProfile` | bool | `true` | Muestra tu avatar y nombre en el sidebar |
| `AutoScale` | bool | `true` | Adapta la ventana al tamaño de la pantalla |
| `DisplayOrder` | number | `50` | DisplayOrder del ScreenGui |
| `Corner` | number | `16` | Radio de las esquinas |

También puedes pasar dentro de `CreateWindow` las tablas `Tab`, `Section`, `Element`, `Notify` y `Theme` (ver [Personalización](#-personalización)).

### Métodos de Window

| Método | Descripción |
|---|---|
| `Window:CreateTab(name, icon)` | Crea una pestaña ([ver Tab](#-tab)) |
| `Window:AddTabCategory(texto)` | Añade un título de categoría en el sidebar |
| `Window:SelectTab(tab o nombre)` | Selecciona una pestaña |
| `Window:GetTab(nombre)` | Devuelve una pestaña por su nombre |
| `Window:CreateSettingsTab(name, icon)` | Crea una pestaña de ajustes lista (tecla del menú, animaciones, configs…) |
| `Window:SetVisible(bool)` | Muestra u oculta la ventana |
| `Window:Toggle()` / `:Show()` / `:Hide()` | Alterna, muestra u oculta |
| `Window:Minimize(estado)` | Minimiza / restaura (sin argumento alterna) |
| `Window:Resize(w, h)` | Cambia el tamaño |
| `Window:SetTitle(t)` / `:SetSubtitle(t)` | Cambia título y subtítulo |
| `Window:SetToggleKey(key)` | Cambia la tecla de mostrar / ocultar |
| `Window:SetFloatingButton(bool)` | Muestra u oculta el botón flotante |
| `Window:ResetPosition()` | Vuelve la ventana al centro |
| `Window:Notify(opts)` | Muestra una notificación |
| `Window:SaveConfig(nombre)` / `:LoadConfig(nombre)` / `:GetConfigs()` | Manejo de configs |
| `Window:Destroy()` | Elimina la ventana y desconecta todo |

```lua
Window:SetTitle("Mi Hub")
Window:SetToggleKey(Enum.KeyCode.K)
Window:Minimize(true)
Window:Resize(800, 520)
```

### `Window:AddTabCategory(texto)`

Los títulos se ordenan según el orden de creación, así que llámalo **antes** de las pestañas que quieres agrupar. En el sidebar compacto las categorías se ocultan.

```lua
Window:AddTabCategory("Principal")
local Home  = Window:CreateTab("Home", 123456)
local Farm  = Window:CreateTab("Farm", 234567)

Window:AddTabCategory("Extras")
local Misc  = Window:CreateTab("Misc")
```

---

## 📑 Tab

### `Window:CreateTab(name, icon)`

```lua
local Tab  = Window:CreateTab("Home", 123456789)        -- con icono
local Tab2 = Window:CreateTab("Misc")                    -- sin icono: usa la letra "M"
```

Con tabla de opciones:

```lua
local Tab = Window:CreateTab({
    Name = "Home",
    Icon = 123456789,
    IconTint = true,             -- tiñe el icono (amarillo activo / gris inactivo)
    IconColor = Color3.fromRGB(255, 120, 80),
    Columns = 2,                 -- 1, 2, 3... columnas de secciones
    Padding = 10,
    Gap = 10,
    IconSize = 22,
})
```

**Formatos de icono aceptados**

```lua
Window:CreateTab("A", 123456789)                       -- número
Window:CreateTab("B", "rbxassetid://123456789")        -- string
Window:CreateTab("C", "123456789")                     -- string solo con números
Window:CreateTab("D", { Image = 123456789 })           -- tabla
Window:CreateTab("E", { Text = "XY" })                 -- letras personalizadas (máx. 2)
```

Si no hay icono se usa la primera letra del nombre de la pestaña.

### Métodos de Tab

| Método | Descripción |
|---|---|
| `Tab:CreateSection(nombre u opts)` | Crea una sección. Alias: `Tab:AddSection` |
| `Tab:Select()` | Selecciona esta pestaña |
| `Tab:SetIcon(icono)` | Cambia el icono |
| `Tab:SetName(nombre)` | Cambia el nombre |
| `Tab:SetVisible(bool)` | Muestra u oculta la pestaña del sidebar |
| `Tab:ScrollToTop()` | Sube el scroll al inicio |
| `Tab:Refresh()` | Recalcula alturas de las secciones |
| `Tab:Destroy()` | Elimina la pestaña |

```lua
Tab:SetIcon(987654321)
Tab:SetName("Inicio")
Tab:Select()
```

---

## 🗂️ Section

Las secciones son tarjetas que agrupan elementos. Se pueden **minimizar** haciendo clic en la cabecera (flecha a la derecha).

### `Tab:CreateSection(nombre u opts)`

```lua
local Section = Tab:CreateSection("Main")      -- forma corta

local Section2 = Tab:CreateSection({            -- forma completa
    Name = "Combat",
    Icon = 123456,             -- reemplaza el puntito amarillo
    Color = Color3.fromRGB(255, 120, 80),
    Collapsible = true,        -- se puede minimizar
    Minimized = false,         -- empieza minimizada
    Columns = 1,               -- columnas internas
    MaxHeight = 200,           -- si el contenido pasa de esto, hace scroll
    Column = "Left",           -- 1, 2, 3... | "Left" | "Right" | "Full"
})
```

**Opciones de sección**

| Opción | Tipo | Descripción |
|---|---|---|
| `Name` | string | Título |
| `Icon` | icono | Icono junto al título (mismos formatos que en tabs) |
| `IconColor` | Color3 | Color del icono (por defecto el de `Color`) |
| `Color` | Color3 | Color del título / punto |
| `Collapsible` | bool | Permite minimizarla |
| `Minimized` | bool | Empieza minimizada (alias: `Collapsed`) |
| `Columns` | number | Columnas internas para los elementos |
| `MaxHeight` | number | Altura máxima antes de hacer scroll interno |
| `Column` | number / string | Columna del tab: `1`, `2`, `"Left"`, `"Right"` o `"Full"` (ancho completo) |
| `Full` | bool | Atajo de `Column = "Full"` |
| `Gap` / `ColumnGap` | number | Separación vertical / entre columnas internas |

### Métodos de Section

| Método | Descripción |
|---|---|
| `Section:SetOpen(abierta, instantaneo)` | Abre o minimiza (con animación, salvo `instantaneo = true`) |
| `Section:Toggle()` / `:Minimize()` / `:Expand()` | Alterna, minimiza o expande |
| `Section:OnToggle(fn)` | `fn(abierta)` se llama al abrir / minimizar |
| `Section:SetTitle(texto)` | Cambia el título |
| `Section:SetColor(color)` | Cambia el color del título |
| `Section:SetMaxHeight(n)` | Cambia el alto máximo (solo si se creó con `MaxHeight`) |
| `Section:SetVisible(bool)` | Muestra u oculta la sección |
| `Section:AddColumns(n)` | Divide la sección en `n` columnas y devuelve `n` sub-secciones |
| `Section:Destroy()` | Elimina la sección |
| `Section.Open` | `true` si está desplegada |

```lua
local Section = Tab:CreateSection({ Name = "Opciones", Minimized = true })

Section:OnToggle(function(abierta)
    print("Sección abierta:", abierta)
end)

Section:Expand()
Section:SetTitle("Opciones avanzadas")
```

### Columnas dentro de una sección

```lua
-- 1) Con la opción Columns: los elementos se reparten solos
local S = Tab:CreateSection({ Name = "Dos hileras", Columns = 2 })
S:AddToggle({ Name = "A" })
S:AddToggle({ Name = "B" })

-- 2) Con AddColumns: tú decides qué va en cada columna
local S2 = Tab:CreateSection("Manual")
local Izq, Der = S2:AddColumns(2)
Izq:AddButton({ Name = "Izquierda" })
Der:AddButton({ Name = "Derecha" })
```

### Sección con scroll

```lua
local Lista = Tab:CreateSection({ Name = "Lista larga", MaxHeight = 180 })
for i = 1, 20 do
    Lista:AddToggle({ Name = "Opción " .. i })
end
```

### Sección de ancho completo

```lua
local Info = Tab:CreateSection({ Name = "Info", Column = "Full" })
Info:AddParagraph({ Title = "Bienvenido", Content = "Esto ocupa todo el ancho de la pestaña." })
```

---

## 🧩 Elementos

Todos se crean desde una sección (`Section:AddXxx({...})`).

### Opciones comunes

| Opción | Descripción |
|---|---|
| `Name` | Texto del elemento |
| `Flag` | Nombre para leerlo / cambiarlo con `Library:GetFlag` / `SetFlag` y guardarlo en configs |
| `Callback` | Función que se llama al cambiar el valor |
| `Default` | Valor inicial |
| `Height` | Alto del elemento en píxeles |
| `Column` | Columna interna (si la sección tiene varias) |
| `Visible = false` | Empieza oculto |
| `Enabled = false` | Empieza deshabilitado (también `Disabled = true`) |

### Métodos comunes

| Método | Descripción |
|---|---|
| `:Set(valor, silent)` | Cambia el valor. Con `silent = true` no dispara el Callback |
| `:Get()` | Devuelve el valor actual |
| `:SetVisible(bool)` | Muestra u oculta |
| `:SetEnabled(bool)` | Habilita o deshabilita (se atenúa y bloquea) |
| `:SetCallback(fn)` | Reemplaza el Callback |
| `:OnChanged(fn)` | Añade un listener extra; devuelve `{ Disconnect = fn }` |
| `:SetText(texto)` | Cambia el nombre mostrado |
| `:Destroy()` | Elimina el elemento |
| `.Value` / `.Frame` / `.Enabled` | Valor actual, Frame de la UI y estado habilitado |

```lua
local Toggle = Section:AddToggle({ Name = "ESP", Flag = "ESP" })

local conn = Toggle:OnChanged(function(v) print("ESP ahora es", v) end)
conn.Disconnect()           -- deja de escuchar

Toggle:SetEnabled(false)    -- bloqueado
Toggle:SetVisible(false)    -- oculto
Toggle:SetText("ESP Players")
```

---

### Label

Texto simple con salto de línea automático.

```lua
local L = Section:AddLabel("Texto de ejemplo")
-- o con opciones:
local L2 = Section:AddLabel({ Text = "Importante", Size = 13, Color = Color3.fromRGB(255, 120, 80) })

L:Set("Nuevo texto")        -- también :SetText()
L:SetColor(Color3.new(1, 1, 1))
L:SetVisible(false)
```

### Paragraph

Cuadro con título y contenido.

```lua
local P = Section:AddParagraph({ Title = "Aviso", Content = "Este script es solo de ejemplo." })
P:Set("Nuevo título", "Nuevo contenido")
```

### Divider

Línea separadora, con texto opcional.

```lua
Section:AddDivider()
Section:AddDivider("OPCIONES")
```

### Spacer

Espacio vacío.

```lua
Section:AddSpacer(10)   -- 10 px
```

### Button

| Opción | Descripción |
|---|---|
| `Style` | `"Default"`, `"Primary"` (amarillo) o `"Danger"` (rojo). También `Primary = true` |
| `Description` | Texto pequeño bajo el nombre |
| `Callback` | Función al hacer clic |

```lua
local B = Section:AddButton({
    Name = "Teleport",
    Description = "Te lleva al spawn",
    Style = "Primary",
    Callback = function() print("Click!") end,
})

B:Click()               -- simula un clic
B:SetText("Ir al spawn")
```

### Toggle

| Opción | Descripción |
|---|---|
| `Default` | `true` / `false` |
| `Description` | Texto pequeño bajo el nombre |
| `Color` | Color cuando está activo |

```lua
local T = Section:AddToggle({
    Name = "Auto Farm",
    Description = "Farmea automáticamente",
    Flag = "AutoFarm",
    Default = false,
    Callback = function(v) print(v) end,
})

T:Set(true)             -- cambia sin presionar
T:Toggle()              -- invierte
T:Toggle(true)          -- invierte en silencio
print(T:Get())
```

### Slider

| Opción | Descripción |
|---|---|
| `Min` / `Max` | Rango (por defecto 0 a 100) |
| `Increment` | Paso (acepta decimales, ej. `0.25`) |
| `Suffix` | Texto tras el valor (`"%"`, `"x"`, `" studs"`) |
| `Default` | Valor inicial |
| `Color` | Color de la barra |

```lua
local S = Section:AddSlider({
    Name = "WalkSpeed",
    Flag = "WalkSpeed",
    Min = 16, Max = 100, Increment = 1, Default = 16,
    Suffix = " sp",
    Callback = function(v)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
    end,
})

S:Set(50)
S:SetRange(0, 200)      -- cambia el rango en caliente
```

Además de arrastrar, puedes escribir el valor en la cajita de la derecha.

### Dropdown

| Opción | Descripción |
|---|---|
| `Options` | Lista de opciones |
| `Multi` | `true` para selección múltiple (el valor es una tabla) |
| `MaxVisible` | Opciones visibles antes de hacer scroll (por defecto 5) |
| `Default` | Opción (o tabla de opciones si es `Multi`) |

```lua
-- Simple
local D = Section:AddDropdown({
    Name = "Arma",
    Options = { "Espada", "Arco", "Bastón" },
    Default = "Espada",
    Flag = "Weapon",
    Callback = function(v) print("Arma:", v) end,
})

-- Múltiple
local M = Section:AddDropdown({
    Name = "Objetivos",
    Options = { "Zombie", "Esqueleto", "Jefe" },
    Multi = true,
    Default = { "Zombie" },
    Callback = function(lista) print(table.concat(lista, ", ")) end,
})

D:Set("Arco")
D:SetOpen(true)                  -- lo despliega
D:AddOption("Lanza")
D:RemoveOption("Bastón")
D:Refresh({ "A", "B", "C" })     -- reemplaza opciones (2º arg true = conserva el valor)
```

### Keybind

| Opción | Descripción |
|---|---|
| `Default` | `Enum.KeyCode` inicial |
| `Mode` | `"Press"` (por defecto), `"Hold"` o `"Toggle"` |
| `Callback` | Se llama al presionar la tecla (ver abajo) |
| `Changed` | `fn(tecla)` cuando el usuario cambia la tecla |

Comportamiento del `Callback` según el modo:

- `Press`: `Callback()` cada vez que se pulsa
- `Hold`: `Callback(true)` al pulsar y `Callback(false)` al soltar
- `Toggle`: `Callback(activo)` alternando entre `true` / `false`

Haz clic en el botón para asignar una tecla; `Esc` cancela y `Backspace` la quita.

```lua
local K = Section:AddKeybind({
    Name = "Fly",
    Default = Enum.KeyCode.F,
    Mode = "Toggle",
    Flag = "FlyKey",
    Callback = function(activo) print("Fly:", activo) end,
    Changed = function(tecla) print("Nueva tecla:", tecla.Name) end,
})

K:Set(Enum.KeyCode.G)     -- también acepta el nombre: K:Set("G")
K:SetMode("Hold")
K:Press()                  -- ejecuta el Callback por código
```

### TextBox

| Opción | Descripción |
|---|---|
| `Placeholder` | Texto de ayuda |
| `Default` | Texto o número inicial |
| `Numeric` | `true` para aceptar solo números (el valor es un número) |
| `ClearOnFocus` | Borra el texto al hacer clic |
| `CallbackOnBlur` | Por defecto `true`: llama el Callback al salir de la caja. Con `false` solo al presionar Enter |

```lua
local TB = Section:AddTextBox({
    Name = "Nombre",
    Placeholder = "Escribe aquí...",
    Flag = "PlayerName",
    Callback = function(texto) print("Texto:", texto) end,
})

local Num = Section:AddTextBox({ Name = "Cantidad", Numeric = true, Default = 10 })

TB:Set("Cookie")
```

### ColorPicker

Selector con cuadro SV, barra de tono, campo HEX y colores predefinidos.

| Opción | Descripción |
|---|---|
| `Default` | `Color3` inicial |
| `Presets` | Lista de `Color3` como accesos rápidos |
| `PanelHeight` | Alto del cuadro de color (por defecto 96) |

```lua
local C = Section:AddColorPicker({
    Name = "Color ESP",
    Flag = "ESPColor",
    Default = Color3.fromRGB(255, 80, 120),
    Presets = {
        Color3.fromRGB(255, 80, 120),
        Color3.fromRGB(80, 200, 255),
        Color3.fromRGB(120, 255, 120),
    },
    Callback = function(color) print(color) end,
})

C:Set(Color3.fromRGB(255, 255, 0))
C:SetHex("#FF8800")
print(C:GetHex())       --> "#FF8800"
C:SetOpen(true)
```

### Progress

Barra de progreso de **solo lectura** que controlas por código. No se guarda en las configs.

| Opción | Descripción |
|---|---|
| `Min` / `Max` | Rango (por defecto 0 a 100) |
| `Default` | Valor inicial |
| `Color` | Color de la barra |
| `ShowPercent` | `false` para mostrar el número en vez del porcentaje |

```lua
local P = Section:AddProgress({ Name = "Descarga", Default = 0 })

for i = 0, 100, 10 do
    P:Set(i)
    task.wait(0.2)
end
```

---

## 🏷️ Flags

Cualquier elemento con `Flag` queda registrado y puedes leerlo o cambiarlo desde cualquier parte, sin guardar la variable del elemento.

```lua
Section:AddSlider({ Name = "Speed", Flag = "Speed", Min = 0, Max = 100, Default = 20 })

print(Library:GetFlag("Speed"))            --> 20
Library:SetFlag("Speed", 60)               -- dispara el Callback
Library:SetFlag("Speed", 80, true)         -- en silencio

local obj = Library:GetObject("Speed")
obj:OnChanged(function(v) print("Speed cambió:", v) end)

-- Leer en un loop
task.spawn(function()
    while task.wait(1) do
        if Library:GetFlag("AutoFarm") then
            -- ...
        end
    end
end)
```

`Library.Flags.AutoFarm.Value` también funciona (`Library.Options` es un alias de `Library.Flags`).

---

## 💾 Configs (guardar / cargar)

Guarda en JSON el valor de todos los elementos con `Flag` (excepto `Progress`) dentro de la carpeta `ConfigFolder`.

```lua
local ok, err = Window:SaveConfig("mi-config")
if not ok then warn(err) end

local ok2, err2 = Window:LoadConfig("mi-config")

for _, nombre in ipairs(Window:GetConfigs()) do
    print("Config:", nombre)
end
```

Para tener una interfaz lista (nombre, guardar, cargar, refrescar), usa la pestaña de ajustes:

```lua
Window:CreateSettingsTab("Settings", "S")
```

Incluye: tecla del menú, botón flotante, animaciones y su velocidad, resetear posición, descargar la UI y el manejo de configs.

---

## 🔔 Notificaciones

```lua
Window:Notify("Hola!")   -- solo título

Window:Notify({
    Title = "Config guardada",
    Content = "Se guardó mi-config",
    Type = "Success",       -- "Info" | "Success" | "Warning" | "Error"
    Duration = 5,           -- segundos (0 = no se cierra sola)
    Color = Color3.fromRGB(255, 120, 80),  -- opcional, pisa al Type
})

local n = Window:Notify({ Title = "Cargando...", Duration = 0 })
task.wait(3)
n.Close()                   -- cerrar manualmente (también se cierra al tocarla)
```

---

## 🎨 Personalización

### Configuración global

Puedes llamarlo antes o después de crear la ventana:

```lua
Library:Configure({
    Animations = true,        -- activa / desactiva todas las animaciones
    AnimationSpeed = 1,       -- 2 = el doble de rápido
    Window  = { Width = 740, Height = 500, Resizable = true, SidebarWidth = 160 },
    Tab     = { Columns = 2, Padding = 10, Gap = 10, IconSize = 22, IconTint = true, SingleColumnBelow = 440 },
    Section = { Collapsible = true, Minimized = false, Columns = 1, MaxHeight = nil, Gap = 6, ColumnGap = 8, Corner = 12 },
    Element = { Height = 34, Corner = 9 },
    Notify  = { Duration = 4, Width = 290 },
    Theme   = { Accent = Color3.fromRGB(255, 80, 120) },
})
```

O directamente en `CreateWindow` (solo afecta a esa ventana):

```lua
local Window = Library:CreateWindow({
    Title = "Mi Hub",
    Tab = { Columns = 1 },
    Section = { Collapsible = false },
    Element = { Height = 38 },
    Theme = { Accent = Color3.fromRGB(80, 200, 255) },
})
```

### Tema

Con solo cambiar `Accent`, los colores derivados (`AccentHi`, `AccentSoft`, `OnAccent`) se calculan solos. Si quieres, puedes definirlos tú.

```lua
Library:SetTheme({ Accent = Color3.fromRGB(255, 80, 120) })
```

| Clave | Uso |
|---|---|
| `Background` | Fondo de la ventana |
| `Panel` | Barra superior, sidebar y área de contenido |
| `Element` | Fondo de las secciones |
| `Row` / `RowHover` | Fondo de los elementos y su hover |
| `Input` | Fondo de cajas de texto, pistas de sliders, etc. |
| `Stroke` / `Outline` | Bordes |
| `Accent` / `AccentHi` / `AccentSoft` | Color principal, su variante clara y su fondo suave |
| `OnAccent` | Color del texto sobre el acento |
| `Text` / `Muted` / `Dim` | Textos principal, secundario y tenue |
| `Success` / `Warning` / `Error` | Colores de notificaciones y botón Danger |

> Cambia el tema **antes** de crear la ventana para que se aplique a todos los elementos.

### Fuentes

```lua
Library.Fonts.Title = Enum.Font.FredokaOne
Library.Fonts.Body  = Enum.Font.GothamMedium
Library.Fonts.Bold  = Enum.Font.GothamBold
```

---

## 📱 Mobile / Responsive

La librería se adapta sola:

- La ventana se ajusta al tamaño real de la pantalla (vertical y horizontal) y respeta el notch
- En pantallas angostas el sidebar pasa a **solo iconos** (`CompactBelow`)
- Las pestañas de varias columnas pasan a **una columna** cuando no hay espacio (`SingleColumnBelow`)
- La ventana y el botón flotante no se pueden arrastrar fuera de la pantalla
- En dispositivos táctiles el botón flotante siempre está visible (no hay tecla para abrir el menú)
- El área para redimensionar es más grande en táctil

Para desactivar el ajuste automático: `AutoScale = false`.

> Como en el sidebar compacto no se ve el nombre de las pestañas, conviene darles siempre un **icono**.

---

## 🧪 Ejemplo completo

```lua
local Library = loadstring(readfile("CookiesLib.lua"))()

-- Tema (antes de crear la ventana)
Library:SetTheme({ Accent = Color3.fromRGB(253, 204, 11) })

local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "Ejemplo completo",
    ToggleKey = Enum.KeyCode.RightShift,
})

---------------------------------------------------------------------
-- HOME
---------------------------------------------------------------------
Window:AddTabCategory("Principal")
local Home = Window:CreateTab("Home", 123456789)

local Info = Home:CreateSection({ Name = "Info", Column = "Full" })
Info:AddParagraph({
    Title = "Bienvenido",
    Content = "Esta es la demo de Cookies Hub. Minimiza las secciones con la flecha.",
})

local Main = Home:CreateSection("Main")

local AutoFarm = Main:AddToggle({
    Name = "Auto Farm",
    Description = "Farmea automáticamente",
    Flag = "AutoFarm",
    Callback = function(v) print("AutoFarm:", v) end,
})

Main:AddSlider({
    Name = "WalkSpeed", Flag = "WalkSpeed",
    Min = 16, Max = 100, Default = 16, Suffix = " sp",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end,
})

Main:AddDropdown({
    Name = "Arma", Flag = "Weapon",
    Options = { "Espada", "Arco", "Bastón" }, Default = "Espada",
})

Main:AddDropdown({
    Name = "Objetivos", Flag = "Targets", Multi = true,
    Options = { "Zombie", "Esqueleto", "Jefe" }, Default = { "Zombie" },
})

local Extra = Home:CreateSection({ Name = "Extra", Minimized = true })
Extra:AddKeybind({
    Name = "Fly", Flag = "FlyKey", Default = Enum.KeyCode.F, Mode = "Toggle",
    Callback = function(activo) print("Fly:", activo) end,
})
Extra:AddTextBox({ Name = "Nombre", Flag = "Nick", Placeholder = "Tu nombre..." })
Extra:AddColorPicker({
    Name = "Color ESP", Flag = "ESPColor", Default = Color3.fromRGB(255, 80, 120),
    Presets = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(80, 200, 255), Color3.fromRGB(120, 255, 120) },
})

---------------------------------------------------------------------
-- FARM (con scroll y columnas internas)
---------------------------------------------------------------------
local Farm = Window:CreateTab({ Name = "Farm", Icon = 234567890, Columns = 2 })

local Lista = Farm:CreateSection({ Name = "Mobs", MaxHeight = 180, Color = Color3.fromRGB(255, 120, 80) })
for i = 1, 12 do
    Lista:AddToggle({ Name = "Mob " .. i, Flag = "Mob" .. i })
end

local Cols = Farm:CreateSection("Opciones rápidas")
local Izq, Der = Cols:AddColumns(2)
Izq:AddButton({ Name = "Activar todo", Style = "Primary", Callback = function()
    for i = 1, 12 do Library:SetFlag("Mob" .. i, true) end
end })
Der:AddButton({ Name = "Desactivar todo", Style = "Danger", Callback = function()
    for i = 1, 12 do Library:SetFlag("Mob" .. i, false) end
end })

local Progreso = Farm:CreateSection("Progreso")
local Barra = Progreso:AddProgress({ Name = "Descarga", Default = 0 })
Progreso:AddButton({
    Name = "Simular",
    Callback = function()
        task.spawn(function()
            for i = 0, 100, 10 do
                Barra:Set(i)
                task.wait(0.15)
            end
            Window:Notify({ Title = "Listo", Content = "Descarga completa", Type = "Success" })
        end)
    end,
})

---------------------------------------------------------------------
-- AJUSTES (tecla del menú, configs, etc.)
---------------------------------------------------------------------
Window:AddTabCategory("Sistema")
Window:CreateSettingsTab("Settings", "S")

---------------------------------------------------------------------
-- Control por código
---------------------------------------------------------------------
AutoFarm:OnChanged(function(v)
    Window:Notify({ Title = "Auto Farm", Content = v and "Activado" or "Desactivado", Type = v and "Success" or "Warning" })
end)

Library:SetFlag("WalkSpeed", 32)   -- cambia el slider sin tocar la UI
print(Library:GetFlag("Weapon"))   --> "Espada"

Window:Notify({ Title = "Cookies Hub", Content = "Cargado correctamente", Type = "Success" })
```

---

## 🧱 Estructura de la API (resumen)

```
Library
├── CreateWindow(opts) ─► Window
│   ├── CreateTab(name, icon) ─► Tab
│   │   └── CreateSection(opts) ─► Section
│   │       ├── AddLabel / AddParagraph / AddDivider / AddSpacer
│   │       ├── AddButton / AddToggle / AddSlider / AddDropdown
│   │       ├── AddKeybind / AddTextBox / AddColorPicker / AddProgress
│   │       └── AddColumns(n)
│   ├── AddTabCategory / CreateSettingsTab
│   └── Notify / SaveConfig / LoadConfig / Destroy
├── Configure / SetTheme
└── GetFlag / SetFlag / GetObject / Notify
```

---

## 📝 Licencia

Usa, modifica y comparte libremente. Si te sirve, deja una ⭐ en el repositorio.
