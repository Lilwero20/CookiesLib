# 🍪 Cookies Hub (CookiesLib)

Librería de UI para Roblox escrita en Luau. Ventana arrastrable y redimensionable, pestañas con icono, secciones minimizables, animaciones suaves, guardado de configs y diseño adaptable a PC y móvil.

**Versión:** 3.2.0

---

## Contenido

1. [Inicio rápido](#inicio-rápido)
2. [Iconos con Lucide](#iconos-con-lucide)
3. [Ventana](#ventana)
4. [Pestañas y secciones](#pestañas-y-secciones)
5. [Elementos](#elementos)
6. [Flags y configs](#flags-y-configs)
7. [Notificaciones](#notificaciones)
8. [Tema y configuración](#tema-y-configuración)
9. [Créditos y licencias](#créditos-y-licencias)

---

## Inicio rápido

```lua
local Library = loadstring(game:HttpGet("URL_RAW_DE_CookiesLib.lua"))()

local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    ToggleKey = Enum.KeyCode.RightShift,
})

local Main = Window:CreateTab("Main", "H")
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

---

## Iconos con Lucide

Cookies Hub acepta iconos en las **pestañas** y en las **secciones**. Los iconos del set [Lucide](https://lucide.dev) se usan mediante la librería **lucide-roblox**, y funcionan directamente porque `Library` entiende el formato de asset que esa librería devuelve (`Id`, `ImageRectSize`, `ImageRectOffset`).

### 1. Obtener lucide-roblox

> **Fuente de los iconos:** los Lucide icons se integran desde el repositorio
> **[latte-soft/lucide-roblox](https://github.com/latte-soft/lucide-roblox)**.
> Todo el crédito de la conversión de Lucide a Roblox es de sus autores.

Desde la página de [releases](https://github.com/latte-soft/lucide-roblox/releases) puedes descargar `lucide-roblox.luau` (un solo módulo) o `lucide-roblox.rbxm`. Si tu executor soporta `loadstring` y `HttpGet`, puedes cargarlo así (comprueba que la URL del release siga disponible):

```lua
local Lucide = loadstring(game:HttpGet(
    "https://github.com/latte-soft/lucide-roblox/releases/latest/download/lucide-roblox.luau"
))()
```

> ⚠️ El repositorio de lucide-roblox fue archivado por su autor (solo lectura). Sigue funcionando, pero ya no recibe actualizaciones. Si quieres evitar depender de la descarga en línea, guarda una copia local del archivo.

### 2. Pasar el icono a una pestaña

`Lucide.GetAsset(nombre, tamaño)` devuelve una tabla con el asset. Esa tabla se pasa tal cual como icono. Usa tamaño **48** para los iconos de pestaña (el tamaño por defecto es 256, más pesado de lo necesario).

```lua
local function icon(name)
    return Lucide.GetAsset(name, 48)
end

local Home    = Window:CreateTab("Home", icon("house"))
local Combat  = Window:CreateTab("Combat", icon("swords"))
local Visuals = Window:CreateTab("Visuals", icon("eye"))
local Misc    = Window:CreateTab("Misc", icon("settings"))
```

También puedes usar la forma con tabla de opciones:

```lua
local Tab = Window:CreateTab({
    Name = "Combat",
    Icon = Lucide.GetAsset("swords", 48),
    IconColor = Color3.fromRGB(245, 194, 12), -- color cuando está activa
    IconSize = 20,
})
```

### 3. Pasar el icono a una sección

```lua
local Section = Combat:CreateSection({
    Name = "Aimbot",
    Icon = Lucide.GetAsset("crosshair", 48),
    IconColor = Color3.fromRGB(245, 194, 12), -- opcional, por defecto el acento
})
```

Si una sección no tiene icono, se muestra el punto de color por defecto.

### 4. Cambiar el icono después de crear la pestaña

```lua
Tab:SetIcon(Lucide.GetAsset("flame", 48))
```

### Nombres de iconos

Los nombres son los de Lucide en minúsculas y con guiones (`"house"`, `"server-crash"`, `"user-round"`...). Puedes consultar la lista completa en el
[índice de iconos de lucide-roblox](https://github.com/latte-soft/lucide-roblox/blob/master/md/icon-index.md) o listarlos por código con `Lucide.IconNames`.

> `Lucide.GetAsset` **lanza un error** si el nombre no existe. Si quieres que un nombre incorrecto no rompa el script, envuélvelo:
>
> ```lua
> local function icon(name)
>     local ok, asset = pcall(Lucide.GetAsset, name, 48)
>     return ok and asset or nil -- sin icono: se usa la letra por defecto
> end
> ```

### Otros formatos de icono admitidos

No es obligatorio usar Lucide. `Icon` acepta:

| Valor | Resultado |
| --- | --- |
| `Lucide.GetAsset("home", 48)` | Icono de Lucide (recomendado) |
| `123456789` (número) | Asset id → `rbxassetid://123456789` |
| `"rbxassetid://123456789"` | Asset id como texto |
| `"123456789"` | Texto numérico (más de 4 dígitos) → asset id |
| `"H"` | Letra (máx. 2 caracteres) dentro de un recuadro |
| `{ Image = id, ImageRectSize = v2, ImageRectOffset = v2 }` | Spritesheet manual |
| `nil` | Primera letra del nombre de la pestaña |

### Tinte de los iconos

Los iconos de Lucide son blancos, así que se tiñen con el tema:

- En pestañas, con `IconTint = true` (valor por defecto) el icono se ve **apagado** cuando la pestaña está inactiva y con el color de acento (o `IconColor`) cuando está activa.
- Con `IconTint = false` se muestra el icono con sus colores originales (útil para iconos que no son de Lucide).

```lua
Library:Configure({ Tab = { IconTint = true, IconSize = 20 } })
```

---

## Ventana

```lua
local Window = Library:CreateWindow({
    Title = "Cookies Hub",
    Subtitle = "v3.2.0",
    Logo = "rbxassetid://76143769732706",
    Width = 740, Height = 500,
    ToggleKey = Enum.KeyCode.RightShift,
    ConfigFolder = "CookiesHub",
})
```

Opciones principales de `Window`:

| Opción | Por defecto | Descripción |
| --- | --- | --- |
| `Title` / `Subtitle` | `"Cookies Hub"` / versión | Textos de la barra superior |
| `Logo` | logo de Cookies Hub | Imagen del título y del botón flotante |
| `Width`, `Height` | `740`, `500` | Tamaño inicial |
| `MinWidth`, `MinHeight` | `480`, `320` | Tamaño mínimo al redimensionar |
| `SidebarWidth` | `160` | Ancho de la barra lateral |
| `CompactBelow` | `600` | Debajo de este ancho la barra lateral pasa a modo compacto (solo iconos) |
| `AutoScale` | `true` | Escala la ventana para que quepa en pantallas pequeñas |
| `ToggleKey` | `RightShift` | Tecla para mostrar/ocultar |
| `FloatingButton` | `true` | Botón flotante (siempre visible en táctil) |
| `Resizable`, `Draggable` | `true` | Redimensionar / arrastrar |
| `Minimizable`, `Closable` | `true` | Botones `-` y `x` |
| `ShowProfile` | `true` | Tarjeta de perfil en la barra lateral |

Métodos de `Window`:

```lua
Window:Toggle()  Window:Show()  Window:Hide()
Window:SetVisible(true)
Window:Minimize()            -- alterna; Window:Minimize(true/false) para forzar
Window:Resize(800, 520)
Window:SetTitle("Nuevo título")
Window:SetSubtitle("Texto")
Window:SetToggleKey(Enum.KeyCode.K)
Window:SetFloatingButton(false)
Window:ResetPosition()
Window:AddTabCategory("Combat")   -- separador de texto en la barra lateral
Window:GetTab("Main")
Window:SelectTab("Main")
Window:Destroy()
```

---

## Pestañas y secciones

```lua
local Tab = Window:CreateTab("Main", icon("house"))
Tab:SetName("Inicio")
Tab:SetVisible(true)
Tab:Select()
Tab:ScrollToTop()
Tab:Destroy()
```

Una pestaña tiene **2 columnas** por defecto (pasa a 1 columna en pantallas estrechas). Las secciones se reparten solas entre columnas, o puedes elegir:

```lua
Tab:CreateSection({ Name = "Izquierda", Column = "Left" })
Tab:CreateSection({ Name = "Derecha",   Column = "Right" })
Tab:CreateSection({ Name = "Ancha",     Full = true })
```

### Secciones minimizables

Las secciones se pliegan pulsando su cabecera (flecha a la derecha).

```lua
local Section = Tab:CreateSection({
    Name = "Aimbot",
    Icon = icon("crosshair"),
    Minimized = true,     -- empieza minimizada
    Collapsible = true,   -- false = no se puede minimizar
    MaxHeight = 220,      -- opcional: el contenido hace scroll
    Columns = 1,          -- columnas internas
})

Section:Minimize()
Section:Expand()
Section:Toggle()
Section:SetOpen(true)
Section:OnToggle(function(open) print(open) end)
Section:SetTitle("Otro nombre")
Section:SetVisible(true)
Section:Destroy()
```

Para colocar varios elementos en una misma fila:

```lua
local left, right = Section:AddColumns(2)
left:AddButton({ Name = "A" })
right:AddButton({ Name = "B" })
```

---

## Elementos

Todos aceptan `Name`, `Flag`, `Callback`, `Height`, `Visible`, `Enabled`. Cada elemento devuelto tiene `:Set(v, silent)`, `:Get()`, `:SetText()`, `:SetVisible()`, `:SetEnabled()`, `:OnChanged(fn)` y `:Destroy()`.

```lua
Section:AddButton({ Name = "Ejecutar", Style = "Primary", Callback = function() end }) -- Default | Primary | Danger

Section:AddToggle({ Name = "ESP", Description = "Muestra jugadores", Default = false, Flag = "ESP",
    Callback = function(v) end })

Section:AddSlider({ Name = "Velocidad", Min = 16, Max = 100, Increment = 1, Default = 16, Suffix = " st",
    Flag = "Speed", Callback = function(v) end })

Section:AddDropdown({ Name = "Objetivo", Options = { "Head", "Torso" }, Default = "Head", Multi = false,
    MaxVisible = 5, Flag = "Target", Callback = function(v) end })

Section:AddKeybind({ Name = "Tecla", Default = Enum.KeyCode.E, Mode = "Press", -- Press | Toggle | Hold
    Callback = function() end })

Section:AddTextBox({ Name = "Mensaje", Placeholder = "...", Numeric = false, Callback = function(text) end })

Section:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(245, 194, 12),
    Presets = { Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0) }, Callback = function(c) end })

Section:AddProgress({ Name = "Carga", Min = 0, Max = 100, Default = 40 })

Section:AddLabel("Texto informativo")
Section:AddParagraph({ Title = "Título", Content = "Descripción más larga" })
Section:AddDivider("Opciones")
Section:AddSpacer(8)
```

---

## Flags y configs

Los elementos con `Flag` se guardan automáticamente en las configs (si tu executor soporta `writefile`/`readfile`).

```lua
Library:GetFlag("ESP")            -- valor
Library:SetFlag("ESP", true)      -- cambia el valor
Library:GetObject("ESP")          -- el elemento

Window:SaveConfig("mi-config")
Window:LoadConfig("mi-config")
Window:GetConfigs()
```

`Window:CreateSettingsTab()` crea una pestaña lista con tecla del menú, botón flotante, animaciones, velocidad de animación, reset de posición, descarga de la UI y gestor de configs.

---

## Notificaciones

```lua
Window:Notify({
    Title = "Cookies Hub",
    Content = "Config cargada",
    Type = "Success",   -- Info | Success | Warning | Error
    Duration = 4,
})
```

---

## Tema y configuración

```lua
Library:SetTheme({ Accent = Color3.fromRGB(245, 194, 12) })

Library:Configure({
    Animations = true,
    AnimationSpeed = 1,
    Tab = { Columns = 2, IconSize = 20, IconTint = true },
    Section = { Collapsible = true, Minimized = false },
})
```

Al cambiar `Accent`, los colores derivados (`AccentHi`, `AccentSoft`, `OnAccent`) se recalculan solos si no los defines.

---

## Créditos y licencias

- **Lucide Icons** — set de iconos de [lucide.dev](https://lucide.dev), licencia ISC.
- **lucide-roblox** — conversión de Lucide a Roblox por **latte-soft**: <https://github.com/latte-soft/lucide-roblox> (licencia MIT). Los iconos de Cookies Hub se integran desde este repositorio.
- **Cookies Hub / CookiesLib** — repositorio: <https://github.com/Lilwero20/CookiesLib>
