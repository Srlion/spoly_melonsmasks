--[[
MIT License

Copyright (c) 2023 Aleksandrs Filipovskis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]
---
--- Melon's Masks
--- https://github.com/melonstuff/melonsmasks/
--- Licensed under MIT
---

local file = file
local string = string
local math = math
local table = table
local render = render
local cam = cam
local surface = surface
local util = util
local gui = gui

local CurTime = CurTime
local isstring = isstring
local isfunction = isfunction
local xpcall = xpcall
local Color = Color
local CreateMaterial = CreateMaterial
local GetRenderTargetEx = GetRenderTargetEx
local Material = Material

local MATERIAL_RT_DEPTH_SEPARATE = MATERIAL_RT_DEPTH_SEPARATE
local IMAGE_FORMAT_BGRA8888 = IMAGE_FORMAT_BGRA8888

local ADDON_NAME = "your_addon_name"
local SPOLY_MELONSMASKS_DIR = ADDON_NAME .. "/" .. "spoly_melonsmasks/"

local STATUS_IDLE = 0
local STATUS_BUSY = 1

local spoly_melonsmasks = {
    materials = {},
    queue = {},
    status = STATUS_IDLE,

    KIND_CUT = {BLEND_ZERO, BLEND_SRC_ALPHA, BLENDFUNC_ADD},
    KIND_STAMP = {BLEND_ZERO, BLEND_ONE_MINUS_SRC_ALPHA, BLENDFUNC_ADD}
}

local materials = spoly_melonsmasks.materials
local queue = spoly_melonsmasks.queue
local queued = {}

local RT_FLAGS = 256

file.CreateDir(SPOLY_MELONSMASKS_DIR)

local color_white = Color(255, 255, 255)

do
    local colorTag = Color(92, 192, 254)
    local colorError = Color(254, 92, 92)
    local tag = "[Spoly Melon] "

    function spoly_melonsmasks.Print(text, ...)
        MsgC(colorTag, tag, color_white, string.format(text, ...), "\n")
    end

    function spoly_melonsmasks.PrintError(text, ...)
        MsgC(colorTag, tag, colorError, "[ERROR] ", color_white, string.format(text, ...), "\n")
    end
end

local DEFAULT_SIZE
local SOURCE_RT, DEST_RT, SOURCE_MAT
local function update_RTs()
    DEFAULT_SIZE = math.max(ScrW(), ScrH())
    SOURCE_RT = GetRenderTargetEx(ADDON_NAME .. "SpolyMelonsMasks_Source" .. DEFAULT_SIZE, DEFAULT_SIZE, DEFAULT_SIZE, 0, MATERIAL_RT_DEPTH_SEPARATE, RT_FLAGS, 0, IMAGE_FORMAT_BGRA8888)
    DEST_RT = GetRenderTargetEx(ADDON_NAME .. "SpolyMelonsMasks_Source" .. DEFAULT_SIZE, DEFAULT_SIZE, DEFAULT_SIZE, 0, MATERIAL_RT_DEPTH_SEPARATE, RT_FLAGS, 0, IMAGE_FORMAT_BGRA8888)
    SOURCE_MAT = CreateMaterial(ADDON_NAME .. "SpolyMelonsMasks_Source" .. DEFAULT_SIZE, "UnlitGeneric", {
        ["$basetexture"] = SOURCE_RT:GetName(),
        ["$translucent"] = "1",
        ["$vertexalpha"] = "1",
        ["$vertexcolor"] = "1",
        ["$alpha"] = "1",
    })
end
update_RTs()
hook.Add("OnScreenSizeChanged", ADDON_NAME .. "spoly_melonsmasks.UpdateRTs", update_RTs)

function spoly_melonsmasks.Render(data)
    local id, funcDraw, w, h = data.id, data.funcDraw, data.w, data.h
    local start = SysTime()

    spoly_melonsmasks.status = STATUS_BUSY

    w = math.min(w or DEFAULT_SIZE, DEFAULT_SIZE)
    h = math.min(h or DEFAULT_SIZE, DEFAULT_SIZE)

    render.PushRenderTarget(DEST_RT)
        render.SetWriteDepthToDestAlpha(false)
        render.Clear(0, 0, 0, 0, true, true)

        cam.Start2D()
            surface.SetDrawColor(color_white)
            draw.NoTexture()
            local success, kind = xpcall(funcDraw, spoly_melonsmasks.PrintError, w, h)
            kind = kind or spoly_melonsmasks.KIND_CUT
        cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(DEST_RT)
        cam.Start2D()
            render.OverrideBlend(true,
                kind[1], kind[2], kind[3]
            )
            surface.SetDrawColor(255, 255, 255)
            surface.SetMaterial(SOURCE_MAT)
            surface.DrawTexturedRect(0, 0, DEFAULT_SIZE, DEFAULT_SIZE)
            render.OverrideBlend(false)
        cam.End2D()

        local mat_content = success and render.Capture({
            x = 0,
            y = 0,
            w = w,
            h = h,
            format = "png",
            alpha = true
        })
    render.PopRenderTarget()

    if success then
        local path = SPOLY_MELONSMASKS_DIR .. util.SHA256(id) .. ".png"
        file.Write(path, mat_content)

        local mat = Material("data/" .. path, "mips smooth noclamp")
        materials[id] = mat
    end

    spoly_melonsmasks.status = STATUS_IDLE

    if success then
        local endtime = SysTime()
        local delta = tostring(math.Round(endtime - start, 3))
        spoly_melonsmasks.Print("Rendered '%s' in %ss", id, delta)
    end
end

function spoly_melonsmasks.Source()
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(SOURCE_RT)
    render.Clear(0, 0, 0, 0, true, true)
    cam.Start2D()
end

function spoly_melonsmasks.And(kind)
    cam.End2D()
    render.PopRenderTarget()

    render.PushRenderTarget(DEST_RT)
    cam.Start2D()
        render.OverrideBlend(true,
            kind[1], kind[2], kind[3]
        )
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(SOURCE_MAT)
        surface.DrawTexturedRect(0, 0, DEFAULT_SIZE, DEFAULT_SIZE)
        render.OverrideBlend(false)
        spoly_melonsmasks.Source()
end

function spoly_melonsmasks.Generate(id, funcDraw, w, h)
    if materials[id] then return end
    if queued[id] then return end

    if not isstring(id) then
        spoly_melonsmasks.PrintError("bad argument #1 to 'spoly_melonsmasks.Generate' (expected string, got %s)", type(id))
        return
    end

    if not isfunction(funcDraw) then
        spoly_melonsmasks.PrintError("bad argument #2 to 'spoly_melonsmasks.Generate' (expected function, got %s)", type(funcDraw))
        return
    end

    do
        local path = SPOLY_MELONSMASKS_DIR .. util.SHA256(id) .. ".png"
        if file.Exists(path, "DATA") then
            materials[id] = Material("data/" .. path, "mips smooth noclamp")
            if not materials[id]:IsError() then
                return
            end
        end
    end

    queued[id] = true

    table.insert(queue, {
        id = id,
        funcDraw = funcDraw,
        w = w,
        h = h
    })
end

do
    local think_rate = 1 / 2
    local next_think = 0
    hook.Add("Think", "spoly_melonsmasks.QueueController." .. ADDON_NAME, function()
        if (spoly_melonsmasks.status == STATUS_IDLE and queue[1] and next_think <= CurTime()) then
            next_think = CurTime() + think_rate

            if gui.IsGameUIVisible() then
                gui.HideGameUI()
                return
            end

            local data = table.remove(queue, 1)
            spoly_melonsmasks.Render(data)
        end
    end)
end

do
    local SetDrawColor = surface.SetDrawColor
    local SetMaterial = surface.SetMaterial
    local DrawTexturedRect = surface.DrawTexturedRect
    local DrawTexturedRectRotated = surface.DrawTexturedRectRotated

    function spoly_melonsmasks.Draw(id, x, y, w, h, color)
        local material = materials[id]
        if not material then return end

        if color then
            SetDrawColor(color)
        else
            SetDrawColor(255, 255, 255)
        end
        SetMaterial(material)
        DrawTexturedRect(x, y, w, h)
    end

    function spoly_melonsmasks.DrawRotated(id, x, y, w, h, rotation, color)
        local material = materials[id]
        if not material then return end

        if color then
            SetDrawColor(color)
        else
            SetDrawColor(255, 255, 255)
        end
        SetMaterial(material)
        DrawTexturedRectRotated(x, y, w, h, rotation)
    end
end

return spoly_melonsmasks
