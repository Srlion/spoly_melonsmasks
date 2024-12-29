# Spoly MelonsMasks!

This is a nice mix between [Spoly](https://github.com/filipovskis/spoly) and [MelonsMasks](https://github.com/melonstuff/melonsmasks)! I take no credit for the original work, as it was done by the respective authors. I just combined them together.

Thanks to [Filipovskis](https://github.com/filipovskis) and [garryspins/orion](https://github.com/garryspins) for the original work!

## Why would I use this?

I created this so I can draw anything I want without worrying about performance, and it also supports anti-aliasing. Basically, it compiles and stores your drawing as a PNG, which you can then render as a material. This means you can use an expensive drawing function and still have it run about 100% faster than a `draw.RoundedBox` call.

It achieves the smooth look by first scaling your drawing up. Then, when loading it with `Material`, we specify `mips` and `smooth`. The `smooth` option essentially does what `render.PushFilter`(`Mag`/`Min`) does, while `mips` enables smaller versions (mipmaps) to be drawn cleanly. As a result, you get a nice, smooth appearance at a very low performance cost.

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

![image](https://github.com/user-attachments/assets/3bb87cd7-ff80-4bec-b9ab-613b8b86ae0e)

You can find more examples at:

- [Spoly](https://github.com/filipovskis/spoly)
- [MelonsMasks](https://github.com/melonstuff/melonsmasks)
