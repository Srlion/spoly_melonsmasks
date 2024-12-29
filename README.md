# Spoly MelonsMasks!

This is a nice mix between [Spoly](https://github.com/filipovskis/spoly) and [MelonsMasks](https://github.com/melonstuff/melonsmasks)! I take no credit for the original work, as it was done by the respective authors. I just combined them together.

Thanks to [Filipovskis](https://github.com/filipovskis) and [garryspins/orion](https://github.com/garryspins) for the original work!

## Example

```lua
local spoly_melonsmasks = include("spoly_melonsmasks.lua")

local mat = Material("data/ur_material.png")
spoly_melonsmasks.Generate("CircleMaterial", function(w, h)
    -- There is no need to do masks.Start() or masks.End()
    -- it is done automatically, incase you need to change End kind, simply return it

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, w, h)

spoly_melonsmasks.Source()
    draw.RoundedBox(w, 0, 0, w, h, Color(255, 255, 255, 255))

    -- return spoly_melonsmasks.KIND_STAMP -- incase you want to change the End kind
end)

hook.Add("HUDPaint", "DrawCircleMaterial", function()
    spoly_melonsmasks.Draw("CircleMaterial", 0, 0, 512, 512)
end)
```

You can find more examples at:

- [Spoly](https://github.com/filipovskis/spoly)
- [MelonsMasks](https://github.com/melonstuff/melonsmasks)
