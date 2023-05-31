local storage = {}
do
    storage.changelog = {
        " - Changed some UI stuff",
    }

    storage.modules = {
		-- player
		"Godmode",
		
		-- movement
		"Jesus",
		"Jetpack",
		"Speed",
		"Fast Stop",
		"Shift Teleport",
		
		-- visual
		"FOV",
		"Invisible Tool",
		"Tool Outline",
		"ESP",
		
		-- game
		"Freeze Timer",
		"Mission Stats",
		"No Alarm",
		"No Objectives",
		"No Robots",
		"Auto Escape",
		"Inf Ammo",
        "Inf Money",
		
		-- interface
		"Watermark",
		"Feature List",
		"Change Log",
	}
end

local containers = {}
do
	containers.bodies = {}
    do
        containers.bodies.targets = {}
        containers.bodies.escapevehicles = {}
        containers.bodies.valuables = {}
        containers.bodies.interactables = {}
        containers.bodies.robots = {}
    end
	containers.tools = {}
    containers.valuables = {}
end

local resolve = {}
do
	resolve.rgb = function()
		local current_time = GetTime()
		return math.sin(current_time) * 0.5 + 0.5, math.sin(current_time + 2) * 0.5 + 0.5, math.sin(current_time + 4) * 0.5 + 0.5
	end
	
	resolve.look_position = function()
		local camera_transform = GetCameraTransform()
		local hit, distance = QueryRaycast(camera_transform.pos, VecNormalize(VecSub(TransformToParentPoint(camera_transform, Vec(0, 0, -500)), camera_transform.pos)), 500)

		if hit then
			return TransformToParentPoint(camera_transform, Vec(0, 0, -distance))
		end
		return nil
	end
	
	resolve.body_center = function(body)
		local bottom_corner, top_corner = GetBodyBounds(body)
		return VecLerp(bottom_corner, top_corner, 0.5)
	end

    resolve.tool_center = function(tool)
        local tool_rotation = GetBodyTransform(tool).rot
		local bottom_corner, top_corner = GetBodyBounds(tool)
		return Transform(VecLerp(bottom_corner, top_corner, 0.5), tool_rotation)
	end
end

local config = {}
do
    config.setup = function()
        -- clear old keys
        local old_keys = {
            "savegame.mod.tearhook.settings",
            "savegame.mod.tearhook.cheats",
            "savegame.mod.tearhook.modules.highlights",
            "savegame.mod.tearhook.modules.chams",
            "savegame.mod.tearhook.modules.tracers",
            "savegame.mod.tearhook.modules.nametags",
            "savegame.mod.tearhook.modules.distance",
            "savegame.mod.tearhook.options.esp.boxes",
        }
        for _, old_key in pairs(old_keys) do
            if HasKey(old_key) then
                ClearKey("savegame.mod.tearhook")
                break
            end
        end

        -- reset options menus
        for _, key in pairs(ListKeys("savegame.mod.tearhook.options")) do
            SetBool("savegame.mod.tearhook.options." .. key .. ".edit", false)
        end
        
        -- set default keys
        if not HasKey("savegame.mod.tearhook.options.jetpack.multiplier") then
            SetInt("savegame.mod.tearhook.options.jetpack.multiplier", 10)
        end
        if not HasKey("savegame.mod.tearhook.options.speed.multiplier") then
            SetInt("savegame.mod.tearhook.options.speed.multiplier", 20)
        end
        if not HasKey("savegame.mod.tearhook.options.fov.amount") then
            SetInt("savegame.mod.tearhook.options.fov.amount", 130)
        end
    end

    config.toggle = function(string)
        SetBool(string, not GetBool(string))
    end
end

local asset = {}
do
    asset.booleans = {"assets/booleans/true.png", "assets/booleans/false.png"}
    asset.cog = "assets/cog.png"
end

local ui = {}
do
    ui.data = {
        ["enabled"] = false,
        ["config"] = false,
        ["screen_height"] = nil,
        ["screen_width"] = nil,
        ["screen_center"] = nil,
        ["main_x"] = nil,
        ["main_y"] = 120,
        ["main_width"] = 250,
        ["main_height"] = nil,
        ["sections"] = {
            ["player"] = nil,
            ["movement"] = nil,
            ["visual"] = nil,
            ["game"] = nil,
            ["interface"] = nil,
        },
        ["options"] = nil,
        ["config_window"] = nil,
    }
    
    ui.setup = function()
        -- ui
        UiMakeInteractive()
        UiBlur(0.25)
        UiAlign("center")
        UiFont("bold.ttf", 40)

        -- screen data
        if not ui.data["screen_height"] then
            ui.data["screen_height"] = UiHeight()
        end
        if not ui.data["screen_width"] then
            ui.data["screen_width"] = UiWidth()
        end
        if not ui.data["screen_center"] then
            ui.data["screen_center"] = {UiCenter(), UiMiddle()}
        end

        -- size data
        if not ui.data["main_height"] then
            ui.data["main_height"] = ui.data["screen_height"] - 200
        end

        -- position data
        if not ui.data["main_x"] then
            ui.data["main_x"] = math.floor(ui.data["screen_width"] / 6)
        end
        if not ui.data["sections"]["player"] then
            ui.data["sections"]["player"] = ui.data["main_x"]
        end
        if not ui.data["sections"]["movement"] then
            ui.data["sections"]["movement"] = ui.data["main_x"] + ui.data["main_x"]
        end
        if not ui.data["sections"]["visual"] then
            ui.data["sections"]["visual"] = ui.data["main_x"] + (ui.data["main_x"] * 2)
        end
        if not ui.data["sections"]["game"] then
            ui.data["sections"]["game"] = ui.data["main_x"] + (ui.data["main_x"] * 3)
        end
        if not ui.data["sections"]["interface"] then
            ui.data["sections"]["interface"] = ui.data["main_x"] + (ui.data["main_x"] * 4)
        end
        if not ui.data["options"] then
            ui.data["options"] = math.floor(ui.data["main_width"] / 2 - 17)
        end
    end
    
    ui.config = function()
        -- checks
        if not ui.data["config"] or not ui.data["config_window"] then
            ui.data["config"] = false
            ui.data["config_window"] = nil
            return
        end

        -- setup base values
        local batches = -2
        for _ in pairs(ui.data["config_window"]) do
            batches = batches + 1
        end
        local extend = 20 * batches
        local outline_rect_height = 57 + extend

        -- exit options window
        UiAlign("center middle")
        UiTranslate(ui.data["screen_center"][1], ui.data["screen_center"][2])
        if UiBlankButton(ui.data["screen_width"], ui.data["screen_height"]) and not UiIsMouseInRect(300, outline_rect_height) then
            ui.data["config"] = false
            ui.data["config_window"] = nil
            return
        end
        local r, g, b = resolve.rgb()
        UiBlur(0.25)

        -- options window
        UiColor(r, g, b)
        UiRect(300, outline_rect_height)
        UiColor(0.1, 0.1, 0.1)
        UiRect(298, 55 + extend)
        UiColor(1, 1, 1)

        UiAlign("center")
        UiFont("bold.ttf", 30)
        UiColor(1, 1, 1)
        UiTextShadow(r, g, b, 1, 1)
        UiTranslate(0, -10 * batches - 5)
        UiText(ui.data["config_window"]["name"] .. " Options")

        UiTextShadow(0, 0, 0, 0, 0)
        UiFont("bold.ttf", 25)
        UiButtonPressDist(0)
        local first = true
        for _, batch in pairs(ui.data["config_window"]) do
            if batch["type"] == "bool" then
                local option_path = "savegame.mod.tearhook.options." .. ui.data["config_window"]["name"]:lower() .. "." .. batch["name"]:lower():gsub("%s+", "")
                local current_value = GetBool(option_path)

                if first and false then
                    UiTranslate(0, 15)
                    first = false
                else
                    UiTranslate(0, 20)
                end

                UiPush()
                    UiAlign("middle left")
                    UiTranslate(-150, 0)
                    UiText(batch["name"])
                UiPop()
                
                UiPush()
                    UiAlign("middle right")
                    UiTranslate(146, 0)
                    if current_value then
                        if UiImageButton(asset.booleans[1]) then
                            SetBool(option_path, not current_value)
                        end
                    else
                        if UiImageButton(asset.booleans[2]) then
                            SetBool(option_path, not current_value)
                        end
                    end
                UiPop()
            elseif batch["type"] == "int" then
                local option_path = "savegame.mod.tearhook.options." .. ui.data["config_window"]["name"]:lower() .. "." .. batch["name"]:lower():gsub("%s+", "")
                local current_value = GetInt(option_path)

                if first and false then
                    UiTranslate(0, 15)
                    first = false
                else
                    UiTranslate(0, 20)
                end

                UiPush()
                    UiAlign("middle left")
                    UiTranslate(-150, 0)
                    UiText(batch["name"])
                UiPop()

                UiPush()
                    UiAlign("center middle")
                    if batch["max"] >= 100 then
                        UiTranslate(130, 0)
                    else
                        UiTranslate(135, 0)
                    end
                    UiText(current_value)

                    UiFont("bold.ttf", 25)
                    if batch["max"] >= 100 then
                        UiTranslate(-24, 0)
                    else
                        UiTranslate(-18, 0)
                    end
                    if UiTextButton("-") then
                        if current_value ~= batch["min"] then
                            SetInt(option_path, current_value - 1)
                        end
                    end
                    UiTranslate(-12, 0)
                    if UiTextButton("+") then
                        if current_value ~= batch["max"] then
                            SetInt(option_path, current_value + 1)
                        end
                    end
                UiPop()
            end
        end
    end

    ui.utilities = {}
    do
        ui.utilities.new_toggle = function(data)
            local first = data["first"] or false
            local name = data["name"]
            local options = data["options"] or false
            local rgb = data["rgb"]

            local key = "savegame.mod.tearhook.modules." .. name:lower():gsub("%s+", "")

            if first then
                UiTranslate(0, 30)
            else
                UiTranslate(0, 35)
            end

            UiPush()
                if GetBool(key) then
                    UiPush()
                        UiTranslate(0, -25)
                        UiColor(rgb[1], rgb[2], rgb[3], 0.15)
                        UiRect(ui.data["main_width"], 35)
                    UiPop()
                end

                UiColor(1, 1, 1)
                if UiTextButton(name) then
                    config.toggle(key)
                end

                if options then
                    options["name"] = name
                    UiTranslate(ui.data["options"], -21)
                    if UiImageButton(asset.cog) then
                        if not ui.data["config"] then
                            ui.data["config"] = true
                            ui.data["config_window"] = options
                        end
                    end
                end
            UiPop()
        end

        ui.utilities.new_button = function(data)
            local first = data["first"] or false
            local name = data["name"]
            local callback = data["callback"]
            local rgb = data["rgb"]

            if first then
                UiTranslate(0, 30)
            else
                UiTranslate(0, 35)
            end

            UiPush()
                UiColor(1, 1, 1)
                if UiTextButton(name) then
                    UiPush()
                        UiTranslate(0, -25)
                        UiColor(rgb[1], rgb[2], rgb[3], 0.15)
                        UiRect(ui.data["main_width"], 35)
                    UiPop()

                    callback()
                end
            UiPop()
        end
    end

    ui.display = function()
        -- toggle
        if InputPressed("alt") then
			ui.data["enabled"] = not ui.data["enabled"]
		end
		if not ui.data["enabled"] then
			return
		end

        -- main setup
        ui.setup()

        -- ui
        do
            -- colors
            local r, g, b = resolve.rgb()

            -- sections
            UiPush()
                -- setup
                UiTextShadow(r, g, b, 1, 1)
                UiButtonPressDist(0)
                UiColor(r, g, b)

                -- player
                UiPush()
                    UiTranslate(ui.data["sections"]["player"], ui.data["main_y"])

                    UiTranslate(0, -1)
                    UiRect(ui.data["main_width"] + 2, ui.data["main_height"] + 2)

                    UiTranslate(0, 1)
                    UiColor(0.1, 0.1, 0.1)
                    UiRect(ui.data["main_width"], ui.data["main_height"])
                    
                    UiColor(1, 1, 1)
                    UiTranslate(0, 30)
                    UiText("Player")

                    UiColor(r, g, b)
                    UiTranslate(0, 10)
                    UiRect(ui.data["main_width"], 5)

                    -- player modules
                    do
                        -- setup
                        UiFont("bold.ttf", 25)
                        UiTextShadow(0, 0, 0, 0, 0)

                        -- godmode
                        ui.utilities.new_toggle({
                            ["first"] = true,
                            ["name"] = "Godmode",
                            ["rgb"] = {r, g, b},
                        })
                    end
                UiPop()

                -- movement
                UiPush()
                    UiTranslate(ui.data["sections"]["movement"], ui.data["main_y"])
                    
                    UiTranslate(0, -1)
                    UiRect(ui.data["main_width"] + 2, ui.data["main_height"] + 2)

                    UiTranslate(0, 1)
                    UiColor(0.1, 0.1, 0.1)
                    UiRect(ui.data["main_width"], ui.data["main_height"])
                    
                    UiColor(1, 1, 1)
                    UiTranslate(0, 30)
                    UiText("Movement")

                    UiColor(r, g, b)
                    UiTranslate(0, 10)
                    UiRect(ui.data["main_width"], 5)

                    -- movement modules
                    do
                        -- setup
                        UiFont("bold.ttf", 25)
                        UiTextShadow(0, 0, 0, 0, 0)
                        
                        -- jesus
                        ui.utilities.new_toggle({
                            ["first"] = true,
                            ["name"] = "Jesus",
                            ["rgb"] = {r, g, b},
                        })

                        -- jetpack
                        ui.utilities.new_toggle({
                            ["name"] = "Jetpack",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "int",
                                    ["name"] = "Multiplier",
                                    ["max"] = 20,
                                    ["min"] = 1,
                                },
                            }
                        })

                        -- speed
                        ui.utilities.new_toggle({
                            ["name"] = "Speed",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "int",
                                    ["name"] = "Multiplier",
                                    ["max"] = 40,
                                    ["min"] = 1,
                                },
                            }
                        })

                        -- fast stop
                        ui.utilities.new_toggle({
                            ["name"] = "Fast Stop",
                            ["rgb"] = {r, g, b},
                        })

                        -- shift teleport
                        ui.utilities.new_toggle({
                            ["name"] = "Shift Teleport",
                            ["rgb"] = {r, g, b},
                        })
                    end
                UiPop()

                -- visual
                UiPush()
                    UiTranslate(ui.data["sections"]["visual"], ui.data["main_y"])
                    
                    UiTranslate(0, -1)
                    UiRect(ui.data["main_width"] + 2, ui.data["main_height"] + 2)

                    UiTranslate(0, 1)
                    UiColor(0.1, 0.1, 0.1)
                    UiRect(ui.data["main_width"], ui.data["main_height"])
                    
                    UiColor(1, 1, 1)
                    UiTranslate(0, 30)
                    UiText("Visual")

                    UiColor(r, g, b)
                    UiTranslate(0, 10)
                    UiRect(ui.data["main_width"], 5)

                    -- visual modules
                    do
                        -- setup
                        UiFont("bold.ttf", 25)
                        UiTextShadow(0, 0, 0, 0, 0)

                        -- fov
                        ui.utilities.new_toggle({
                            ["first"] = true,
                            ["name"] = "FOV",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "int",
                                    ["name"] = "Amount",
                                    ["max"] = 170,
                                    ["min"] = 1,
                                },
                            }
                        })

                        -- invisible tool
                        ui.utilities.new_toggle({
                            ["name"] = "Invisible Tool",
                            ["rgb"] = {r, g, b},
                        })

                        -- tool outline
                        ui.utilities.new_toggle({
                            ["name"] = "Tool Outline",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Rainbow",
                                },
                            }
                        })

                        -- esp
                        ui.utilities.new_toggle({
                            ["name"] = "ESP",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Highlights",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Chams",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Tracers",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Nametags",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Distance",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "3D Boxes",
                                },
                                {
                                    ["type"] = "bool",
                                    ["name"] = "2D Boxes",
                                },
                            }
                        })
                    end
                UiPop()

                -- game
                UiPush()
                    UiTranslate(ui.data["sections"]["game"], ui.data["main_y"])
                    
                    UiTranslate(0, -1)
                    UiRect(ui.data["main_width"] + 2, ui.data["main_height"] + 2)

                    UiTranslate(0, 1)
                    UiColor(0.1, 0.1, 0.1)
                    UiRect(ui.data["main_width"], ui.data["main_height"])
                    
                    UiColor(1, 1, 1)
                    UiTranslate(0, 30)
                    UiText("Game")

                    UiColor(r, g, b)
                    UiTranslate(0, 10)
                    UiRect(ui.data["main_width"], 5)

                    -- game modules
                    do
                        -- setup
                        UiFont("bold.ttf", 25)
                        UiTextShadow(0, 0, 0, 0, 0)

                        -- freeze timer
                        ui.utilities.new_toggle({
                            ["first"] = true,
                            ["name"] = "Freeze Timer",
                            ["rgb"] = {r, g, b},
                        })

                        -- mission stats
                        ui.utilities.new_toggle({
                            ["name"] = "Mission Stats",
                            ["rgb"] = {r, g, b},
                        })

                        -- no alarm
                        ui.utilities.new_toggle({
                            ["name"] = "No Alarm",
                            ["rgb"] = {r, g, b},
                        })

                        -- no objectives
                        ui.utilities.new_toggle({
                            ["name"] = "No Objectives",
                            ["rgb"] = {r, g, b},
                        })

                        -- no robots
                        ui.utilities.new_toggle({
                            ["name"] = "No Robots",
                            ["rgb"] = {r, g, b},
                        })

                        -- auto escape
                        ui.utilities.new_toggle({
                            ["name"] = "Auto Escape",
                            ["rgb"] = {r, g, b},
                        })

                        -- inf ammo
                        ui.utilities.new_toggle({
                            ["name"] = "Inf Ammo",
                            ["rgb"] = {r, g, b},
                        })

                        -- inf money
                        ui.utilities.new_toggle({
                            ["name"] = "Inf Money",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Teleport",
                                },
                            }
                        })
                    end
                UiPop()
                
                -- interface
                UiPush()
                    UiTranslate(ui.data["sections"]["interface"], ui.data["main_y"])
                    
                    UiTranslate(0, -1)
                    UiRect(ui.data["main_width"] + 2, ui.data["main_height"] + 2)

                    UiTranslate(0, 1)
                    UiColor(0.1, 0.1, 0.1)
                    UiRect(ui.data["main_width"], ui.data["main_height"])
                    
                    UiColor(1, 1, 1)
                    UiTranslate(0, 30)
                    UiText("Interface")

                    UiColor(r, g, b)
                    UiTranslate(0, 10)
                    UiRect(ui.data["main_width"], 5)

                    -- interface modules
                    do
                        -- setup
                        UiFont("bold.ttf", 25)
                        UiTextShadow(0, 0, 0, 0, 0)

                        -- watermark
                        ui.utilities.new_toggle({
                            ["first"] = true,
                            ["name"] = "Watermark",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Rainbow",
                                },
                            }
                        })

                        -- feature list
                        ui.utilities.new_toggle({
                            ["name"] = "Feature List",
                            ["rgb"] = {r, g, b},
                            ["options"] = {
                                {
                                    ["type"] = "bool",
                                    ["name"] = "Rainbow",
                                },
                            }
                        })

                        -- change log
                        ui.utilities.new_toggle({
                            ["name"] = "Change Log",
                            ["rgb"] = {r, g, b},
                        })
                    end
                UiPop()
            UiPop()
        end

        -- config
        ui.config()
    end
end

local modules = {}
do
    modules.utilities = {}
    do
        modules.utilities.draw_origin = nil

        modules.utilities.apply_esp = function(body, esp_config)
            if esp_config["highlights"] then
                DrawBodyHighlight(body, 1)
            end
            
            if esp_config["chams"] then
                DrawBodyOutline(body, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3], 1)
            end
            
            if esp_config["tracers"] then
                DebugLine(modules.utilities.draw_origin, resolve.body_center(body), esp_config["color"][1], esp_config["color"][2], esp_config["color"][3], 1)
            end
            
            if esp_config["nametags"] or esp_config["distance"] then
                local body_screen_x, body_screen_y, body_distance = UiWorldToPixel(resolve.body_center(body))
                if body_distance > 0 then
                    local body_distance = math.floor(body_distance)
                    
                    UiPush()
                        UiTextOutline(0, 0, 0, 1, 0.2)
                        UiFont("bold.ttf", 15)
                        UiColor(esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                        UiAlign("center")
                        if esp_config["nametags"] and esp_config["distance"] then
                            UiPush()
                                UiTranslate(body_screen_x, body_screen_y - 6)
                                UiText(esp_config["body_name"])
                            UiPop()
                            
                            UiPush()
                                UiTranslate(body_screen_x, body_screen_y + 6)
                                UiText(body_distance .. "m")
                            UiPop()
                        elseif esp_config["nametags"] then
                            UiTranslate(body_screen_x, body_screen_y)
                            UiAlign("center")
                            UiText(name)
                        elseif esp_config["distance"] then
                            UiTranslate(body_screen_x, body_screen_y)
                            UiAlign("center")
                            UiText(body_distance .. "m")
                        end
                    UiPop()
                end
            end

            if esp_config["3dboxes"] or esp_config["2dboxes"] then
                -- 3d
                local bottom_corner, top_corner = GetBodyBounds(body)

                local y_offset = Vec(0, bottom_corner[2] - top_corner[2], 0) 

                local x_offset = Vec(bottom_corner[1] - top_corner[1], 0, 0)
                local z_offset = Vec(0, 0, bottom_corner[3] - top_corner[3])
                local xz_offset = VecAdd(x_offset, z_offset)
                local zx_offset = VecAdd(z_offset, x_offset)

                local xy_offset = VecAdd(x_offset, y_offset)
                local zy_offset = VecAdd(z_offset, y_offset)
                local xzy_offset = VecAdd(xz_offset, y_offset)
                local zxy_offset = VecAdd(zx_offset, y_offset)

                local point_a = VecSub(bottom_corner, x_offset)
                local point_b = VecSub(bottom_corner, z_offset)
                local point_c = VecSub(bottom_corner, y_offset)
                local point_d = VecSub(bottom_corner, zx_offset)
                local point_e = VecSub(bottom_corner, xy_offset)
                local point_f = VecSub(bottom_corner, xzy_offset)
                local point_g = VecSub(bottom_corner, zy_offset)

                if esp_config["3dboxes"] then
                    DebugLine(bottom_corner, point_a, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_a, VecSub(bottom_corner, xz_offset), esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(bottom_corner, point_b, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_b, point_d, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])

                    DebugLine(point_c, point_e, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_e, point_f, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_c, point_g, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_g, VecSub(bottom_corner, zxy_offset), esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])

                    DebugLine(point_a, point_e, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_b, point_g, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(point_d, point_f, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                    DebugLine(bottom_corner, point_c, esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])
                end

                -- 2d
                if esp_config["2dboxes"] then
                    local screen_points = {}
                    local world_points = {
                        point_a,
                        point_b,
                        point_c,
                        point_d,
                        point_e,
                        point_f,
                        point_g,
                        bottom_corner,
                    }

                    local box_top = {0, math.huge}
                    local box_bottom = {0, 0}
                    local box_left = {math.huge, 0}
                    local box_right = {0, 0}

                    local box_top_size = {0, 1}
                    local box_bottom_size = {0, 1}
                    local box_left_size = {1, 0}
                    local box_right_size = {1, 0}

                    local is_box_on_screen = true
                    for _, world_point in pairs(world_points) do
                        local screen_x, screen_y, distance = UiWorldToPixel(world_point)

                        is_box_on_screen = distance > 0
                        if not is_box_on_screen then
                            break
                        end

                        table.insert(screen_points, {screen_x, screen_y})
                    end

                    if is_box_on_screen then
                        for _, screen_point in pairs(screen_points) do
                            if screen_point[2] < box_top[2] then
                                box_top = screen_point
                            end

                            if screen_point[2] > box_bottom[2] then
                                box_bottom = screen_point
                            end

                            if screen_point[1] < box_left[1] then
                                box_left = screen_point
                            end

                            if screen_point[1] > box_right[1] then
                                box_right = screen_point
                            end
                        end
                        
                        local point_a = {box_left[1], box_top[2]}
                        local point_b = {box_left[1], box_bottom[2]}
                        local point_c = {box_right[1], box_top[2]}

                        local size_a = {math.floor(box_right[1] - box_left[1]) + 1, 1}
                        local size_b = {1, math.floor(box_bottom[2] - box_top[2]) + 1}

                        UiPush()
                            UiColor(esp_config["color"][1], esp_config["color"][2], esp_config["color"][3])

                            UiAlign("left")
                            UiPush()
                                UiTranslate(point_a[1], point_a[2])
                                UiRect(size_a[1], size_a[2])
                            UiPop()
                            UiPush()
                                UiTranslate(point_b[1], point_b[2])
                                UiRect(size_a[1], size_a[2])
                            UiPop()
                            
                            UiAlign("top")
                            UiPush()
                                UiTranslate(point_a[1], point_a[2])
                                UiRect(size_b[1], size_b[2])
                            UiPop()
                            UiPush()
                                UiTranslate(point_c[1], point_c[2])
                                UiRect(size_b[1], size_b[2])
                            UiPop()
                        UiPop()
                    end
                end
            end
        end
    end
	
	modules.player = function()
		-- godmode
		if GetBool("savegame.mod.tearhook.modules.godmode") then
			SetPlayerHealth(1)
		end
	end
	
	modules.movement = function()
        -- checks
        if GetPlayerVehicle() ~= 0 or ui.data["enabled"] then
            return
        end
        
		-- jesus
		if GetBool("savegame.mod.tearhook.modules.jesus") then
			local player_in_water, player_depth = IsPointInWater(GetPlayerTransform().pos)
			if player_in_water then
				local current_player_velocity = GetPlayerVelocity()
				
				local vertical_velocity
				if InputDown("jump") or player_depth > 0.1 then
					vertical_velocity = 5
				else
					vertical_velocity = player_depth * 20
				end
				
				SetPlayerVelocity(Vec(current_player_velocity[1], vertical_velocity, current_player_velocity[3]))
			end
		end
	
		-- jetpack
		if GetBool("savegame.mod.tearhook.modules.jetpack") then
			if InputDown("jump") then
				local current_player_velocity = GetPlayerVelocity()
				SetPlayerVelocity(Vec(current_player_velocity[1], GetInt("savegame.mod.tearhook.options.jetpack.multiplier"), current_player_velocity[3]))
			end
		end
		
		-- speed
		if GetBool("savegame.mod.tearhook.modules.speed") then
			if InputDown("up") then
				local player_velocity = GetPlayerVelocity()
				if VecLength(player_velocity) > 50 then
                    return
                end
				
				local direction = Vec(0, 0, 0)
				if InputDown("up") then
                    direction = VecAdd(direction, Vec(0, 0, 1))
                end
				if InputDown("down") then
                    direction = VecAdd(direction, Vec(0, 0, -1))
                end
				if InputDown("left") then
                    direction = VecAdd(direction, Vec(1, 0, 0))
                end
				if InputDown("right") then
                    direction = VecAdd(direction, Vec(-1, 0, 0))
                end
				
				local camera_transform = GetPlayerCameraTransform()
				local camera_transform_position = camera_transform.pos
				local camera_transform_parent_point = TransformToParentPoint(camera_transform, Vec(0, 0, 1))
                camera_transform_parent_point[2] = 0
				camera_transform_position[2] = 0
				camera_transform.rot = QuatLookAt(GetPlayerTransform(), VecNormalize(VecSub(camera_transform_position, camera_transform_parent_point)))

				local new_velocity = VecSub(camera_transform_position, TransformToParentPoint(camera_transform, VecScale(VecNormalize(direction), GetInt("savegame.mod.tearhook.options.speed.multiplier"))))
				new_velocity[2] = player_velocity[2]
				
				SetPlayerVelocity(new_velocity)
			end
		end
		
		-- faststop
		if GetBool("savegame.mod.tearhook.modules.faststop") then
			if not InputDown("up") and not InputDown("down") and not InputDown("left") and not InputDown("right") then
				local vertical_player_velocity = GetPlayerVelocity()[2]
				SetPlayerVelocity(Vec(0, vertical_player_velocity, 0))
			end
		end
		
		-- shiftteleport
		if GetBool("savegame.mod.tearhook.modules.shiftteleport") then
			if InputPressed("shift") then
				local look_position = resolve.look_position()
				if not look_position then
                    return
                end
				SetPlayerTransform(Transform(look_position, GetCameraTransform().rot), true)
			end
		end
	end
	
	modules.visual = function()
		-- fov
		if GetBool("savegame.mod.tearhook.modules.fov") then
			SetCameraFov(GetInt("savegame.mod.tearhook.options.fov.amount"))
		end
		
        -- invisible tool and tool outline
        do
            local do_invisibletool = GetBool("savegame.mod.tearhook.modules.invisibletool")
            local do_tooloutline = GetBool("savegame.mod.tearhook.modules.tooloutline")
            local current_tool = GetToolBody()
            local is_tool_valid = IsHandleValid(current_tool)
            if do_invisibletool or do_tooloutline and is_tool_valid then
                local current_tool_shapes = GetBodyShapes(current_tool)
                
                local r, g, b
                if GetBool("savegame.mod.tearhook.options.tooloutline.rainbow") then
                    r, g, b = resolve.rgb()
                else
                    r, g, b = 1, 1, 1
                end
                
                for _, shape in pairs(current_tool_shapes) do
                    if do_invisibletool then
                        if not HasTag(shape, "invisible") then
                            SetTag(shape, "invisible")
                        end
                    else
                        if HasTag(shape, "invisible") then
                            RemoveTag(shape, "invisible")
                        end
                    end
                    
                    if do_tooloutline then
                        DrawShapeOutline(shape, r, g, b, 1)
                    end
                end
            elseif is_tool_valid then
                local current_tool_shapes = GetBodyShapes(current_tool)
                for _, shape in pairs(current_tool_shapes) do
                    if HasTag(shape, "invisible") then
                        RemoveTag(shape, "invisible")
                    end
                end
            end
        end

		-- esp
		do
            if GetBool("savegame.mod.tearhook.modules.esp") then
                local esp_config = {
                    ["highlights"] = GetBool("savegame.mod.tearhook.options.esp.highlights"),
                    ["chams"] = GetBool("savegame.mod.tearhook.options.esp.chams"),
                    ["tracers"] = GetBool("savegame.mod.tearhook.options.esp.tracers"),
                    ["nametags"] = GetBool("savegame.mod.tearhook.options.esp.nametags"),
                    ["distance"] = GetBool("savegame.mod.tearhook.options.esp.distance"),
                    ["3dboxes"] = GetBool("savegame.mod.tearhook.options.esp.3dboxes"),
                    ["2dboxes"] = GetBool("savegame.mod.tearhook.options.esp.2dboxes"),
                }
                
                if not esp_config["highlights"] and not esp_config["chams"] and not esp_config["tracers"] and not esp_config["nametags"] and not esp_config["distance"] and not esp_config["3dboxes"] and not esp_config["2dboxes"] then
                    return
                end

                modules.utilities.draw_origin = VecSub(GetCameraTransform().pos, Vec(0, 3, 0))

                for _, target in pairs(containers.bodies.targets) do
                    if GetTagValue(target, "target") ~= "cleared" then
                        esp_config["body_name"] = "Objective"
                        esp_config["color"] = {0.3, 1, 0.3}
                        modules.utilities.apply_esp(target, esp_config)
                    end
                end
                
                for _, escapevehicle in pairs(containers.bodies.escapevehicles) do
                    esp_config["body_name"] = "Escape"
                    esp_config["color"] = {1, 1, 1}
                    modules.utilities.apply_esp(escapevehicle, esp_config)
                end
                
                for _, valuable in pairs(containers.bodies.valuables) do
                    if not IsBodyBroken(valuable) then
                        esp_config["body_name"] = "Valuable"
                        esp_config["color"] = {1, 1, 0.3}
                        modules.utilities.apply_esp(valuable, esp_config)
                    end
                end
                
                for _, interactable in pairs(containers.bodies.interactables) do
                    if not IsBodyBroken(interactable) and GetTagValue(interactable, "interact") == "Pick up" then
                        esp_config["body_name"] = "Tool"
                        esp_config["color"] = {0.3, 0.3, 1}
                        modules.utilities.apply_esp(interactable, esp_config)
                    end
                end
            end
		end
	end
	
	modules.game = function()
		-- freezetimer
		if GetBool("savegame.mod.tearhook.modules.freezetimer") then
			if HasKey("level.alarmtimer") then
				if GetFloat("level.alarmtimer") < 60 then
					SetFloat("level.alarmtimer", 60)
				end
			end
		end
		
		-- missionstats
		if GetBool("savegame.mod.tearhook.modules.missionstats") then
			if GetFloat("level.missiontime") then
				if GetFloat("level.missiontime") > 0 then
					SetFloat("level.missiontime", 0)
				end
			end
		end
		
		-- noalarm
		if GetBool("savegame.mod.tearhook.modules.noalarm") then
			if GetBool("level.alarm") then
				SetBool("level.alarm", false)
			end
			if GetBool("level.firealarm") then
				SetBool("level.firealarm", false)
			end
		end
		
		-- noobjectives
		if GetBool("savegame.mod.tearhook.modules.noobjectives") then
			for _, target in pairs(containers.bodies.targets) do
				if not IsHandleValid(target) then
                    return
                end
			
				if GetTagValue(target, "target") ~= "cleared" then
					SetTag(target, "target", "cleared")
				end
			end
		end
		
		-- norobots
        do
            if GetBool("savegame.mod.tearhook.modules.norobots") then
                for _, robot in pairs(containers.bodies.robots) do
                    if not IsHandleValid(robot) then
                        return
                    end
                
                    if not HasTag(robot, "inactive") then
                        SetTag(robot, "inactive")
                    end
                end
            else
                for _, robot in pairs(containers.bodies.robots) do
                    if HasTag(robot, "inactive") then
                        RemoveTag(robot, "inactive")
                    end
                end
            end
        end
		
		-- autoescape
		if GetBool("savegame.mod.tearhook.modules.autoescape") then
			if GetBool("level.complete") then
				SetString("level.state", "win")
			end
		end

        -- infammo
		if GetBool("savegame.mod.tearhook.modules.infammo") then
			for _, batch in pairs(containers.tools) do
				SetInt(batch[1], batch[2])
			end
		end

        -- infmoney
        do
            if GetBool("savegame.mod.tearhook.modules.infmoney") then
                for _, valuable in pairs(containers.bodies.valuables) do
                    if IsHandleValid(valuable) then
                        if GetBool("savegame.mod.tearhook.options.infmoney.teleport") then
                            local camera_transform_position = GetCameraTransform().pos
                            if GetBodyTransform(valuable).pos ~= camera_transform_position then
                                if IsBodyJointedToStatic(valuable) then
                                    for _, shape in pairs(GetBodyShapes(valuable)) do
                                        for _, joint in pairs(GetShapeJoints(shape)) do
                                            DetachJointFromShape(joint, shape)
                                        end
                                    end
                                end
                                
                                SetBodyTransform(valuable, Transform(VecAdd(camera_transform_position, Vec(0, 1, 0))))
                                SetBodyActive(valuable, false)
                            end
                        end
                        if tonumber(GetTagValue(valuable, "value")) ~= 999999 then
                            SetTag(valuable, "value", 999999)
                        end
                    end
                end
            else
                for _, valuable in pairs(containers.bodies.valuables) do
                    if IsHandleValid(valuable) and tonumber(GetTagValue(valuable, "value")) == 999999 then
                        for _, batch in pairs(containers.valuables) do
                            if batch[1] == valuable then
                                SetTag(valuable, "value", batch[2])
                            end
                        end
                    end
                end
            end
        end
	end
	
	modules.interface = function()
		local do_watermark_rainbow = GetBool("savegame.mod.tearhook.options.watermark.rainbow")
        local do_featurelist_rainbow = GetBool("savegame.mod.tearhook.options.featurelist.rainbow")
		local r, g, b = resolve.rgb()

		if GetBool("savegame.mod.tearhook.modules.watermark") and not ui.data["enabled"] then
			UiPush()
				UiAlign("top right")
				UiTranslate(UiWidth(), 0)
				UiTextOutline(0, 0, 0, 1, 0.2)
                if do_watermark_rainbow then
				    UiColor(r, g, b)
                else
                    UiColor(1, 1, 1)
                end
				UiFont("bold.ttf", 38)
				UiText("TearHook")
			UiPop()
		end
		
		if GetBool("savegame.mod.tearhook.modules.featurelist") and not ui.data["enabled"] then
			UiPush()
				UiAlign("top right")
				if GetBool("savegame.mod.tearhook.modules.watermark") then
					UiTranslate(UiWidth(), 28)
				else
					UiTranslate(UiWidth(), 0)
				end
				UiTextOutline(0, 0, 0, 1, 0.2)
                if do_featurelist_rainbow then
				    UiColor(r, g, b)
                else
                    UiColor(1, 1, 1)
                end
				UiFont("bold.ttf", 18)
				for _, feature in pairs(storage.modules) do
					if GetBool("savegame.mod.tearhook.modules." .. feature:gsub("%s+", "")) then
						UiText(feature, true)
					end
				end
			UiPop()
		end
		
		if GetBool("savegame.mod.tearhook.modules.changelog") and not ui.data["enabled"] then
			UiPush()
				UiAlign("top left")
				UiTextOutline(0, 0, 0, 1, 0.2)
				UiColor(1, 1, 1)
				UiTranslate(0, 0)
				UiFont("bold.ttf", 28)
				UiText("Change Log")
				UiTranslate(0, 24)
				UiFont("bold.ttf", 16)
				for _, line in pairs(storage.changelog) do
					UiText(line, true)
				end
			UiPop()
		end
	end

    do
        modules.draw = function()
            modules.visual()
            modules.interface()
        end

        modules.update = function()
            modules.player()
            modules.movement()
            modules.game()
        end
    end
end

function update()
    -- sort module list
    UiFont("bold.ttf", 18)
    table.sort(storage.modules, function(module_a, module_b)
        return UiGetTextSize(module_a) > UiGetTextSize(module_b)
    end)

    -- other
    config.setup()

    -- update storage
    do
        containers.bodies.targets = FindBodies("target", true)
        containers.bodies.escapevehicles = FindBodies("escapevehicle", true)
        containers.bodies.valuables = FindBodies("valuable", true)
        containers.bodies.interactables = FindBodies("interact", true)
        containers.bodies.robots = FindBodies("body", true)

        for _, tool in pairs(ListKeys("game.tool")) do
            local ammo_path = "game.tool." .. tool .. ".ammo"
            local is_registered = false
            for _, batch in pairs(containers.tools) do
                if batch[1] == ammo_path then
                    is_registered = true
                    break
                end
            end
            if HasKey(ammo_path) and not is_registered then
                table.insert(containers.tools, {ammo_path, GetInt(ammo_path)})
            end
        end

        for _, valuable in pairs(containers.bodies.valuables) do
            local current_value = tonumber(GetTagValue(valuable, "value"))
            local is_registered = false
            for _, batch in pairs(containers.valuables) do
                if batch[1] == valuable then
                    is_registered = true
                    break
                end
            end
            if IsHandleValid(valuable) and current_value ~= 999999 and not is_registered then
                table.insert(containers.valuables, {valuable, current_value})
            end
        end
    end

    -- other
    modules.update()
end

function draw()
    -- other
    modules.draw()
    ui.display()
end
