local function header()
    return [[

    this script was maded with love for nixware community.
    if you want to support us, consider joining our discord server: https://demonside.dev/discord

    этот скрипт был создан с любовью для комьюнити никсвара.
    если вы хотите поддержать нас, присоединяйтесь к нашему дискорд-серверу: https://demonside.dev/discord

    ]]
end

-- Bundled by luabundle {"version":"1.7.0"}
local __bundle_require, __bundle_loaded, __bundle_register, __bundle_modules = (function(superRequire)
	local loadingPlaceholder = {[{}] = true}

	local register
	local modules = {}

	local require
	local loaded = {}

	register = function(name, body)
		if not modules[name] then
			modules[name] = body
		end
	end

	require = function(name)
		local loadedModule = loaded[name]

		if loadedModule then
			if loadedModule == loadingPlaceholder then
				return nil
			end
		else
			if not modules[name] then
				if not superRequire then
					local identifier = type(name) == 'string' and '\"' .. name .. '\"' or tostring(name)
					error('Tried to require ' .. identifier .. ', but no such module has been registered')
				else
					return superRequire(name)
				end
			end

			loaded[name] = loadingPlaceholder
			loadedModule = modules[name](require, loaded, register, modules)
			loaded[name] = loadedModule
		end

		return loadedModule
	end

	return require, loaded, register, modules
end)(require)
__bundle_register("__root", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef [[
    typedef struct {
        long x;
        long y;
    } p;

    short GetKeyState(int nVirtKey);
    unsigned short GetAsyncKeyState(int vKey);

    int GetCursorPos(p* lpPoint);
    int ScreenToClient(void* hWnd, p* lpPoint);

    void* FindWindowA(const char* lpClassName, const char* lpWindowName);
    void* GetActiveWindow(void);
    void* GetForegroundWindow(void);
    bool FlashWindow(void* hWnd, bool bInvert);
]]

local base_path = get_game_directory() .. "\\lua\\demonside\\"

local paths_to_add = {
    base_path .. "library\\?.lua",
    base_path .. "library\\?\\init.lua",
    base_path .. "?.lua",
    base_path .. "?\\init.lua"
}

for _, p in ipairs(paths_to_add) do
    if not string.find(package.path, p, 1, true) then
        package.path = package.path .. ";" .. p
    end
end

local function ternary(a, b, c)
    if a then return b else return c end
end

function in_bounds(a, b, point)
    return point.x >= a.x and point.x <= b.x
        and point.y >= a.y and point.y <= b.y;
end

function lerp(a, b, t)
    local delta = b - a;

    if type(delta) == "number" then
        if math.abs(delta) < 0.005 then
            return b;
        end
    end

    return delta * t + a;
end

function inverse_lerp(a, b, v)
    return (v - a) / (b - a);
end

function clamp(x, min, max)
    if x < min then
        return min;
    end

    if x > max then
        return max;
    end

    return x;
end

function round(x)
    if x < 0 then
        return math.ceil(x - .5);
    end

    return math.floor(x + .5);
end

function normalize(x, min, max)
    if x < min or x > max then
        local delta = max - min;
        local offset = x - min;

        return min + (offset % delta);
    end

    return x;
end

function normalize_yaw(yaw)
    return normalize(yaw, -180, 180);
end

f = string.format

script_name = "demonside"
branch = get_user_name() == "sqwat1337" and "debug" or "release"
_DEBUG = false

local logging = require("core/logging")

require("render/render")
local color = require("render/color")
local events = require("engine/events")
local http = require("system/http")
local fs = require("core/file_system")
local utils = require("core/utils")
local cvar = require("engine/cvar")
local vector = require("engine/vector")
local tweening = require("render/tweening")
windows = require("render/windows")
local gui = require("render/gui")
local c_input = require("engine/input")
local entity = require("engine/entity")
local override = require("core/override")
local json = require("core/json")
local base64 = require("core/base64")
local clipboard = require("system/clipboard")
local cmd_button_t = require("engine/cmd_button_t")
local particle_manager = require("engine/particle_manager")
-- local veh = require "library/system/veh"
--
local folders = {}; do
    local PATH = get_game_directory() .. "/nix/"

    folders.demonside = PATH .. "demonside"
    folders.configs = folders.demonside .. "/configs"
    folders.locations = folders.demonside .. "/locations"
    folders.particles = get_game_directory():match("(.-game)") .. "\\csgo\\bin\\"

    for _, folder in pairs(folders) do
        if not fs.is_exists(folder) then
            fs.create_directory(folder)
            print_raw(f("\a%s[demonside] \adefault %s", gui.color:to_hex(), "%s not found. creating..."))
        end
    end
end

local files = {}; do
    local link = "https://github.com/emptyspotify/demonside-files/raw/refs/heads/main/"
    local PATH = get_game_directory() .. "/nix/demonside/"

    local list = {
        { path = "root",      name = "icons.ttf" },
        { path = "root",      name = "Inter-ExtraBold.ttf" },
        { path = "root",      name = "Inter-Medium.ttf" },
        { path = "root",      name = "Inter-SemiBold.ttf" },
        { path = "root",      name = "smallest_pixel-7.ttf" },
        { path = "root",      name = "MuseoSansCyrl-500.ttf" },
        { path = "locations", name = "de_dust2.json" },
        { path = "locations", name = "de_inferno.json" },
        { path = "locations", name = "de_mirage.json" },
        { path = "locations", name = "de_nuke.json" },
        { path = "locations", name = "de_overpass.json" },
        { path = "locations", name = "de_vertigo.json" },
        { path = "particles", name = "falling_ember1.vpcf_c" },
        { path = "particles", name = "falling_ember2.vpcf_c" },
        { path = "particles", name = "falling_snow1.vpcf_c" },
        { path = "particles", name = "nomove_stars.vpcf_c" },

    }


    for _, data in pairs(list) do
        local PATH = data.path:find("particles") and folders.particles or PATH
        local name = data.name
        local path = data.path
        local file_path = PATH .. name

        if path ~= "root" and path ~= "particles" then
            file_path = PATH .. path .. "/" .. name
        end

        if fs.is_exists(file_path) then
            goto continue
        end

        http.get(link .. name, function(response)
            if response.status ~= 200 then
                return
            end

            print_raw(f("\a%s[demonside] \a%s", gui.color:to_hex(), "downloading " .. name .. "..."))
            fs.write(file_path, response.body)
        end)

        ::continue::
    end
end

local script = {
    name = script_name,
    branch = branch,
    user = {
        name = get_user_name(),
    }
}

local g_view_angles = angle_t(0, 0, 0)
local wallbang_needs_reload = false

local screen = render.screen_size()

local uix = {}; do
    local aimbot = gui:create("A", "Aimbot"); do
        local general = aimbot:group "General"; do
            general.duck_peek_assist = general:label("Duck Peek Assist", function(gear)
                return {
                    hotkey = gear:hotkey "Hotkey",
                    hitboxes = gear:selectable("Hitboxes",
                        { "Head", "Neck", "Chest", "Stomach", "Pelvis", "Arms", "Legs", "Feet" }, true),
                    damage = gear:slider("Damage", 1, 120, 50),
                    remove_visualize = gear:switch("Remove Visualize", false),
                }
            end)
        end

        aimbot.general = general
    end

    local anti_aim = gui:create("B", "Anti-aim"); do
        local hotkeys = anti_aim:group "Hotkeys"; do
            hotkeys.manual_yaw = hotkeys:label("Manual Yaw", function(gear)
                return {
                    left = gear:hotkey("Left", c_input:get_code "Z"),
                    right = gear:hotkey("Right", c_input:get_code "C"),
                    static = gear:switch("Static", false)
                }
            end)
            hotkeys.avoid_backstab = hotkeys:switch "Avoid Backstab"
            -- hotkeys.freestanding = hotkeys:hotkey "Freestanding"
            -- hotkeys.edge_yaw = hotkeys:hotkey "Edge Yaw"
        end

        anti_aim.hotkeys = hotkeys
    end

    local visuals = gui:create("C", "Visuals"); do
        local general = visuals:group "General"; do
            general.watermark = general:switch("Watermark", true, function(gear)
                local gears = {
                    fields = gear:selectable("Fields", { "User", "Build", "Time" }, true, { "User", "Build" }),
                    user = gear:selectable("User", { "Nixware", "Steam", "Custom" }),
                    custom = gear:input "Custom"
                }

                gears.custom:depend { gears.user, "Custom" }

                return gears
            end)
            -- general.hotkeys = general:switch "Hotkeys"
            -- general.spectators = general:switch "Spectators"
            general.crosshair_indicators = general:switch("Crosshair Indicators", false, function(gear)
                return {
                    branch = gear:switch "Branch",
                    statement = gear:switch("Statement", true),
                    pixel = gear:switch("Pixel", true)
                }
            end)
            general.slowdown_warning = general:switch("Slowdown Warning", false)
            general.manual_arrows = general:switch("Manual Arrows", false, function(gear)
                return {
                    always_visible = gear:switch("Always visible", true)
                }
            end)
            -- general.gamesense = general:switch "Gamesense"
            general.logs = general:switch("Logs", false, function(gear)
                return {
                    hit = gear:color_picker("Hit", gui.color),
                    hurt = gear:color_picker("Hurt", color(1, .5, .5, 1)),
                    events = gear:selectable("Events", { "Hit", "Hurt" }, true),
                    output = gear:selectable("Output", { "Screen", "Console" }, true)
                }
            end)
            general.fog = general:switch("Override Fog", false, function(gear)
                return {
                    start = gear:slider("Start", 1, 3500, 200),
                    final = gear:slider("End", 1, 5000, 3500),
                    density = gear:slider("Max density", 0, 100, 100, "%s%%"),
                    exponent = gear:slider("Exponent", 1, 100, 10),
                    color = gear:color_picker("Color", gui.color)
                    -- scattering = gear:switch("Scattering", false),
                    -- blendtobackground = gear:switch("Blend to background", false),
                    -- locallightscale = gear:slider("Local light scale", 0, 100, 0, "%d%%"),
                }
            end)
            general.dof = general:switch("Override DoF", false, function(gear)
                return {
                    near_blurry = gear:slider("Near Blurry", -100, 2000, -100),
                    far_blurry = gear:slider("Far Blurry", 0, 2000, 2000),
                    near_crisp = gear:slider("Near Crisp", 0, 2000, 0),
                    far_crisp = gear:slider("Far Crisp", 0, 2000, 180)
                }
            end)

            general.watermark_align = general:slider("Watermark align", 0, 2, 2)
            general.watermark_pos_x = general:slider("Watermark pos x", 0, screen.x, 0)

            general.watermark_align:visibility(false)
            general.watermark_pos_x:visibility(false)
        end

        local in_game = visuals:group "In Game"; do
            in_game.accent = in_game:color_picker("Accent", gui.color)
            in_game.perspective_options = in_game:label("Perspective Options", function(gear)
                return {
                    force_thirdperson = gear:switch "Force Third Person",
                    distance = gear:slider("Distance", 30, 180, round(cvar.cam_idealdist:float() or 50), "%du"),
                    height_offset = gear:slider("Height Offset", -10, 10, 0),
                    animated = gear:switch("Animated", true)
                }
            end)
            in_game.view_options = in_game:switch("View Options", false, function(gear)
                return {
                    fov = gear:slider("Field Of View", 50, 130, 90),
                    zoom = gear:slider("Zoom (x1)", 0, 100, 0, "%d%%"),
                    second_zoom = gear:slider("Zoom (x2)", 0, 100, 0, "%d%%"),
                }
            end)
            in_game.scope_overlay = in_game:switch("Scope Overlay", false, function(gear)
                return {
                    invert = gear:switch "Invert",
                    exclude_lines = gear:selectable("Exlclude Lines", { "Left", "Up", "Down", "Right" }, true),
                    offset = gear:slider("Offset", 1, 100),
                    length = gear:slider("Length", 10, 100),
                    hide_viewmodel = gear:switch "Hide Viewmodel"
                }
            end)

            in_game.grenades_esp = in_game:switch("Grenades ESP", false, function(gear)
                return {
                    molotov = gear:color_picker("Molotov", color(1, 0, 0, .5)),
                    smoke = gear:color_picker("Smoke", color(1, .3)),
                }
            end)

            in_game.kill_effect = in_game:switch("Kill Effect", false, function(gear)
                return {
                    effect = gear:selectable("Effect",
                        { "Molotov Explosion", "Explosion C4", "Explosion Falling", "Explosion Splash", "Taser" })
                }
            end)

            in_game.wallbang_helper = in_game:switch("Wallbang Helper", false, function(gear)
                local gears = {}

                local function get_level_name()
                    local level = engine.get_level_name()
                    if not level or level == "" or level == "<empty>" then return nil end
                    return level:gsub(".*/", ""):gsub("%.%w+$", "")
                end

                local function get_locations_file(level)
                    if not level then return nil end
                    return folders.locations .. "/" .. level .. ".json"
                end

                local function load_locations(level)
                    local file = get_locations_file(level)
                    if not file or not fs.is_exists(file) then return {} end
                    local content = fs.read(file)
                    if not content or content == "" then return {} end
                    local success, data = pcall(json.parse, content)
                    if not success or not data[level] then return {} end
                    return data[level]
                end

                local function save_locations(level, data)
                    local file = get_locations_file(level)
                    if not file then return end
                    local wrap = { [level] = data }
                    fs.write(file, json.stringify(wrap))
                end

                local function get_location_names()
                    local level = get_level_name()
                    if not level then return { "Empty :(" } end
                    local data = load_locations(level)
                    local names = {}
                    for _, loc in ipairs(data) do
                        table.insert(names, loc.name)
                    end
                    if #names == 0 then return { "Empty :(" } end
                    return names
                end

                gears.location = gear:selectable("Locations", get_location_names())
                gears.new_name = gear:input("Location Name", "")

                gears.add = gear:button("Add Position", function()
                    local level = get_level_name()
                    if not level then return end

                    local me = entitylist.get_local_player_pawn()
                    if not me or not me:is_alive() then return end

                    local name = gears.new_name:get()
                    if name == "" or name == "Default" then
                        name = "Wallbang " .. (#load_locations(level) + 1)
                    end

                    local pos = me:get_abs_origin()
                    local eye = me:get_eye_position()
                    local locs = load_locations(level)


                    table.insert(locs, {
                        name = name,
                        pos = { x = pos.x, y = pos.y, z = pos.z },
                        eye_pos = { x = eye.x, y = eye.y, z = eye.z },
                        angles = { pitch = g_view_angles.pitch, yaw = g_view_angles.yaw, roll = g_view_angles.roll },
                    })
                    save_locations(level, locs)
                    gears.location:set_items(get_location_names())
                    wallbang_needs_reload = true
                end)

                gears.remove = gear:button("Remove Selected", function()
                    local level = get_level_name()
                    if not level then return end

                    local manual_name = gears.new_name:get()
                    local locs = load_locations(level)
                    if #locs == 0 then return end

                    local index = -1

                    if manual_name ~= "" then
                        for i, v in ipairs(locs) do
                            if v.name == manual_name then
                                index = i
                                break
                            end
                        end
                    else
                        local selection = gears.location:get()
                        for i, v in ipairs(gears.location:get_items()) do
                            if v == selection then
                                index = i
                                break
                            end
                        end
                    end

                    if index ~= -1 then
                        table.remove(locs, index)
                        save_locations(level, locs)
                        gears.location:set_items(get_location_names())
                        wallbang_needs_reload = true
                    end
                end)

                gears.refresh = gear:button("Refresh", function()
                    gears.location:set_items(get_location_names())
                    wallbang_needs_reload = true
                end)

                gears.current_map = gear:label(f("Current Map: %s", get_level_name() or "<empty>"))

                return gears
            end)

            in_game.world_effects = in_game:switch("World Effects", false, function(gear)
                return {
                    weather = gear:selectable("Weather", { "Ash", "Snow", "Rain", "Stars" }),
                    density = gear:slider("Density", 50, 1000, 200),
                }
            end)

            in_game.head_gear = in_game:switch("Head Gear", false, function(gear)
                return {
                    accent = gear:color_picker("Accent", color()),
                    accessory = gear:selectable("Accessory", { "Nimbus", "China Hat" }),
                }
            end)

            in_game.accent:set_callback(function(self)
                gui.color = self:get():alpha_modulate(1)
            end, true)
        end

        visuals.general = general
        visuals.in_game = in_game
    end

    local settings = gui:create("D", "Settings"); do
        local config = settings:group "Config"; do
            local path = f("%s/nix/demonside/configs", get_game_directory())
            local files = fs.get_files(path, "*.txt")

            if not files or #files == 0 then
                files = { "Empty :(" }
            end


            config.list = config:selectable("Configs", files)
            config.name = config:input("Name", "")
            config.save = config:button("Create / Save")
            config.load = config:button("Load")

            config.warning = config:label("You want to delete this config?")
            config.confirm = config:button("Confirm")
            config.cancel = config:button("Cancel")
            config.delete = config:button("Delete")
            config.refresh = config:button("Refresh")

            config.space = config:label("")
            config.export = config:button "Export"
            config.import = config:button "Import"

            config.warning:visibility(false)
            config.confirm:visibility(false)
            config.cancel:visibility(false)

            config.refresh:set_callback(function()
                local files = fs.get_files(path, "*.txt")

                if not files or #files == 0 then
                    files = { "Empty :(" }
                end

                config.list:set_items(files)
            end)
        end

        local extra = settings:group "Extra"; do
            extra.auto_buy = extra:switch("Auto Buy", false, function(gear)
                return {
                    weapon = gear:selectable("Weapon", { "None", "Autosnipers", "Scout", "AWP" }),
                    pistol = gear:selectable("Pistol", { "None", "Revolver", "Deagle", "P-250" }),
                    equipment = gear:selectable("Equipment",
                        { "Armor", "Full Armor", "Defuser", "Taser", "HE", "Molotov", "Smoke", "Flashbang", "Decoy" },
                        true)
                }
            end)
            extra.air_strafe = extra:switch("Air Strafe", false, function(gear)
                return {
                    settings = gear:selectable("Settings", {
                        --"Avoid Collisions",
                        -- "Stop On Shift",
                        "Movement Keys",
                        "Only While Holding Jump" }, true)
                }
            end)
            extra.edge_jump = extra:hotkey "Edge Jump"
            extra.removals = extra:selectable("Removals", { "Team Intro" }, true)
            extra.flash_taskbar = extra:switch "Flash Taskbar"
            extra.switch_knife_hand = extra:switch("Switch Knife Hand", true)
            extra.ragdolls = extra:switch("Ragdolls", false, function(gear)
                return {
                    gravity = gear:slider("Gravity", -200, 150, round(cvar.ragdoll_gravity_scale:float() * 100), "%s%%"),
                    fraction = gear:slider("Fraction", 0, 100, round(cvar.ragdoll_friction_scale:float() * 100), "%s%%"),
                }
            end)
        end

        settings.config = config
        settings.extra = extra
    end
    -- local config = gui:create("E", "Script")

    uix.aimbot = aimbot
    uix.anti_aim = anti_aim
    uix.visuals = visuals
    uix.settings = settings
end

local threat = nil

local aimbot = {}; do
    local tab = uix.aimbot
    local general = tab.general

    local hitbox_map = {
        ["Head"] = { 0 },
        ["Neck"] = { 1 },
        ["Chest"] = { 5, 6 },
        ["Stomach"] = { 3, 4 },
        ["Pelvis"] = { 2 },
        ["Arms"] = { 13, 14, 15, 16, 17, 18 },
        ["Legs"] = { 7, 8, 9, 10 },
        ["Feet"] = { 11, 12 }
    }

    local function get_hitboxes_by_selection(selection)
        local hitboxes = {}

        for _, menu_index in pairs(selection) do
            local group = hitbox_map[menu_index]
            if group then
                for _, hitbox_id in ipairs(group) do
                    table.insert(hitboxes, hitbox_id)
                end
            end
        end

        return hitboxes
    end


    local duck_peek_assist = {}; do
        local gear = general.duck_peek_assist

        function duck_peek_assist:can_hit(me, threat, hitboxes, wanted_damage)
            local condition = false

            if threat then
                for _, hitbox in pairs(hitboxes) do
                    local position = engine.get_hitbox_pos(threat, hitbox)
                    local damage = engine.trace_bullet(me, me:get_eye_position(true), position)

                    if damage and damage >= wanted_damage then
                        condition = true
                    end
                end
            end

            return condition
        end

        function duck_peek_assist:createmove(cmd)
            if not gear.hotkey:is_active() then
                return
            end

            local me = entitylist.get_local_player_pawn()

            if not me or not me:is_alive() then
                return
            end

            local hitboxes = gear.hitboxes:get()
            local damage = gear.damage:get()

            local can_hit = self:can_hit(me, threat, hitboxes, damage)

            if can_hit and me:can_fire() then
                return
            end

            cmd.in_duck = 1
        end
    end

    function aimbot.createmove(cmd)
        duck_peek_assist:createmove(cmd)
    end
end

local anti_aimbot = {}; do
    local tab = uix.anti_aim
    local hotkeys = tab.hotkeys

    local ctx = {
        side = 0,
        offset = 180
    }

    local IN_SPEED = false

    local MOVETYPE_NOCLIP = bit.lshift(1, 7)
    local MOVETYPE_LADDER = bit.lshift(1, 9)

    local FL_ONGROUND = bit.lshift(1, 0)
    local FL_DUCKING = bit.lshift(1, 1)

    local view_angles = angle_t(0, 0, 0)

    function anti_aimbot:get_statement()
        local me = entitylist.get_local_player_pawn()

        if not (me and me:is_alive()) then
            return "DEATH"
        end

        local flags = me.m_fFlags

        local in_air = bit.band(flags, FL_ONGROUND) == 0
        local in_duck = bit.band(flags, FL_DUCKING) ~= 0
        local speed = me:get_velocity():length_2d()

        if not in_air and me.m_bInLanding then
            in_air = true
        end

        if in_air then
            return in_duck and "IN AIR & C" or "IN AIR"
        end

        if in_duck then
            return speed > 0 and "SNEAKING" or "DUCKING"
        end

        if speed > 0 then
            return IN_SPEED and "SLOWWALKING" or "RUNNING"
        end

        return "STANDING"
    end

    function anti_aimbot:disable_at_targets(offset, static)
        local me = entitylist.get_local_player_pawn()
        local fake_offset = offset

        if threat then
            local my_pos = me:get_abs_origin()
            local enemy_pos = threat:get_abs_origin()

            local dx = enemy_pos.x - my_pos.x
            local dy = enemy_pos.y - my_pos.y
            local yaw_to_enemy = math.deg(math.atan2(dy, dx))

            local what_at_targets_wants = yaw_to_enemy
            local what_we_want = (static and 0 or view_angles.yaw) + offset

            fake_offset = normalize_yaw(what_we_want - what_at_targets_wants)
        end

        return fake_offset
    end

    function anti_aimbot.manuals()
        if c_input:is_key_clicked(hotkeys.manual_yaw.left:get().key) then
            if ctx.side ~= -1 then
                ctx.side = -1
                ctx.offset = 90
            else
                ctx.side = 0
            end
        end

        if c_input:is_key_clicked(hotkeys.manual_yaw.right:get().key) then
            if ctx.side ~= 1 then
                ctx.side = 1
                ctx.offset = -90
            else
                ctx.side = 0
            end
        end
    end

    function anti_aimbot.freestanding()
    end

    function anti_aimbot.avoid_backstab()
        if not hotkeys.avoid_backstab:get() then
            return
        end

        local me = entitylist.get_local_player_pawn()
        local origin = me:get_abs_origin()
        local entities = {}

        entity.get_players(true, false, function(enemy)
            local enemy_origin = enemy:get_abs_origin()
            local dist = origin:dist_to(enemy_origin)
            local weapon = enemy:get_active_weapon()
            local weapon_name = weapon ~= nil and weapon:get_class_name() or ""

            if dist <= 200 and weapon_name:lower():find "knife" then
                entities[#entities + 1] = {
                    entity = enemy,
                    distance = dist,
                    yaw = origin:angle_to(enemy_origin).yaw
                }
            end
        end)

        table.sort(entities, function(a, b)
            return a.distance < b.distance
        end)

        return entities[1] and entities[1].yaw or nil
    end

    local function disablers(cmd)
        local me = entitylist.get_local_player_pawn()

        if not me or not me:is_alive() then
            return false
        end

        if cmd.in_use == 1 then
            return true
        end

        local move_type = me.m_MoveType

        if move_type == 7 or move_type == 9 then
            return true
        end

        local weapon = me:get_active_weapon()

        if not weapon then
            return false
        end

        local weapon_data = weapon.m_pWeaponData

        if not weapon_data then
            return false
        end

        local throw_time = weapon.m_flThrowTime

        if weapon_data.m_WeaponType == 9 and throw_time > 0 then
            return true
        end

        return false
    end

    function anti_aimbot.createmove(cmd)
        local offset = nil
        local avoid_backstab = anti_aimbot.avoid_backstab()

        anti_aimbot.manuals()
        -- anti_aimbot.safe_head(cmd)

        if ctx.side ~= 0 then
            offset = hotkeys.manual_yaw.static:get() and anti_aimbot:disable_at_targets(ctx.offset) or ctx.offset
        end

        if avoid_backstab then
            offset = anti_aimbot:disable_at_targets(avoid_backstab, true)
        end

        override("ragebot_anti_aim_base_yaw_offset", offset)

        -- print(me:get_abs_rotation().yaw)

        -- override("ragebot_anti_aim", false)
        -- override("ragebot_anti_aim_base_yaw_offset", normalize_yaw(needed_offset - view_angles.yaw))
        IN_SPEED = cmd.in_speed ~= 0
    end

    function anti_aimbot.override_view(view)
        view_angles = view.angles
    end

    anti_aimbot.ctx = ctx
end

local visuals = {}; do
    local tab = uix.visuals
    local general = tab.general
    local in_game = tab.in_game

    local PATH = get_game_directory() .. "/nix/demonside/"

    windows:set_group(general)

    local perspective = {}; do
        local gear = in_game.perspective_options
        local view_options = in_game.view_options
        local previous_distance = cvar.cam_idealdist:float()
        local distance = cvar.cam_idealdist:float()

        local duck_peek_assist = uix.aimbot.general.duck_peek_assist

        function perspective.override_view(view)
            local me = entitylist.get_local_player_pawn()

            if not me then
                return
            end

            local new_distance = gear.distance:get()

            if gear.animated:get() then
                if engine.camera_in_thirdperson() then
                    distance = tweening:interp(distance, new_distance, .05)
                else
                    distance = 30
                end
            end

            if distance ~= new_distance then
                if not gear.animated:get() then
                    distance = new_distance
                end

                cvar.cam_idealdist:float(distance)
            end

            if not view_options:get() then
                return
            end

            local weapon = me:get_active_weapon()
            local zoom_level = weapon ~= nil and weapon.m_zoomLevel or 0

            local fov = in_game.view_options.fov:get()
            local scale_first = in_game.view_options.zoom:get()
            local scale_second = in_game.view_options.second_zoom:get()

            local height_offset = engine.camera_in_thirdperson() and gear.height_offset:get() or 0
            local movement_services = me.m_pMovementServices
            local duck_offset = movement_services and movement_services.m_flDuckViewOffset or 0
            local remove_visualize = duck_peek_assist.hotkey:is_active() and duck_peek_assist.remove_visualize:get()

            if remove_visualize then
                height_offset = height_offset - duck_offset
            end

            view.origin = vector(view.origin.x, view.origin.y, view.origin.z + height_offset)

            view.fov = ({
                [0] = fov,
                [1] = fov - (20 * (scale_first / 100)),
                [2] = fov - (40 * (scale_second / 100))

            })[zoom_level]

            local m_pObserverServices = me.m_pObserverServices

            if not m_pObserverServices then
                return
            end

            if gear.force_thirdperson:get() and m_pObserverServices.m_iObserverMode == 2 then
                m_pObserverServices.m_iObserverMode = 3
            end
        end

        function perspective.unload()
            cvar.cam_idealdist:float(previous_distance)
        end
    end

    local museo500 = render.setup_font(PATH .. "MuseoSansCyrl-500.ttf", 13)
    local icons = render.setup_font(PATH .. "icons.ttf", 15)
    local padding = 4

    local function render_container(icon, text, pos, size, accent, alpha, custom_icon)
        alpha = clamp(alpha, 0, 1)
        local position = vec2_t(pos.x, pos.y)
        local size = vec2_t(size.x, size.y)

        local icon_measure = type(icon) == "string" and render.calc_text_size(icon, icons) or vec2_t(14, 14)

        render.push_clip_rect(pos, pos + size)

        do -- header
            render.rect_filled(position, position + size, color(0.1, 0.1, 0.1, .5 * alpha), 4)
        end

        do -- icon
            position.x = position.x + padding

            if custom_icon then
                custom_icon(position + vec2_t(icon_measure.x * 0.5, size.y * 0.5), alpha)
            else
                render.text(icon, icons, position + vec2_t(1, (size.y - icon_measure.y) * .5),
                    accent:alpha_modulate(alpha))
            end

            position.x = position.x + icon_measure.x + padding
        end


        do -- background
            render.rect_filled(position, position + size - vector(icon_measure.x + padding * 2, 0),
                color(0.1, 0.1, 0.1, alpha), 4)
        end

        if text then
            position.x = position.x + padding

            local measure = render.calc_text_size(text, museo500)
            render.text(text, museo500, position + vec2_t(0, (size.y - measure.y) * .5), color(1, 1, 1, alpha))
        end

        render.pop_clip_rect()
    end

    local widgets = {}; do
        local watermark = {}; do
            local master = general.watermark
            local offset = 10

            local alpha = 0
            local width = 0

            local window = windows.new "Watermark"
                :set_pos(vec2_t(screen.x - offset, offset))
                :update(true)
            window.align = general.watermark_align:get() or 0

            local position_x = general.watermark_pos_x:get() ~= 0
                and general.watermark_pos_x:get()
                or window.pos.x

            window.on_dragging = function(self)
                position_x = self.pos.x
                self.align = 0
                general.watermark_align:set(0)
            end

            window.on_release = function(self)
                local part = screen.x / 3
                local new_pos_x = position_x + self.size.x * 0.5
                local align = math.floor(new_pos_x / part)

                if self.align ~= align then
                    self.align = align

                    if self.align == 1 then
                        position_x = position_x + self.size.x * 0.5
                    elseif self.align == 2 then
                        position_x = position_x + self.size.x
                    end

                    general.watermark_align:set(self.align)
                    general.watermark_pos_x:set(position_x)
                end
            end

            window.render_callback = function(self)
                local position = self.pos
                alpha = tweening:interp(alpha, master:get(), .05)

                self.is_active = ui.is_menu_opened() and master:get()

                if alpha <= 0 then
                    return
                end

                local fields = master.fields
                local user = master.user
                local custom = master.custom

                local icon = "F"
                local icon_measure = render.calc_text_size(icon, icons)
                local new_width = icon_measure.x + padding * 2
                local height = 23
                local size = vector(width, height)

                if next(fields:get()) ~= nil then
                    new_width = new_width + padding * 2
                end

                if self.align == 1 then
                    self.pos.x = position_x - width * 0.5
                elseif self.align == 2 then
                    self.pos.x = position_x - width
                end

                render_container(icon, nil, position, size, gui.color, alpha)

                render.push_clip_rect(position, position + size)
                local pos = vector(position.x + icon_measure.x + padding * 3, position.y)

                if fields:get "User" then
                    local icon = "P"
                    local icon_measure = render.calc_text_size(icon, icons)

                    render.text(icon, icons, pos + vector(0, (height - icon_measure.y) * .5),
                        gui.color:alpha_modulate(alpha))

                    local text = ({
                        ["Nixware"] = script.user.name,
                        ["Steam"] = cvar.name:string(),
                        ["Custom"] = custom:get()
                    })[user:get()]
                    local measure = render.calc_text_size(text, museo500)

                    render.text(text, museo500, pos + vector(icon_measure.x, (height - measure.y) * .5),
                        color(1, 1, 1, alpha))
                    new_width = new_width + icon_measure.x + measure.x + padding * .5
                    pos.x = pos.x + icon_measure.x + measure.x + padding * .5
                end

                if fields:get "Build" then
                    local icon = "Q"
                    local icon_measure = render.calc_text_size(icon, icons)

                    render.text(icon, icons, pos + vector(0, (height - icon_measure.y) * .5),
                        gui.color:alpha_modulate(alpha))

                    local text = script.branch
                    local measure = render.calc_text_size(text, museo500)

                    render.text(text, museo500, pos + vector(icon_measure.x, (height - measure.y) * .5),
                        color(1, 1, 1, alpha))
                    new_width = new_width + icon_measure.x + measure.x + padding * .5
                    pos.x = pos.x + icon_measure.x + measure.x + padding * .5
                end

                if fields:get "Time" then
                    local icon = "S"
                    local icon_measure = render.calc_text_size(icon, icons)

                    render.text(icon, icons, pos + vector(0, (height - icon_measure.y) * .5),
                        gui.color:alpha_modulate(alpha))

                    local text = os.date "%I:%M %p"
                    local measure = render.calc_text_size(text, museo500)

                    render.text(text, museo500, pos + vector(icon_measure.x, (height - measure.y) * .5),
                        color(1, 1, 1, alpha))
                    new_width = new_width + icon_measure.x + measure.x + padding * .5
                    pos.x = pos.x + icon_measure.x + measure.x + padding * .5
                end

                render.pop_clip_rect()

                width = clamp(tweening:interp(width, new_width, .05), 0, new_width)

                self:set_rules {
                    { pos = vector(screen.x / 2, screen.y / 2),                      horizontal = true },
                    { pos = vector(size.x * .5 + offset, screen.y / 2),              horizontal = true },
                    { pos = vector(screen.x - (size.x * .5 + offset), screen.y / 2), horizontal = true },
                    { pos = vector(0, screen.y * .5),                                horizontal = false },
                    { pos = vector(screen.x / 2, size.y * .5 + offset),              horizontal = false },
                    { pos = vector(screen.x / 2, screen.y - size.y * .5 - offset),   horizontal = false }
                }
                self:set_size(size)
            end
        end

        local logger = {}; do
            local master = general.logs
            local output = master.output
            local show = master.events
            local hit = master.hit
            local hurt = master.hurt

            local font = museo500

            local logs = {}

            local function add_log(icon, event, log, burn_update)
                if burn_update then
                    for i = 1, #logs do
                        if logs[i].burn_id == burn_update then
                            logs[i].text = log
                            logs[i].time = os.time()
                            return
                        end
                    end
                end

                table.insert(logs, 1, {
                    icon = icon,
                    type = event,
                    text = log,
                    time = os.time(),
                    width = 0,
                    alpha = 0,
                    offset_x = -30,
                    offset_y = 0,
                    burn_id = burn_update
                })
            end

            local hitgroups = {
                [-1] = "Invalid",
                [0] = "Generic",
                [1] = "Head",
                [2] = "Chest",
                [3] = "Stomach",
                [4] = "Left arm",
                [5] = "Right arm",
                [6] = "Left leg",
                [7] = "Right leg",
                [8] = "Neck",
                [9] = "Unused",
                [10] = "Gear",
                [11] = "Special",
                [12] = "Count",
                INVALID = -1,
                GENERIC = 0,
                HEAD = 1,
                CHEST = 2,
                STOMACH = 3,
                LEFTARM = 4,
                RIGHTARM = 5,
                LEFTLEG = 6,
                RIGHTLEG = 7,
                NECK = 8,
                UNUSED = 9,   -- WTF
                GEAR = 10,
                SPECIAL = 11, -- WTF x2
                COUNT = 12
            }

            local function console_print(s, clr)
                if not master:get() or not output:get "Console" then
                    return
                end

                local text = f(("\a%s[demonside]\adefault %s"):format(clr:to_hex(), s))

                print_raw(text)
            end

            local allow_weapons = { "knife", "c4", "decoy", "flashbang", "hegrenade", "incgrenade", "molotov", "inferno",
                "smokegrenade" }

            logger.player_hurt = function(e)
                local me = entitylist.get_local_player_controller()

                local attacker = e:get_controller "attacker"
                local userid = e:get_controller "userid"

                if not attacker or not userid then
                    return
                end

                local state = "Idle"

                if attacker == me and userid ~= me then
                    state = "Hit"
                end

                if attacker ~= me and userid == me then
                    state = "Hurt"
                end

                local name = state == "Hit" and userid.m_sSanitizedPlayerName or attacker.m_sSanitizedPlayerName
                local hitgroup = hitgroups[e:get_int "hitgroup"]:lower()
                local fatal = e:get_int "health" == 0
                local result = fatal and "Killed" or state
                local icon = "K"

                local total_damage = e:get_int "dmg_health"
                local weapon = e:get_string "weapon"

                if fatal and weapon == "hegrenade" then
                    result = "Exploded"
                    icon = "M"
                end

                if fatal and weapon == "knife" then
                    result = "Stabbed"
                end

                if fatal and weapon == "taser" then
                    result = "Tasered"
                    icon = "T"
                end

                if weapon == "inferno" then
                    result = "Burned"
                    icon = "N"

                    local burn_id = userid.m_steamID

                    for i = 1, #logs do
                        if logs[i].burn_id == burn_id then
                            local prev_dmg = tonumber(logs[i].text:match "(%d+)")
                            if prev_dmg then
                                total_damage = total_damage + prev_dmg
                            end
                            break
                        end
                    end
                end

                if state == "Hit" and show:get(state) then
                    local console_text = f("%s %s's %s for %d damage", result, name, hitgroup, total_damage)

                    console_print(console_text, hit:get())

                    local text = f("%s %s's %s for %d damage", result, name, hitgroup, total_damage)

                    if result ~= "Hit" then
                        text = f("%s %s%s%s", result, name, result == "Killed" and f(" in the %s", hitgroup) or "",
                            result == "Burned" and f(" for %d damage", total_damage) or "")
                    end

                    add_log(icon, state, text, result == "Burned" and userid.m_steamID)
                elseif state == "Hurt" and show:get(state) then
                    local console_text = f("%s by %s in the %s for %d damage", result, name, hitgroup, total_damage)

                    console_print(console_text, hurt:get())

                    local text = f("%s by %s in the %s for %d damage", result, name, hitgroup, total_damage)

                    if result ~= "Hurt" then
                        text = f("%s by %s%s%s", result, name, result == "Killed" and f(" in the %s", hitgroup) or "",
                            result == "Burned" and f(" for %d damage", total_damage) or "")
                    end

                    add_log("L", state, text, result == "Burned" and userid.m_steamID)
                end
            end

            local offset = 5

            local preview = {
                {
                    icon = "K",
                    type = "Hit",
                    text = "Hit sqwat's head for 100 damage",
                    time = -1,
                    width = 0,
                    alpha = 0,
                    offset_x = -30,
                    offset_y = 0
                },
                {
                    icon = "L",
                    type = "Hurt",
                    text = "Hurt by herstyle in the head for 100 damage",
                    time = -1,
                    width = 0,
                    alpha = 0,
                    offset_x = -30,
                    offset_y = 0
                }
            }

            local window = windows.new "Logs"
                :set_pos(vector(offset * 2, 10))
                :update(true)

            local align = 1

            window.render_callback = function(self)
                local list = logs

                if #list == 0 then
                    list = preview
                end

                self.is_active = ui.is_menu_opened() and master:get() and output:get "Screen"

                local offset_y = 0

                for i = 1, #list do
                    local log = list[i]

                    if log then
                        if log.alpha >= 0.1 then
                            local accent = log.type == "Hit" and hit:get() or hurt:get()

                            local text = log.text
                            local icon = log.icon
                            local icon_size = render.calc_text_size(icon, icons)
                            local measure = render.calc_text_size(text, font)

                            local width = measure.x + icon_size.x + padding * 4 + 2
                            local height = 23

                            if log.width == 0 then
                                log.width = width
                            end

                            log.width = tweening:interp(log.width, width, 0.05)

                            local size = vector(log.width, height)
                            local x = round(lerp(self.pos.x, self.pos.x + self.size.x * .5 - size.x * .5, align))
                            local y = round(self.pos.y + offset_y)

                            local position = vector(x, y)
                            render_container(icon, text, position, size, accent, 1 * log.alpha)

                            offset_y = offset_y + (size.y + padding) * log.offset_y
                        end
                    end
                end

                for i = 1, #list do
                    local log = list[i]

                    if log then
                        if log.time ~= -1 then
                            local should_remove = log.time + 5 < os.time() or i > 8 or
                                not (master:get() and output:get "Screen")

                            log.offset_y = tweening:interp(log.offset_y, 1, .075)
                            log.offset_x = tweening:interp(log.offset_x,
                                should_remove and (align == 0 and -30 or (i % 2 == 0 and 30 or -30)) or 0, .075)
                            log.alpha = tweening:interp(log.alpha, should_remove and 0 or 1, 0.075)

                            if should_remove and log.alpha <= 0.1 then
                                table.remove(list, i)
                            end
                        else
                            local reference = ui.is_menu_opened() and master:get() and output:get "Screen"

                            log.offset_y = tweening:interp(log.offset_y, 1, .075)
                            log.offset_x = tweening:interp(log.offset_x,
                                reference and 0 or (align == 0 and -30 or (i % 2 == 0 and 30 or -30)), .075)
                            log.alpha = tweening:interp(log.alpha, reference and 1 or 0, .075)
                        end
                    end
                end

                align = tweening:interp(align, self.pos.x < screen.x / 3 and 0 or 1, 0.075)

                self:set_rules {
                    { pos = vector(self.size.x * .5 + 10, 0),  horizontal = true },
                    { pos = vector(10, 10 + self.size.y * .5), horizontal = false },
                    { pos = screen * .5,                       horizontal = true }
                }
                self:set_size(vector(266, 23 * 2 + offset))
            end
        end

        local slowdown = {}; do
            local master = general.slowdown_warning

            local icons = render.setup_font(PATH .. "icons.ttf", 35);

            local alpha = 1
            local bar = 1

            local icon = "Y"
            local text = "Slowed down"

            local window = windows.new "Slowdown"
                :set_pos(vector(screen.x * .5, 300))
                :update(true)

            window.render_callback = function(self)
                local me = entitylist.get_local_player_pawn()
                local is_alive = me ~= nil and me:is_alive() or false
                local velocity_modifier = is_alive and me.m_flVelocityModifier or 1

                self.is_active = ui.is_menu_opened() and master:get()

                if ui.is_menu_opened() then
                    bar = (math.sin(os.clock() * 2) + 1) * .5
                else
                    bar = tweening:interp(bar, velocity_modifier, .05)
                end

                bar = clamp(bar, 0.01, 1)

                alpha = tweening:interp(alpha, master:get() and (ui.is_menu_opened() and 1 or bar < 1), .05)

                if alpha <= 0 then
                    return
                end

                local icon_measure = render.calc_text_size(icon, icons)
                local measure = render.calc_text_size(text, museo500)

                local width = icon_measure.x + measure.x + padding * 4
                local size = vector(width + 15, icon_measure.y + padding * 2)

                local pos = self.pos
                local position = vec2_t(self.pos.x, self.pos.y)


                local accent = gui.color:alpha_modulate(alpha)
                render.push_clip_rect(pos, pos + size)

                do -- header
                    render.rect_filled(position, position + size, color(0.1, 0.1, 0.1, .5 * alpha), 4)
                end

                do -- icon
                    position.x = position.x + padding

                    render.text(icon, icons, position + vec2_t(1, (size.y - icon_measure.y) * .5),
                        accent:alpha_modulate(alpha))
                    position.x = position.x + icon_measure.x + padding
                end


                do -- background
                    render.rect_filled(position, position + size - vector(icon_measure.x + padding * 2, 0),
                        color(0.1, 0.1, 0.1, alpha), 4)
                end

                if text then
                    position.x = position.x + padding + 7.5
                    local measure = render.calc_text_size(text, museo500)

                    render.text(text, museo500, position + vec2_t(0, (size.y - measure.y) * .5 - 4),
                        color(1, 1, 1, alpha))

                    do
                        local bar_y = (size.y - measure.y) * .5 + 12
                        local bar_h = 4
                        local bar_width = measure.x


                        -- render.rect_filled(position + vec2_t(-1, bar_y - 1),
                        --     position + vec2_t(bar_width + 1, bar_y + bar_h + 1), color(0, 0, 0, 0.8 * alpha), 5)

                        render.rect_filled(position + vec2_t(0, bar_y), position + vec2_t(bar_width, bar_y + bar_h),
                            color(0, 0.8 * alpha), 5)
                    end

                    render.rect_filled(position + vec2_t(0, (size.y - measure.y) * .5 + 12),
                        position + vec2_t(measure.x * bar, (size.y - measure.y) * .5 + 16), accent, 5)
                end

                render.pop_clip_rect()

                self:set_min(vector(screen.x * .5, 0))
                self:set_max(vector(screen.x * .5, screen.y))

                self:set_rules {
                    {
                        pos = vector(screen.x * .5, 0),
                        end_pos = vector(screen.x * .5, screen.y),
                        horizontal = true
                    }
                }
                self:set_size(size)
                self:set_pos(vector(screen.x * .5 - self.size.x * .5, self.pos.y))
            end
        end

        function widgets.player_hurt(e)
            logger.player_hurt(e)
        end
    end

    local crosshair = {}; do
        local master = general.crosshair_indicators
        local pixel = render.setup_font(PATH .. "smallest_pixel-7.ttf", 9)
        local verdana = render.setup_font("C:/Windows/Fonts/verdana.ttf", 13)
        local font = verdana

        local alpha = 0
        local offset = 0
        local reversed = 0

        local list = {
            {
                update_name = function(self)
                    return script.branch
                end,

                update_alpha = function(self)
                    self.alpha = tweening:interp(self.alpha, self:is_active() and 1 or 0, .05)
                    return self.alpha
                end,

                is_active = function()
                    return master.branch:get()
                end,

                alpha = 0
            },
            {
                update_name = function(self)
                    local statement = f("-%s-", anti_aimbot:get_statement())
                    return statement
                end,

                update_alpha = function(self)
                    self.alpha = tweening:interp(self.alpha, self:is_active() and 1 or 0, .05)
                    return self.alpha
                end,

                is_active = function()
                    return master.statement:get()
                end,

                alpha = 0
            },
            {
                update_name = function(self)
                    local me = entitylist.get_local_player_pawn()
                    local stamina = 0

                    if me then
                        stamina = me:get_stamina()
                    end
                    return f("\a%sDUCK", color():lerp(color(1, 0, 0), 1 - stamina):to_hex())
                end,

                update_alpha = function(self)
                    self.alpha = tweening:interp(self.alpha, self:is_active() and 1 or 0, .05)
                    return self.alpha
                end,

                is_active = function()
                    return uix.aimbot.general.duck_peek_assist.hotkey:is_active()
                end,

                alpha = 0
            },
            {
                update_name = function(self)
                    return "EDGE"
                end,

                update_alpha = function(self)
                    self.alpha = tweening:interp(self.alpha, self:is_active() and 1 or 0, .05)
                    return self.alpha
                end,

                is_active = function()
                    return uix.settings.extra.edge_jump:is_active()
                end,

                alpha = 0
            }
        }

        local function render_outline(text, font, position, clr)
            local outline_color = color(0, 0, 0, .25 * clr.a);

            render.text(text, font, position + vec2_t(-1, -1), outline_color);
            render.text(text, font, position + vec2_t(-1, 0), outline_color);
            render.text(text, font, position + vec2_t(-1, 1), outline_color);

            render.text(text, font, position + vec2_t(0, -1), outline_color);
            render.text(text, font, position + vec2_t(0, 0), outline_color);
            render.text(text, font, position + vec2_t(0, 1), outline_color);

            render.text(text, font, position + vec2_t(1, -1), outline_color);
            render.text(text, font, position + vec2_t(1, 0), outline_color);
            render.text(text, font, position + vec2_t(1, 1), outline_color);

            render.text(text, font, vec2_t(position.x, position.y), clr)
        end

        local function render_shadow(text, font, position, clr)
            local shadow_color = color(0, 0, 0, .5 * clr.a);

            render.text(text, font, position + 1, shadow_color);

            render.text(text, font, vec2_t(position.x, position.y), clr)
        end

        local function render_list(position, main_alpha)
            local offset_y = 1

            for i = 1, #list do
                local indicator = list[i]
                local name = indicator:update_name()
                local alpha = indicator:update_alpha()

                if not master.pixel:get() then
                    name = name:lower()
                end

                if alpha > 0 then
                    local measure = render.calc_text_size(name, font)
                    local indicator_offset = round((measure.x * .5))
                    local flags = master.pixel:get() and "o" or "d"

                    render.text(name, font, position + vector(-indicator_offset, (measure.y * offset_y) * reversed),
                        color(1, 1, 1, alpha * main_alpha), nil, flags)

                    offset_y = offset_y + alpha
                end
            end
        end

        local window = windows.new "Crosshair"
            :set_pos(screen.y / 2 + 10, "y")
            :update(true)

        crosshair.update = function()
            local active = master:get()

            local me = entitylist.get_local_player_pawn()
            local is_alive = me ~= nil and me:is_alive() or false

            local weapon_services = me and me.m_pWeaponServices or false
            local weapon = type(weapon_services) ~= "boolean" and weapon_services.m_hActiveWeapon or false
            local weapon_data = type(weapon) ~= "boolean" and weapon.m_pWeaponData or false
            local weapon_type = type(weapon_data) ~= "boolean" and weapon_data.m_WeaponType or 0
            local is_nade = weapon_type == 9
            local is_scoped = is_alive and me.m_bIsScoped or false

            alpha = tweening:interp(alpha, (is_alive and active) and (is_nade and 0.35 or 1) or 0, .05)
            offset = tweening:interp(offset,
                not window.is_dragging and not window.is_hovered and (is_alive and is_scoped) and 1 or 0, .05)
        end


        window.render_callback = function(self)
            font = verdana

            if master.pixel:get() then
                font = pixel
            end

            self.is_active = alpha > 0

            if alpha <= 0 then
                crosshair.is_reversed = false
                return
            end

            local position = vector(self.pos.x, self.pos.y)
            local is_reversed = false

            if screen.y * .5 - 10 > position.y then
                is_reversed = true
            end

            crosshair.is_reversed = is_reversed

            reversed = tweening:interp(reversed, is_reversed and -1 or 1, .05)
            local logo = "DEMONSIDE"

            if not master.pixel:get() then
                logo = logo:lower()
            end

            local logo_measure = render.calc_text_size(logo, font)
            position.x = position.x + round((logo_measure.x * .5 + 10) * offset)

            local fn = master.pixel:get() and render_outline or render_shadow

            fn(logo, font, position, gui.color:alpha_modulate(alpha))
            render_list(position + vector(logo_measure.x * .5, 0), alpha)

            self:set_min(vector(screen.x / 2, screen.y / 2 - 50))
            self:set_max(vector(screen.x / 2, screen.y / 2 + 50))
            self:set_rules {
                {
                    pos = vector(screen.x / 2, screen.y / 2 - 50),
                    end_pos = vector(screen.x / 2, screen.y / 2 + 50),
                    horizontal = true
                }
            }

            if screen.x * .5 - logo_measure.x * .5 ~= self.pos.x then
                self:set_pos(screen.x * .5 - logo_measure.x * .5, "x")
            end

            self:set_size(logo_measure)
        end
    end

    local manual_arrows = {}; do
        local function draw_arrow(direction, position, size, clr)
            local positions = {}

            if direction == "left" then
                positions = {
                    position,
                    vec2_t(position.x + size, position.y - size * .5),
                    vec2_t(position.x + size * 0.9, position.y - size * 0.2),
                    vec2_t(position.x + size * 0.9, position.y + size * 0.2),
                    vec2_t(position.x + size, position.y + size / 2)
                }
            else
                positions = {
                    position,
                    vec2_t(position.x - size, position.y + size / 2),
                    vec2_t(position.x - size * 0.9, position.y + size * 0.2),
                    vec2_t(position.x - size * 0.9, position.y - size * 0.2),
                    vec2_t(position.x - size, position.y - size * .5)
                }
            end

            render.polygon(positions, clr)
        end

        local size = 20
        local distance = size * 3.5
        local center = screen * vector(.5, .5)

        local window = windows.new "Arrows"
            :set_pos(vector(center.x - distance, center.y - size * .5))
            :update(true)

        local alpha = 0
        local y = center.y
        local master = general.manual_arrows

        window.render_callback = function(self)
            local position = vector(self.pos.x, self.pos.y)
            local pawn = entitylist.get_local_player_pawn()
            local condition = pawn and pawn:is_alive() and master:get()
            local align = center.y - size - 5

            if crosshair.is_reversed then
                align = center.y + size + 5
            end

            self.is_active = ui.is_menu_opened() and master:get()

            local side = anti_aimbot.ctx.side

            if master.always_visible:get() then
                alpha = tweening:interp(alpha, condition and 1 or 0, .05)
            else
                if ui.is_menu_opened() then
                    alpha = tweening:interp(alpha, condition and 1 or 0, .05)
                else
                    alpha = tweening:interp(alpha, (condition and side ~= 0) and 1 or 0, .05)
                end
            end

            y = tweening:interp(y, (condition and pawn.m_bIsScoped) and align or center.y, .05)

            local accent = gui.color

            local clr = {
                left = side == -1 and accent:alpha_modulate(alpha) or color(0, 0, 0, 0.6 * alpha),
                right = side == 1 and accent:alpha_modulate(alpha) or color(0, 0, 0, 0.6 * alpha)
            }

            local left = vector(position.x, y)
            local right = vector(center.x + (center.x - position.x) - 2, y)

            draw_arrow("left", left, size, clr.left)
            draw_arrow("right", right, size, clr.right)

            self:set_min(vector(center.x - size * 6, center.y))
            self:set_max(vector(center.x - size * 2, center.y))

            self:set_rules {
                {
                    pos = vector(center.x - size * 6, center.y),
                    end_pos = vector(center.x - size * 2, center.y),
                    horizontal = false
                }
            }

            self:set_pos(vector(position.x, center.y - size * .5))
            self:set_size(vector(size, size))
        end
    end

    local scope_overlay = {}; do
        local master = in_game.scope_overlay
        local exclude_lines = master.exclude_lines
        local alpha = 0
        local hide_viewmodel = master.hide_viewmodel


        local r_drawviewmodel = cvar.r_drawviewmodel
        local drawviewmodel = r_drawviewmodel:bool()
        local SCOPE_BORDERS = bit.lshift(1, 3)

        function scope_overlay.paint()
            local pawn = entitylist.get_local_player_pawn()

            if not pawn or not pawn:is_alive() then
                return
            end

            local removals = menu.misc_removals

            override("misc_removals", master:get() and bit.band(removals, bit.bnot(SCOPE_BORDERS)) or nil)

            local is_scoped = pawn.m_bIsScoped
            drawviewmodel = ternary(master:get() and is_scoped, not hide_viewmodel:get(), true)

            if drawviewmodel ~= r_drawviewmodel:bool() then
                r_drawviewmodel:bool(drawviewmodel)
            end

            alpha = tweening:interp(alpha, (master:get() and is_scoped) and 1 or 0, .05)

            if alpha > .1 then
                local length = master.length:get() * alpha
                local offset = master.offset:get() * alpha
                local invert = master.invert:get()

                local clr = gui.color:alpha_modulate(invert and 0 or alpha)
                local clr_inverted = gui.color:alpha_modulate(invert and alpha or 0)

                local position = screen * vec2_t(.5, .5)

                if not exclude_lines:get "Right" then
                    render.rect_filled_fade(position + vec2_t(offset + 1, 0), position + vec2_t(offset + length + 1, 1),
                        clr, clr_inverted, clr_inverted, clr)
                end

                if not exclude_lines:get "Left" then
                    render.rect_filled_fade(position - vec2_t(offset, 0), position - vec2_t(offset + length, -1), clr,
                        clr_inverted, clr_inverted, clr)
                end

                if not exclude_lines:get "Down" then
                    render.rect_filled_fade(position + vec2_t(0, offset + 1), position + vec2_t(1, offset + length + 1),
                        clr, clr, clr_inverted, clr_inverted)
                end

                if not exclude_lines:get "Up" then
                    render.rect_filled_fade(position - vec2_t(0, offset), position - vec2_t(-1, offset + length), clr,
                        clr, clr_inverted, clr_inverted)
                end
            end
        end

        function scope_overlay.scope_overlay(player, params)
            if master:get() then
                ffi.cast("unsigned char*", params)[4] = 0
            end
        end

        function scope_overlay.unload()
            r_drawviewmodel:bool(true)
        end
    end

    local depth_of_field = {}; do
        local master = general.dof

        local dof_override = cvar.r_dof_override
        local near_blurry = cvar.r_dof_override_near_blurry
        local far_blurry = cvar.r_dof_override_far_blurry
        local near_crisp = cvar.r_dof_override_near_crisp
        local far_crisp = cvar.r_dof_override_far_crisp

        local last_frame_check = 0

        local cache = {
            dof_override = { master:get(), master },
            near_blurry = { master.near_blurry:get(), master.near_blurry },
            far_blurry = { master.far_blurry:get(), master.far_blurry },
            near_crisp = { master.near_crisp:get(), master.near_crisp },
            far_crisp = { master.far_crisp:get(), master.far_crisp }
        }

        local function update()
            dof_override:bool(master:get())
            near_blurry:float(master.near_blurry:get())
            far_blurry:float(master.far_blurry:get())
            near_crisp:float(master.near_crisp:get())
            far_crisp:float(master.far_crisp:get())
        end

        local function check_cache()
            local frame = render.frame_count()
            local delta = frame - last_frame_check

            if delta < 5 then
                return
            end

            last_frame_check = frame

            for _, data in pairs(cache) do
                local new_value = data[2]:get()

                if data[1] ~= new_value then
                    data[1] = new_value
                    update()
                    return true
                end
            end
        end

        function depth_of_field.paint()
            check_cache()
        end

        function depth_of_field.level_init()
            update()
        end

        function depth_of_field.unload()
            dof_override:bool(false)
        end
    end

    local fog = {}; do
        local master = general.fog

        fog.paint = function()
            local pawn = entitylist.get_local_player_pawn()
            if not pawn then
                return
            end

            local CPlayer_CameraServices = pawn.m_pCameraServices
            if not CPlayer_CameraServices then
                return
            end

            local fogparams_t = CPlayer_CameraServices.m_CurrentFog
            if not fogparams_t then
                return
            end

            local enabled = master:get()
            if not enabled then
                return
            end

            local start = master.start:get()
            local final = master.final:get()
            local color = master.color:get()
            local exponent = master.exponent:get() / 10
            local density = master.density:get() / 100
            -- local scattering = master.scattering:get()
            -- local blendtobackground = master.blendtobackground:get()
            -- local locallightscale = master.locallightscale:get() / 100

            fogparams_t.enable = true;
            fogparams_t.maxdensity = density;
            fogparams_t.HDRColorScale = 1;
            fogparams_t.start = start;
            fogparams_t["end"] = final;
            fogparams_t.colorPrimary = color;
            fogparams_t.colorSecondary = color;
            fogparams_t.exponent = exponent
            -- fogparams_t.scattering = scattering
            -- fogparams_t.blendtobackground = blendtobackground
            -- fogparams_t.locallightscale = locallightscale

            local fogparams_t = pawn.m_skybox3d.fog

            fogparams_t.enable = true;
            fogparams_t.maxdensity = density;
            fogparams_t.HDRColorScale = 1;
            fogparams_t.start = start;
            fogparams_t["end"] = final;
            fogparams_t.colorPrimary = color;
            fogparams_t.colorSecondary = color;
            fogparams_t.exponent = exponent
            -- fogparams_t.scattering = scattering
            -- fogparams_t.blendtobackground = blendtobackground
            -- fogparams_t.locallightscale = locallightscale
        end
    end

    local grenade_esp = {}; do
        local MOLOTOV_RADIUS = 60.0
        local SMOKE_RADIUS = 160.0
        local CIRCLE_SEGMENTS = 60

        local master = in_game.grenades_esp

        local function get_convex_hull(points)
            local n = #points
            if n <= 2 then return points end
            table.sort(points, function(a, b)
                return a.x < b.x or (a.x == b.x and a.y < b.y)
            end)
            local function cross_product(o, a, b)
                return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
            end
            local lower = {}
            for i = 1, n do
                while #lower >= 2 and cross_product(lower[#lower - 1], lower[#lower], points[i]) <= 0 do
                    table.remove(lower)
                end
                table.insert(lower, points[i])
            end
            local upper = {}
            for i = n, 1, -1 do
                while #upper >= 2 and cross_product(upper[#upper - 1], upper[#upper], points[i]) <= 0 do
                    table.remove(upper)
                end
                table.insert(upper, points[i])
            end
            table.remove(lower)
            table.remove(upper)
            for i = 1, #upper do table.insert(lower, upper[i]) end
            return lower
        end

        function grenade_esp.draw(class_name, clr)
            entitylist.get_entities(class_name, function(ent)
                local world_points = {}

                if class_name == "C_Inferno" then
                    local count = ent.m_fireCount
                    if not count or count < 1 then return end

                    for i = 0, count - 1 do
                        if ent.m_bFireIsBurning[i] then
                            local pos = ent.m_firePositions[i]
                            if pos and pos.x ~= 0 then
                                for j = 1, 4 do
                                    local ang = (j * 90) * (math.pi / 180)
                                    table.insert(world_points, {
                                        x = pos.x + math.cos(ang) * MOLOTOV_RADIUS,
                                        y = pos.y + math.sin(ang) * MOLOTOV_RADIUS,
                                        z = pos.z
                                    })
                                end
                            end
                        end
                    end
                elseif class_name == "C_SmokeGrenadeProjectile" then
                    if not ent.m_bDidSmokeEffect then return end

                    local pos = ent.m_vSmokeDetonationPos
                    if not pos or pos.x == 0 then pos = ent.m_vecOrigin end
                    if not pos or pos.x == 0 then return end

                    for i = 1, CIRCLE_SEGMENTS do
                        local ang = (i / CIRCLE_SEGMENTS) * math.pi * 2
                        table.insert(world_points, {
                            x = pos.x + math.cos(ang) * SMOKE_RADIUS,
                            y = pos.y + math.sin(ang) * SMOKE_RADIUS,
                            z = pos.z
                        })
                    end
                end

                if #world_points < 3 then return end

                local screen_points = {}
                for _, wp in ipairs(world_points) do
                    local sp = render.world_to_screen(vec3_t(wp.x, wp.y, wp.z))
                    if sp then table.insert(screen_points, sp) end
                end

                local hull = get_convex_hull(screen_points)

                if #hull > 2 then
                    render.polygon(hull, clr)
                    local outline_clr = color_t(clr.r, clr.g, clr.b, 0.8)
                    render.poly_line(hull, outline_clr, 2)
                end
            end)
        end

        function grenade_esp.paint()
            if not master:get() then
                return
            end

            grenade_esp.draw("C_Inferno", master.molotov:get())
            grenade_esp.draw("C_SmokeGrenadeProjectile", master.smoke:get())
        end
    end

    local kill_effect = {}; do
        local master = in_game.kill_effect

        local effect_map = {
            ["Molotov Explosion"] = "particles/inferno_fx/molotov_explosion.vpcf",
            ["Explosion C4"] = "particles/explosions_fx/explosion_c4_500.vpcf",
            ["Explosion Falling"] = "particles/inferno_fx/explosion_incend_air_falling.vpcf",
            ["Explosion Splash"] = "particles/inferno_fx/explosion_incend_air_splash07a.vpcf",
            ["Taser"] = "particles/blood_impact/impact_taser_bodyfx.vpcf",
        }

        local fnPlayEffect = assert(
            find_pattern("client.dll", "48 89 5C 24 ? 48 89 7C 24 ? 55 41 56"),
            "fnPlayEffect outdated"); do
            fnPlayEffect = ffi.cast(
                "void (__fastcall *)(const char*, int, uintptr_t, char, int, char, unsigned int, int, char)",
                fnPlayEffect)
        end

        function kill_effect.player_death(e)
            if not master:get() then
                return
            end

            local pawn = entitylist.get_local_player_pawn()
            local victim = e:get_pawn("userid")
            local attacker = e:get_pawn("attacker")

            if attacker ~= pawn or victim == pawn then
                return
            end

            local effect_path = effect_map[master.effect:get()]
            if not effect_path then
                return
            end

            fnPlayEffect(effect_path, 5, ffi.cast("uintptr_t", victim[0]), 0, 0, 0, 0, 0, 0)
        end
    end

    local wallbang_helper = {}; do
        local master = in_game.wallbang_helper
        local level_name = ""
        local locations = {}

        local function get_level_name()
            local level = engine.get_level_name()
            if not level or level == "" or level == "<empty>" then return nil end
            return level:gsub(".*/", ""):gsub("%.%w+$", "")
        end

        function wallbang_helper.update()
            local current_level = get_level_name()
            if current_level ~= level_name or wallbang_needs_reload then
                wallbang_needs_reload = false
                level_name = current_level
                if level_name then
                    master.current_map:set_name(f("Current Map: %s", level_name))
                    master.current_map:visibility(true)

                    local file = folders.locations .. "/" .. level_name .. ".json"
                    if fs.is_exists(file) then
                        local content = fs.read(file)
                        local success, data = pcall(json.parse, content)
                        locations = (success and data[level_name]) and data[level_name] or {}
                    else
                        locations = {}
                    end

                    local names = {}
                    for _, loc in pairs(locations) do table.insert(names, loc.name) end
                    if #names == 0 then names = { "Empty :(" } end
                    master.location:set_items(names)
                else
                    master.current_map:visibility(false)
                    locations = {}
                end
            end
        end

        function wallbang_helper.paint()
            wallbang_helper.update()
            if not master:get() then return end

            local pawn = entitylist.get_local_player_pawn()
            if not pawn or not pawn:is_alive() then return end

            local eye_pos = pawn:get_eye_position()
            local abs_origin = pawn:get_abs_origin()

            local grouped = {}
            for _, loc in pairs(locations) do
                local pos = vec3_t(loc.pos.x, loc.pos.y, loc.pos.z)
                local found = false
                for _, group in ipairs(grouped) do
                    local first = group[1]
                    local first_pos = vec3_t(first.pos.x, first.pos.y, first.pos.z)
                    if pos:dist_to(first_pos) < 10 then
                        table.insert(group, loc)
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(grouped, { loc })
                end
            end

            for _, group in ipairs(grouped) do
                local best_loc = group[1]
                local min_dist = 999999
                for _, loc in ipairs(group) do
                    local d = abs_origin:dist_to(vec3_t(loc.pos.x, loc.pos.y, loc.pos.z))
                    if d < min_dist then
                        min_dist = d
                        best_loc = loc
                    end
                end

                local stand_pos = vec3_t(best_loc.pos.x, best_loc.pos.y, best_loc.pos.z)
                local dist_to_group = abs_origin:dist_to_2d(stand_pos)

                if not best_loc.alpha then best_loc.alpha = 0 end
                best_loc.alpha = tweening:interp(best_loc.alpha, dist_to_group > 350 and 0 or 1, .1)

                if best_loc.alpha > 0.01 then
                    local w2s_stand = render.world_to_screen(stand_pos)
                    if w2s_stand then
                        local names = {}
                        for _, loc in ipairs(group) do table.insert(names, loc.name) end
                        local text = table.concat(names, " / ")

                        local text_size = render.calc_text_size(text, museo500)
                        local icon_measure = vec2_t(14, 14)
                        local container_size = vec2_t(icon_measure.x + text_size.x + padding * 4, 20)
                        local draw_pos = w2s_stand - vec2_t(container_size.x * 0.5, container_size.y * 0.5)
                        render_container("A", text, draw_pos, container_size, gui.color, best_loc.alpha)
                    end
                end


                for _, loc in ipairs(group) do
                    local loc_stand = vec3_t(loc.pos.x, loc.pos.y, loc.pos.z)
                    local dist = eye_pos:dist_to_2d(loc_stand)

                    if dist < 25 then
                        local stored_eye = loc.eye_pos and vec3_t(loc.eye_pos.x, loc.eye_pos.y, loc.eye_pos.z) or
                            (loc_stand + vec3_t(0, 0, 64))

                        local p, y = math.rad(loc.angles.pitch), math.rad(loc.angles.yaw)
                        local sp, cp = math.sin(p), math.cos(p)
                        local sy, cy = math.sin(y), math.cos(y)
                        local forward = vec3_t(cp * cy, cp * sy, -sp)

                        local target_pos = stored_eye + forward * 2000
                        local w2s_aim = render.world_to_screen(target_pos)

                        if w2s_aim then
                            local target_angles = eye_pos:angle_to(target_pos)
                            local pitch_diff = math.abs(g_view_angles.pitch - target_angles.pitch)
                            local yaw_diff = math.abs(normalize_yaw(g_view_angles.yaw - target_angles.yaw))
                            local total_error = math.sqrt(pitch_diff ^ 2 + yaw_diff ^ 2)

                            local in_clr = color(1, 1, 1, 1)
                            if total_error < 0.5 then
                                in_clr = color(0, 1, 0, 1) -- Green
                            elseif total_error < 5.0 then
                                in_clr = color(1, 1, 0, 1) -- Yellow
                            end

                            local text = loc.name .. " (Aim)"
                            local text_size = render.calc_text_size(text, museo500)
                            local icon_measure = vec2_t(14, 14)
                            local container_size = vec2_t(icon_measure.x + text_size.x + padding * 4, 20)
                            local draw_pos = w2s_aim - vec2_t(padding + icon_measure.x * 0.5, container_size.y * 0.5)

                            local custom_icon = function(pos, alpha)
                                render.circle_fade(pos, 6, in_clr:alpha_modulate(alpha),
                                    in_clr:alpha_modulate(0))
                                render.circle_filled(pos, 2, 12, in_clr:alpha_modulate(alpha))
                            end

                            render_container("A", text, draw_pos, container_size, gui.color, best_loc.alpha, custom_icon)
                        end
                    end
                end
            end
        end
    end

    local world_effects = {}; do
        local master = in_game.world_effects
        local weather = master.weather
        local density = master.density

        local effect_map = {
            ["Ash"] = { "bin/falling_ember1.vpcf", "bin/falling_ember2.vpcf" },
            ["Rain"] = "particles/rain_fx/rain_single_800.vpcf",
            ["Snow"] = "bin/falling_snow1.vpcf",
            ["Stars"] = "bin/nomove_stars.vpcf",
        }

        local last_effect_index = nil
        local last_effect_index2 = nil
        local last_selected = ""
        local last_update = -1

        local fade_factor = 0

        function world_effects.paint()
            local me = entitylist.get_local_player_pawn()
            local game_rules = entitylist.get_game_rules()

            if (not me or not game_rules) then
                return
            end

            if engine.get_level_name():find("empty") then
                return
            end

            fade_factor = clamp(tweening:interp(fade_factor, master:get(), master:get() and .05 or .2), 0, 1)

            if fade_factor == 0 then
                last_selected = ""
                if last_effect_index then
                    particle_manager:destroy_particle(last_effect_index)
                    last_effect_index = nil
                end
                if last_effect_index2 then
                    particle_manager:destroy_particle(last_effect_index2)
                    last_effect_index2 = nil
                end
                return
            end

            local effect = effect_map[weather:get()]

            if last_selected ~= effect or last_update ~= game_rules.m_fRoundStartTime then
                if last_effect_index then
                    particle_manager:destroy_particle(last_effect_index)
                    last_effect_index = nil
                end
                if last_effect_index2 then
                    particle_manager:destroy_particle(last_effect_index2)
                    last_effect_index2 = nil
                end

                last_selected = effect
                last_update = game_rules.m_fRoundStartTime

                if type(effect) == "table" then
                    if last_effect_index == nil then
                        last_effect_index = particle_manager:create_particle_effect(effect[1])
                    end
                    if last_effect_index2 == nil then
                        last_effect_index2 = particle_manager:create_particle_effect(effect[2])
                    end
                else
                    if last_effect_index == nil then
                        last_effect_index = particle_manager:create_particle_effect(effect)
                    end
                end
            end
            local abs_origin = me:get_abs_origin()

            if last_effect_index then
                particle_manager:set_position(last_effect_index, abs_origin)
                particle_manager:set_density(last_effect_index, density:get() * fade_factor)
            end
            if last_effect_index2 then
                particle_manager:set_position(last_effect_index2, abs_origin)
                particle_manager:set_density(last_effect_index2, density:get() * fade_factor)
            end
        end

        function world_effects.unload()
            if last_effect_index then
                particle_manager:destroy_particle(last_effect_index)
                last_effect_index = nil
            end
            if last_effect_index2 then
                particle_manager:destroy_particle(last_effect_index2)
                last_effect_index2 = nil
            end
        end
    end

    local head_gear = {}; do
        local master = in_game.head_gear
        local accessory = master.accessory
        local accent = master.accent

        local alpha = 0

        local function draw_china_hat(pos, clr)
            local segments = 80
            local radius = 10
            local height_offset = 8

            local points = {}
            local step = (math.pi * 2) / segments

            local top_world_pos = vec3_t(pos.x, pos.y, pos.z + height_offset)
            local top_screen_pos = render.world_to_screen(top_world_pos)

            if not top_screen_pos then return end

            for i = 0, segments do
                local angle = i * step
                local world_point = vec3_t(
                    pos.x + math.cos(angle) * radius,
                    pos.y + math.sin(angle) * radius,
                    pos.z
                )

                local screen_point = render.world_to_screen(world_point)

                if screen_point then
                    table.insert(points, screen_point)
                end
            end

            if #points > 2 then
                local poly_points = { top_screen_pos }
                for _, p in ipairs(points) do
                    table.insert(poly_points, p)
                end

                render.polygon(poly_points, clr)
            end
        end

        function head_gear.paint()
            alpha = tweening:interp(alpha, master:get(), .05)

            if alpha <= 0 then
                return
            end

            local me = entitylist.get_local_player_pawn()

            if not me or not me:is_alive() then
                return
            end

            if not engine.camera_in_thirdperson() then
                return
            end

            local hat_choice = accessory:get()
            local head_pos = engine.get_hitbox_pos(me, 0) + vec3_t(0, 0, hat_choice == "Nimbus" and 10 or 5)
            local clr = accent:get():alpha_modulate(alpha, true)

            if hat_choice == "Nimbus" then
                render.circle_3d(head_pos, 5, clr)
            else
                draw_china_hat(head_pos, clr)
            end
        end
    end

    function visuals.paint()
        depth_of_field.paint()
        fog.paint()
        grenade_esp.paint()
        head_gear.paint()
        wallbang_helper.paint()
        crosshair.update()
        scope_overlay.paint()
        world_effects.paint()
    end

    function visuals.override_view(view)
        perspective.override_view(view)
    end

    function visuals.player_hurt(e)
        widgets.player_hurt(e)
    end

    function visuals.player_death(e)
        kill_effect.player_death(e)
    end

    function visuals.scope_overlay(player, params)
        scope_overlay.scope_overlay(player, params)
    end

    function visuals.level_init()
        depth_of_field.level_init()
        particle_manager:update()
        particle_manager.is_active = true
    end

    function visuals.unload()
        perspective.unload()
        scope_overlay.unload()
        world_effects.unload()
        depth_of_field.unload()
    end
end

local settings = {}; do
    local tab = uix.settings
    local config = tab.config
    local extra = tab.extra

    do -- config
        local PREFIX = "DEMONSIDE::"
        local path = f("%s/nix/demonside/configs", get_game_directory())

        local function new_profile_data()
            return {
                author = script.user.name,
                items = {}
            }
        end

        local function get_configs(update_list)
            local files = fs.get_files(path, "*.txt")

            if not files or #files == 0 then
                config.list:set_items({ "Empty :(" })

                return
            end

            if update_list then
                config.list:set_items(files)
            end

            return files
        end

        local function export(is_exported)
            local data = new_profile_data()
            data.items = gui:save()

            local text = json.stringify(data)
            local encoded = f("%s%s", PREFIX, base64.encode(text))

            if is_exported then
                print_raw(f("\a%s[demonside]\adefault %s", gui.color:to_hex(), "exported config to clipboard"))
            end

            return encoded
        end

        local function import(encoded, is_imported)
            local text = encoded

            if not text or not text:find(PREFIX) then
                return
            end

            text = text:gsub(PREFIX, "")

            local success, result = pcall(base64.decode, text)

            if not success then
                print_raw(f("\a%s[demonside]\adefault %s", gui.color:to_hex(), result))
                return
            end

            local success2, result2 = pcall(json.parse, result)

            if not success2 then
                print(result)
                print_raw(f("\a%s[demonside]\adefault %s", gui.color:to_hex(), result2))
                return
            end

            local data = result2

            if not data.items then
                print_raw(f("\a%s[demonside]\adefault %s", gui.color:to_hex(), "This config don't have settings"))
                return
            end

            gui:load(data.items)
            print_raw(f("\a%s[demonside]\adefault %s", gui.color:to_hex(),
                (is_imported and "imported" or "loaded") .. " config by " .. data.author))
        end

        config.delete:set_callback(function()
            config.delete:visibility(false)
            config.warning:visibility(true)
            config.confirm:visibility(true)
            config.cancel:visibility(true)
        end)
        config.confirm:set_callback(function()
            config.warning:visibility(false)
            config.confirm:visibility(false)
            config.cancel:visibility(false)
            config.delete:visibility(true)

            local selected = config.list:get()
            if selected then
                fs.delete(path .. "/" .. selected .. ".txt")
            end

            get_configs(true)
        end)
        config.cancel:set_callback(function()
            config.warning:visibility(false)
            config.confirm:visibility(false)
            config.cancel:visibility(false)
            config.delete:visibility(true)
        end)

        config.save:set_callback(function()
            local data = export()
            local name = config.name:get()

            if name:gsub(" ", "") == "" then
                name = config.list:get()
            end

            fs.write(path .. "/" .. name .. ".txt", data)

            get_configs(true)
        end)

        config.load:set_callback(function()
            local selected = config.list:get()
            if selected then
                import(fs.read(path .. "/" .. selected .. ".txt"), true)
            end
        end)

        config.export:set_callback(function()
            clipboard.set(export(true))
        end)
        config.import:set_callback(function()
            import(clipboard.get(), true)
        end)
    end

    local auto_buy = {}; do
        local master = extra.auto_buy
        local weapons_list = {
            ["None"] = "",
            ["Autosnipers"] = ".scar20;g3sg1;",
            ["Scout"] = ".ssg08;",
            ["AWP"] = ".awp;"
        }
        local pistols_list = {
            ["None"] = "",
            ["Revolver"] = ".revolver;",
            ["Deagle"] = ".deagle;",
            ["P-250"] = ".p250;"
        }
        local other_list = {
            ["Armor"] = ".vest;",
            ["Full Armor"] = ".vesthelm;",
            ["Defuser"] = ".defuser;",
            ["Taser"] = ".taser;",
            ["HE"] = ".hegrenade;",
            ["Molotov"] = ".molotov;.incgrenade;",
            ["Smoke"] = ".smokegrenade;",
            ["Flashbang"] = ".flashbang;",
            ["Decoy"] = ".decoy;"
        }

        local function purchase()
            if not master:get() then
                return
            end

            local weapon = weapons_list[master.weapon:get()]
            local pistol = pistols_list[master.pistol:get()]
            local other  = ""

            for k, v in pairs(master.equipment:get()) do
                other = other .. other_list[v]
            end

            local final = string.format("%s%s%s", weapon, pistol, other)
            if final ~= "" then
                engine.execute_client_cmd(final:gsub("%.", "buy "))
            end
        end

        master:set_callback(function()
            local me = entitylist.get_local_player_pawn()

            if not me or not me:is_alive() then
                return
            end

            purchase()
        end)

        function auto_buy.player_spawn(e)
            local userid = e:get_pawn("userid")
            local me = entitylist.get_local_player_pawn()

            if userid ~= me then
                return
            end

            purchase()
        end
    end

    local air_strafe = {}; do
        local master = extra.air_strafe
        local settings = master.settings

        function air_strafe.createmove(cmd)
            if not master then
                override("ragebot_auto_strafer", nil)
                return
            end

            local me = entitylist.get_local_player_pawn()
            local velocity = me and me:get_velocity():length_2d() or 0

            local condition = true

            if settings:get "Movement Keys" then
                if velocity <= 5 then
                    condition = false
                end
            end

            if settings:get "Only While Holding Jump" then
                if not c_input:is_key_pressed(0x20) then
                    condition = false
                end
            end

            override("ragebot_auto_strafer", condition)
        end

        function air_strafe.override_view(view)
            -- view_angles = view.angles
        end

        function air_strafe.unload()
            override("ragebot_auto_strafer", nil)
        end
    end

    local edge_jump = {}; do
        local jump = cmd_button_t "jump"

        local FL_ONGROUND = bit.lshift(1, 0)

        function edge_jump.createmove()
            jump:release()

            local me = entitylist.get_local_player_pawn()

            if not me and not me:is_alive() then
                return
            end

            local flags = me.m_fFlags

            if extra.edge_jump:is_active() and not (bit.band(flags, FL_ONGROUND) ~= 0) then
                jump:press()
            end
        end

        function edge_jump.unload()
            jump:release()
        end
    end

    local removals = {}; do
        local master = extra.removals

        function removals.team_intro(rcx, rdx, r8)
            if master:get "Team Intro" then
                -- local rules = tonumber(ffi.cast("uintptr_t", rcx))
                -- local m_bTeamIntroPeriod = ffi.cast("uint8_t*", rules + 0xF04)

                -- m_bTeamIntroPeriod[0] = 1

                local game_rules = entitylist.get_game_rules()

                if game_rules then
                    game_rules.m_bTeamIntroPeriod = true
                end
            end
        end
    end

    local filter_console = {}; do
        local master = extra.filter_console

        function filter_console.block_message()
            if master:get() then
                if logging.called_via_lua then
                    return false
                end

                return true
            end

            return false
        end
    end

    local flash_taskbar = {}; do
        local master = extra.flash_taskbar

        function flash_taskbar.round_start()
            if not master:get() then
                return
            end

            local hwnd = utils.get_cs2_hwnd()
            if hwnd ~= nil then
                ffi.C.FlashWindow(hwnd, true)
            end
        end
    end

    local switch_knife_hand = {}; do
        local master = extra.switch_knife_hand
        local cl_prefer_lefthanded = cvar.cl_prefer_lefthanded

        master:set_callback(function()
            if master:get() then
                return
            end

            local hand = cl_prefer_lefthanded:bool() and "left" or "right"
            engine.execute_client_cmd("switchhands" .. hand)
        end)

        function switch_knife_hand.createmove(cmd)
            if not master:get() then return end

            local me = entitylist.get_local_player_pawn()
            if not me or not me:is_alive() then return end

            local weapon = me:get_active_weapon()
            if not weapon then return end

            local prefer_left = cl_prefer_lefthanded:bool()
            local should_be_left = ternary(weapon:is_knife(), not prefer_left, prefer_left)

            if me.m_bLeftHanded ~= should_be_left then
                engine.execute_client_cmd(should_be_left and "switchhandsleft" or "switchhandsright")
            end
        end

        function switch_knife_hand.unload()
            local hand = cl_prefer_lefthanded:bool() and "left" or "right"
            engine.execute_client_cmd("switchhands" .. hand)
        end
    end

    local ragdolls = {}; do
        local master = extra.ragdolls
        local gravity = master.gravity
        local fraction = master.fraction

        local map = {
            [gravity] = { raw = cvar.ragdoll_gravity_scale, original_value = nil },
            [fraction] = { raw = cvar.ragdoll_friction_scale, original_value = nil },
        }

        for element, data in pairs(map) do
            data.original_value = data.raw:float()
            element:set_callback(function(self)
                local value = master:get() and self:get() / 100 or data.original_value
                data.raw:float(value)
            end)
        end

        master:set_callback(function(self)
            for element, data in pairs(map) do
                local curvalue = self:get() and element:get() / 100 or data.original_value
                data.raw:float(curvalue)
            end
        end, true)


        function ragdolls.unload()
            if master:get() then
                for element, data in pairs(map) do
                    data.raw:float(data.original_value)
                end
            end
        end
    end

    function settings.block_message()
        return filter_console.block_message()
    end

    function settings.round_start()
        flash_taskbar.round_start()
    end

    function settings.createmove(cmd)
        air_strafe.createmove(cmd)
        edge_jump.createmove()
        switch_knife_hand.createmove(cmd)
    end

    function settings.team_intro(rcx, rdx, r8)
        removals.team_intro(rcx, rdx, r8)
    end

    function settings.override_view(view)
        air_strafe.override_view(view)
    end

    function settings.unload()
        edge_jump.unload()
        air_strafe.unload()
        switch_knife_hand.unload()
        ragdolls.unload()
    end

    function settings.player_hurt(e)
        -- hitsound.player_hurt(e)
    end

    function settings.player_spawn(e)
        auto_buy.player_spawn(e)
    end
end

events.paint:set(function()
    threat = entity.get_threat()
    visuals.paint()

    gui:paint()
    gui:dependeces()
    gui:proccess_callbacks()
    gui:process_hotkeys()
end)

events.override_view:set(function(view)
    g_view_angles = view.angles
    anti_aimbot.override_view(view)
    visuals.override_view(view)
end)

events.level_init:set(function()
    visuals.level_init()
end)

events.level_shutdown:set(function()
    particle_manager.is_active = false
end)

events.scope_overlay:set(function(player, params)
    visuals.scope_overlay(player, params)
end)

events.createmove:set(function(cmd)
    aimbot.createmove(cmd)
    anti_aimbot.createmove(cmd)
    settings.createmove(cmd)

    if ui.is_menu_opened() and utils.is_cs2_foreground() then
        cmd.in_attack = 0
        cmd.in_attack2 = 0
    end

    -- cmd.in_forward = 1
end)

events.unload:set(function()
    settings.unload()
    visuals.unload()
end)

-- events.block_message:set(function()
--     return settings.block_message()
-- end)


events.team_intro:set(function(rcx, rdx, r8)
    settings.team_intro(rcx, rdx, r8)
end)

events.player_hurt:set(function(e)
    visuals.player_hurt(e)
    settings.player_hurt(e)
end)

events.player_death:set(function(e)
    visuals.player_death(e)
end)

events.player_spawn:set(function(e)
    settings.player_spawn(e)
end)

events.round_start:set(function()
    settings.round_start()
end)

-- print(f("Glad to see you, %s!", discord.username))

end)
__bundle_register("engine/particle_manager", function(require, _LOADED, __bundle_register, __bundle_modules)
local particle_mgr = {}
local vmt = require("engine/vmt")
local utils = require("core/utils")

ffi.cdef [[
    typedef struct {
        float x, y, z;
    } Vector_t;

]]

local sig = assert(
    find_pattern("client.dll", "48 8B 0D ? ? ? ? 41 B8 ? ? ? ? F3 0F 11 74 24 ? 48 C7 44 24 ? ? ? ? ?"),
    "particle_manager outdated")

local ptr = ffi.cast("uintptr_t", sig)
local this = ffi.cast("void**", ptr + 7 + ffi.cast("int*", ptr + 3)[0])[0]

local g_particle_system_mgr = utils.create_interface("particles.dll", "ParticleSystemMgr00")

local PARTICLE_SETTING_POSITION = 0
local PARTICLE_SETTING_DENSITY = 2
local PARTICLE_SETTING_COLOR = 8

particle_mgr.is_active = true

local destroy_sig = assert(
    find_pattern("client.dll", "83 FA ? 0F 84 ? ? ? ? 41 54"),
    "destroy_particle not found")
local fn_destroy = ffi.cast("void(__fastcall*)(void*, uint32_t, bool, bool)", destroy_sig)

local set_setting_sig = assert(
    find_pattern("client.dll",
        "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? F3 0F 10 1D ? ? ? ? 41 8B F8 8B DA 4C 8D 05"),
    "set_particle_setting not found")
local fn_set_setting = ffi.cast("void(__fastcall*)(void*, uint32_t, int, void*, int)", set_setting_sig)

local create_sig = assert(find_pattern("client.dll", "4C 8B DC 53 48 81 EC ? ? ? ? F2 0F 10 05"),
    "create_particle_effect not found")
local fn_create = ffi.cast("void(__fastcall*)(void*, uint32_t*, const char*, int, int, int, int, int)", create_sig)

function particle_mgr:update()
    local sig = assert(
        find_pattern("client.dll", "48 8B 0D ? ? ? ? 41 B8 ? ? ? ? F3 0F 11 74 24 ? 48 C7 44 24 ? ? ? ? ?"),
        "particle_manager outdated")

    local ptr = ffi.cast("uintptr_t", sig)
    this = ffi.cast("void**", ptr + 7 + ffi.cast("int*", ptr + 3)[0])[0]
end

function particle_mgr:create_particle_effect(szName)
    if not particle_mgr.is_active then
        return
    end

    local handle = ffi.new("uint32_t[1]", 0)
    fn_create(this, handle, szName, 8, 0, 0, 0, 0)
    return handle[0]
end

function particle_mgr:set_position(nIndex, vPos)
    if not particle_mgr.is_active then
        return
    end

    local pos = ffi.new("Vector_t", vPos.x, vPos.y, vPos.z)
    fn_set_setting(this, nIndex, PARTICLE_SETTING_POSITION, pos, 0)
end

function particle_mgr:set_density(nIndex, fDensity)
    if not particle_mgr.is_active then
        return
    end

    local density_vec = ffi.new("Vector_t", fDensity, 0, 0)
    fn_set_setting(this, nIndex, PARTICLE_SETTING_DENSITY, density_vec, 0)
end

function particle_mgr:destroy_particle(iIndex)
    if not particle_mgr.is_active then
        return
    end

    if iIndex and iIndex ~= 0 then
        fn_destroy(this, iIndex, true, true)
        vmt.call_virtual(this, 3, iIndex)
    end
end

return particle_mgr

end)
__bundle_register("core/utils", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef [[
    void* GetModuleHandleA(const char* lpModuleName);
    void* GetProcAddress(void* hModule, const char* lpProcName);
    int CreateDirectoryA(const char* lpPathName, void* lpSecurityAttributes);
]]


local timers = {}; do
    local queue = {};

    function timers:execute_after(delay, func, ...)
        local info = {};

        info.delay = delay;
        info.func = func;
        info.args = { ... };

        queue[#queue + 1] = info;
    end

    function timers:listener()
        local deltatime = render.frametime();

        for i = #queue, 1, -1 do
            local info = queue[i];
            info.delay = info.delay - deltatime;

            if info.delay <= 0 then
                info.func(unpack(info.args));
                table.remove(queue, i);
            end
        end
    end
end


local utils = {}

local cs2_hwnd = ffi.C.FindWindowA(nil, "Counter-Strike 2")

function utils.is_cs2_foreground()
    return cs2_hwnd ~= nil and ffi.C.GetForegroundWindow() == cs2_hwnd
end

function utils.get_cs2_hwnd()
    return cs2_hwnd
end

function utils.get_abs_address(relative_address, pre_offset, post_offset)
    if not relative_address then
        return
    end

    pre_offset = pre_offset or 0
    post_offset = post_offset or 0

    local addr = ffi.cast("uint8_t*", relative_address)

    addr = addr + pre_offset
    addr = addr + ffi.cast("int32_t*", addr)[0] + ffi.sizeof "int32_t"
    addr = addr + post_offset

    return addr
end

function utils.create_directory(path)
    return ffi.C.CreateDirectoryA(path, nil)
end

function utils.create_interface(dll, name)
    local module_handle = ffi.C.GetModuleHandleA(dll)
    if module_handle == nil then
        return nil
    end

    local interface = ffi.cast("void*(__cdecl*)(const char*, int*)",
        ffi.C.GetProcAddress(module_handle, "CreateInterface"))
    if interface == nil then
        return nil
    end

    return interface(name, nil)
end

function utils.execute_after(delay, fn, ...)
    -- timers.new_timeout(fn, delay)
    timers:execute_after(delay, fn, ...)
end

-- register_callback("paint", function()
--     timers.listener()
-- end)

return utils

end)
__bundle_register("engine/vmt", function(require, _LOADED, __bundle_register, __bundle_modules)
local vmt = {}

function vmt.get_v_method(class_, index)
    if class_ == nil then
        return nil
    end
    
    local vtable = ffi.cast("void***", class_)[0]
    if vtable == nil then
        return nil
    end
    
    return vtable[index]
end

function vmt.call_virtual(class_, index, ...)
    local func = vmt.get_v_method(class_, index)
    if func == nil then
        return nil
    end
    
    local args = {...}
    
    local ffi_func = ffi.cast("void*(__thiscall*)(void*, ...)", func)
    return ffi_func(class_, unpack(args))
end

return vmt
end)
__bundle_register("engine/cmd_button_t", function(require, _LOADED, __bundle_register, __bundle_modules)
local keybind_t = {}; do
    
    local function is_key_down(key)
        return bit.band(ffi.C.GetAsyncKeyState(key), 0x8000) ~= 0;
    end;

    local _private = setmetatable({}, { __mode = 'k' });

    function keybind_t:get_key()
        return _private[self].key;
    end;

    function keybind_t:set_key(key)
        _private[self].key = key;
    end;

    function keybind_t:get_mode()
        return _private[self].mode;
    end;

    function keybind_t:set_mode(mode)
        _private[self].mode = mode;
    end;

    function keybind_t:active()
        local data = _private[self];
        if data.mode == 0 then
            return true;
        elseif data.mode == 1 then
            return is_key_down(data.key);
        elseif data.mode == 2 then
            local pressed = is_key_down(data.key);
            if pressed and not data.last_pressed then
                data.toggled = not data.toggled;
            end;
            data.last_pressed = pressed;
            return data.toggled;
        end;
        return false;
    end;

    setmetatable(keybind_t, {
        __call = function(cls, key, mode)
            local self = setmetatable({}, cls);
            _private[self] = {
                key = key,
                mode = mode or 0,
                toggled = false,
                last_pressed = false
            };
            return self;
        end
    });

    keybind_t.__index = keybind_t;
end

local cmd_button_t = {}; do
    local _private = setmetatable({}, { __mode = 'k' });

    function cmd_button_t:get_button_name()
        return _private[self].button_name;
    end;

    function cmd_button_t:set_button_name(button_name)
        _private[self].button_name = button_name;
    end;

    function cmd_button_t:is_pressed()
        return _private[self].is_pressed;
    end;

    function cmd_button_t:press()
        local data = _private[self];
        if not data.is_pressed then
            data.is_pressed = true;
            engine.execute_client_cmd('+' .. data.button_name);
        end;
    end;

    function cmd_button_t:release()
        local data = _private[self];
        if data.is_pressed then
            data.is_pressed = false;
            engine.execute_client_cmd('-' .. data.button_name);
        end;
    end;

    setmetatable(cmd_button_t, {
        __call = function(cls, button_name)
            local self = setmetatable({}, cls);
            _private[self] = {
                button_name = button_name,
                is_pressed = false
            };
            return self;
        end
    });

    cmd_button_t.__index = cmd_button_t;
end

return cmd_button_t
end)
__bundle_register("system/clipboard", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef [[
    int     OpenClipboard(void* hWndNewOwner);
    int     CloseClipboard(void);
    int     EmptyClipboard(void);
    void*   GetClipboardData(unsigned int uFormat);
    void*   SetClipboardData(unsigned int uFormat, void* hMem);
    void*   GlobalAlloc(unsigned int uFlags, size_t dwBytes);
    void*   GlobalLock(void* hMem);
    int     GlobalUnlock(void* hMem);
    size_t  GlobalSize(void* hMem);
    int     IsClipboardFormatAvailable(unsigned int format);

    int MultiByteToWideChar(unsigned int CodePage, unsigned long dwFlags,
                            const char* lpMultiByteStr, int cbMultiByte,
                            void* lpWideCharStr, int cchWideChar);

    int WideCharToMultiByte(unsigned int CodePage, unsigned long dwFlags,
                            const void* lpWideCharStr, int cchWideChar,
                            char* lpMultiByteStr, int cbMultiByte,
                            const char* lpDefaultChar, int* lpUsedDefaultChar);
]]

local C              = ffi.C

local CF_UNICODETEXT = 13
local GMEM_MOVEABLE  = 0x0002
local CP_UTF8        = 65001

local function set_clipboard_text(text)
    if not text then return false, "nil text" end

    local utf8len = #text
    local wlen = C.MultiByteToWideChar(CP_UTF8, 0, text, utf8len, nil, 0)
    if wlen == 0 then
        return false, "MultiByteToWideChar failed"
    end

    local wide_buf = ffi.new("uint16_t[?]", wlen + 1)
    local conv = C.MultiByteToWideChar(CP_UTF8, 0, text, utf8len, wide_buf, wlen)
    if conv == 0 then
        return false, "MultiByteToWideChar convert failed"
    end

    wide_buf[wlen] = 0


    local bytes = (wlen + 1) * 2


    local hMem = C.GlobalAlloc(GMEM_MOVEABLE, bytes)
    if hMem == nil then
        return false, "GlobalAlloc failed"
    end

    local pMem = C.GlobalLock(hMem)
    if pMem == nil then
        return false, "GlobalLock failed"
    end


    ffi.copy(pMem, wide_buf, bytes)
    C.GlobalUnlock(hMem)


    if C.OpenClipboard(nil) == 0 then
        return false, "OpenClipboard failed"
    end

    C.EmptyClipboard()

    if C.SetClipboardData(CF_UNICODETEXT, hMem) == nil then
        C.CloseClipboard()
        return false, "SetClipboardData failed"
    end

    C.CloseClipboard()
    return true
end

local function get_clipboard_text()
    if C.IsClipboardFormatAvailable(CF_UNICODETEXT) == 0 then
        return nil, "no unicode text available"
    end

    if C.OpenClipboard(nil) == 0 then
        return nil, "OpenClipboard failed"
    end

    local hData = C.GetClipboardData(CF_UNICODETEXT)
    if hData == nil then
        C.CloseClipboard()
        return nil, "GetClipboardData failed"
    end

    local pData = C.GlobalLock(hData)
    if pData == nil then
        C.CloseClipboard()
        return nil, "GlobalLock failed"
    end


    local size_bytes = tonumber(C.GlobalSize(hData)) or 0
    local wchar_count = math.floor(size_bytes / 2)

    local wide_ptr = ffi.cast("const uint16_t*", pData)
    local real_wlen = 0
    for i = 0, wchar_count - 1 do
        if wide_ptr[i] == 0 then
            real_wlen = i
            break
        end
    end
    if real_wlen == 0 and wchar_count > 0 then real_wlen = wchar_count end


    local needed = C.WideCharToMultiByte(CP_UTF8, 0, pData, real_wlen, nil, 0, nil, nil)
    if needed == 0 then
        C.GlobalUnlock(hData)
        C.CloseClipboard()
        return nil, "WideCharToMultiByte failed"
    end

    local out_buf = ffi.new("char[?]", needed + 1)
    local got = C.WideCharToMultiByte(CP_UTF8, 0, pData, real_wlen, out_buf, needed, nil, nil)
    C.GlobalUnlock(hData)
    C.CloseClipboard()

    if got == 0 then
        return nil, "WideCharToMultiByte convert failed"
    end


    return ffi.string(out_buf, got)
end

return {
    set = set_clipboard_text,
    get = get_clipboard_text
}

end)
__bundle_register("core/base64", function(require, _LOADED, __bundle_register, __bundle_modules)
local shl, shr, band = bit.lshift, bit.rshift, bit.band
local char, byte, gsub, sub, format, concat, tostring, error, pairs = string.char, string.byte, string.gsub, string.sub, string.format, table.concat, tostring, error, pairs

local extract = function(v, from, width)
    return band(shr(v, from), shl(1, width) - 1)
end

local function makeencoder(alphabet)
    local encoder, decoder = {}, {}
    for i = 1, 65 do
        local chr = byte(sub(alphabet, i, i)) or 32
        if decoder[chr] ~= nil then
            error("invalid alphabet: duplicate character " .. tostring(chr), 3)
        end
        encoder[i - 1] = chr
        decoder[chr] = i - 1
    end
    return encoder, decoder
end

local encoders, decoders = {}, {}

encoders["base64"], decoders["base64"] = makeencoder "DEMONSIdeABCFGHJKLPQRTUVWXYZabcfghijklmnopqrstuvwxyz0123456789+/="
encoders["base64std"], decoders["base64std"] = makeencoder "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/="
encoders["base64url"], decoders["base64url"] = makeencoder "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"

local alphabet_mt = {
    __index = function(tbl, key)
        if type(key) == "string" and key:len() == 64 or key:len() == 65 then
            encoders[key], decoders[key] = makeencoder(key)
            return tbl[key]
        end
    end
}

setmetatable(encoders, alphabet_mt)
setmetatable(decoders, alphabet_mt)

local function encode(str, encoder)
    encoder = encoders[encoder or "base64"] or error("invalid alphabet specified", 2)

    str = tostring(str)

    local t, k, n = {}, 1, #str
    local lastn = n % 3
    local cache = {}

    for i = 1, n - lastn, 3 do
        local a, b, c = byte(str, i, i + 2)
        local v = a * 0x10000 + b * 0x100 + c
        local s = cache[v]

        if not s then
            s = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)], encoder[extract(v, 0, 6)])
            cache[v] = s
        end

        t[k] = s
        k = k + 1
    end

    if lastn == 2 then
        local a, b = byte(str, n - 1, n)
        local v = a * 0x10000 + b * 0x100
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[extract(v, 6, 6)], encoder[64])
    elseif lastn == 1 then
        local v = byte(str, n) * 0x10000
        t[k] = char(encoder[extract(v, 18, 6)], encoder[extract(v, 12, 6)], encoder[64], encoder[64])
    end

    return concat(t)
end

local function decode(b64, decoder)
    decoder = decoders[decoder or "base64"] or error("invalid alphabet specified", 2)

    local pattern = "[^%w%+%/%=]"
    if decoder then
        local s62, s63
        for charcode, b64code in pairs(decoder) do
            if b64code == 62 then
                s62 = charcode
            elseif b64code == 63 then
                s63 = charcode
            end
        end
        pattern = format("[^%%w%%%s%%%s%%=]", char(s62), char(s63))
    end

    b64 = gsub(tostring(b64), pattern, "")

    local cache = {}
    local t, k = {}, 1
    local n = #b64
    local padding = sub(b64, -2) == "==" and 2 or sub(b64, -1) == "=" and 1 or 0

    for i = 1, padding > 0 and n - 4 or n, 4 do
        local a, b, c, d = byte(b64, i, i + 3)

        local v0 = a * 0x1000000 + b * 0x10000 + c * 0x100 + d
        local s = cache[v0]
        if not s then
            local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
            s = char(extract(v, 16, 8), extract(v, 8, 8), extract(v, 0, 8))
            cache[v0] = s
        end

        t[k] = s
        k = k + 1
    end

    if padding == 1 then
        local a, b, c = byte(b64, n - 3, n - 1)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40
        t[k] = char(extract(v, 16, 8), extract(v, 8, 8))
    elseif padding == 2 then
        local a, b = byte(b64, n - 3, n - 2)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000
        t[k] = char(extract(v, 16, 8))
    end
    return concat(t)
end

return {
    encode = encode,
    decode = decode
}

end)
__bundle_register("core/json", function(require, _LOADED, __bundle_register, __bundle_modules)
local json = { _version = "0.1.2" }; do
    local encode
    local escape_char_map = {
        ["\\"] = "\\",
        ["\""] = "\"",
        ["\b"] = "b",
        ["\f"] = "f",
        ["\n"] = "n",
        ["\r"] = "r",
        ["\t"] = "t"
    }
    local escape_char_map_inv = { ["/"] = "/" }
    for k, v in pairs(escape_char_map) do
        escape_char_map_inv[v] = k
    end
    local function escape_char(c)
        return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
    end
    local function encode_nil(val)
        return "null"
    end
    local function encode_table(val, stack)
        local res = {}
        stack = stack or {}
        -- Circular reference?
        if stack[val] then error "circular reference" end
        stack[val] = true
        if rawget(val, 1) ~= nil or next(val) == nil then
            -- Treat as array -- check keys are valid and it is not sparse
            local n = 0
            for k in pairs(val) do
                if type(k) ~= "number" then
                    error "invalid table: mixed or invalid key types"
                end
                n = n + 1
            end
            if n ~= #val then
                error "invalid table: sparse array"
            end
            -- Encode
            for i, v in ipairs(val) do
                table.insert(res, encode(v, stack))
            end
            stack[val] = nil
            return "[" .. table.concat(res, ",") .. "]"
        else
            -- Treat as an object
            for k, v in pairs(val) do
                if type(k) ~= "string" and type(k) ~= "number" then
                    error("invalid table: invalid key type '" .. type(k) .. "'")
                end
                table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
            end
            stack[val] = nil
            return "{" .. table.concat(res, ",") .. "}"
        end
    end
    local function encode_string(val)
        return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
    end
    local function encode_number(val)
        -- Check for NaN, -inf and inf
        if val ~= val or val <= -math.huge or val >= math.huge then
            error("unexpected number value '" .. tostring(val) .. "'")
        end
        return string.format("%.14g", val)
    end
    local type_func_map = {
        ["nil"] = encode_nil,
        ["table"] = encode_table,
        ["string"] = encode_string,
        ["number"] = encode_number,
        ["boolean"] = tostring
    }
    encode = function(val, stack)
        local t = type(val)
        local f = type_func_map[t]
        if f then
            return f(val, stack)
        end
        error("unexpected type '" .. t .. "'")
    end
    function json.stringify(val)
        return (encode(val))
    end

    -------------------------------------------------------------------------------
    -- Decode
    -------------------------------------------------------------------------------
    local parse
    local function create_set(...)
        local res = {}
        for i = 1, select("#", ...) do
            res[select(i, ...)] = true
        end
        return res
    end
    local space_chars  = create_set(" ", "\t", "\r", "\n")
    local delim_chars  = create_set(" ", "\t", "\r", "\n", "]", "}", ",", ":")
    local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
    local literals     = create_set("true", "false", "null")
    local literal_map  = {
        ["true"] = true,
        ["false"] = false,
        ["null"] = nil
    }
    local function next_char(str, idx, set, negate)
        for i = idx, #str do
            if set[str:sub(i, i)] ~= negate then
                return i
            end
        end
        return #str + 1
    end
    local function decode_error(str, idx, msg)
        local line_count = 1
        local col_count = 1
        for i = 1, idx - 1 do
            col_count = col_count + 1
            if str:sub(i, i) == "\n" then
                line_count = line_count + 1
                col_count = 1
            end
        end
        error(string.format("%s at line %d col %d", msg, line_count, col_count))
    end
    local function codepoint_to_utf8(n)
        -- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
        local f = math.floor
        if n <= 0x7f then
            return string.char(n)
        elseif n <= 0x7ff then
            return string.char(f(n / 64) + 192, n % 64 + 128)
        elseif n <= 0xffff then
            return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
        elseif n <= 0x10ffff then
            return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
                f(n % 4096 / 64) + 128, n % 64 + 128)
        end
        error(string.format("invalid unicode codepoint '%x'", n))
    end
    local function parse_unicode_escape(s)
        local n1 = tonumber(s:sub(1, 4), 16)
        local n2 = tonumber(s:sub(7, 10), 16)
        -- Surrogate pair?
        if n2 then
            return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
        else
            return codepoint_to_utf8(n1)
        end
    end
    local function parse_string(str, i)
        local res = ""
        local j = i + 1
        local k = j
        while j <= #str do
            local x = str:byte(j)
            if x < 32 then
                decode_error(str, j, "control character in string")
            elseif x == 92 then -- `\`: Escape
                res = res .. str:sub(k, j - 1)
                j = j + 1
                local c = str:sub(j, j)
                if c == "u" then
                    local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1)
                        or str:match("^%x%x%x%x", j + 1)
                        or decode_error(str, j - 1, "invalid unicode escape in string")
                    res = res .. parse_unicode_escape(hex)
                    j = j + #hex
                else
                    if not escape_chars[c] then
                        decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string")
                    end
                    res = res .. escape_char_map_inv[c]
                end
                k = j + 1
            elseif x == 34 then -- `"`: End of string
                res = res .. str:sub(k, j - 1)
                return res, j + 1
            end
            j = j + 1
        end
        decode_error(str, i, "expected closing quote for string")
    end
    local function parse_number(str, i)
        local x = next_char(str, i, delim_chars)
        local s = str:sub(i, x - 1)
        local n = tonumber(s)
        if not n then
            decode_error(str, i, "invalid number '" .. s .. "'")
        end
        return n, x
    end
    local function parse_literal(str, i)
        local x = next_char(str, i, delim_chars)
        local word = str:sub(i, x - 1)
        if not literals[word] then
            decode_error(str, i, "invalid literal '" .. word .. "'")
        end
        return literal_map[word], x
    end
    local function parse_array(str, i)
        local res = {}
        local n = 1
        i = i + 1
        while 1 do
            local x
            i = next_char(str, i, space_chars, true)
            -- Empty / end of array?
            if str:sub(i, i) == "]" then
                i = i + 1
                break
            end
            -- Read token
            x, i = parse(str, i)
            res[n] = x
            n = n + 1
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "]" then break end
            if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
        end
        return res, i
    end
    local function parse_object(str, i)
        local res = {}
        i = i + 1
        while 1 do
            local key, val
            i = next_char(str, i, space_chars, true)
            -- Empty / end of object?
            if str:sub(i, i) == "}" then
                i = i + 1
                break
            end
            -- Read key
            key, i = parse(str, i)
            -- Read ':' delimiter
            i = next_char(str, i, space_chars, true)
            if str:sub(i, i) ~= ":" then
                decode_error(str, i, "expected ':' after key")
            end
            i = next_char(str, i + 1, space_chars, true)
            -- Read value
            val, i = parse(str, i)
            -- Set
            res[key] = val
            -- Next token
            i = next_char(str, i, space_chars, true)
            local chr = str:sub(i, i)
            i = i + 1
            if chr == "}" then break end
            if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
        end
        return res, i
    end
    local char_func_map = {
        ['"'] = parse_string,
        ["0"] = parse_number,
        ["1"] = parse_number,
        ["2"] = parse_number,
        ["3"] = parse_number,
        ["4"] = parse_number,
        ["5"] = parse_number,
        ["6"] = parse_number,
        ["7"] = parse_number,
        ["8"] = parse_number,
        ["9"] = parse_number,
        ["-"] = parse_number,
        ["t"] = parse_literal,
        ["f"] = parse_literal,
        ["n"] = parse_literal,
        ["["] = parse_array,
        ["{"] = parse_object
    }
    parse = function(str, idx)
        local chr = str:sub(idx, idx)
        local f = char_func_map[chr]
        if f then
            return f(str, idx)
        end
        decode_error(str, idx, "unexpected character '" .. chr .. "'")
    end
    function json.parse(str)
        if type(str) ~= "string" then
            error("expected argument of type string, got " .. type(str))
        end
        local res, idx = parse(str, next_char(str, 1, space_chars, true))
        idx = next_char(str, idx, space_chars, true)
        if idx <= #str then
            decode_error(str, idx, "trailing garbage")
        end
        return res
    end
end

return json

end)
__bundle_register("core/override", function(require, _LOADED, __bundle_register, __bundle_modules)
local cache = {}

local function override(name, value)
    local data = cache[name]

    if not data then
        cache[name] = {
            overrided = false,
            old_value = menu[name],
            value = value
        }

        data = cache[name]
    end

    if value ~= nil then
        if not cache[name].overrided then
            cache[name].old_value = menu[name]
            cache[name].overrided = true
        end

        if cache[name].value ~= value then
            menu[name] = value
            cache[name].value = value
        end
    else
        if cache[name].overrided then
            menu[name] = cache[name].old_value
            cache[name].value = cache[name].old_value
            cache[name].overrided = false
        end
    end
end

register_callback("unload", function()
    for name, data in pairs(cache) do
        override(name, nil)
    end
end)

return override

end)
__bundle_register("engine/entity", function(require, _LOADED, __bundle_register, __bundle_modules)
local entity = {}

local view_angles = angle_t(0, 0, 0)
local MATH_HUGE = math.huge
local FLT_MAX = 3.402823466e+38;
local FLT_MIN = -3.402823466e+38;

local m_vecVelocity = engine.get_netvar_offset("client.dll", "C_BaseEntity", "m_vecVelocity")
local m_vecViewOffset = engine.get_netvar_offset("client.dll", "C_BaseModelEntity", "m_vecViewOffset")
local m_flStamina = engine.get_netvar_offset("client.dll", "CCSPlayer_MovementServices", "m_flStamina")

local m_pGameSceneNode = engine.get_netvar_offset("client.dll", "C_BaseEntity", "m_pGameSceneNode");
local m_nodeToWorld = engine.get_netvar_offset("client.dll", "CGameSceneNode", "m_nodeToWorld");

local m_pCollision = engine.get_netvar_offset("client.dll", "C_BaseEntity", "m_pCollision");
local m_vecMins = engine.get_netvar_offset("client.dll", "CCollisionProperty", "m_vecMins");
local m_vecMaxs = engine.get_netvar_offset("client.dll", "CCollisionProperty", "m_vecMaxs");

local MAX_DUCK_SPEED = 8
local set_model; do
    -- // STR: "models/inventory_items/dogtags.vmdl"
    local sig = assert(find_pattern("client.dll", "40 53 48 83 ? ? 48 8B ? 4C 8B ? 48 8B ? ? ? ? ? 48 8D ? ? ? 48 8B"),
        "fnSetModel outdated")
    set_model = ffi.cast("void* (__fastcall*)(void*, const char*)", sig)
end

local math_min, math_max, math_floor, math_ceil = math.min, math.max, math.floor, math.ceil;

function base_entity_t:get_bbox()
    if not self then return nil; end;

    local ent_ptr = ffi.cast("uintptr_t*", self)[0];
    if ent_ptr == 0 then return nil; end;

    local collision = ffi.cast("uintptr_t*", ent_ptr + m_pCollision)[0];
    local scene_node = ffi.cast("uintptr_t*", ent_ptr + m_pGameSceneNode)[0];
    if collision == 0 or scene_node == 0 then return nil; end;

    local mins_ptr = ffi.cast("float*", collision + m_vecMins);
    local maxs_ptr = ffi.cast("float*", collision + m_vecMaxs);
    local transform_addr = scene_node + m_nodeToWorld;

    local pos = ffi.cast("float*", transform_addr);
    local rot = ffi.cast("float*", transform_addr + 16);

    local qx, qy, qz, qw = rot[0], rot[1], rot[2], rot[3];
    local px, py, pz = pos[0], pos[1], pos[2];

    local m1, m2, m3 = 1.0 - 2.0 * (qy * qy + qz * qz), 2.0 * (qx * qy - qw * qz), 2.0 * (qx * qz + qw * qy);
    local m5, m6, m7 = 2.0 * (qx * qy + qw * qz), 1.0 - 2.0 * (qx * qx + qz * qz), 2.0 * (qy * qz - qw * qx);
    local m9, m10, m11 = 2.0 * (qx * qz - qw * qy), 2.0 * (qy * qz + qw * qx), 1.0 - 2.0 * (qx * qx + qy * qy);

    local min_x, min_y, max_x, max_y = FLT_MAX, FLT_MAX, FLT_MIN, FLT_MIN;

    local b_mins_x, b_mins_y, b_mins_z = mins_ptr[0], mins_ptr[1], mins_ptr[2];
    local b_maxs_x, b_maxs_y, b_maxs_z = maxs_ptr[0], maxs_ptr[1], maxs_ptr[2];

    for i = 0, 7 do
        local lx = (bit.band(i, 1) ~= 0) and b_maxs_x or b_mins_x;
        local ly = (bit.band(i, 2) ~= 0) and b_maxs_y or b_mins_y;
        local lz = (bit.band(i, 4) ~= 0) and b_maxs_z or b_mins_z;

        local wx = lx * m1 + ly * m2 + lz * m3 + px;
        local wy = lx * m5 + ly * m6 + lz * m7 + py;
        local wz = lx * m9 + ly * m10 + lz * m11 + pz;

        local screen = render.world_to_screen(vec3_t(wx, wy, wz));
        if not screen then return nil; end;

        if screen.x < min_x then min_x = screen.x; end;
        if screen.y < min_y then min_y = screen.y; end;
        if screen.x > max_x then max_x = screen.x; end;
        if screen.y > max_y then max_y = screen.y; end;
    end;

    local width, height = max_x - min_x, max_y - min_y;

    if width < 4.0 then
        local half = (4.0 - width) * 0.5;
        min_x = min_x - math_floor(half);
        max_x = max_x + math_ceil(half);
        width = max_x - min_x;
    end;

    if height < 4.0 then
        local half = (4.0 - height) * 0.5;
        min_y = min_y - math_floor(half);
        max_y = max_y + math_ceil(half);
        height = max_y - min_y;
    end;

    return { x = min_x, y = min_y, w = width, h = height };
end

function base_entity_t:is_alive()
    return self.m_iHealth > 0 and self.m_nLifeState ~= 0
end

function base_entity_t:get_stamina()
    local movement_services = self.m_pMovementServices

    if not movement_services then
        return 0
    end

    local m_flDuckSpeed = movement_services.m_flDuckSpeed or 8

    return m_flDuckSpeed / MAX_DUCK_SPEED
end

function base_entity_t:is_enemy()
    local me = entitylist.get_local_player_pawn()
    return self.m_iTeamNum ~= me.m_iTeamNum and not cvars.mp_teammates_are_enemies:get_bool()
end

function base_entity_t:is_knife()
    return self:get_class_name():lower():find("knife") ~= nil
end

function base_entity_t:get_active_weapon()
    local weapon_services = self.m_pWeaponServices

    if not weapon_services then
        return
    end

    return weapon_services.m_hActiveWeapon
end

function base_entity_t:get_all_weapons()
    local weapons = {}

    local weapon_services = ffi.cast("uintptr_t", self.m_pWeaponServices)
    if weapon_services == 0 then
        return weapons
    end

    local weapons_count_ptr = ffi.cast("int*", self.m_pWeaponServices.m_hMyWeapons)
    local weapons_count = weapons_count_ptr[0]

    if weapons_count <= 0 or weapons_count > 64 then
        return weapons
    end

    local weapons_data_ptr = ffi.cast("uintptr_t*", ffi.cast("uintptr_t", self.m_pWeaponServices.m_hMyWeapons) + 0x8)
    local weapons_data = weapons_data_ptr[0]

    if weapons_data == 0 then
        return weapons
    end

    for i = 0, 8 do
        local weapon_handle_offset = weapons_data + (i * 0x4)

        local weapon_handle_ptr = ffi.cast("uint32_t*", weapon_handle_offset)
        local weapon_handle = weapon_handle_ptr[0]

        if weapon_handle == 0 or weapon_handle == 0xFFFFFFFF then
            goto continue
        end

        table.insert(weapons, entitylist.get_entity_from_handle(weapon_handle))

        ::continue::
    end

    return weapons
end

function base_entity_t:get_name()
    local name = self.m_sSanitizedPlayerName
    local controller = self.m_hController

    if controller then
        name = controller.m_sSanitizedPlayerName
    end

    return name
end

function base_entity_t:get_eye_position(ignore_duck)
    local data = ffi.cast("float*", self[m_vecViewOffset])
    local vector = vec3_t(data[0], data[1], data[2])

    if ignore_duck then
        local movement_services = self.m_pMovementServices

        if movement_services then
            vector.z = vector.z - movement_services.m_flDuckViewOffset
        end
    end

    return self:get_abs_origin() + vector
end

function base_entity_t:can_fire()
    local controller = self.m_hController or self
    if not controller then return end

    local tickbase = controller.m_nTickBase
    if not tickbase then return end

    local weapon = self:get_active_weapon()
    if not weapon then return end

    return tickbase > weapon.m_nNextPrimaryAttackTick
end

function base_entity_t:get_velocity()
    local vec_velocity = ffi.cast("float*", self[m_vecVelocity])

    return vec3_t(vec_velocity[0], vec_velocity[1], vec_velocity[2])
end

function base_entity_t:set_model(path)
    set_model(self[0], path)
end

function entity.get_players(enemy_only, include_dead, callback)
    local entities = {}

    entitylist.get_entities("C_CSPlayerPawn", function(entity)
        if (not enemy_only and true or entity:is_enemy()) and (include_dead and true or entity:is_alive()) then
            entities[#entities + 1] = entity

            if callback then
                callback(entity)
            end
        end
    end)


    return entities
end

function entity.get_threat()
    local me = entitylist.get_local_player_pawn()
    if not me then return nil end

    local my_pos = me:get_abs_origin()
    local my_yaw = view_angles.yaw

    local best_entity = nil
    local best_angle_diff = MATH_HUGE

    entitylist.get_entities("C_CSPlayerPawn", function(entity)
        if entity:is_alive() and entity:is_enemy() then
            local enemy_pos = entity:get_abs_origin()

            local dx = enemy_pos.x - my_pos.x
            local dy = enemy_pos.y - my_pos.y
            local angle_to_enemy = math.deg(math.atan2(dy, dx))

            local angle_diff = math.abs(normalize_yaw(angle_to_enemy - my_yaw))
            if angle_diff < best_angle_diff then
                best_angle_diff = angle_diff
                best_entity = entity
            end
        end
    end)

    return best_entity
end

function entity.get_threats_in_fov(max_fov)
    local me = entitylist.get_local_player_pawn()
    if not me then
        return {}
    end

    local origin = me:get_abs_origin()

    origin.z = 0
    view_angles.pitch = 0

    local threats = {}
    local enemies = entity.get_players(true)

    for i = 1, #enemies do
        local enemy = enemies[i]
        local enemy_origin = enemy:get_abs_origin()
        enemy_origin.z = 0

        local angles = origin:angle_to(enemy_origin)
        angles.pitch = 0

        local angle_diff = math.abs(normalize_yaw(angles.yaw - view_angles.yaw))

        if angle_diff <= max_fov then
            table.insert(threats, {
                entity = enemy,
                angle_diff = angle_diff,
                distance = origin:dist_to(enemy_origin)
            })
        end
    end

    table.sort(threats, function(a, b)
        return a.angle_diff < b.angle_diff
    end)

    return threats
end

register_callback("override_view", function(view)
    view_angles = view.angles
end)

return entity

end)
__bundle_register("engine/input", function(require, _LOADED, __bundle_register, __bundle_modules)
local utils = require("core/utils")
local input = {}; do
    local keys = {};

    local key_codes = {
        VK_LBUTTON = 0x01, VK_RBUTTON = 0x02, VK_CANCEL = 0x03, VK_MBUTTON = 0x04, VK_XBUTTON1 = 0x05, VK_XBUTTON2 = 0x06, VK_BACK = 0x08, VK_TAB = 0x09, VK_CLEAR = 0x0C, VK_RETURN = 0x0D, VK_SHIFT = 0x10, VK_CONTROL = 0x11, VK_MENU = 0x12, VK_PAUSE = 0x13, VK_CAPITAL = 0x14, VK_KANA = 0x15, VK_JUNJA = 0x17, VK_FINAL = 0x18, VK_KANJI = 0x19, VK_ESCAPE = 0x1B, VK_CONVERT = 0x1C, VK_NONCONVERT = 0x1D, VK_ACCEPT = 0x1E, VK_MODECHANGE = 0x1F, VK_SPACE = 0x20, VK_PRIOR = 0x21, VK_NEXT = 0x22, VK_END = 0x23, VK_HOME = 0x24, VK_LEFT = 0x25, VK_UP = 0x26, VK_RIGHT = 0x27, VK_DOWN = 0x28, VK_SELECT = 0x29, VK_PRINT = 0x2A, VK_EXECUTE = 0x2B, VK_SNAPSHOT = 0x2C, VK_INSERT = 0x2D, VK_DELETE = 0x2E, VK_HELP = 0x2F, VK_0 = 0x30, VK_1 = 0x31, VK_2 = 0x32, VK_3 = 0x33, VK_4 = 0x34, VK_5 = 0x35, VK_6 = 0x36, VK_7 = 0x37, VK_8 = 0x38, VK_9 = 0x39, VK_A = 0x41, VK_B = 0x42, VK_C = 0x43, VK_D = 0x44, VK_E = 0x45, VK_F = 0x46, VK_G = 0x47, VK_H = 0x48, VK_I = 0x49, VK_J = 0x4A, VK_K = 0x4B, VK_L = 0x4C, VK_M = 0x4D, VK_N = 0x4E, VK_O = 0x4F, VK_P = 0x50, VK_Q = 0x51, VK_R = 0x52, VK_S = 0x53, VK_T = 0x54, VK_U = 0x55, VK_V = 0x56, VK_W = 0x57, VK_X = 0x58, VK_Y = 0x59, VK_Z = 0x5A, VK_LWIN = 0x5B, VK_RWIN = 0x5C, VK_APPS = 0x5D, VK_SLEEP = 0x5F, VK_NUMPAD0 = 0x60, VK_NUMPAD1 = 0x61, VK_NUMPAD2 = 0x62, VK_NUMPAD3 = 0x63, VK_NUMPAD4 = 0x64, VK_NUMPAD5 = 0x65, VK_NUMPAD6 = 0x66, VK_NUMPAD7 = 0x67, VK_NUMPAD8 = 0x68, VK_NUMPAD9 = 0x69, VK_MULTIPLY = 0x6A, VK_ADD = 0x6B, VK_SEPARATOR = 0x6C, VK_SUBTRACT = 0x6D, VK_DECIMAL = 0x6E, VK_DIVIDE = 0x6F, VK_F1 = 0x70, VK_F2 = 0x71, VK_F3 = 0x72, VK_F4 = 0x73, VK_F5 = 0x74, VK_F6 = 0x75, VK_F7 = 0x76, VK_F8 = 0x77, VK_F9 = 0x78, VK_F10 = 0x79, VK_F11 = 0x7A, VK_F12 = 0x7B, VK_F13 = 0x7C, VK_F14 = 0x7D, VK_F15 = 0x7E, VK_F16 = 0x7F, VK_F17 = 0x80, VK_F18 = 0x81, VK_F19 = 0x82, VK_F20 = 0x83, VK_F21 = 0x84, VK_F22 = 0x85, VK_F23 = 0x86, VK_F24 = 0x87, VK_NUMLOCK = 0x90, VK_SCROLL = 0x91, VK_OEM_FJ_JISHO = 0x92, VK_OEM_FJ_MASSHOU = 0x93, VK_OEM_FJ_TOUROKU = 0x94, VK_OEM_FJ_LOYA = 0x95, VK_OEM_FJ_ROYA = 0x96, VK_LSHIFT = 0xA0, VK_RSHIFT = 0xA1, VK_LCONTROL = 0xA2, VK_RCONTROL = 0xA3, VK_LMENU = 0xA4, VK_RMENU = 0xA5, VK_BROWSER_BACK = 0xA6, VK_BROWSER_FORWARD = 0xA7, VK_BROWSER_REFRESH = 0xA8, VK_BROWSER_STOP = 0xA9, VK_BROWSER_SEARCH = 0xAA, VK_BROWSER_FAVORITES = 0xAB, VK_BROWSER_HOME = 0xAC, VK_VOLUME_MUTE = 0xAD, VK_VOLUME_DOWN = 0xAE, VK_VOLUME_UP = 0xAF, VK_MEDIA_NEXT_TRACK = 0xB0, VK_MEDIA_PREV_TRACK = 0xB1, VK_MEDIA_STOP = 0xB2, VK_MEDIA_PLAY_PAUSE = 0xB3, VK_LAUNCH_MAIL = 0xB4, VK_LAUNCH_MEDIA_SELECT = 0xB5, VK_LAUNCH_APP1 = 0xB6, VK_LAUNCH_APP2 = 0xB7, VK_OEM_1 = 0xBA, VK_OEM_PLUS = 0xBB, VK_OEM_COMMA = 0xBC, VK_OEM_MINUS = 0xBD, VK_OEM_PERIOD = 0xBE, VK_OEM_2 = 0xBF, VK_OEM_3 = 0xC0, VK_ABNT_C1 = 0xC1, VK_ABNT_C2 = 0xC2, VK_OEM_4 = 0xDB, VK_OEM_5 = 0xDC, VK_OEM_6 = 0xDD, VK_OEM_7 = 0xDE, VK_OEM_8 = 0xDF, VK_OEM_AX = 0xE1, VK_OEM_102 = 0xE2, VK_ICO_HELP = 0xE3, VK_PROCESSKEY = 0xE5, VK_ICO_CLEAR = 0xE6, VK_PACKET = 0xE7, VK_OEM_RESET = 0xE9, VK_OEM_JUMP = 0xEA, VK_OEM_PA1 = 0xEB, VK_OEM_PA2 = 0xEC, VK_OEM_PA3 = 0xED, VK_OEM_WSCTRL = 0xEE, VK_OEM_CUSEL = 0xEF, VK_OEM_ATTN = 0xF0, VK_OEM_FINISH = 0xF1, VK_OEM_COPY = 0xF2, VK_OEM_AUTO = 0xF3, VK_OEM_ENLW = 0xF4, VK_OEM_BACKTAB = 0xF5, VK_ATTN = 0xF6, VK_CRSEL = 0xF7, VK_EXSEL = 0xF8, VK_EREOF = 0xF9, VK_PLAY = 0xFA, VK_ZOOM = 0xFB, VK_PA1 = 0xFD, VK_OEM_CLEAR = 0xFE,
    }

    local key_names = {
        [key_codes.VK_LBUTTON] = "LMB",
        [key_codes.VK_RBUTTON] = "RMB",
        [key_codes.VK_CANCEL] = "Break",
        [key_codes.VK_MBUTTON] = "M3",
        [key_codes.VK_XBUTTON1] = "M4",
        [key_codes.VK_XBUTTON2] = "M5",
        [key_codes.VK_BACK] = "Backspace",
        [key_codes.VK_TAB] = "Tab",
        [key_codes.VK_CLEAR] = "Clear",
        [key_codes.VK_RETURN] = "Enter",
        [key_codes.VK_SHIFT] = "Shift",
        [key_codes.VK_CONTROL] = "Ctrl",
        [key_codes.VK_MENU] = "Alt",
        [key_codes.VK_PAUSE] = "Pause",
        [key_codes.VK_CAPITAL] = "Caps Lock",
        [key_codes.VK_KANA] = "Kana",
        [key_codes.VK_JUNJA] = "Junja",
        [key_codes.VK_FINAL] = "Final",
        [key_codes.VK_KANJI] = "Kanji",
        [key_codes.VK_ESCAPE] = "Esc",
        [key_codes.VK_CONVERT] = "Convert",
        [key_codes.VK_NONCONVERT] = "Non Convert",
        [key_codes.VK_ACCEPT] = "Accept",
        [key_codes.VK_MODECHANGE] =
        "Mode Change",
        [key_codes.VK_SPACE] = "Space",
        [key_codes.VK_PRIOR] = "Page Up",
        [key_codes.VK_NEXT] = "Page Down",
        [key_codes.VK_END] = "End",
        [key_codes.VK_HOME] = "Home",
        [key_codes.VK_LEFT] = "Arrow Left",
        [key_codes.VK_UP] =
        "Arrow Up",
        [key_codes.VK_RIGHT] = "Arrow Right",
        [key_codes.VK_DOWN] = "Arrow Down",
        [key_codes.VK_SELECT] =
        "Select",
        [key_codes.VK_PRINT] = "Print",
        [key_codes.VK_EXECUTE] = "Execute",
        [key_codes.VK_SNAPSHOT] =
        "Print Screen",
        [key_codes.VK_INSERT] = "Insert",
        [key_codes.VK_DELETE] = "Delete",
        [key_codes.VK_HELP] = "Help",
        [key_codes.VK_0] = "0",
        [key_codes.VK_1] = "1",
        [key_codes.VK_2] = "2",
        [key_codes.VK_3] = "3",
        [key_codes.VK_4] =
        "4",
        [key_codes.VK_5] = "5",
        [key_codes.VK_6] = "6",
        [key_codes.VK_7] = "7",
        [key_codes.VK_8] = "8",
        [key_codes.VK_9] =
        "9",
        [key_codes.VK_A] = "A",
        [key_codes.VK_B] = "B",
        [key_codes.VK_C] = "C",
        [key_codes.VK_D] = "D",
        [key_codes.VK_E] =
        "E",
        [key_codes.VK_F] = "F",
        [key_codes.VK_G] = "G",
        [key_codes.VK_H] = "H",
        [key_codes.VK_I] = "I",
        [key_codes.VK_J] =
        "J",
        [key_codes.VK_K] = "K",
        [key_codes.VK_L] = "L",
        [key_codes.VK_M] = "M",
        [key_codes.VK_N] = "N",
        [key_codes.VK_O] =
        "O",
        [key_codes.VK_P] = "P",
        [key_codes.VK_Q] = "Q",
        [key_codes.VK_R] = "R",
        [key_codes.VK_S] = "S",
        [key_codes.VK_T] =
        "T",
        [key_codes.VK_U] = "U",
        [key_codes.VK_V] = "V",
        [key_codes.VK_W] = "W",
        [key_codes.VK_X] = "X",
        [key_codes.VK_Y] =
        "Y",
        [key_codes.VK_Z] = "Z",
        [key_codes.VK_LWIN] = "Left Win",
        [key_codes.VK_RWIN] = "Right Win",
        [key_codes.VK_APPS] =
        "Context Menu",
        [key_codes.VK_SLEEP] = "Sleep",
        [key_codes.VK_NUMPAD0] = "Numpad 0",
        [key_codes.VK_NUMPAD1] =
        "Numpad 1",
        [key_codes.VK_NUMPAD2] = "Numpad 2",
        [key_codes.VK_NUMPAD3] = "Numpad 3",
        [key_codes.VK_NUMPAD4] =
        "Numpad 4",
        [key_codes.VK_NUMPAD5] = "Numpad 5",
        [key_codes.VK_NUMPAD6] = "Numpad 6",
        [key_codes.VK_NUMPAD7] =
        "Numpad 7",
        [key_codes.VK_NUMPAD8] = "Numpad 8",
        [key_codes.VK_NUMPAD9] = "Numpad 9",
        [key_codes.VK_MULTIPLY] =
        "Numpad *",
        [key_codes.VK_ADD] = "Numpad +",
        [key_codes.VK_SEPARATOR] = "Separator",
        [key_codes.VK_SUBTRACT] =
        "Num -",
        [key_codes.VK_DECIMAL] = "Numpad .",
        [key_codes.VK_DIVIDE] = "Numpad /",
        [key_codes.VK_F1] = "F1",
        [key_codes.VK_F2] = "F2",
        [key_codes.VK_F3] = "F3",
        [key_codes.VK_F4] = "F4",
        [key_codes.VK_F5] = "F5",
        [key_codes.VK_F6] = "F6",
        [key_codes.VK_F7] = "F7",
        [key_codes.VK_F8] = "F8",
        [key_codes.VK_F9] = "F9",
        [key_codes.VK_F10] = "F10",
        [key_codes.VK_F11] = "F11",
        [key_codes.VK_F12] = "F12",
        [key_codes.VK_F13] = "F13",
        [key_codes.VK_F14] = "F14",
        [key_codes.VK_F15] = "F15",
        [key_codes.VK_F16] = "F16",
        [key_codes.VK_F17] = "F17",
        [key_codes.VK_F18] = "F18",
        [key_codes.VK_F19] = "F19",
        [key_codes.VK_F20] = "F20",
        [key_codes.VK_F21] = "F21",
        [key_codes.VK_F22] = "F22",
        [key_codes.VK_F23] = "F23",
        [key_codes.VK_F24] = "F24",
        [key_codes.VK_NUMLOCK] =
        "Num Lock",
        [key_codes.VK_SCROLL] = "Scrol Lock",
        [key_codes.VK_OEM_FJ_JISHO] = "Jisho",
        [key_codes.VK_OEM_FJ_MASSHOU] = "Mashu",
        [key_codes.VK_OEM_FJ_TOUROKU] = "Touroku",
        [key_codes.VK_OEM_FJ_LOYA] =
        "Loya",
        [key_codes.VK_OEM_FJ_ROYA] = "Roya",
        [key_codes.VK_LSHIFT] = "Left Shift",
        [key_codes.VK_RSHIFT] =
        "Right Shift",
        [key_codes.VK_LCONTROL] = "Left Ctrl",
        [key_codes.VK_RCONTROL] = "Right Ctrl",
        [key_codes.VK_LMENU] =
        "Left Alt",
        [key_codes.VK_RMENU] = "Right Alt",
        [key_codes.VK_BROWSER_BACK] = "Browser Back",
        [key_codes.VK_BROWSER_FORWARD] = "Browser Forward",
        [key_codes.VK_BROWSER_REFRESH] = "Browser Refresh",
        [key_codes.VK_BROWSER_STOP] = "Browser Stop",
        [key_codes.VK_BROWSER_SEARCH] = "Browser Search",
        [key_codes.VK_BROWSER_FAVORITES] = "Browser Favorites",
        [key_codes.VK_BROWSER_HOME] = "Browser Home",
        [key_codes.VK_VOLUME_MUTE] = "Volume Mute",
        [key_codes.VK_VOLUME_DOWN] = "Volume Down",
        [key_codes.VK_VOLUME_UP] =
        "Volume Up",
        [key_codes.VK_MEDIA_NEXT_TRACK] = "Next Track",
        [key_codes.VK_MEDIA_PREV_TRACK] = "Previous Track",
        [key_codes.VK_MEDIA_STOP] = "Stop",
        [key_codes.VK_MEDIA_PLAY_PAUSE] = "Play / Pause",
        [key_codes.VK_LAUNCH_MAIL] =
        "Mail",
        [key_codes.VK_LAUNCH_MEDIA_SELECT] = "Media",
        [key_codes.VK_LAUNCH_APP1] = "App1",
        [key_codes.VK_LAUNCH_APP2] =
        "App2",
        [key_codes.VK_OEM_1] = ";",
        [key_codes.VK_OEM_PLUS] = "=",
        [key_codes.VK_OEM_COMMA] = ",",
        [key_codes.VK_OEM_MINUS] = "-",
        [key_codes.VK_OEM_PERIOD] = ".",
        [key_codes.VK_OEM_2] = "/",
        [key_codes.VK_OEM_3] =
        "`",
        [key_codes.VK_ABNT_C1] = "Abnt C1",
        [key_codes.VK_ABNT_C2] = "Abnt C2",
        [key_codes.VK_OEM_4] = "[",
        [key_codes.VK_OEM_5] = "\\",
        [key_codes.VK_OEM_6] = "]",
        [key_codes.VK_OEM_7] = "\"",
        [key_codes.VK_OEM_8] = "!",
        [key_codes.VK_OEM_AX] = "Ax",
        [key_codes.VK_OEM_102] = "> <",
        [key_codes.VK_ICO_HELP] = "IcoHlp",
        [key_codes.VK_PROCESSKEY] = "Process",
        [key_codes.VK_ICO_CLEAR] = "IcoClr",
        [key_codes.VK_PACKET] = "Packet",
        [key_codes.VK_OEM_RESET] = "Reset",
        [key_codes.VK_OEM_JUMP] = "Jump",
        [key_codes.VK_OEM_PA1] = "OemPa1",
        [key_codes.VK_OEM_PA2] = "OemPa2",
        [key_codes.VK_OEM_PA3] = "OemPa3",
        [key_codes.VK_OEM_WSCTRL] = "WsCtrl",
        [key_codes.VK_OEM_CUSEL] = "Cu Sel",
        [key_codes.VK_OEM_ATTN] = "Oem Attn",
        [key_codes.VK_OEM_FINISH] = "Finish",
        [key_codes.VK_OEM_COPY] = "Copy",
        [key_codes.VK_OEM_AUTO] = "Auto",
        [key_codes.VK_OEM_ENLW] = "Enlw",
        [key_codes.VK_OEM_BACKTAB] = "Back Tab",
        [key_codes.VK_ATTN] = "Attn",
        [key_codes.VK_CRSEL] = "Cr Sel",
        [key_codes.VK_EXSEL] = "Ex Sel",
        [key_codes.VK_EREOF] = "Er Eof",
        [key_codes.VK_PLAY] = "Play",
        [key_codes.VK_ZOOM] = "Zoom",
        [key_codes.VK_PA1] = "Pa1",
        [key_codes.VK_OEM_CLEAR] = "OemClr"
    }

    function input:get_code(name)
        return key_codes[name] or -1
    end

    function input:get_name(code)
        return key_names[code] or "?"
    end

    function input:is_key_clicked(code)
        local state = self:is_key_pressed(code);

        if not utils.is_cs2_foreground() then
            return false
        end

        if keys[code] == nil then
            keys[code] = false;
        end

        if not state then
            keys[code] = false;
            return false;
        end

        if not keys[code] then
            keys[code] = true;
            return true;
        end

        return false;
    end

    function input:is_key_pressed(code)
        return bit.band(ffi.C.GetKeyState(code), 0x8000) ~= 0 and utils.is_cs2_foreground();
    end

    local user32 = ffi.load("user32");

    local cs2_window = user32.FindWindowA(nil, "Counter-Strike 2")

    function input:mouse_position()
        local point = ffi.new("p[1]");

        user32.GetCursorPos(point);

        if cs2_window ~= nil then
            user32.ScreenToClient(cs2_window, point);
        end

        return vec2_t(point[0].x, point[0].y);
    end
end

return input

end)
__bundle_register("render/gui", function(require, _LOADED, __bundle_register, __bundle_modules)
local c_input = require("engine/input")
local tweening = require("render/tweening")
local clipboard = require("system/clipboard")
local utils = require("core/utils")

local gui = {}; do
    local tabs = {};
    local hotkeys = {};
    local gear = {};

    local dependeces = {};
    local callbacks = {};

    local selected = {}; do
        selected.predicted_tab = nil;
        selected.tab = nil;
    end

    local function HSVToRGB(c)
        local hue, sat, val, a = c[1], c[2], c[3], 1
        if sat == 0 then
            return color_t(val, val, val, a)
        end
        local i = math.floor(hue * 6);
        local o = hue * 6 - i;
        local p, q, t = val * (1 - sat), val * (1 - sat * o), val * (1 - sat * (1 - o));
        c = {}
        local l = math.floor(i % 6)
        if l == 0 then
            c = { val, t, p }
        elseif l == 1 then
            c = { q, val, p }
        elseif l == 2 then
            c = { p, val, t }
        elseif l == 3 then
            c = { p, q, val }
        elseif l == 4 then
            c = { t, p, val }
        elseif l == 5 then
            c = { val, p, q }
        end
        return color_t(c[1], c[2], c[3], a)
    end

    local function RBGtoHSV(c)
        local r, g, b, a = c.r * 255, c.g * 255, c.b * 255, c.a * 255
        local min = math.min(r, g, b)
        local max = math.max(r, g, b)
        local d = max - min
        local val, hue, sat = max / 255, 0, max ~= 0 and d / max or 0
        if max == min then
            hue = 0
        elseif max == r then
            hue = (g - b) + d * (g < b and 6 or 0)
        elseif max == g then
            hue = (b - r) + d * 2
        else
            hue = (r - g) + d * 4
        end
        if max ~= min then hue = hue / (6 * d) end
        return { hue, sat, val, a }
    end

    local function clamp(x, min, max)
        if x < min then
            return min
        end

        if x > max then
            return max
        end

        return x
    end

    local function hex2rgba(hex)
        hex = hex:gsub("#", "")

        local r = tonumber(hex:sub(1, 2), 16) / 255 or 0
        local g = tonumber(hex:sub(3, 4), 16) / 255 or 0
        local b = tonumber(hex:sub(5, 6), 16) / 255 or 0
        local a = tonumber(hex:sub(7, 8), 16) / 255 or 0

        return r, g, b, a
    end

    local function table_equal(t1, t2)
        for k, v1 in pairs(t1) do
            local v2 = t2[k]
            if type(v1) == "table" and type(v2) == "table" then
                if not table_equal(v1, v2) then return false end
            elseif v1 ~= v2 then
                return false
            end
        end

        return true
    end

    local cases = {
        selectable = function(v)
            if v.multi then
                if v[3] == true then
                    return not v[1]:get(v[2])
                else
                    for i = 2, #v do
                        if v[1]:get(v[i]) then return true end
                    end
                end
            else
                if v[3] == true then
                    return v[1]:get() ~= v[2]
                else
                    for i = 2, #v do
                        if v[1]:get() == v[i] then return true end
                    end
                end
            end

            return false
        end,
        slider = function(v)
            return v[2] <= v[1]:get() and v[1]:get() <= (v[3] or v[2])
        end
    }

    local function depend(self, ...)
        local rules = { ... }

        dependeces[#dependeces + 1] = function()
            local eligible = true

            for i = 1, #rules do
                local rule = rules[i]
                local elem = rule[1]
                local condition = false

                if type(rule[2]) == "function" then
                    condition = rule[2](elem)
                else
                    local f = cases[elem.__typeof]
                    if f then
                        condition = f(rule)
                    else
                        condition = elem:get() == rule[2]
                    end
                end

                if not condition then
                    eligible = false
                    break
                end
            end

            self:visibility(eligible)
        end
    end

    local switch = {}; do
        function switch:new(name, default, cb)
            default = default or false;

            local data = {}; do
                data.name = name;
                data.value = default;
                data.pct = 0;
                data.visible = true;
                data.__gear = nil;
            end

            if cb then
                if not data.__gear then
                    data.__gear = gear:new();
                    data.__gear.__parent = self;
                end

                setmetatable(data, self)

                local items = cb(data.__gear, data)

                for key, value in pairs(items) do
                    data[key] = value
                end

                return data
            end

            setmetatable(data, self)
            return data
        end

        function switch:set_callback(fn, force)
            local old_value = self.value

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                if old_value ~= element.value then
                    fn(element)

                    old_value = element.value
                end
            end
        end

        function switch:depend(...)
            depend(self, ...)
        end

        function switch:get()
            return self.value
        end

        function switch:set(value)
            self.value = value
        end

        function switch:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function switch:parent()
            return self.__parent;
        end

        switch.__index = switch;
    end

    local slider = {}; do
        function slider:new(name, min, max, default, suffix, cb)
            default = default or min;

            local data = {}; do
                data.name = name;
                data.value = default;
                data.limites = { min, max };
                data.pct = inverse_lerp(min, max, default);
                data.visible = true;
                data.suffix = suffix or "%s"

                data.interacting = false;
                data.__typeof = "slider"
                data.__gear = nil;
            end

            if cb then
                if not data.__gear then
                    data.__gear = gear:new();
                    data.__gear.__parent = self;
                end

                setmetatable(data, self)

                local items = cb(data.__gear, data)

                for key, value in pairs(items) do
                    data[key] = value
                end

                return data
            end

            setmetatable(data, self)
            return data
        end

        function slider:set_callback(fn, force)
            local old_value = self.value

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                if old_value ~= element.value then
                    fn(element)

                    old_value = element.value
                end
            end
        end

        function slider:depend(...)
            depend(self, ...)
        end

        function slider:get()
            return self.value;
        end

        function slider:set(value)
            if value < self.limites[1] then value = self.limites[1]; end
            if value > self.limites[2] then value = self.limites[2]; end

            self.value = value;
        end

        function slider:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function slider:parent()
            return self.__parent;
        end

        slider.__index = slider;
    end

    local label = {}; do
        function label:new(name, cb)
            local data = {}; do
                data.name = name;
                data.pct = 0.;
                data.visible = true;
            end

            if cb then
                if not data.__gear then
                    data.__gear = gear:new();
                    data.__gear.__parent = self;
                end

                local items = cb(data.__gear)

                for key, value in pairs(items) do
                    data[key] = value
                end
            end

            setmetatable(data, self);
            return data;
        end

        function label:depend(...)
            depend(self, ...)
        end

        function label:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function label:set_name(text)
            self.name = text
        end

        function label:parent()
            return self.__parent;
        end

        label.__index = label;
    end

    local button = {}; do
        function button:new(name, callback)
            callback = callback or function() end

            local data = {}; do
                data.name = name;
                data.interacting = false;
                data.pct = 0.;
                data.visible = true;
                data.callback = callback
                data.__gear = nil;
            end

            setmetatable(data, self);
            return data;
        end

        function button:set_callback(fn, force)
            local element = self

            element.callback = fn

            if force then
                fn(element)
            end
        end

        function button:depend(...)
            depend(self, ...)
        end

        function button:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function button:parent()
            return self.__parent;
        end

        button.__index = button;
    end

    local selectable = {}; do
        function selectable:new(name, items, multi, default, cb)
            default = default or (multi and {} or items[1])

            local data = {}; do
                data.name = name;
                data.value = default;
                data.items = items or {};
                data.multi = multi;
                data.pct = 0;
                data.visible = true;

                data.interacting = false;
                data.__typeof = "selectable"
                data.__gear = nil;
            end

            if cb then
                if not data.__gear then
                    data.__gear = gear:new();
                    data.__gear.__parent = self;
                end

                setmetatable(data, self)

                local items = cb(data.__gear, data)

                for key, value in pairs(items) do
                    data[key] = value
                end

                return data
            end

            setmetatable(data, self)
            return data
        end

        function selectable:set_callback(fn, force)
            local old_value = self.value

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                local condition = old_value ~= element.value

                if element.multi then
                    condition = not table_equal(old_value, element.value)
                end

                if condition then
                    fn(element)

                    old_value = element.value
                end
            end
        end

        function selectable:set(value)
            self.value = value
        end

        function selectable:get(value)
            if self.multi and value then
                local condition = false

                for _, v in pairs(self.value) do
                    if v == value then
                        condition = true
                        break
                    end
                end

                return condition
            end

            if not self.multi and value then
                local number = -1

                for i, v in pairs(self.items) do
                    if v == self.value then
                        number = i
                    end
                end

                return number
            end

            return self.value
        end

        function selectable:get_items()
            return self.items
        end

        function selectable:set_items(items)
            self.items = items
        end

        function selectable:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function selectable:parent()
            return self.__parent;
        end

        selectable.__index = selectable;
    end

    local hotkey = {}; do
        function hotkey:new(name, key, mode)
            local data = {}; do
                data.name = name;
                data.key = key or 0
                data.mode = mode or 1
                data.active = false;
                data.pct = 0;
                data.visible = true;

                data.interacting = false;
            end

            setmetatable(data, self)
            return data
        end

        function hotkey:set_callback(fn, force)
            local old_value = { key = self.key, mode = self.mode }

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                if not table_equal(old_value, { key = element.key, mode = element.mode }) then
                    fn(element)

                    old_value = { key = element.key, mode = element.mode }
                end
            end
        end

        function hotkey:is_active()
            return self.active
        end

        function hotkey:get()
            return { key = self.key, mode = self.mode }
        end

        function hotkey:set(tbl)
            self.key = tbl.key
            self.mode = tbl.mode
        end

        function hotkey:set_key(key)
            self.key = key
        end

        function hotkey:set_mode(mode)
            self.mode = mode
        end

        function hotkey:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function hotkey:parent()
            return self.__parent;
        end

        hotkey.__index = hotkey;
    end

    local input = {}; do
        function input:new(name, text)
            local data = {}; do
                data.name = name;
                data.value = text or ""
                data.pct = 0;
                data.visible = true;

                data.interacting = false;
            end

            setmetatable(data, self)
            return data
        end

        function input:set_callback(fn, force)
            local old_value = self.value

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                if old_value ~= element.value then
                    fn(element)

                    old_value = element.value
                end
            end
        end

        function input:depend(...)
            depend(self, ...)
        end

        function input:get()
            return self.value
        end

        function input:set(text)
            self.value = text
        end

        function input:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function input:parent()
            return self.__parent;
        end

        input.__index = input;
    end

    local color_picker = {}; do
        function color_picker:new(name, default)
            local data = {}; do
                data.name = name;
                data.value = default or color_t(1, 1, 1, 1)
                data.hsv = RBGtoHSV(data.value)
                data.pct = 0;
                data.visible = true;

                data.interacting = false;
            end

            setmetatable(data, self)
            return data
        end

        function color_picker:set_callback(fn, force)
            local old_value = self.value

            local element = self

            if force then
                fn(element)
            end

            callbacks[#callbacks + 1] = function()
                if old_value ~= element.value then
                    fn(element)

                    old_value = element.value
                end
            end
        end

        function color_picker:depend(...)
            depend(self, ...)
        end

        function color_picker:get()
            return self.value
        end

        function color_picker:set(value)
            self.value = value
        end

        function color_picker:visibility(value)
            if value ~= nil then
                self.visible = value
            end

            return self.visible
        end

        function color_picker:parent()
            return self.__parent;
        end

        color_picker.__index = color_picker
    end

    gear = {}; do
        function gear:new()
            local data = {}; do
                data.items = {};
                data.opened = false;
                data.pct = 0;
            end

            setmetatable(data, self);
            return data;
        end

        function gear:switch(...)
            local item = switch:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:slider(...)
            local item = slider:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:label(...)
            local item = label:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:button(...)
            local item = button:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:selectable(...)
            local item = selectable:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:hotkey(...)
            local item = hotkey:new(...); do
                item.__parent = self;
            end

            hotkeys[#hotkeys + 1] = item;
            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:input(...)
            local item = input:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:color_picker(...)
            local item = color_picker:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function gear:parent()
            return self.__parent;
        end

        gear.__index = gear;
    end

    local column = {}; do
        function column:new(name)
            local data = {}; do
                data.__name = name;
                data.items = {};
                data.pct = 0.;
            end

            setmetatable(data, self);
            return data;
        end

        function column:switch(...)
            local item = switch:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:slider(...)
            local item = slider:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:label(...)
            local item = label:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:button(...)
            local item = button:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:selectable(...)
            local item = selectable:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:hotkey(...)
            local item = hotkey:new(...); do
                item.__parent = self;
            end

            hotkeys[#hotkeys + 1] = item;
            self.items[#self.items + 1] = item;
            return item;
        end

        function column:input(...)
            local item = input:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        function column:color_picker(...)
            local item = color_picker:new(...); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        column.__index = column;
    end

    local tab = {}; do
        function tab:new(icon, name)
            local data = {}; do
                data.name = name;
                data.icon = icon;
                data.items = {};
                data.pct = 0;
            end

            tabs[#tabs + 1] = data;
            setmetatable(data, self);

            return data;
        end

        function tab:group(name)
            local length = #self.items;

            if length >= 3 then
                return;
            end

            local item = column:new(name); do
                item.__parent = self;
            end

            self.items[#self.items + 1] = item;
            return item;
        end

        tab.__index = tab;
    end

    function gui:create(icon, tab_name)
        return tab:new(icon, tab_name);
    end

    local function path_to_assets(file)
        return string.format("%s\\nix\\demonside\\%s", get_game_directory(), file)
    end

    gui.color = color_t(157 / 255, 183 / 255, 245 / 255, 1)

    local alpha = 1;
    local items_alpha = 1;

    local position = vec2_t(300, 300);
    local drag_delta;

    local tabs_info = {
        interped_current = 0,
        current = 0,
        size = vec2_t(0, 0)
    };

    local size = {
        init = vec2_t(660, 410),
        min = vec2_t(10, 10),
        current = vec2_t(660, 410)
    };


    local COLORS = {
        BACKGROUND = color_t(25 / 255, 25 / 255, 25 / 255, 1),
        OUTLINE = color_t(60 / 255, 60 / 255, 60 / 255, 1),
        TAB_BUTTON = color_t(45 / 255, 45 / 255, 45 / 255, 1),
        BACKGROUND_ITEMS = color_t(32 / 255, 32 / 255, 32 / 255, 1),
        BACKGROUND_COLUMN = color_t(40 / 255, 40 / 255, 40 / 255, 1),
        HEADER_TEXT = color_t(120 / 255, 120 / 255, 120 / 255, 1),
        TEXT_INACTIVE = color_t(.9, .9, .9, 100 / 255),
        TEXT = color_t(.9, .9, .9, 1)
    };

    local ANIM_SPEED = .05;

    -- local FONTS = {
    --     TAB = render.setup_font(path_to_assets 'MuseoSansCyrl-700.ttf', 18, 0),
    --     ICON = render.setup_font(path_to_assets 'icons.ttf', 16, 0),
    --     LOGO = render.setup_font(path_to_assets 'MuseoSansCyrl-900.ttf', 24, 0),
    --     ITEMS = render.setup_font(path_to_assets 'MuseoSansCyrl-500.ttf', 16, 0),
    --     COLUMN = render.setup_font(path_to_assets 'MuseoSansCyrl-700.ttf', 16, 0)
    -- }

    local FONTS = {
        TAB = render.setup_font(path_to_assets "Inter-SemiBold.ttf", 18, 24),
        LOGO = render.setup_font(path_to_assets "Inter-ExtraBold.ttf", 24, 24),
        ICON = render.setup_font(path_to_assets "icons.ttf", 19, 0),
        ITEMS = render.setup_font(path_to_assets "Inter-Medium.ttf", 16, 24),
        USERNAME = render.setup_font(path_to_assets "Inter-SemiBold.ttf", 16, 24),
        COLUMN = render.setup_font(path_to_assets "Inter-Medium.ttf", 16, 24),
        ITEMS_ICON = render.setup_font(path_to_assets "icons.ttf", 16, 0)
    }

    local ROUNDING = 16;
    local PADDING = 8; -- 8

    local LOGO_HEIGHT = 50;

    local ITEM_MARGIN = 12;

    local TAB_WIDTH = 130;
    local TAB_PADDING = 12;
    local TAB_MARGIN = 12;

    local post_render = {}; do
        post_render.data = {}

        post_render.push_clip_rect = function(from, to, intersect_with_current_clip_rect)
            post_render.data[#post_render.data + 1] = {
                type = "push_clip_rect",
                from = from,
                to = to,
                intersect_with_current_clip_rect = intersect_with_current_clip_rect
            }
        end

        post_render.switch = function(from, to, background_color, circle_color, pct)
            post_render.data[#post_render.data + 1] = {
                type = "switch",
                from = from,
                to = to,
                background_color = background_color,
                circle_color = circle_color,
                pct = pct
            };
        end

        post_render.rect = function(from, to, color, r)
            post_render.data[#post_render.data + 1] = {
                type = "rect",
                from = from,
                to = to,
                color = color,
                r = r
            };
        end

        post_render.rect_filled = function(from, to, color, r)
            post_render.data[#post_render.data + 1] = {
                type = "rect_filled",
                from = from,
                to = to,
                color = color,
                r = r
            };
        end

        post_render.rect_filled_fade = function(from, to, color_a, color_b, color_c, color_d)
            post_render.data[#post_render.data + 1] = {
                type = "rect_filled_fade",
                from = from,
                to = to,
                color_a = color_a,
                color_b = color_b,
                color_c = color_c,
                color_d = color_d
            };
        end

        post_render.circle = function(position, radius, segments, filled, color)
            post_render.data[#post_render.data + 1] = {
                type = "circle",
                pos = position,
                r = radius,
                s = segments,
                fill = filled,
                color = color
            };
        end
        post_render.text = function(text, font, pos, color)
            post_render.data[#post_render.data + 1] = {
                type = "text",
                text = text,
                font = font,
                pos = pos,
                color = color
            };
        end

        post_render.pop_clip_rect = function()
            post_render.data[#post_render.data + 1] = {
                type = "pop_clip_rect"
            }
        end
    end

    local allow_dragging = true
    local is_interacting = false
    local is_popup_open = false

    local gui_render = {}; do
        local ITEM_HEIGHT = 20

        function gui_render:gear(item, pos, alpha, mouse)
            if item.__gear and item.__gear.items and #item.__gear.items > 0 then
                local icon = "D"
                local icon_size = render.calc_text_size(icon, FONTS.ITEMS_ICON)
                local x, y = pos.x, pos.y

                y = y - icon_size.y * .5
                x = x - icon_size.x

                if item.__gear.opened == nil then
                    item.__gear.opened = false
                end

                if item.__gear.icon_pct == nil then
                    item.__gear.icon_pct = 0
                end

                local icon_color = color_t(.6, .6, .6, 1)

                if in_bounds(vec2_t(x, y), vec2_t(x, y) + icon_size, mouse.pos) then
                    icon_color = color_t(.9, .9, .9, 1)
                    if mouse.is_lmb and not is_interacting and not is_popup_open then
                        item.__gear.opened = not item.__gear.opened
                        allow_dragging = false
                    end
                end

                item.__gear.icon_pct = tweening:interp(item.__gear.icon_pct, item.__gear.opened and 1 or 0, ANIM_SPEED)
                icon_color = icon_color:lerp(gui.color, item.__gear.icon_pct)

                render.text(icon, FONTS.ITEMS_ICON, vec2_t(x, y), icon_color:alpha_modulate(alpha))

                if item.__gear.icon_pct > 0.01 then
                    return {
                        item = item,
                        pos = vec2_t(x + icon_size.x + PADDING, y),
                        pct = item.__gear.icon_pct
                    }
                end

                return
            end
        end

        function gui_render:switch(item, pos, column_width, alpha, mouse, it_gear, gear)
            local height = 16;
            local width = round(height * 1.75);
            local cached_value = item.value;

            local measure = render.calc_text_size(item.name, FONTS.ITEMS)
            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            if mouse.is_lmb and not is_interacting and should_click then
                if in_bounds(vec2_t(pos.x, pos.y), vec2_t(pos.x + measure.x, pos.y + height), mouse.pos) or
                    in_bounds(vec2_t(pos.x + column_width - width - PADDING * 2, pos.y), vec2_t(pos.x + column_width - PADDING * 2, pos.y + height), mouse.pos) then
                    item.value = not cached_value;
                    allow_dragging = false;
                end
            end

            item.pct = tweening:interp(item.pct, cached_value, ANIM_SPEED);

            local background_color = color_t(.4, .4, .4, 1):lerp(gui.color, item.pct):alpha_modulate(alpha)
            local circle_color = color_t(.75, .75, .75, 1):lerp(color_t(.92, .92, .92, 1), item.pct):alpha_modulate(
                alpha)

            render.switch(vec2_t(pos.x + column_width - width - PADDING * 1.5, pos.y), vec2_t(width, height),
                background_color, circle_color, item.pct)

            local text_color = color_t(.75, .75, .75, 1):lerp(color_t(.92, .92, .92, 1), item.pct):alpha_modulate(alpha)

            render.text(item.name, FONTS.ITEMS, vec2_t(pos.x, pos.y - .5), text_color)

            if gear then
                local gear_icon_x = pos.x + column_width - width - PADDING * 2.5
                local gear_icon_y = pos.y + height * .5

                local data = gui_render:gear(item, vec2_t(gear_icon_x, gear_icon_y), alpha, mouse)

                return ITEM_HEIGHT * .5 + ITEM_MARGIN, data
            end

            return ITEM_HEIGHT * .5 + ITEM_MARGIN
        end

        function gui_render:slider(item, pos, column_width, alpha, mouse, it_gear, gear)
            local box_size = vec2_t(column_width - PADDING * 3.5 - 7, 10)
            local formatted_value = string.format(item.suffix, item.value);
            local x, y = pos.x, pos.y

            local item_value = item.value;

            local measure = render.calc_text_size(item.name, FONTS.ITEMS);
            local measure_value = render.calc_text_size(formatted_value, FONTS.ITEMS);

            local ITEM_ROUNDING = box_size.y * .5
            local width = box_size.x * item.pct;

            item.pct = tweening:interp(item.pct, inverse_lerp(item.limites[1], item.limites[2], item.value), .033);

            render.text(item.name, FONTS.ITEMS, vec2_t(x, y), COLORS.TEXT:alpha_modulate(alpha))

            render.text(formatted_value, FONTS.ITEMS, vec2_t(x + column_width - measure_value.x - PADDING * 1.5, y),
                COLORS.TEXT:alpha_modulate(.75 * alpha))

            x = x + PADDING + 4
            y = y + (measure.y + ITEM_MARGIN * .5)

            local is_ctrl = c_input:is_key_pressed(0x11);
            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            if mouse.is_left_button and should_click then
                if mouse.is_lmb and not is_interacting then
                    if in_bounds(vec2_t(x, y), vec2_t(x + box_size.x, y + box_size.y), mouse.pos) then
                        item.interacting = true;
                        allow_dragging = false;
                    elseif in_bounds(vec2_t(x - PADDING, y), vec2_t(x, y + box_size.y), mouse.pos) then
                        item.value = clamp(item_value - (is_ctrl and 10 or 1), item.limites[1], item.limites[2]);

                        allow_dragging = false;
                    elseif in_bounds(vec2_t(x + box_size.x, y), vec2_t(x + box_size.x + PADDING, y + box_size.y), mouse.pos) then
                        item.value = clamp(item_value + (is_ctrl and 10 or 1), item.limites[1], item.limites[2]);

                        allow_dragging = false;
                    end
                end

                if item.interacting then
                    local value = (mouse.pos.x - x) / box_size.x;
                    value = clamp(value, 0, 1);

                    item.value = round(lerp(item.limites[1], item.limites[2], value))
                end
            else
                item.interacting = false;
            end

            local arf_height = 7
            local arf_width = 7

            render.rect_filled(vec2_t(x - arf_width - 4, y + box_size.y * .5 - 1), vec2_t(x - 4, y + box_size.y * .5),
                COLORS.TEXT:alpha_modulate(.5 * alpha))

            --x
            render.rect_filled(vec2_t(x + box_size.x + 4, y + box_size.y * .5 - 1),
                vec2_t(x + box_size.x + 4 + arf_width, y + box_size.y * .5), COLORS.TEXT:alpha_modulate(.5 * alpha))
            --y
            render.rect_filled(vec2_t(x + box_size.x + arf_width * .5 + 4, y + 1),
                vec2_t(x + box_size.x + arf_width * .5 + 5, y + 1 + arf_height), COLORS.TEXT:alpha_modulate(.5 * alpha))

            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, color_t(.4, .4, .4, .5 * alpha), ITEM_ROUNDING);

            render.push_clip_rect(vec2_t(x, y), vec2_t(x + width, y + box_size.y))
            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, gui.color:alpha_modulate(alpha), ITEM_ROUNDING);
            render.pop_clip_rect();

            render.rect_filled(vec2_t(x + width - 2, y - 1), vec2_t(x + width + 2, y + box_size.y + 1),
                color_t(1, 1, 1, 1 * alpha), 2);

            if gear then
                local gear_icon_x = x + column_width - measure_value.x - PADDING * 2.5 - 3
                local gear_icon_y = y - (measure.y - ITEM_MARGIN * .5) - 3

                local data = gui_render:gear(item, vec2_t(gear_icon_x, gear_icon_y), alpha, mouse)

                return box_size.y * .5 + measure.y + ITEM_MARGIN * 1.5, data
            end

            return box_size.y * .5 + measure.y + ITEM_MARGIN * 1.5
        end

        function gui_render:label(item, pos, column_width, alpha, mouse, it_gear, gear)
            local measure = render.calc_text_size(item.name, FONTS.ITEMS);
            local x, y = pos.x, pos.y

            render.text(item.name, FONTS.ITEMS, vec2_t(x, y), COLORS.TEXT:alpha_modulate(alpha))

            if gear then
                local gear_icon_x = x + column_width - PADDING * 1.5
                local gear_icon_y = y + ITEM_HEIGHT * .5

                local data = gui_render:gear(item, vec2_t(gear_icon_x, gear_icon_y), alpha, mouse)

                return ITEM_MARGIN + ITEM_HEIGHT * .5 + 2, data
            end

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 2
        end

        function gui_render:input(item, pos, column_width, alpha, mouse, it_gear, gear)
            local box_size = vec2_t(column_width - PADDING * 1.5, 20);
            local margin = 100
            local x, y = pos.x, pos.y

            render.text(item.name, FONTS.ITEMS, vec2_t(x, y + 2), COLORS.TEXT:alpha_modulate(alpha))

            box_size.x = box_size.x - PADDING - margin;
            x = x + margin + PADDING;

            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, color_t(.3, .3, .3, alpha), 3);

            if item.cursor_pos == nil then
                item.cursor_pos = #item.value + 1
            end

            if item.scroll_offset == nil then
                item.scroll_offset = 0
            end

            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            if in_bounds(vec2_t(x, y), vec2_t(x, y) + box_size, mouse.pos) and should_click then
                if mouse.is_lmb and not is_interacting then
                    item.interacting = true;
                    is_interacting = true;

                    local click_x = mouse.pos.x - (x + 4) + item.scroll_offset
                    local text_width = 0
                    item.cursor_pos = 1

                    for i = 1, #item.value do
                        local char = item.value:sub(i, i)
                        local char_width = render.calc_text_size(char, FONTS.ITEMS).x

                        if text_width + char_width / 2 > click_x then
                            break
                        end

                        text_width = text_width + char_width
                        item.cursor_pos = i + 1
                    end
                end
                allow_dragging = false;
            end

            item.pct = tweening:interp(item.pct, item.interacting, ANIM_SPEED);

            if item.pct > .08 then
                render.rect(vec2_t(x, y), vec2_t(x, y) + box_size, color_t(.4, .4, .4, alpha * item.pct), 3);

                if not in_bounds(vec2_t(x, y), vec2_t(x, y) + box_size, mouse.pos) and mouse.is_lmb then
                    item.interacting = false;
                end

                local text_changed = false

                for i = 0x2F, 0x5A do
                    if c_input:is_key_clicked(i) then
                        local symbol = c_input:get_name(i)

                        if not c_input:is_key_pressed(0x10) then
                            symbol = symbol:lower()
                        end

                        item.value = item.value:sub(1, item.cursor_pos - 1) .. symbol .. item.value:sub(item.cursor_pos)
                        item.cursor_pos = item.cursor_pos + 1
                        text_changed = true
                    end
                end

                if c_input:is_key_clicked(0x20) then
                    item.value = item.value:sub(1, item.cursor_pos - 1) .. " " .. item.value:sub(item.cursor_pos)
                    item.cursor_pos = item.cursor_pos + 1
                    text_changed = true
                end

                if c_input:is_key_clicked(0x08) and item.cursor_pos > 1 then
                    item.value = item.value:sub(1, item.cursor_pos - 2) .. item.value:sub(item.cursor_pos)
                    item.cursor_pos = item.cursor_pos - 1
                    text_changed = true
                end

                if c_input:is_key_clicked(0x2E) and item.cursor_pos <= #item.value then
                    item.value = item.value:sub(1, item.cursor_pos - 1) .. item.value:sub(item.cursor_pos + 1)
                    text_changed = true
                end

                local cursor_moved = false

                if c_input:is_key_clicked(0x25) and item.cursor_pos > 1 then
                    item.cursor_pos = item.cursor_pos - 1
                    cursor_moved = true
                end

                if c_input:is_key_clicked(0x27) and item.cursor_pos <= #item.value then
                    item.cursor_pos = item.cursor_pos + 1
                    cursor_moved = true
                end

                if text_changed or cursor_moved then
                    local text_before_cursor = item.value:sub(1, item.cursor_pos - 1)
                    local measure_before = render.calc_text_size(text_before_cursor, FONTS.ITEMS)
                    local total_text_width = render.calc_text_size(item.value, FONTS.ITEMS).x
                    local visible_width = box_size.x - 8

                    if measure_before.x - item.scroll_offset > visible_width then
                        item.scroll_offset = measure_before.x - visible_width
                    end

                    if measure_before.x - item.scroll_offset < 0 then
                        item.scroll_offset = measure_before.x
                    end

                    if total_text_width - item.scroll_offset < visible_width then
                        item.scroll_offset = math.max(0, total_text_width - visible_width)
                    end

                    item.scroll_offset = math.max(0, item.scroll_offset)
                end
            end

            render.push_clip_rect(vec2_t(x + 3, y + 2), vec2_t(x + 5, y + 2) + box_size - vec2_t(8, 4))
            local text_before_cursor = item.value:sub(1, item.cursor_pos - 1)
            local measure_before = render.calc_text_size(text_before_cursor, FONTS.ITEMS)

            render.text(item.value, FONTS.ITEMS, vec2_t(x + 4 - item.scroll_offset, y + 2),
                COLORS.TEXT:alpha_modulate(alpha))

            local cursor_x = x + 4 + measure_before.x - item.scroll_offset
            local cursor_alpha = alpha * item.pct

            if cursor_x >= x + 4 and cursor_x <= x + box_size.x - 4 then
                render.rect_filled(
                    vec2_t(cursor_x - 1, y + 4),
                    vec2_t(cursor_x, y + box_size.y - 4),
                    COLORS.TEXT:alpha_modulate(cursor_alpha)
                )
            end
            render.pop_clip_rect()

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4
        end

        function gui_render:button(item, pos, column_width, alpha, mouse, it_gear, gear)
            local box_size = vec2_t(column_width - PADDING * 1.5, 20);
            local measure = render.calc_text_size(item.name, FONTS.ITEMS);
            local x, y = pos.x, pos.y

            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, color_t(.3, .3, .3, alpha), 3);

            local half_width = round(box_size.x * .5)
            local animated_half_width = round(half_width * (item.pct + .1))

            render.push_clip_rect(vec2_t(x + half_width - animated_half_width, y),
                vec2_t(x + half_width + animated_half_width, y + box_size.y))
            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, gui.color:alpha_modulate(item.pct * alpha), 3);
            render.pop_clip_rect()

            if in_bounds(vec2_t(x, y), vec2_t(x, y) + box_size, mouse.pos) and should_click then
                if mouse.is_lmb and not is_interacting then
                    item.callback();

                    item.interacting = true;
                    allow_dragging = false;
                end
            end

            if item.interacting and item.pct >= 1 then
                item.interacting = mouse.is_left_button
            end

            item.pct = tweening:interp(item.pct, item.interacting, ANIM_SPEED * .75);

            render.text(item.name, FONTS.ITEMS, vec2_t(x + box_size.x * .5 - measure.x * .5, y + 2),
                COLORS.TEXT:alpha_modulate(alpha))

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4
        end

        function gui_render:selectable(item, pos, column_width, alpha, mouse, it_gear, gear)
            local box_size = vec2_t(column_width - PADDING * 1.5, 20);
            local margin = 100
            local x, y = pos.x, pos.y

            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            render.text(item.name, FONTS.ITEMS, vec2_t(x, y + 2), COLORS.TEXT:alpha_modulate(alpha))

            box_size.x = box_size.x - PADDING - margin;
            x = x + margin + PADDING;

            if in_bounds(vec2_t(x, y), vec2_t(x, y) + box_size, mouse.pos) and should_click then
                if mouse.is_lmb and not is_interacting then
                    item.interacting = not item.interacting;
                    is_interacting = true;
                end
                allow_dragging = false;
            end

            item.pct = tweening:interp(item.pct, item.interacting, ANIM_SPEED);

            render.rect_filled(vec2_t(x, y), vec2_t(x, y) + box_size, color_t(.3, .3, .3, alpha), 3);

            if item.pct > .08 then
                is_interacting = true;

                local height = 20 * #item.items;
                local item_alpha = alpha * item.pct;
                local x = x + box_size.x
                local max_width = box_size.x

                for i = 1, #item.items do
                    local measure = render.calc_text_size(item.items[i], FONTS.ITEMS)
                    if measure.x + PADDING * 2 > max_width then
                        max_width = measure.x + PADDING * 2
                    end
                end

                local width = max_width

                post_render.rect_filled(vec2_t(x - width, y + box_size.y + 3),
                    vec2_t(x, y + box_size.y + 3 + height), color_t(.3, .3, .3, 1 * item_alpha), 4);
                post_render.rect(vec2_t(x - width, y + box_size.y + 3),
                    vec2_t(x, y + box_size.y + 3 + height), color_t(.4, .4, .4, 1 * item_alpha), 4);

                for i = 1, #item.items do
                    local y = y + box_size.y + 3 + (i - 1) * 20;
                    local color = color_t(160 / 255, 160 / 255, 160 / 255, 1 * item_alpha);
                    local value = item.multi and item.value[i] or item.items[i] == item.value

                    if in_bounds(vec2_t(x - width, y), vec2_t(x, y + 19.5), mouse.pos) then
                        color = color_t(225 / 255, 225 / 255, 225 / 255, 1 * item_alpha);

                        if mouse.is_lmb then
                            if item.multi then
                                if item.value[i] then
                                    item.value[i] = nil
                                else
                                    item.value[i] = item.items[i]
                                end
                            else
                                item.value = item.items[i]
                            end
                        end

                        allow_dragging = false;
                    end

                    if value then
                        color = color_t(1, 1, 1, 1 * item_alpha);
                    end

                    post_render.text(item.items[i], FONTS.ITEMS, vec2_t(x - width + PADDING * .5, y + 1), color);
                end

                if not in_bounds(vec2_t(x - width, y + 2), vec2_t(x, y + 2 + box_size.y + height), mouse.pos) and mouse.is_lmb then
                    item.interacting = false;
                end
            end

            local selected_items = {};

            if item.multi then
                for i = 1, #item.items do
                    if item.value[i] then selected_items[#selected_items + 1] = item.items[i]; end
                end
            end

            local total_measure = 0;
            local limited;
            local concated_text = table.concat(selected_items, ", ");
            local text = item.multi and (concated_text ~= "" and concated_text or "Select") or item.value;
            local selected_alpha = text == "Select" and .5 or 1

            text = text:gsub(".", function(match)
                local symbol_measure = render.calc_text_size(match, FONTS.ITEMS);
                if total_measure + symbol_measure.x > box_size.x - PADDING * 2.5 then
                    match = not limited and "..." or "";
                    limited = true;
                end
                total_measure = total_measure + symbol_measure.x;
                return match;
            end)

            render.text(text, FONTS.ITEMS, vec2_t(x + PADDING * .5, y + 2), color_t(1, 1, 1, selected_alpha * alpha));

            if gear then
                local gear_icon_x = x - 5
                local gear_icon_y = y + box_size.y * .5

                local data = gui_render:gear(item, vec2_t(gear_icon_x, gear_icon_y), alpha, mouse)
                return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4, data
            end

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4
        end

        function gui_render:hotkey(item, pos, column_width, alpha, mouse, it_gear, gear)
            local width, height = 30, 20;
            local x, y = pos.x, pos.y
            local new_x, new_y = pos.x, pos.y;

            if item.width == nil then
                item.width = 30;
            end

            render.text(item.name, FONTS.ITEMS, vec2_t(x, y + 2), color_t(1, 1, 1, 1 * alpha));

            new_x = new_x + column_width - PADDING * 1.5 - item.width;

            y = y + 1;

            local item_key = item:get().key;
            local key = item.interacting == 1 and "..." or (item_key > 0 and c_input:get_name(item_key) or "N/A");
            local key_measure = render.calc_text_size(key, FONTS.ITEMS);

            render.rect_filled(vec2_t(new_x, y), vec2_t(new_x + item.width, y + height),
                color_t(60 / 255, 60 / 255, 60 / 255, 1 * alpha), 3);
            render.rect(vec2_t(round(new_x - 1), round(y - 1)), vec2_t(new_x + item.width, y + height),
                color_t(80 / 255, 80 / 255, 80 / 255, 1 * alpha), 3);

            render.text(key, FONTS.ITEMS,
                vec2_t(round(new_x + item.width * .5 - key_measure.x * .5), y + height * .5 - key_measure.y * .5),
                color_t(1, 1, 1, 1 * alpha));

            if key_measure.x > width - 5 then
                width = key_measure.x + PADDING
            end

            item.width = tweening:interp(item.width, width > 30 and width or 30, .05)

            if item.interacting == 2 then
                is_interacting = true;
            end

            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            if in_bounds(vec2_t(new_x, y), vec2_t(new_x + item.width, y + 2 + height), mouse.pos) and should_click then
                if mouse.is_lmb and not item.interacting and not is_interacting then
                    item.interacting = 1;
                end

                if mouse.is_rmb and not item.interacting then
                    item.interacting = 2;
                end

                allow_dragging = false;
            else
                if item.interacting == 1 and mouse.is_lmb then
                    item.interacting = false;
                end
            end

            if item.interacting == 1 and not mouse.is_left_button and not mouse.is_right_button and not is_interacting then
                for i = 0x01, 0xFE do
                    if c_input:is_key_clicked(i) then
                        if c_input:get_name(i) ~= "Esc" then
                            item:set_key(i);
                        else
                            item:set_key(0);
                        end
                        item.interacting = false;
                        break;
                    end
                end

                if c_input:is_key_clicked(27) then
                    item:set_key(0);
                    item.interacting = false;
                end
            elseif item.interacting == 2 then
                local converted = { 1, 2, 3 };
                local strings = { "always", "hold", "toggle" };

                local str_max_x = 0;
                local str_max_y = 2;

                for i = 1, #strings do
                    local measure = render.calc_text_size(strings[i], FONTS.ITEMS);
                    str_max_x = math.max(str_max_x, measure.x);
                    str_max_y = str_max_y + measure.y;
                end

                local popup_size = vec2_t(str_max_x + PADDING * 1.5, str_max_y + PADDING);

                new_x = new_x + item.width + PADDING;

                post_render.rect_filled(vec2_t(new_x, new_y), vec2_t(new_x, new_y) + popup_size,
                    color_t(60 / 255, 60 / 255, 60 / 255, 1 * item.pct * alpha), 3);
                post_render.rect(vec2_t(new_x - 1, new_y - 1), vec2_t(new_x, new_y) + popup_size + 1,
                    color_t(80 / 255, 80 / 255, 80 / 255, 1 * item.pct * alpha), 3);

                new_x, new_y = new_x + PADDING * .75, new_y + PADDING * .5;

                for i = 1, #strings do
                    local measure = render.calc_text_size(strings[i], FONTS.ITEMS);
                    local pos = vec2_t(new_x, new_y + (measure.y + 1) * (i - 1));
                    local color = color_t(160 / 255, 160 / 255, 160 / 255, 1);
                    local mode = converted[i];

                    if in_bounds(pos - vec2_t(PADDING * .5, -2), pos + vec2_t(popup_size.x, measure.y), mouse.pos) then
                        color = color_t(225 / 255, 225 / 255, 225 / 255, 1);

                        if mouse.is_lmb then
                            item:set_mode(mode - 1);
                            item.interacting = false;
                        end
                    else
                        if mouse.is_lmb then
                            item.interacting = false;
                        end
                    end

                    local item_mode = item:get().mode

                    if item_mode == mode - 1 then
                        color = color_t(1, 1, 1, 1);
                    end

                    color.a = 1 * alpha;

                    post_render.text(strings[i], FONTS.ITEMS, pos, color);
                end
            end

            item.pct = tweening:interp(item.pct, not item.interacting == false, ANIM_SPEED);

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4
        end

        function gui_render:color_picker(item, pos, column_width, alpha, mouse, it_gear, gear)
            local measure = render.calc_text_size(item.name, FONTS.ITEMS);
            local x, y = pos.x, pos.y
            local new_x, new_y = pos.x, pos.y;
            local h, w = 16, 16;

            render.text(item.name, FONTS.ITEMS, vec2_t(new_x, new_y + 1), color_t(1, 1, 1, 1 * alpha));

            new_x = new_x + column_width - PADDING * 1.5 - w;
            new_y = new_y + 2;

            local value = item:get();
            local r, g, b, a = value.r, value.g, value.b, value.a;

            render.rect_filled(vec2_t(new_x, round(new_y)), vec2_t(new_x + w, round(new_y + h)),
                color_t(r, g, b, a * alpha), 3);
            render.rect(vec2_t(new_x - 1, round(new_y - 1)), vec2_t(new_x + w, round(new_y + h)),
                color_t(80 / 255, 80 / 255, 80 / 255, 1 * alpha), 3);

            new_y = new_y - 2;

            local should_click = not is_popup_open

            if it_gear then
                should_click = true
            end

            if item.pct ~= 0 then
                if item.interacting == 1 or item.interacting == 3 or item.interacting == 4 or item.interacting == 5 then
                    allow_dragging = false;
                    is_interacting = true;

                    local popup_size = PADDING + 150 + PADDING * .5 + 10 + PADDING;

                    new_x, new_y = new_x + PADDING + w, new_y + 2;

                    post_render.rect_filled(vec2_t(new_x, new_y), vec2_t(new_x, new_y) + popup_size,
                        color_t(60 / 255, 60 / 255, 60 / 255, 1 * alpha), 3);

                    new_x, new_y = new_x + PADDING, new_y + PADDING;

                    local hsv = item.hsv;

                    local size = vec2_t(150, 150);


                    -- Hue slider
                    do
                        local pos = vec2_t(new_x, round(new_y))
                        pos.x = pos.x + size.x + PADDING * .75
                        local width = 10
                        local height = size.y + 1
                        local hue_colors = { color_t(1, 0, 0, 1), color_t(1, 1, 0, 1), color_t(0, 1, 0, 1), color_t(0, 1,
                            1, 1), color_t(0, 0, 1, 1), color_t(1, 0, 1, 1), color_t(1, 0, 0, 1) }
                        local t = (1 / (#hue_colors - 1))

                        for i = 1, #hue_colors - 1 do
                            local p = pos + vec2_t(0, (i - 1) * (t * height))
                            post_render.rect_filled_fade(p, p + vec2_t(width, height * t), hue_colors[i], hue_colors[i],
                                hue_colors[i + 1], hue_colors[i + 1])
                        end

                        post_render.rect_filled(pos, pos + vec2_t(width, height),
                            color_t(50 / 255, 50 / 255, 50 / 255, 50 / 255 * item.pct * alpha), 2)
                        post_render.rect_filled(pos + vec2_t(-1, -2 + hsv[1] * height),
                            pos + vec2_t(width + 1, 2 + hsv[1] * height), color_t(1, 1, 1, 1 * item.pct * alpha), 2)

                        if in_bounds(pos, pos + vec2_t(width, 2 + height), mouse.pos) and should_click then
                            if mouse.is_lmb then
                                item.interacting = 4
                            end
                        end

                        if item.interacting == 4 then
                            item.interacting = mouse.is_left_button and 4 or 1

                            hsv[1] = clamp((mouse.pos.y - new_y) / height, 0, 359 / 360)

                            local hsv_color = HSVToRGB(hsv);

                            item:set(hsv_color);
                        end
                    end

                    -- Alpha slider
                    do
                        local pos = vec2_t(new_x, round(new_y))
                        pos.y = pos.y + size.y + PADDING * .75
                        local width = size.x;
                        local height = 10;

                        post_render.rect_filled_fade(pos, pos + vec2_t(width, height),
                            value:alpha_modulate(0), value:alpha_modulate(1), value:alpha_modulate(1),
                            value:alpha_modulate(0))
                        post_render.rect(pos, pos + vec2_t(width, height), color_t(.3, .3, .3, item.pct * alpha))

                        post_render.rect_filled(pos + vec2_t(width * value.a - 2, -1),
                            pos + vec2_t(width * value.a, 0) + vec2_t(2, height + 1),
                            color_t(1, 1, 1, 1 * item.pct * alpha), 2)

                        if in_bounds(pos, pos + vec2_t(width, height), mouse.pos) and should_click then
                            if mouse.is_lmb then
                                item.interacting = 5
                            end
                        end

                        if item.interacting == 5 then
                            item.interacting = mouse.is_left_button and 5 or 1

                            value.a = clamp((mouse.pos.x - new_x) / size.x, 0, 1)

                            item:set(value);
                        end
                    end

                    -- Box
                    do
                        local pos = vec2_t(new_x, new_y)
                        for i = 0, size.y do
                            local c1 = HSVToRGB { hsv[1], 1, 1 - (i / size.y) };
                            local c2 = HSVToRGB { hsv[1], 0, 1 - (i / size.y) };
                            c1.a, c2.a = 1 * item.pct * alpha, 1 * item.pct * alpha;
                            post_render.rect_filled_fade(pos + vec2_t(0, i), pos + vec2_t(size.y, i + 1), c2, c1, c1, c2);
                        end

                        if in_bounds(vec2_t(new_x, new_y), vec2_t(new_x, new_y) + size, mouse.pos) and should_click then
                            if mouse.is_lmb then
                                item.interacting = 3;
                            end
                        end

                        if item.interacting == 3 then
                            item.interacting = mouse.is_left_button and 3 or 1;

                            hsv[2] = clamp((mouse.pos.x - new_x) / size.x, 0, 1);
                            hsv[3] = clamp(1 - (mouse.pos.y - new_y) / size.y, 0, 1);

                            local hsv_color = HSVToRGB(hsv);

                            item:set(hsv_color);
                        end

                        local color = HSVToRGB(hsv); color.a = 1 * item.pct * alpha;
                        local size_color = item.interacting == 3 and 5 or 4;

                        post_render.circle(vec2_t(pos.x + size.x * hsv[2], pos.y + size.y * (1 - hsv[3])), size_color, 18,
                            true, color);
                        post_render.circle(vec2_t(pos.x + size.x * hsv[2], pos.y + size.y * (1 - hsv[3])), size_color, 18,
                            false, color_t(1, 1, 1, 1 * item.pct * alpha));
                    end


                    if item.interacting and not in_bounds(vec2_t(new_x, new_y), vec2_t(new_x, new_y) + popup_size, mouse.pos) and (mouse.is_lmb or mouse.is_rmb) then
                        item.interacting = false;
                    end
                elseif item.interacting == 2 then
                    is_interacting = true;

                    local strings = {
                        string.format("R:%d G:%d B:%d A:%d", r * 255, g * 255, b * 255, a * 255),
                        "Copy",
                        "Paste"
                    };

                    local str_max_x = 0;
                    local str_max_y = 0;

                    for i = 1, #strings do
                        local measure = render.calc_text_size(strings[i], FONTS.ITEMS);
                        str_max_x = math.max(str_max_x, measure.x);
                        str_max_y = str_max_y + measure.y;
                    end

                    str_max_y = str_max_y + 3

                    local popup_size = vec2_t(str_max_x + PADDING * 1.5, str_max_y)

                    new_x, new_y = new_x + PADDING * .5 + w, new_y + 2

                    post_render.rect_filled(vec2_t(new_x, round(new_y)),
                        vec2_t(new_x, round(new_y)) + popup_size,
                        color_t(60 / 255, 60 / 255, 60 / 255, 1 * item.pct * alpha), 3);
                    post_render.rect(vec2_t(new_x - 1, round(new_y - 1)),
                        vec2_t(new_x, round(new_y)) + popup_size,
                        color_t(80 / 255, 80 / 255, 80 / 255, 1 * item.pct * alpha), 3);

                    new_x, new_y = new_x + PADDING * .5, new_y + PADDING * .25

                    for i = 1, #strings do
                        local pos = vec2_t(new_x, new_y + (ITEM_MARGIN + 3) * (i - 1))
                        local measure = render.calc_text_size(strings[i], FONTS.ITEMS)
                        local color = color_t(160 / 255, 160 / 255, 160 / 255, 1)

                        if i > 1 then
                            if in_bounds(pos, pos + measure - 2, mouse.pos) then
                                color = color_t(225 / 255, 225 / 255, 225 / 255, 1);

                                if i == 2 and mouse.is_lmb then
                                    clipboard.set(string.format("#%02x%02x%02x%02x", r * 255, g * 255, b * 255, a * 255)
                                        :upper())
                                elseif i == 3 and mouse.is_lmb then
                                    local hex = clipboard:get()
                                    local r, g, b, a = hex2rgba(hex)
                                    local success, c = pcall(color_t, r, g, b, a)
                                    if success then
                                        local transformed = color_t(c.r, c.g, c.b, c.a);

                                        item.hsv = RBGtoHSV(c)
                                        item:set(transformed)
                                    else
                                        -- print(tostring(c))
                                        -- item:set(color_t(0, 0, 0, 1))
                                    end
                                end
                            end
                        end

                        color.a = 1 * alpha
                        post_render.text(strings[i], FONTS.ITEMS, pos, color)
                    end

                    if item.interacting and not in_bounds(vec2_t(new_x, new_y) - PADDING * .5, vec2_t(new_x, new_y) + popup_size - PADDING * .5, mouse.pos) and (mouse.is_lmb or mouse.is_rmb) then
                        item.interacting = false;
                    end
                end
            end

            if in_bounds(vec2_t(new_x, new_y), vec2_t(new_x + w, new_y + h), mouse.pos) and not is_interacting and should_click then
                if mouse.is_lmb then
                    item.interacting = 1;
                elseif mouse.is_rmb then
                    item.interacting = 2;
                end

                allow_dragging = false;
            end

            if not ui.is_menu_opened() then
                item.interacting = false
            end

            item.pct = tweening:interp(item.pct, not (item.interacting == false), ANIM_SPEED)

            return ITEM_MARGIN + ITEM_HEIGHT * .5 + 4
        end
    end

    local gear_popups = {}
    local avatar

    function gui:paint()
        local cs2_focused = utils.is_cs2_foreground()
        local is_left_button = cs2_focused and c_input:is_key_pressed(0x01) or false;
        local is_right_button = cs2_focused and c_input:is_key_pressed(0x02) or false;
        local is_lmb = cs2_focused and c_input:is_key_clicked(0x01) or false;
        local is_rmb = cs2_focused and c_input:is_key_clicked(0x02) or false;

        allow_dragging = true
        is_interacting = false

        local any_gear_open = false
        for _, popup_data in pairs(gear_popups) do
            if popup_data.pct > 0.1 then
                any_gear_open = true
                break
            end
        end

        is_popup_open = any_gear_open

        post_render.data = {};
        post_render.data = {};

        local screen = render.screen_size();
        local mouse = c_input:mouse_position();

        alpha = tweening:interp(alpha, ui.is_menu_opened(), ANIM_SPEED);

        if not selected.predicted_tab and not selected.tab and tabs[1] then
            selected.predicted_tab = tabs[1];
            selected.tab = tabs[1];
        end

        if alpha >= .1 then
            render.rect_filled(position, position + size.current, COLORS.BACKGROUND:alpha_modulate(alpha), ROUNDING);
            render.rect(position - 1, position + size.current + 1, COLORS.OUTLINE:alpha_modulate(alpha), ROUNDING + 1);

            local this_tab = selected.tab; do
                if selected.tab ~= selected.predicted_tab then
                    items_alpha = tweening:interp(items_alpha, 0, ANIM_SPEED);

                    if items_alpha == 0 then
                        selected.tab = selected.predicted_tab;
                    end
                else
                    items_alpha = tweening:interp(items_alpha, alpha, ANIM_SPEED);
                end

                local x, y = position.x, position.y; do
                    x = x + PADDING;
                    y = y + PADDING + LOGO_HEIGHT;
                end

                local offset_y = ((tabs_info.size.y - PADDING * 2) + TAB_MARGIN + TAB_PADDING) *
                    tabs_info.interped_current

                render.rect_filled(vec2_t(x, y + offset_y), vec2_t(x + tabs_info.size.x, y + offset_y + tabs_info.size.y),
                    COLORS.TAB_BUTTON:alpha_modulate(alpha), ROUNDING - PADDING);
                render.rect(vec2_t(x, y + offset_y), vec2_t(x + tabs_info.size.x, y + offset_y + tabs_info.size.y),
                    COLORS.OUTLINE:alpha_modulate(alpha), ROUNDING - PADDING);

                local m_y = y;

                local tab_max_width = 0;

                local current_tab = 0;

                for i = 1, #tabs do
                    local tab = tabs[i];
                    local name = tab.name;
                    local icon = tab.icon;
                    local measure = render.calc_text_size(name, FONTS.TAB);
                    local icon_measure = render.calc_text_size(icon, FONTS.ICON)

                    local width, height = measure.x, measure.y; do
                        local new_padding = PADDING * 2;

                        local width = width + new_padding
                        local height = height + new_padding

                        if width > tab_max_width then
                            tab_max_width = width;
                        end

                        tabs_info.size.y = height;
                        tabs_info.size.x = tab_max_width;
                    end

                    if tab_max_width < TAB_WIDTH then
                        tab_max_width = TAB_WIDTH
                    end

                    local pct = 0;

                    if in_bounds(vec2_t(x, m_y), vec2_t(x + tab_max_width, m_y + height + PADDING * 2), mouse) then
                        if is_lmb then
                            selected.predicted_tab = tab;
                        end

                        allow_dragging = false;
                        pct = .5;
                    end

                    if selected.predicted_tab == tab then
                        pct = 1;
                    end

                    pct = pct * alpha;

                    tab.pct = tweening:interp(tab.pct, pct, ANIM_SPEED);

                    local text_color = COLORS.TEXT_INACTIVE:lerp(tab.pct > .5 and color_t(1, 1, 1, 1) or COLORS.TEXT,
                        tab.pct);

                    render.text(icon, FONTS.ICON, vec2_t(x, m_y - 1) + PADDING, self.color:alpha_modulate(alpha));
                    render.text(name, FONTS.TAB, vec2_t(x + 28, m_y - 1) + PADDING,
                        text_color:alpha_modulate(alpha, true));

                    if selected.tab == tab then
                        tabs_info.current = i - 1
                    end

                    m_y = m_y + measure.y;
                    m_y = m_y + TAB_MARGIN;
                    m_y = m_y + TAB_PADDING;
                end

                tabs_info.interped_current = tweening:interp(tabs_info.interped_current, tabs_info.current,
                    ANIM_SPEED * .5)

                y = y - PADDING - LOGO_HEIGHT;

                local measure_logo = render.calc_text_size(script_name, FONTS.LOGO)

                render.text(script_name, FONTS.LOGO,
                    vec2_t(x + tab_max_width * .5 - measure_logo.x * .5, y + LOGO_HEIGHT * .5 - measure_logo.y * .5) + 1,
                    self.color:alpha_modulate(alpha));
                render.text(script_name, FONTS.LOGO,
                    vec2_t(x + tab_max_width * .5 - measure_logo.x * .5, y + LOGO_HEIGHT * .5 - measure_logo.y * .5),
                    color_t(1, 1, 1, alpha));

                render.rect_filled(vec2_t(x, y + LOGO_HEIGHT - 2), vec2_t(x + tab_max_width, y + LOGO_HEIGHT),
                    COLORS.OUTLINE:alpha_modulate(alpha))

                x = x + PADDING + tab_max_width;

                render.rect_filled(vec2_t(x, position.y), position + size.current,
                    COLORS.BACKGROUND_ITEMS:alpha_modulate(alpha), ROUNDING);

                render.push_clip_rect(vec2_t(x - 1, position.y - 1), vec2_t(x + 12, position.y + size.current.y + 1));
                render.rect(vec2_t(x - 1, position.y - 1), position + size.current + vec2_t(0, 1),
                    COLORS.OUTLINE:alpha_modulate(alpha), ROUNDING);
                render.pop_clip_rect();

                if this_tab ~= nil then
                    local items = this_tab.items;

                    local column_width = ((size.init.x - tab_max_width) * .5) - PADDING * 2.5;
                    local column_y = y;
                    local old_y = y;

                    x = x + PADDING

                    render.push_clip_rect(position, position + size.current)

                    for i = 1, #items do
                        local column = items[i];

                        local alpha = alpha * column.pct

                        local name = column.__name
                        local measure = render.calc_text_size(name, FONTS.COLUMN)

                        column.pct = tweening:interp(column.pct, items_alpha, ANIM_SPEED)

                        y = column_y;

                        render.rect_filled(vec2_t(x, y + measure.y + PADDING * 2),
                            vec2_t(x + column_width, y + size.current.y - PADDING),
                            COLORS.BACKGROUND_COLUMN:alpha_modulate(alpha), ROUNDING - PADDING);
                        render.rect(vec2_t(x, y + measure.y + PADDING * 2),
                            vec2_t(x + column_width, y + size.current.y - PADDING), COLORS.OUTLINE:alpha_modulate(alpha),
                            ROUNDING - PADDING);
                        render.text(name, FONTS.COLUMN, vec2_t(x + PADDING, y + PADDING * 1.50),
                            COLORS.HEADER_TEXT:alpha_modulate(alpha))

                        y = y + PADDING * 2.5

                        local y = round(y + measure.y + PADDING)

                        for _, item in pairs(column.items) do
                            local instanceof = getmetatable(item);
                            local x = x + PADDING * 1.5;
                            local column_width = column_width - PADDING * 1.5;

                            if item.offset_pct == nil then
                                item.offset_pct = 0.;
                            end

                            item.offset_pct = tweening:interp(item.offset_pct, item:visibility() and 1 or 0, .05);

                            local item_alpha = items_alpha * column.pct * item.offset_pct;
                            if instanceof == switch then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                    local add, gear_data = gui_render:switch(item, vec2_t(x, y), column_width, item_alpha,
                                        mouse_data, false, true)
                                    local path = f("%s.%s.%s", this_tab.name, column.__name, item.name)

                                    if gear_data then
                                        gear_popups[path] = gear_data
                                    end
                                    y = y + add;
                                end
                            end

                            if instanceof == slider then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, is_left_button = is_left_button, pos = mouse }
                                    local add, gear_data = gui_render:slider(item, vec2_t(x, y), column_width, item_alpha,
                                        mouse_data, false, true)
                                    local path = f("%s.%s.%s", this_tab.name, column.__name, item.name)

                                    if gear_data then
                                        gear_popups[path] = gear_data
                                    end

                                    y = y + add
                                end
                            end

                            if instanceof == button then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, is_left_button = is_left_button, pos = mouse }
                                    local add = gui_render:button(item, vec2_t(x, y), column_width, item_alpha,
                                        mouse_data, false)

                                    y = y + add
                                end
                            end

                            if instanceof == label then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                    local add, gear_data = gui_render:label(item, vec2_t(x, y), column_width, item_alpha,
                                        mouse_data, false, true)
                                    local path = f("%s.%s.%s", this_tab.name, column.__name, item.name)

                                    if gear_data then
                                        gear_popups[path] = gear_data
                                    end

                                    y = y + add
                                end
                            end

                            if instanceof == selectable then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                    local add, gear_data = gui_render:selectable(item, vec2_t(x, y), column_width,
                                        item_alpha, mouse_data, false, true)
                                    local path = f("%s.%s.%s", this_tab.name, column.__name, item.name)

                                    if gear_data then
                                        gear_popups[path] = gear_data
                                    end

                                    y = y + add;
                                end
                            end

                            if instanceof == hotkey then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = {
                                        is_lmb = is_lmb,
                                        is_rmb = is_rmb,
                                        is_left_button =
                                            is_left_button,
                                        is_right_button = is_right_button,
                                        pos = mouse
                                    }
                                    local add = gui_render:hotkey(item, vec2_t(x, y), column_width, item_alpha,
                                        mouse_data, false)

                                    y = y + add
                                end
                            end

                            if instanceof == input then
                                if item.offset_pct > 0.1 then
                                    local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                    local add = gui_render:input(item, vec2_t(x, y), column_width, item_alpha, mouse_data,
                                        false)

                                    y = y + add * item.offset_pct;
                                end
                            end

                            if instanceof == color_picker then
                                local mouse_data = {
                                    is_lmb = is_lmb,
                                    is_rmb = is_rmb,
                                    is_left_button = is_left_button,
                                    pos =
                                        mouse
                                }
                                local add = gui_render:color_picker(item, vec2_t(x, y), column_width, item_alpha,
                                    mouse_data, false)

                                y = y + add;
                            end
                        end

                        if (y - old_y) + PADDING > size.min.y then
                            size.min.y = (y - old_y) + PADDING
                        end

                        x = round(x + column_width + PADDING);
                    end

                    render.pop_clip_rect();

                    for _, popup_data in pairs(gear_popups) do
                        local popup_item = popup_data.item
                        local popup_x = popup_data.pos.x
                        local popup_y = popup_data.pos.y
                        local pct = popup_data.pct

                        local popup_width = 250
                        local popup_item_height = 20

                        if not popup_data.item.__gear.cached_height then
                            popup_data.item.__gear.cached_height = (#popup_data.item.__gear.items * (popup_item_height * .5 + ITEM_MARGIN)) +
                                PADDING
                        end

                        if pct > 0.1 then
                            local popup_height = popup_data.item.__gear.cached_height

                            local popup_alpha = items_alpha * pct

                            render.rect_filled(vec2_t(popup_x, popup_y),
                                vec2_t(popup_x + popup_width, popup_y + popup_height),
                                COLORS.BACKGROUND_COLUMN:alpha_modulate(popup_alpha), ROUNDING - PADDING)
                            render.rect(vec2_t(popup_x, popup_y), vec2_t(popup_x + popup_width, popup_y + popup_height),
                                COLORS.OUTLINE:alpha_modulate(popup_alpha), ROUNDING - PADDING)

                            local gear_y = popup_y + PADDING * 1.5

                            render.push_clip_rect(vec2_t(popup_x, popup_y),
                                vec2_t(popup_x + popup_width, popup_y + popup_height))
                            for _, item in pairs(popup_item.__gear.items) do
                                local instanceof = getmetatable(item)
                                local popup_width = popup_width - PADDING * 1.5;

                                if item.offset_pct == nil then
                                    item.offset_pct = 1
                                end

                                item.offset_pct = tweening:interp(item.offset_pct, item:visibility() and pct or 0, .05)

                                local x, y = popup_x + PADDING * 1.5, gear_y

                                local item_alpha = popup_alpha * item.offset_pct

                                if instanceof == switch then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                        local add = gui_render:switch(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == label then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                        local add = gui_render:label(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == slider then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = {
                                            is_lmb = is_lmb,
                                            is_left_button = is_left_button,
                                            pos =
                                                mouse
                                        }
                                        local add = gui_render:slider(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == input then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                        local add = gui_render:input(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == button then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = {
                                            is_lmb = is_lmb,
                                            is_left_button = is_left_button,
                                            pos =
                                                mouse
                                        }
                                        local add = gui_render:button(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == selectable then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = { is_lmb = is_lmb, pos = mouse }
                                        local add = gui_render:selectable(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == hotkey then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = {
                                            is_lmb = is_lmb,
                                            is_rmb = is_rmb,
                                            is_left_button =
                                                is_left_button,
                                            is_right_button = is_right_button,
                                            pos = mouse
                                        }
                                        local add = gui_render:hotkey(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end

                                if instanceof == color_picker then
                                    if item.offset_pct > 0.1 then
                                        local mouse_data = {
                                            is_lmb = is_lmb,
                                            is_rmb = is_rmb,
                                            is_left_button =
                                                is_left_button,
                                            is_right_button = is_right_button,
                                            pos = mouse
                                        }
                                        local add = gui_render:color_picker(item, vec2_t(x, y), popup_width, item_alpha,
                                            mouse_data, true)

                                        gear_y = gear_y + add
                                    end
                                end
                            end

                            render.pop_clip_rect()

                            popup_data.item.__gear.cached_height = (gear_y - popup_y) + PADDING

                            -- Close popup if clicked outside
                            if pct == 1 and not is_interacting and is_lmb and not in_bounds(vec2_t(popup_x, popup_y), vec2_t(popup_x + popup_width, popup_y + popup_height), mouse) then
                                popup_item.__gear.opened = false
                            end
                        end
                    end


                    local columns_width = (column_width + PADDING) * #items

                    size.min.x = round(PADDING + tab_max_width + (PADDING * 2 + columns_width))

                    if size.min.y < size.init.y or #items == 0 then
                        size.min.y = size.init.y
                    end

                    -- local absolute_column_width = PADDING * 3 + column_width
                    -- local total_width = PADDING + tab_max_width + absolute_column_width + 1

                    if size.min.x < size.init.x then
                        size.min.x = size.init.x
                    end
                end
                -- print(size.min.y)
                size.current.y = tweening:interp(size.current.y, size.min.y, ANIM_SPEED);
                size.current.x = tweening:interp(size.current.x, size.min.x, ANIM_SPEED);
            end

            for i = 1, #post_render.data do
                local data = post_render.data[i]
                if data then
                    if data.type == "push_clip_rect" then
                        render.push_clip_rect(data.from, data.to, data.intersect_with_current_clip_rect)
                    end

                    if data.type == "switch" then
                        render.switch(data.from, data.to, data.background_color, data.circle_color, data.pct)
                    end

                    if data.type == "rect_filled" then
                        render.rect_filled(data.from, data.to, data.color, data.r)
                    end

                    if data.type == "rect" then
                        render.rect(data.from, data.to, data.color, data.r)
                    end

                    if data.type == "rect_filled_fade" then
                        render.rect_filled_fade(data.from, data.to, data.color_a, data.color_b, data.color_c,
                            data.color_d)
                    end

                    if data.type == "circle" then
                        local fn = data.fill and render.circle_filled or render.circle
                        fn(data.pos, data.r, data.s, data.color)
                    end

                    if data.type == "text" then
                        render.text(data.text, data.font, data.pos, data.color)
                    end

                    if data.type == "pop_clip_rect" then
                        render.pop_clip_rect()
                    end
                end
            end

            local avatar_size = 15
            local avatar_pos = position + vec2_t(avatar_size + PADDING * 1.5, size.current.y - avatar_size - PADDING * 2)

            render.circle_filled(avatar_pos, 15, 30, color_t(0.05, 0.05, 0.05, alpha))
            local text_size = render.calc_text_size("?", FONTS.USERNAME)
            render.text("?", FONTS.USERNAME, avatar_pos - vec2_t(text_size.x / 2 - 1, text_size.y / 2),
                color_t(1, 1, 1, alpha))
            render.circle(avatar_pos, avatar_size, 30, color_t(.8, .8, .8, alpha))

            -- if avatar then
            -- end

            render.text(get_user_name(), FONTS.USERNAME,
                position + vec2_t(avatar_size * 2 + PADDING * 2.5, size.current.y - avatar_size * 2 - PADDING),
                color_t(1, 1, 1, alpha))

            if is_left_button then
                if allow_dragging and is_lmb and in_bounds(position, position + size.current, mouse) then
                    windows:set_focus "GUI"
                    drag_delta = position - mouse;
                end

                if drag_delta ~= nil then
                    position.x = math.max(math.min(mouse.x + drag_delta.x, screen.x - size.current.x * .5),
                        -size.current.x * .5);
                    position.y = math.max(math.min(mouse.y + drag_delta.y, screen.y - size.current.y * .5),
                        -size.current.y * .5);
                end
            else
                drag_delta = nil;
            end
        end
    end

    function gui:dependeces()
        for k, v in pairs(dependeces) do
            v()
        end
    end

    function gui:proccess_callbacks()
        for k, v in pairs(callbacks) do
            v()
        end
    end

    function gui:process_hotkeys()
        for i, item in ipairs(hotkeys) do
            local item_key = item:get().key;
            local item_mode = item:get().mode

            if item_mode == 0 then
                item.active = true;
            elseif item_mode == 1 then
                item.active = c_input:is_key_pressed(item_key)
            elseif item_mode == 2 then
                if c_input:is_key_clicked(item_key) then
                    item.active = not item.active
                end
            else
                item.active = false;
            end
        end
    end

    function gui:traverse()
        local items = {}

        for _, tab in pairs(tabs) do
            if not items[tab.name] then
                items[tab.name] = {}
            end

            for __, column in pairs(tab.items) do
                if not items[tab.name][column.__name] then
                    items[tab.name][column.__name] = {}
                end

                for ___, item in pairs(column.items) do
                    -- local path = f("%s::%s::%s", tab.name, column.__name, item.name)

                    if not items[tab.name][column.__name][item.name] then
                        items[tab.name][column.__name][item.name] = item
                    end

                    if item.__gear then
                        for k, gear_item in pairs(item.__gear.items) do
                            -- local path = f("%s::%s", path, gear_item.name)
                            local name = f("%s::%s", item.name, gear_item.name)

                            if not items[tab.name][column.__name][name] then
                                items[tab.name][column.__name][name] = gear_item
                            end
                        end
                    end
                end
            end
        end

        return items
    end

    function gui:save()
        local cfg = {}
        local items = self:traverse()

        for tab_name, tab in pairs(items) do
            if not cfg[tab_name] then
                cfg[tab_name] = {}
            end

            for column_name, column in pairs(tab) do
                if not cfg[tab_name][column_name] then
                    cfg[tab_name][column_name] = {}
                end

                for item_name, item in pairs(column) do
                    local instanceof = getmetatable(item)

                    if not cfg[tab_name][column_name][item_name] and not (instanceof == label or instanceof == button) then
                        local value = item:get()

                        if instanceof == color_picker then
                            value = f("#%s", value:to_hex())
                        end

                        cfg[tab_name][column_name][item_name] = value
                    end
                end
            end
        end

        return cfg
    end

    function gui:load(cfg)
        local items = self:traverse()

        for tab_name, tab in pairs(cfg) do
            if items[tab_name] then
                for column_name, column in pairs(tab) do
                    if items[tab_name][column_name] then
                        for item_name, value in pairs(column) do
                            if items[tab_name][column_name][item_name] then
                                if type(value) == "string" and value:find "#" then
                                    value = color_t(string.rgba(value))
                                end

                                items[tab_name][column_name][item_name]:set(value)
                            end
                        end
                    end
                end
            end
        end
    end
end


return gui

end)
__bundle_register("render/tweening", function(require, _LOADED, __bundle_register, __bundle_modules)
local tweening = {}; do
    --- @private
    local abs, floor, ceil = math.abs, math.floor, math.ceil;
    local frametime = render.frame_time;

    local function linear(t, b, c, d)
        return c * t / d + b;
    end

    local function solve(easing_fn, prev, new, clock, duration)
        if not prev then
            color_print "cannot find preview value";
            return
        end

        if not new then
            color_print "cannot find new value";
            return
        end

        if type(new) == "boolean" then new = new and 1 or 0 end
        if type(prev) == "boolean" then prev = prev and 1 or 0 end

        prev = easing_fn(clock, prev, new - prev, duration);

        if type(prev) == "number" then
            if abs(new - prev) < .01 then
                return new;
            end

            local fmod = prev % 1;

            if fmod < .001 then
                return floor(prev);
            end

            if fmod > .999 then
                return ceil(prev);
            end
        end

        return prev;
    end

    --- @public
    function tweening:interp(a, b, t, easing_fn)
        easing_fn = easing_fn or linear;

        if type(b) == "boolean" then
            b = b and 1 or 0;
        end

        return solve(easing_fn, a, b, frametime(), t);
    end
end

return tweening

end)
__bundle_register("render/windows", function(require, _LOADED, __bundle_register, __bundle_modules)
local c_input = require("engine/input")
local tweening = require("render/tweening")
local utils = require("core/utils")

local screen = render.screen_size()

local windows = {}; do
    local window_list = {}
    local dragged_window = nil
    local hovered_window = nil
    local group = nil

    local background_alpha = 0

    local function is_colliding(point, pos, size)
        return point.x >= pos.x and point.x <= pos.x + size.x and
            point.y >= pos.y and point.y <= pos.y + size.y
    end

    local function clamp_position(pos, min, max)
        return vec2_t(clamp(pos.x, min.x, max.x), clamp(pos.y, min.y, max.y))
    end

    local mouse = {}; do
        mouse.pos = vec2_t(0, 0)
        mouse.prev_pos = vec2_t(0, 0)
        mouse.delta = vec2_t(0, 0)
        mouse.down = false
        mouse.clicked = false
        mouse.down_duration = 0

        function mouse.update()
            local cursor = c_input:mouse_position()
            local is_down = utils.is_cs2_foreground() and c_input:is_key_pressed(0x01)

            mouse.prev_pos = mouse.pos
            mouse.pos = cursor
            mouse.delta = mouse.pos - mouse.prev_pos
            mouse.down = is_down
            mouse.clicked = is_down and mouse.down_duration < 0
            mouse.down_duration = is_down and (mouse.down_duration < 0 and 0 or mouse.down_duration + 1) or -1
        end
    end

    local c_draggable = {}; do
        local ui_alpha = 0

        ---@param axis? 'x'|'y'
        ---@return number|vector
        function c_draggable:get_pos(axis)
            local pos = vec2_t(self.x:get(), self.y:get())

            if not pos then return vec2_t(0, 0) end

            if axis then
                return pos[axis]
            end

            return vec2_t(pos.x, pos.y)
        end

        ---@param pos number|vector
        ---@param axis? 'x'|'y'
        function c_draggable:set_pos(pos, axis)
            if type(pos) == "number" then
                if axis == "x" then
                    self.pos.x = pos
                elseif axis == "y" then
                    self.pos.y = pos
                end

                self.x:set(self.pos.x)
                self.y:set(self.pos.y)
            else
                self.pos = pos
                self.x:set(self.pos.x)

                self.y:set(self.pos.y)
            end
            return self
        end

        ---@param size number|vector
        ---@param axis? 'x'|'y'
        function c_draggable:set_size(size, axis)
            if type(size) == "number" then
                if axis == "x" then
                    self.size.x = size
                elseif axis == "y" then
                    self.size.y = size
                end
            else
                self.size = size
            end

            return self
        end

        ---@param pos vector
        function c_draggable:set_min(pos)
            self.min = pos
            return self
        end

        ---@param pos vector
        function c_draggable:set_max(pos)
            self.max = pos
            return self
        end

        ---@param rules table<number, { pos: number|vector, end_pos: number|vector|nil, horizontal: boolean }>
        function c_draggable:set_rules(rules)
            self.rules = rules
            return self
        end

        ---@param from_ui? boolean
        function c_draggable:update(from_ui)
            if from_ui then
                local data = vec2_t(self.x:get(), self.y:get())

                if data then
                    if data.x then self:set_pos(data.x, "x") end
                    if data.y then self:set_pos(data.y, "y") end
                end

                return self
            end

            if not self.is_active then return end

            self.is_hovered = is_colliding(mouse.pos, self.pos, self.size)

            self.in_dragging = false

            if self.is_hovered then
                hovered_window = self
            end

            if self.is_hovered and mouse.clicked then
                dragged_window = self
                self.offset = self.pos - mouse.pos
            end

            local offset_pos = self.offset and mouse.pos + self.offset or self.pos
            local preferred = { x = nil, y = nil }

            local center = self.pos + self.size * 0.5
            local offset_center = offset_pos + self.size * 0.5

            local control_down = c_input:is_key_pressed(0xA2)

            for i, rule in ipairs(self.rules) do
                local pos = rule.pos
                local end_pos = rule.end_pos
                local is_horizontal = rule.horizontal
                local animation = self.animations[i] or (function()
                    self.animations[i] = 0
                    return self.animations[i]
                end)()

                local axis = is_horizontal and "x" or "y"
                local dist = math.abs(offset_center[axis] - pos[axis])

                if dragged_window == self and not control_down then
                    if dist < 8 then
                        preferred[axis] = pos[axis] - self.size[axis] * 0.5
                    end
                end

                local align_dist = math.abs(center[axis] - pos[axis])
                self.animations[i] = tweening:interp(self.animations[i],
                    (dragged_window == self and not control_down) and (align_dist < 10 and 120 / 255 or 60 / 255) or 0,
                    0.05)
                local alpha = animation

                local line_start = is_horizontal and vec2_t(pos.x, end_pos and pos.y or 0) or
                    vec2_t(end_pos and pos.x or 0, pos.y)
                local line_end = is_horizontal and vec2_t(pos.x, end_pos and end_pos.y or screen.y) or
                    vec2_t(end_pos and end_pos.x or screen.x, pos.y)

                render.line(line_start, line_end, color_t(1, 1, 1, alpha))
            end

            if dragged_window == self then
                local new_pos = vec2_t(preferred.x or offset_pos.x, preferred.y or offset_pos.y)

                local min_pos = self.min
                local max_pos = self.max

                if self.is_centered then
                    min_pos = self.min - self.size * 0.5
                    max_pos = self.max - self.size * 0.5
                end

                min_pos = clamp_position(min_pos, vec2_t(0, 0), screen - self.size)
                max_pos = clamp_position(max_pos, vec2_t(0, 0), screen - self.size)

                local clamped_pos = clamp_position(new_pos, min_pos, max_pos)

                if self.on_dragging then
                    self:on_dragging()
                end

                self.in_dragging = true

                self:set_pos(clamped_pos)
            end

            self.x:set(self.pos.x)
            self.y:set(self.pos.y)

            return self
        end

        function c_draggable:render()
            local pos = self.pos

            ui_alpha = tweening:interp(ui_alpha, ui.is_menu_opened(), .05)

            self.animations.hover = tweening:interp(self.animations.hover,
                self.is_active and (self.is_hovered and (c_input:is_key_pressed(0x01) and 0.4 or 0.2) or 0) or 0, 0.05)
            local hover = self.animations.hover * ui_alpha

            if hover > 0 then
                render.rect_filled(pos - 1, pos + self.size + 1, color_t(1, 1, 1, 170 / 255 * hover), 4)
            end

            self.animations.border = tweening:interp(self.animations.border,
                (self.is_active and self.render_border and dragged_window == self) and 1 or 0, 0.05)

            local border = self.animations.border * ui_alpha

            if border > 0 then
                render.rect_filled(self.min, self.max + self.size, color_t(1, 1, 1, .5 * border), 1, 4)
            end

            if self.pos < vec2_t(0, 0) then
                self:set_pos(vec2_t(0, 0))
            elseif self.pos > screen - self.size then
                self:set_pos(screen - self.size)
            end

            if self.render_callback then
                self.render_callback(self)
            end
        end

        c_draggable.__index = c_draggable
    end

    windows.items = {}
    windows.list = window_list

    ---@param name string
    function windows.new(name)
        local instance = {
            name = name,
            x = group:slider(name .. " x", 1, screen.x, 1),
            y = group:slider(name .. " y", 1, screen.y, 1),

            offset = vec2_t(0, 0),
            pos = vec2_t(0, 0),
            size = vec2_t(0, 0),
            min = vec2_t(0, 0),
            max = vec2_t(screen.x, screen.y),
            rules = {},

            is_centered = true,
            is_active = true,
            is_hovered = false,
            is_dragging = false,

            render_border = false,
            render_callback = nil,
            on_release = nil,
            on_dragging = nil,

            animations = {
                rulers = {},
                border = 0,
                hover = 0
            }
        }

        instance.x:visibility(false)
        instance.y:visibility(false)

        table.insert(windows.items, { x = instance.x, y = instance.y })

        setmetatable(instance, c_draggable)
        table.insert(window_list, instance)

        return instance
    end

    function windows:get_focus()
        return dragged_window
    end

    function windows:set_focus(window)
        dragged_window = window
    end

    function windows:set_group(value)
        group = value
    end

    register_callback("paint", function()
        mouse.update()

        if not mouse.down then
            if dragged_window and dragged_window.on_release then
                dragged_window:on_release()
            end
            dragged_window = nil
        end

        background_alpha = tweening:interp(background_alpha, (dragged_window ~= nil and windows.background) and 1 or 0,
            0.075)

        if background_alpha > 0 then
            render.rect_filled(vec2_t(0, 0), screen, color_t(0, 0, 0, 75 / 255 * background_alpha))
        end

        for i = #window_list, 1, -1 do
            local window = window_list[i]

            if ui.is_menu_opened() and utils.is_cs2_foreground() then
                window:update()
            end

            window:render()
        end
    end)
end

return windows

end)
__bundle_register("engine/vector", function(require, _LOADED, __bundle_register, __bundle_modules)
local vector; do
    local vec2_mt = getmetatable(vec2_t(0, 0))

    function vec2_mt:__lt(b)
        return self.x < b.x and self.y < b.y
    end

    function vec2_mt:__le(b)
        return self.x <= b.x and self.y <= b.y
    end

    function vec3_t:angle_to(to)
        local direction = to - self
        local length = direction:length()

        local pitch = -math.deg(math.asin(direction.z / length))
        pitch = clamp(pitch, -89.0, 89.0)

        local yaw = normalize_yaw(math.deg(math.atan2(direction.y, direction.x)))

        return angle_t(pitch, yaw, 0)
    end

    vector = function(...)
        local args = select("#", ...)

        if args == 2 then
            return vec2_t(...)
        elseif args == 3 then
            return vec3_t(...)
        elseif args == 4 then
            return vec4_t(...)
        end
    end
end

return vector

end)
__bundle_register("engine/cvar", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef [[
    typedef union {
        bool i1;
        int16_t i16;
        uint16_t u16;
        int32_t i32;
        uint32_t u32;
        int64_t i64;
        uint64_t u64;
        float fl;
        double db;
        const char* sz;
        void* clr;
        void* vec2;
        void* vec3;
        void* vec4;
        void* ang;
    } CVValue_t;

    typedef struct {
        const char* szName;           // 0x00
        CVValue_t* m_pDefaultValue;   // 0x08
        char pad_0010[0x10];          // 0x10
        const char* szDescription;    // 0x20
        uint32_t nType;               // 0x28
        uint32_t nRegistered;         // 0x2C
        uint32_t nFlags;              // 0x30
        char pad_0034[0x24];          // 0x34
        CVValue_t value;              // 0x58
    } CConVar;
]]

local utils = require("core/utils")

---@note: Просто ебаный шизофренник писал этот код на плюсах, я пока разобрал думал убьюсь нахуй
-- credits: https://github.com/or75/Andromeda-CS2-Base/blob/master/Andromeda-CS2-Base/Andromeda-CS2-Base/CS2/SDK/Interface/IEngineCvar.hpp

local IEngineCVar = {}; do
    local FCVAR_HIDDEN = bit.lshift(1, 4)
    local engine_cvar_interface_version = "VEngineCvar007"

    local gEngineCvar = utils.create_interface("tier0.dll", engine_cvar_interface_version)


    local IEngineCVar_Search = {
        GetFirstCvarIteratorFn = "48 89 74 24 ? 48 89 7C 24 ? 41 56 48 83 EC ? 48 8B F2 48 8D B9",
        GetNextCvarIteratorFn =
        "40 53 55 56 41 56 41 57 48 83 EC ? 49 8B D8 48 8D B1 ? ? ? ? 4C 8B F2 48 8B E9 FF 15 ? ? ? ? 8B D0 39 46 ? 75 ? 66 FF 46 ? EB ? 8B 06 90 85 C0 75 ? B9 ? ? ? ? F0 0F B1 0E 75 ? 66 C7 46 ? ? ? 89 56 ? EB ? 48 8B CE E8 ? ? ? ? 41 BF ? ? ? ? 48 89 7C 24 ? 4C 89 6C 24 ? 66 41 3B DF 74 ? 41 BD ? ? ? ? 66 44 85 6D",
        FindVarByIndexFn =
        "48 89 5C 24 ? 48 89 74 24 ? 57 48 83 EC ? 48 8B DA 48 8D B9 ? ? ? ? 48 8B F1 FF 15 ? ? ? ? 8B D0 39 47 ? 75 ? 66 FF 47 ? EB ? 8B 07 90 85 C0 75 ? B9 ? ? ? ? F0 0F B1 0F 75 ? 66 C7 47 ? ? ? 89 57 ? EB ? 48 8B CF E8 ? ? ? ? BA"
    }

    local pCConVar = ffi.typeof "CConVar*"
    local pUint64 = ffi.typeof "uint64_t*"

    function IEngineCVar.Initialize()
        IEngineCVar.GetFirstCvarIterator_addr = assert(
            find_pattern("tier0.dll", IEngineCVar_Search.GetFirstCvarIteratorFn), "GetFirstCvarIterator outdated")
        IEngineCVar.GetNextCvarIterator_addr = assert(
            find_pattern("tier0.dll", IEngineCVar_Search.GetNextCvarIteratorFn), "GetNextCvarIterator outdated")
        IEngineCVar.FindVarByIndex_addr = assert(find_pattern("tier0.dll", IEngineCVar_Search.FindVarByIndexFn),
            "FindVarByIndex outdated")

        if IEngineCVar.GetFirstCvarIterator_addr then
            IEngineCVar.GetFirstCvarIterator = ffi.cast("void(*)(void*, uint64_t*)",
                IEngineCVar.GetFirstCvarIterator_addr)
        end

        if IEngineCVar.GetNextCvarIterator_addr then
            IEngineCVar.GetNextCvarIterator = ffi.cast("void(*)(void*, uint64_t*, uint64_t)",
                IEngineCVar.GetNextCvarIterator_addr)
        end

        if IEngineCVar.FindVarByIndex_addr then
            IEngineCVar.FindVarByIndex = ffi.cast("void*(*)(void*, uint64_t)", IEngineCVar.FindVarByIndex_addr)
        end
    end

    function IEngineCVar:Find(convar_name)
        if not self.GetFirstCvarIterator or not self.GetNextCvarIterator or not self.FindVarByIndex then
            return nil
        end

        local idx = ffi.new("uint64_t[1]", 0)
        self.GetFirstCvarIterator(gEngineCvar, idx)

        while idx[0] ~= 0xFFFFFFFF do
            local pConVar = self.FindVarByIndex(gEngineCvar, idx[0])

            if pConVar ~= nil then
                local convar = ffi.cast(pCConVar, pConVar)
                if ffi.string(convar.szName) == convar_name then
                    return convar
                end
            end

            self.GetNextCvarIterator(gEngineCvar, idx, idx[0])
        end

        return nil
    end

    function IEngineCVar:UnlockHiddenCVars()
        if not self.GetFirstCvarIterator or not self.GetNextCvarIterator or not self.FindVarByIndex then
            return
        end

        local idx = ffi.new("uint64_t[1]", 0)
        self.GetFirstCvarIterator(gEngineCvar, idx)

        while idx[0] ~= 0xFFFFFFFF do
            local pConVar = self.FindVarByIndex(gEngineCvar, idx[0])

            if pConVar ~= nil then
                local convar = ffi.cast(pCConVar, pConVar)
                if bit.band(convar.nFlags, FCVAR_HIDDEN) ~= 0 then
                    convar.nFlags = bit.band(convar.nFlags, bit.bnot(FCVAR_HIDDEN))
                end
            end

            self.GetNextCvarIterator(gEngineCvar, idx, idx[0])
        end
    end
end

IEngineCVar.Initialize()
-- IEngineCVar:UnlockHiddenCVars()
-- print("test")
local cvar = {}; do
    local cache = {}
    local EConVarType = {
        Invalid = -1,
        Bool = 0,
        Int16 = 1,
        UInt16 = 2,
        Int32 = 3,
        UInt32 = 4,
        Int64 = 5,
        UInt64 = 6,
        Float32 = 7,
        Float64 = 8,
        String = 9,
        Color = 10,
        Vector2 = 11,
        Vector3 = 12,
        Vector4 = 13,
        Qangle = 14,
        MAX = 15
    }

    local int2type = {
        [-1] = nil,
        [0] = "i1",
        [1] = "i16",
        [2] = "u16",
        [3] = "i32",
        [4] = "u32",
        [5] = "i64",
        [6] = "u64",
        [7] = "fl",
        [8] = "db",
        [9] = "sz"
        -- а дальше иди нахуй
    }

    local c_convar = {
        __index = {
            bool = function(self, value)
                if not self[0] then
                    return
                end

                if self[0].nType ~= EConVarType.Bool then
                    return
                end

                if value ~= nil then
                    self[0].value.i1 = value
                    return
                end

                return self[0].value.i1
            end,
            int = function(self, value)
                if not self[0] then
                    return
                end

                if self[0].nType == EConVarType.Int16 or self[0].nType == EConVarType.UInt16
                    or self[0].nType == EConVarType.Int32 or self[0].nType == EConVarType.UInt32
                    or self[0].nType == EConVarType.Int64 or self[0].nType == EConVarType.UInt64 then
                    local field = int2type[self[0].nType]
                    if not field then
                        return
                    end

                    if value ~= nil then
                        self[0].value[field] = value
                        return
                    end

                    return self[0].value[field]
                end
            end,
            float = function(self, value)
                if not self[0] then
                    return
                end

                if self[0].nType == EConVarType.Float32 or self[0].nType == EConVarType.Float64 then
                    local field = int2type[self[0].nType]

                    if not field then
                        return
                    end

                    if value ~= nil then
                        self[0].value[field] = value
                        return
                    end

                    return self[0].value[field]
                end
            end,
            string = function(self, value)
                if not self[0] then
                    return
                end

                if self[0].nType ~= EConVarType.String then
                    return
                end

                local field = int2type[self[0].nType]
                if not field then
                    return
                end

                if value ~= nil then
                    self[0].value[field] = ffi.cast("const char*", value)
                    return
                end

                return ffi.string(self[0].value[field])
            end
        }
    }
    setmetatable(cvar, {
        __index = function(self, key)
            if cache[key] then
                return cache[key]
            end

            local mt = setmetatable({ [0] = IEngineCVar:Find(key) }, c_convar)
            cache[key] = mt

            return mt
        end
    })
end

return cvar

end)
__bundle_register("core/file_system", function(require, _LOADED, __bundle_register, __bundle_modules)
ffi.cdef [[
    int PathFileExistsA(const char* pszPath);
    int CreateDirectoryA(const char *lpPathName, void* lpSecurityAttributes);

    typedef struct {
        uint32_t dwFileAttributes;
        uint32_t ftCreationTime[2];
        uint32_t ftLastAccessTime[2];
        uint32_t ftLastWriteTime[2];
        uint32_t nFileSizeHigh;
        uint32_t nFileSizeLow;
        uint32_t dwReserved0;
        uint32_t dwReserved1;
        char     cFileName[260];
        char     cAlternateFileName[14];
    } WIN32_FIND_DATAA;

    void* FindFirstFileA(const char* lpFileName, WIN32_FIND_DATAA* lpFindFileData);
    int FindNextFileA(void* hFindFile, WIN32_FIND_DATAA* lpFindFileData);
    int FindClose(void* hFindFile);
    int DeleteFileA(const char* lpFileName);
]]

local shlwapi = ffi.load("shlwapi.dll")

local fs = {}

function fs.get_files(directory_path, file_format)
    local files = {}
    local find_data = ffi.new("WIN32_FIND_DATAA")

    local search_path = directory_path:gsub("[\\/]$", "") .. "/" .. file_format

    local hFind = ffi.C.FindFirstFileA(search_path, find_data)
    if hFind == ffi.cast("void*", -1) then
        return files
    end

    repeat
        local file_name = ffi.string(find_data.cFileName):gsub("%.%w+$", "")
        if file_name ~= "." and file_name ~= ".." then
            table.insert(files, file_name)
        end
    until ffi.C.FindNextFileA(hFind, find_data) == 0

    ffi.C.FindClose(hFind)
    return files
end

function fs.is_exists(path)
    return shlwapi.PathFileExistsA(path) == 1
end

function fs.create_directory(path)
    if fs.is_exists(path) then return true end
    return ffi.C.CreateDirectoryA(path, nil) ~= 0
end

function fs.write(path, content)
    local file, err = io.open(path, "wb")
    if not file then
        error("Error writing file: " .. (err or "unknown"))
        return false
    end

    file:write(content)
    file:close()
    return true
end

function fs.read(path)
    local file, err = io.open(path, "rb")
    if not file then
        error("Error reading file: " .. (err or "unknown"))
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

function fs.delete(path)
    return ffi.C.DeleteFileA(path) ~= 0
end

return fs

end)
__bundle_register("system/http", function(require, _LOADED, __bundle_register, __bundle_modules)
local http = {}; do
    ffi.cdef [[
        typedef void* HINTERNET;
        typedef unsigned long DWORD;
        typedef int BOOL;

        HINTERNET WinHttpOpen(const wchar_t* userAgent, DWORD accessType, const wchar_t* proxyName, const wchar_t* proxyBypass, DWORD flags);
        HINTERNET WinHttpConnect(HINTERNET session, const wchar_t* serverName, unsigned short serverPort, DWORD reserved);
        HINTERNET WinHttpOpenRequest(HINTERNET connect, const wchar_t* verb, const wchar_t* objectName, const wchar_t* version, const wchar_t* referrer, const wchar_t** acceptTypes, DWORD flags);
        BOOL WinHttpSendRequest(HINTERNET request, const wchar_t* headers, DWORD headersLength, void* optional, DWORD optionalLength, DWORD totalLength, DWORD context);
        BOOL WinHttpReceiveResponse(HINTERNET request, void* reserved);
        BOOL WinHttpQueryHeaders(HINTERNET request, DWORD infoLevel, const wchar_t* name, void* buffer, DWORD* bufferLength, DWORD* index);
        BOOL WinHttpReadData(HINTERNET request, void* buffer, DWORD bytesToRead, DWORD* bytesRead);
        BOOL WinHttpCloseHandle(HINTERNET handle);

        DWORD GetLastError();
    ]];

    local winhttp = ffi.load "WinHttp";
    local C = ffi.C;

    local INTERNET_DEFAULT_HTTP_PORT = 80;
    local INTERNET_DEFAULT_HTTPS_PORT = 443;
    local WINHTTP_FLAG_SECURE = 0x00800000;
    local WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY = 4;
    local WINHTTP_QUERY_STATUS_CODE = 19;
    local WINHTTP_QUERY_FLAG_NUMBER = 0x20000000;

    local function to_wstr(str)
        if not str then return nil; end;
        local len = #str;
        local buf = ffi.new("wchar_t[?]", len + 1);
        for i = 1, len do
            buf[i - 1] = string.byte(str, i);
        end;
        buf[len] = 0;
        return buf;
    end;

    local function headers_to_string(headers)
        if not headers then return nil; end;
        local header_lines = {};
        for key, value in pairs(headers) do
            table.insert(header_lines, key .. ": " .. value);
        end;
        return table.concat(header_lines, "\r\n");
    end;

    local function close_handles(...)
        for i = 1, select("#", ...) do
            local handle = select(i, ...);
            if handle ~= nil and handle ~= ffi.cast("HINTERNET", 0) then
                winhttp.WinHttpCloseHandle(handle);
            end;
        end;
    end;

    local function get_status_code(request)
        local status_code = -1;
        local status_buffer = ffi.new("DWORD[1]", 0);
        local status_buffer_size = ffi.new("DWORD[1]", ffi.sizeof "DWORD");
        status_buffer_size[0] = ffi.sizeof "DWORD";

        local query_flags = bit.bor(WINHTTP_QUERY_STATUS_CODE, WINHTTP_QUERY_FLAG_NUMBER);

        if winhttp.WinHttpQueryHeaders(request, query_flags, nil, status_buffer, status_buffer_size, nil) ~= 0 then
            status_code = status_buffer[0];
            return status_code, nil;
        else
            local error_msg = "WinHttpQueryHeaders failed to retrieve status code. Error: " .. tostring(C.GetLastError());
            return -1, error_msg;
        end;
    end;

    local function read_response(request)
        local buffer_size = 8192;
        local buffer = ffi.new("uint8_t[?]", buffer_size);
        local chunks = {};

        while true do
            local bytesRead = ffi.new("DWORD[1]", 0);
            if winhttp.WinHttpReadData(request, buffer, buffer_size, bytesRead) == 0 then
                break;
            end;

            if bytesRead[0] == 0 then
                break;
            end;

            table.insert(chunks, ffi.string(buffer, bytesRead[0]));
        end;

        return table.concat(chunks);
    end;

    local function parse_url(url)
        local t = {};
        local scheme, host_port, path = url:match "^([hH][tT][tT][pP][sS]?)://([^/]+)(.*)$";

        if not scheme then
            scheme, host_port, path = "http", url, "/";
        end;

        t.https = scheme:lower() == "https";

        local host, port_str = host_port:match "^(.-):(%d+)$";
        if host then
            t.host = host;
            t.port = tonumber(port_str);
        else
            t.host = host_port;
            t.port = nil;
        end;

        t.path = path and (#path > 0 and path or "/") or "/";

        return t;
    end;

    local function perform_request(method, host, options, callback)
        local path = options.path or "/";
        local secure = options.https or false;
        local custom_port = options.port;
        local headers = options.headers;
        local body_data = options.body or "";
        local user_agent = options.user_agent or "LuaHTTP/1.0";

        local port = custom_port or (secure and INTERNET_DEFAULT_HTTPS_PORT or INTERNET_DEFAULT_HTTP_PORT);
        local flags = secure and WINHTTP_FLAG_SECURE or 0;

        local session, connect, request;
        local headers_str = nil;
        local headers_length = 0;

        session = winhttp.WinHttpOpen(to_wstr(user_agent), WINHTTP_ACCESS_TYPE_AUTOMATIC_PROXY, nil, nil, 0);
        if session == nil or session == ffi.cast("HINTERNET", 0) then
            return callback { status = 0, body = "WinHttpOpen failed: " .. tostring(C.GetLastError()) };
        end;

        connect = winhttp.WinHttpConnect(session, to_wstr(host), port, 0);
        if connect == nil or connect == ffi.cast("HINTERNET", 0) then
            close_handles(session);
            return callback { status = 0, body = "WinHttpConnect failed: " .. tostring(C.GetLastError()) };
        end;

        request = winhttp.WinHttpOpenRequest(connect, to_wstr(method), to_wstr(path), nil, nil, nil, flags);
        if request == nil or request == ffi.cast("HINTERNET", 0) then
            close_handles(connect, session);
            return callback { status = 0, body = "WinHttpOpenRequest failed: " .. tostring(C.GetLastError()) };
        end;

        if headers then
            local header_string_lua = headers_to_string(headers);
            headers_str = to_wstr(header_string_lua);
            headers_length = #header_string_lua;
        end;

        local body_bytes = nil;
        local body_length = #body_data;
        if body_length > 0 then
            body_bytes = ffi.new("char[?]", body_length + 1);
            ffi.copy(body_bytes, body_data, body_length);
        end;

        if winhttp.WinHttpSendRequest(request, headers_str, headers_length, body_bytes, body_length, body_length, 0) == 0 then
            close_handles(request, connect, session);
            return callback { status = 0, body = "WinHttpSendRequest failed: " .. tostring(C.GetLastError()) };
        end;

        if winhttp.WinHttpReceiveResponse(request, nil) == 0 then
            close_handles(request, connect, session);
            return callback { status = 0, body = "WinHttpReceiveResponse failed: " .. tostring(C.GetLastError()) };
        end;

        local status_code, status_error = get_status_code(request);

        local body = read_response(request);

        close_handles(request, connect, session);

        if status_error then
            body = "Status Query Error: " .. status_error .. "\n\n" .. body;
            callback { status = -1, body = body };
        else
            callback { status = status_code, body = body };
        end;
    end;

    function http.request(method, url_or_host, options, callback)
        if (callback == nil and type(options) == "function") then
            callback = options;
            options = {};
        end;

        method = string.upper(method or "GET");
        local final_options = options or {};
        local host;

        if url_or_host:match "://" then
            local parsed_url = parse_url(url_or_host);
            host = parsed_url.host;

            final_options.path = final_options.path or parsed_url.path;
            final_options.https = final_options.https or parsed_url.https;
            final_options.port = final_options.port or parsed_url.port;
        else
            host = url_or_host;
        end;

        if not host then
            return callback { status = 0, body = "Invalid or missing host/URL." };
        end;

        if (method == "POST" or method == "PUT") and not final_options.body then
            final_options.body = "";
        elseif (method == "GET" or method == "DELETE") then
            final_options.body = "";
        end;

        perform_request(method, host, final_options, callback);
    end;

    function http.get(url_or_host, options, callback)
        return http.request("GET", url_or_host, options, callback);
    end;

    function http.post(url_or_host, options, callback)
        return http.request("POST", url_or_host, options, callback);
    end;

    function http.put(url_or_host, options, callback)
        return http.request("PUT", url_or_host, options, callback);
    end;

    function http.delete(url_or_host, options, callback)
        return http.request("DELETE", url_or_host, options, callback);
    end;
end;

-- http.get('https://demonside.dev/', function(response)
--     print(response.status);
--     print(response.body);
-- end);

return http

end)
__bundle_register("engine/events", function(require, _LOADED, __bundle_register, __bundle_modules)
local vmt = require("engine/vmt")
local utils = require("core/utils")

local timer = (function()
    ffi.cdef [[
        typedef struct {
            long long QuadPart;
        } LARGE_INTEGER;
        int QueryPerformanceCounter(LARGE_INTEGER* lpPerformanceCount);
        int QueryPerformanceFrequency(LARGE_INTEGER* lpFrequency);
        uint64_t GetTickCount64(void);
        uint32_t timeGetDevCaps(void* ptc, uint32_t cbtc);
    ]]

    local frequency = ffi.new "LARGE_INTEGER"
    local counter = ffi.new "LARGE_INTEGER"

    if ffi.C.QueryPerformanceFrequency(frequency) == 1 then
        local frequency_num = tonumber(frequency.QuadPart)

        return function()
            if ffi.C.QueryPerformanceCounter(counter) == 1 then
                return tonumber(counter.QuadPart) / frequency_num
            end
            return ffi.C.GetTickCount64() / 1000
        end
    end

    return function()
        return ffi.C.GetTickCount64() / 1000
    end
end)()

local NULLPTR = ffi.cast("void*", 0)
local INVALID_HANDLE = ffi.cast("void*", -1)

local function opcode_scan(module, signature)
    local result = find_pattern(module, signature)
    if ffi.cast("void*", result) == NULLPTR then
        return nil
    end;

    return ffi.cast("uintptr_t", result)
end

local create_hook; do
    ffi.cdef [[
        typedef struct Thread32Entry {
            uint32_t dwSize;
            uint32_t cntUsage;
            uint32_t th32ThreadID;
            uint32_t th32OwnerProcessID;
            long tpBasePri;
            long tpDeltaPri;
            uint32_t dwFlags;
        } Thread32Entry;

        int CloseHandle(void*);
        void* GetCurrentProcess();
        uint32_t ResumeThread(void*);
        uint32_t GetCurrentThreadId();
        uint32_t SuspendThread(void*);
        uint32_t GetCurrentProcessId();
        void* OpenThread(uint32_t, int, uint32_t);
        int Thread32Next(void*, struct Thread32Entry*);
        int Thread32First(void*, struct Thread32Entry*);
        void* CreateToolhelp32Snapshot(uint32_t, uint32_t);
        int VirtualProtect(void*, uint64_t, uint32_t, uint32_t*);
    ]];

    local __hooks = {}
    local __threads = {}

    local function Thread(nTheardID)
        local hThread = ffi.C.OpenThread(0x0002, 0, nTheardID);
        if hThread == NULLPTR or hThread == INVALID_HANDLE then
            return false;
        end;

        return setmetatable({
            bValid = true,
            nId = nTheardID,
            hThread = hThread,
            bIsSuspended = false
        }, {
            __index = {
                Suspend = function(self)
                    if self.bIsSuspended or not self.bValid then
                        return false;
                    end;

                    if ffi.C.SuspendThread(self.hThread) ~= -1 then
                        self.bIsSuspended = true;
                        return true;
                    end;

                    return false;
                end,

                Resume = function(self)
                    if not self.bIsSuspended or not self.bValid then
                        return false;
                    end;

                    if ffi.C.ResumeThread(self.hThread) ~= -1 then
                        self.bIsSuspended = false;
                        return true;
                    end;

                    return false;
                end,

                Close = function(self)
                    if not self.bValid then
                        return;
                    end;

                    self:Resume();
                    self.bValid = false;
                    ffi.C.CloseHandle(self.hThread);
                end
            }
        });
    end

    local function UpdateThreadList()
        __threads = {};
        local hSnapShot = ffi.C.CreateToolhelp32Snapshot(0x00000004, 0);
        if hSnapShot == INVALID_HANDLE then
            return false;
        end;

        local pThreadEntry = ffi.new "struct Thread32Entry[1]";
        pThreadEntry[0].dwSize = ffi.sizeof "struct Thread32Entry";
        if ffi.C.Thread32First(hSnapShot, pThreadEntry) == 0 then
            ffi.C.CloseHandle(hSnapShot);
            return false;
        end;

        local nCurrentThreadID = ffi.C.GetCurrentThreadId();
        local nCurrentProcessID = ffi.C.GetCurrentProcessId();
        while ffi.C.Thread32Next(hSnapShot, pThreadEntry) > 0 do
            if pThreadEntry[0].dwSize >= 20 and pThreadEntry[0].th32OwnerProcessID == nCurrentProcessID and pThreadEntry[0].th32ThreadID ~= nCurrentThreadID then
                local hThread = Thread(pThreadEntry[0].th32ThreadID);
                if not hThread then
                    for _, pThread in pairs(__threads) do
                        pThread:Close();
                    end;

                    __threads = {};
                    ffi.C.CloseHandle(hSnapShot);
                    return false;
                end;

                table.insert(__threads, hThread);
            end;
        end;

        ffi.C.CloseHandle(hSnapShot);
        return true;
    end

    local function SuspendThreads()
        if not UpdateThreadList() then
            return false;
        end;

        for _, hThread in pairs(__threads) do
            hThread:Suspend();
        end;

        return true;
    end

    local function ResumeThreads()
        for _, hThread in pairs(__threads) do
            hThread:Resume()
            hThread:Close()
        end
    end

    create_hook = function(pTarget, pDetour, szType)
        assert(type(pDetour) == "function", "create_hook: invalid detour function");
        assert(
            type(pTarget) == "cdata" or type(pTarget) == "userdata" or type(pTarget) == "number" or
            type(pTarget) == "function", "create_hook: invalid target function");
        if not SuspendThreads() then
            ResumeThreads();
            print "create_hook: failed suspend threads";
            return false;
        end;

        local arrBackUp = ffi.new "uint8_t[14]";
        local pTargetFn = ffi.cast(szType, pTarget);
        local arrShellCode = ffi.new("uint8_t[14]", {
            0xFF, 0x25, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
        });

        local __Object = {
            bValid = true,
            bAttached = false,
            pBackup = arrBackUp,
            pTarget = pTargetFn,
            pOldProtect = ffi.new "uint32_t[1]",
            hCurrentProcess = ffi.C.GetCurrentProcess()
        };

        ffi.copy(arrBackUp, pTargetFn, ffi.sizeof(arrBackUp));
        ffi.cast("uintptr_t*", arrShellCode + 0x6)[0] = ffi.cast("uintptr_t", ffi.cast(szType, function(...)
            local bSuccessfully, pResult = pcall(pDetour, __Object, ...);
            if not bSuccessfully then
                __Object:Remove();
                print(("[antiaim]: unexception runtime error -> %s"):format(pResult));
                return pTargetFn(...);
            end;

            return pResult;
        end));

        __Object.__index = setmetatable(__Object, {
            __call = function(self, ...)
                if not self.bValid then
                    return nil;
                end;

                self:Detach();
                local bSuccessfully, pResult = pcall(self.pTarget, ...);
                if not bSuccessfully then
                    self.bValid = false;
                    print(("[antiaim]: runtime error -> %s"):format(pResult));
                    return nil;
                end;

                self:Attach();
                return pResult;
            end,

            __index = {
                Attach = function(self)
                    if self.bAttached or not self.bValid then
                        return false;
                    end;

                    self.bAttached = true;
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), 0x40, self.pOldProtect);
                    ffi.copy(self.pTarget, arrShellCode, ffi.sizeof(arrBackUp));
                    -- ffi.C.FlushInstructionCache(self.hCurrentProcess, self.pTarget, ffi.sizeof(arrBackUp))
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), self.pOldProtect[0], self.pOldProtect);
                    return true;
                end,

                Detach = function(self)
                    if not self.bAttached or not self.bValid then
                        return false;
                    end;

                    self.bAttached = false;
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), 0x40, self.pOldProtect);
                    ffi.copy(self.pTarget, self.pBackup, ffi.sizeof(arrBackUp));
                    -- ffi.C.FlushInstructionCache(self.hCurrentProcess, self.pTarget, ffi.sizeof(arrBackUp))
                    ffi.C.VirtualProtect(self.pTarget, ffi.sizeof(arrBackUp), self.pOldProtect[0], self.pOldProtect);
                    return true;
                end,

                Remove = function(self)
                    if not self.bValid then
                        return false;
                    end;

                    SuspendThreads();
                    self:Detach();
                    ResumeThreads();
                    self.bValid = false;
                end
            }
        });

        __Object:Attach();
        table.insert(__hooks, __Object);
        ResumeThreads();
        return __Object;
    end

    register_callback("unload", function()
        for _, obj in pairs(__hooks) do
            obj:Remove()
        end
    end)
end

local events, debug_enabled = {}, _DEBUG; do
    ffi.cdef [[
        typedef struct Vector {
            float x, y, z;
        } Vector;

        typedef struct Vector4D {
            float x, y, z, w;
        } Vector4D;

        typedef struct CMsgVector {
            char pad_0x0[0x8];
            uint32_t nHasBits;
            uint64_t nCachedBits;
            Vector4D vecValue;
        } CMsgVector;

        typedef struct Repeated {
            int nAllocatedSize;
            void* tElements[255];
        } Repeated;

        typedef struct RepeatedPtrField {
            void* pArena;
            int nCurrentSize;
            int nTotalSize;
            Repeated* pRep;
        } RepeatedPtrField;

        typedef struct CInButtonStatePB {
            char pad_0x0[0x8];
            uint32_t nHasBits;
            uint64_t nCachedBits;
            uint64_t nValue;
            uint64_t nValueChanged;
            uint64_t nValueScroll;
        } CInButtonStatePB;

        typedef struct CBaseUserCmdPB {
            char pad_0x0[0x8];
            uint32_t nHasBits;
            uint64_t nCachedBits;
            RepeatedPtrField subtickMovesField;
            const char* strMoveCrc;
            CInButtonStatePB* pInButtonState;
            CMsgVector* pViewAngles;
            int32_t nLegacyCommandNumber;
            int32_t nClientTick;
            float flForwardMove;
            float flSideMove;
            float flUpMove;
            int32_t nImpulse;
            int32_t nWeaponSelect;
            int32_t nRandomSeed;
            int32_t nMousedX;
            int32_t nMousedY;
            uint32_t nConsumedServerAngleChanges;
            int32_t nCmdFlags;
            uint32_t hPawn;
        } CBaseUserCmdPB;

        typedef struct CInButtonState {
            char pad_0x0[0x8];
            uint64_t nValue;
            uint64_t nValueChanged;
            uint64_t nValueScroll;
        } CInButtonState;

        typedef struct CUserCmd {
            char pad_0x0[0x18];
            uint32_t nHasBits;
            uint64_t nCachedBits;
            RepeatedPtrField inputHistoryField;
            CBaseUserCmdPB* pBaseCmd;
            bool bLeftHandDesired;
            bool bIsPredictingBodyShotFX;
            bool bIsPredictingHeadShotFX;
            bool bIsPredictingKillRagdolls;
            int32_t nAttack3StartHistoryIndex;
            int32_t nAttack1StartHistoryIndex;
            int32_t nAttack2StartHistoryIndex;
            CInButtonState nButtons;
            char pad_0x58[0x20];
        } CUserCmd;

        typedef struct {
            char pad_0000[0x04D8];
            float m_fov;
            float m_viewmodel_fov;
            float m_origin_x;
            float m_origin_y;
            float m_origin_z;
            char pad_04EC[0xC];
            float m_angles_x;
            float m_angles_y;
            float m_angles_z;
            char pad_0504[0x14];
            float m_aspect_ratio;
        } CViewSetup;
    ]]

    local Source2Client002 = utils.create_interface("client.dll", "Source2Client002")

    local fnCreateMove, GetUserCmd; do
        fnCreateMove = assert(find_pattern("client.dll", "E9 ?? ?? ?? ?? ?? ?? ?? 48 8B C4 44 88 40 18"),
            "fnCreateMove outdated") -- // @xref: client.dll @ cl: %d ===========================

        local fnGetCommandIndex; do
            local address = utils.get_abs_address(
                assert(
                    opcode_scan("client.dll",
                        "E8 ?? ?? ?? ?? 8B 4C 24 38 8D 51 FF 83 F9 FF 75 05 BA FF FF FF FF 48 8B 0D"),
                    "fnGetCommandIndex outdated"),
                0x1, 0x0
            )

            fnGetCommandIndex = ffi.cast("void*(__fastcall*)(void*, int*)", address)
        end

        local fnGetUserCmdBase; do
            local address = utils.get_abs_address(
                assert(opcode_scan("client.dll", "E8 ?? ?? ?? ?? 48 8B CF 48 8B F0 44 8B B0 10 59 00 00"),
                    "fnGetUserCmdBase outdated"),
                0x1, 0x0
            )

            fnGetUserCmdBase = ffi.cast("void*(__fastcall*)(void*, int)", address)
        end

        local fnGetUserCmd = ffi.cast("CUserCmd*(__fastcall*)(void*, int)",
            assert(opcode_scan("client.dll", "40 53 48 83 EC ?? 8B DA E8 ?? ?? ?? ?? 4C 8B C0"), "fnGetUserCmd: outdated"))

        local pClientInput = (function()
            local pBase = assert(opcode_scan("client.dll", "48 8B 0D ?? ?? ?? ?? E8 ?? ?? ?? ?? 48 8B CF 48 8B F0"),
                "pClientInput outdated")
            return ffi.cast("void**", pBase + 7 + ffi.cast("int*", pBase + 3)[0])[0]
        end)()

        GetUserCmd = function()
            local pLocalPlayer = entitylist.get_local_player_controller();
            if not pLocalPlayer then
                return false
            end

            local pCommandIndex = ffi.new "int[1]"
            fnGetCommandIndex(pLocalPlayer[0], pCommandIndex)
            if pCommandIndex[0] == 0 then
                return false
            end

            local nCurrentCommand = pCommandIndex[0] - 1
            local pUserCmdBase = fnGetUserCmdBase(pClientInput, nCurrentCommand)
            if pUserCmdBase == NULLPTR then
                return false
            end

            local nSequenceNumber = ffi.cast("int*", ffi.cast("uintptr_t", pUserCmdBase) + 0x5910)[0];
            if nSequenceNumber <= 0 then
                return false
            end

            local pUserCmd = fnGetUserCmd(pLocalPlayer[0], nSequenceNumber);
            if pUserCmd == NULLPTR then
                return false
            end

            return pUserCmd
        end
    end

    local fnTeamIntro = assert(find_pattern("client.dll", "48 83 EC 28 45 0F B6 08"), "fnTeamIntro outdated")
    local fnRunPrediction = assert(find_pattern("engine2.dll", "40 55 41 56 48 83 EC ?? 80 B9"),
        "fnRunPrediction outdated") -- // @xref: engine2.dll @ "CNetworkGameClient::ClientSidePredict", "%i pred reason %s -- start (latest command created %d)\n", "%i pred reason %s -- finish\n"
    local fnScopeOverlay = assert(
        utils.get_abs_address(opcode_scan("client.dll", "E8 ?? ?? ?? ?? 80 7C 24 ?? ?? 74 25"), 1, 0),
        "fnScopeOverlay outdated") -- // ClientModeCSNormal > 27

    local fnLogSystem = assert(find_pattern("tier0.dll", "4C 89 4C 24 ? 44 89 44 24 ? 89 54 24 ? 55"),
        "fnLogSsytem outdated") -- //xref: %s():\n%s, Exiting due to logging LR_ABORT request.\n

    -- котакбасина туда встань
    -- local fnOverrideView = assert(opcode_scan("client.dll", "48 89 5C 24 10 55 48 8D 6C 24 A9 48 81 EC B0 00 00 00"), "fnOverrideView outdated") -- // ClientModeShared > 15
    local fnFrameStageNotify = vmt.get_v_method(Source2Client002, 36) -- // @xref: STR: "Client Restore Server State", "FrameNetUpdate(%.3f %d)", "FramePostDataUpdate(%.3f %d)", "C:\buildworker\csgo_rel_win64\build\src\game\client\cdll_client_int.cpp"
    local fnLevelInit = assert(
        utils.get_abs_address(opcode_scan("client.dll", "E8 ?? ?? ?? ?? C6 83 34 02 00 00 01"), 1, 0),
        "fnLevelInit outdated") -- // @xref: game_newmap, mapname
    local fnLevelShutdown = assert(
        utils.get_abs_address(opcode_scan("client.dll", "E8 ?? ?? ?? ?? 48 8D 8F C8 01 00 00 33 F6"), 1, 0),
        "fnLevelShutdown outdated") -- // @xref: mapshutdown

    local events_data = {
        map = {},
        performance = {},
        setup = {}
    }

    local buttons = {
        IN_ATTACK = bit.lshift(1, 0),
        IN_JUMP = bit.lshift(1, 1),
        IN_DUCK = bit.lshift(1, 2),
        IN_FORWARD = bit.lshift(1, 3),
        IN_BACK = bit.lshift(1, 4),
        IN_USE = bit.lshift(1, 5),
        UNKNOWN0 = bit.lshift(1, 6),
        IN_TURNLEFT = bit.lshift(1, 7),
        IN_TURNRIGHT = bit.lshift(1, 8),
        IN_MOVELEFT = bit.lshift(1, 9),
        IN_MOVERIGHT = bit.lshift(1, 10),
        IN_ATTACK2 = bit.lshift(1, 11),
        UNKNOWN1 = bit.lshift(1, 12),
        IN_RELOAD = bit.lshift(1, 13),
        IN_SPEED = bit.lshift(1, 16),
        IN_JOYAUTOSPRINT = bit.lshift(1, 17),
        IN_USEORRELOAD = bit.lshift(1, 32),
        IN_SCORE = bit.lshift(1, 33),
        IN_ZOOM = bit.lshift(1, 34),
        IN_JUMP_THROW_RELEASE = bit.lshift(1, 35)
    }

    local has = function(cmd_wrapper, value)
        if not cmd_wrapper or not cmd_wrapper[0] then return false end
        local current = cmd_wrapper[0].nButtons.nValue
        return current % (value * 2) >= value
    end

    local bits = {
        has = has,

        add = function(cmd_wrapper, value)
            if not has(cmd_wrapper, value) then
                cmd_wrapper[0].nButtons.nValue = cmd_wrapper[0].nButtons.nValue + value
            end
        end,

        remove = function(cmd_wrapper, value)
            if has(cmd_wrapper, value) then
                local raw = cmd_wrapper[0]
                raw.nButtons.nValue = raw.nButtons.nValue - value

                if raw.nButtons.nValueChanged % (value * 2) >= value then
                    raw.nButtons.nValueChanged = raw.nButtons.nValueChanged - value
                end
                if raw.nButtons.nValueScroll % (value * 2) >= value then
                    raw.nButtons.nValueScroll = raw.nButtons.nValueScroll - value
                end
            end
        end
    }

    local usercmd = {}; do
        local cmd_mt = {}; do
            cmd_mt.__index = function(self, key)
                if key == "buttons" then
                    return self[0].nButtons.nValue
                end

                if key == "pBaseCmd" then
                    return self[0].pBaseCmd
                end

                if key == "weaponselect" then
                    return self[0].pBaseCmd.nWeaponSelect
                end

                if key:find "in_" then
                    local key = key:upper()
                    return bits.has(self, buttons[key]) and 1 or 0
                end

                if key == "forwardmove" then
                    return self[0].pBaseCmd.flForwardMove
                end

                if key == "sidemove" then
                    return self[0].pBaseCmd.flSideMove
                end

                if key == "view_angles" then
                    local angles = self[0].pBaseCmd.pViewAngles.vecValue
                    return angle_t(angles.x, angles.y, angles.z)
                end
            end

            cmd_mt.__newindex = function(self, key, value)
                if key == "buttons" then
                    self[0].nButtons.nValue = value
                    self[0].nButtons.nValueChanged = value
                    self[0].nButtons.nValueScroll = value
                    return
                end

                if key == "weaponselect" then
                    self[0].pBaseCmd.nWeaponSelect = value
                end

                if key:find "in_" then
                    local key = key:upper()

                    if value == 1 then
                        bits.add(self, buttons[key])
                    elseif value == 0 then
                        bits.remove(self, buttons[key])
                    end
                end

                if key == "forwardmove" then
                    self[0].pBaseCmd.flForwardMove = value
                    return
                end

                if key == "sidemove" then
                    self[0].pBaseCmd.flSideMove = value
                    return
                end

                if key == "view_angles" then
                    local angles = value

                    self[0].pBaseCmd.pViewAngles.vecValue.x = angles.pitch
                    self[0].pBaseCmd.pViewAngles.vecValue.y = angles.yaw
                    self[0].pBaseCmd.pViewAngles.vecValue.z = angles.roll

                    return
                end

                rawset(self, key, value)
            end
        end

        setmetatable(usercmd, {
            __call = function(_, raw_cmd)
                return setmetatable({ [0] = raw_cmd }, cmd_mt)
            end
        })
    end

    local c_viewsetup = {}; do
        local viewsetup_t = {}; do
            viewsetup_t.__index = function(self, key)
                local ptr = self[0]
                if not ptr then return nil end

                if key == "fov" then
                    return ptr.m_fov
                end

                if key == "aspect_ratio" then
                    return ptr.m_aspect_ratio
                end

                if key == "origin" then
                    return vec3_t(ptr.m_origin_x, ptr.m_origin_y, ptr.m_origin_z)
                end

                if key == "angles" then
                    return angle_t(ptr.m_angles_x, ptr.m_angles_y, ptr.m_angles_z)
                end

                return rawget(self, key)
            end

            viewsetup_t.__newindex = function(self, key, value)
                local ptr = self[0]
                if not ptr then return end

                if key == "fov" then
                    ptr.m_fov = value
                    return
                end

                if key == "aspect_ratio" then
                    ptr.m_aspect_ratio = value
                    return
                end

                if key == "origin" then
                    ptr.m_origin_x = value.x
                    ptr.m_origin_y = value.y
                    ptr.m_origin_z = value.z
                    return
                end

                if key == "angles" then
                    ptr.m_angles_x = value.pitch
                    ptr.m_angles_y = value.yaw
                    ptr.m_angles_z = value.roll
                    return
                end

                rawset(self, key, value)
            end
        end

        setmetatable(c_viewsetup, {
            __call = function(_, ctx)
                return setmetatable({ [0] = ffi.cast("CViewSetup*", ctx) }, viewsetup_t)
            end
        })
    end

    local function call_handlers(event_name, ...)
        local handlers = events_data.setup[event_name]
        if not handlers then return end

        local last_result

        if debug_enabled then
            events_data.performance[event_name] = events_data.performance[event_name] or {}
            for _, handler in ipairs(handlers) do
                local start = timer()
                local ok, result = xpcall(handler, debug.traceback, ...)
                local elapsed = (timer() - start) * 1000
                events_data.performance[event_name][handler] = elapsed

                if ok then
                    last_result = result
                else
                    print(string.format("[%s] error: %s", event_name, result))
                end
            end
        else
            for _, handler in ipairs(handlers) do
                local ok, result = pcall(handler, ...)
                if ok then
                    last_result = result
                else
                    print(string.format("[%s] handler error: %s", event_name, result))
                end
            end
        end

        return last_result
    end

    local function hkCreateMove(o_fn, pCCSGOInput, slot, active)
        o_fn(pCCSGOInput, slot, active);

        local o_cmd = GetUserCmd()

        local cmd = usercmd(o_cmd)

        if cmd then
            call_handlers("createmove", cmd, slot, active)
        end
    end

    local function hkTeamIntro(o_fn, rcx, rdx, r8)
        if r8 ~= nil then
            call_handlers("team_intro", rcx, rdx, r8)
        end

        return o_fn(rcx, rdx, r8)
    end

    local function hkRunPrediction(o_fn, this, reason)
        -- print(string.format("[RunPrediction] reason = %d", reason))
        if reason then
            call_handlers("run_prediction", this, reason)
        end

        return o_fn(this, reason)
    end

    local function hkScopeOverlay(o_fn, player, params)
        local result = o_fn(player, params)

        if player and params then
            call_handlers("scope_overlay", player, params)
        end

        return result
    end

    -- local function hkOverrideView(o_fn, source2client, view_setup)
    --     o_fn(source2client, view_setup)

    --     if view_setup then
    --         call_handlers("override_view", c_viewsetup(view_setup))
    --     end
    -- end

    local function hkFrameStageNotify(o_fn, source2client, stage)
        if stage then
            call_handlers("frame_stage_notify", stage)
        end

        return o_fn(source2client, stage)
    end

    local function hkLevelInit(o_fn, a1, mapname)
        if mapname then
            call_handlers "level_init"
        end

        return o_fn(a1, mapname)
    end

    local function hkShutdown(o_fn, a1)
        if a1 then
            call_handlers "level_shutdown"
        end

        return o_fn(a1)
    end

    create_hook(fnRunPrediction, hkRunPrediction, "void(__fastcall*)(void*, int)")
    create_hook(fnCreateMove, hkCreateMove, "void(__fastcall*)(void*, int, uint8_t)") -- .. prob fixed idk need to check later
    create_hook(fnTeamIntro, hkTeamIntro, "void(__fastcall*)(void*, void*, void*)")
    create_hook(fnLevelShutdown, hkShutdown, "void(__fastcall*)(void*, void*)")
    create_hook(fnScopeOverlay, hkScopeOverlay, "void(__fastcall*)(void*, void*)")

    --     return o_fn(a1, a2, a3, a4, a5)
    -- end, "void(__fastcall*)(void*, void*, void*, void*, void*)")
    -- create_hook(fnLogSystem, function(o_fn, a1, a2, a3, a4, a5, a6)
    --     local result = call_handlers("block_message", a1, a2, a3, a4, a5, a6)

    --     if result == true then
    --         return 0
    --     end

    --     return o_fn(a1, a2, a3, a4, a5, a6)
    -- end, "__int64(*)(void*, unsigned int, int, void*, const char*, void*)")
    -- create_hook(fnOverrideView, hkOverrideView, "void(__fastcall*)(void*, void*)")
    -- create_hook(fnFrameStageNotify, hkFrameStageNotify, "void(__fastcall*)(void*, int)")
    create_hook(fnLevelInit, hkLevelInit, "void*(__fastcall*)(void*, const char*)")


    local hooked_events = {
        -- "createmove",
        "team_intro",
        "run_prediction",
        "scope_overlay",
        -- "override_view",
        "frame_stage_notify",
        -- "should_draw_legs",
        "level_init",
        "log_system"
    }

    local function create_event_handler(event_name)
        if type(event_name) ~= "string" then return end

        if hooked_events[event_name] then
            return
        end

        if type(register_callback) ~= "function" then
            return
        end

        register_callback(event_name, function(...)
            call_handlers(event_name, ...)
        end)
    end

    local Event = {
        set = function(self, fn)
            if type(fn) ~= "function" then return false end
            events_data.setup[self.name] = events_data.setup[self.name] or {}
            for _, v in ipairs(events_data.setup[self.name]) do
                if v == fn then return false end
            end
            table.insert(events_data.setup[self.name], fn)
            return true
        end,

        unset = function(self, fn)
            local t = events_data.setup[self.name]
            if not t then return false end
            for i, v in ipairs(t) do
                if v == fn then
                    table.remove(t, i)
                    return true
                end
            end
            return false
        end
    }

    events = setmetatable({}, {
        __index = function(_, event_name)
            if type(event_name) ~= "string" then return nil end

            local event = events_data.map[event_name]
            if not event then
                event = setmetatable({
                    handlers = events_data.setup[event_name] or {},
                    name = event_name
                }, {
                    __index = Event,
                    __call = function(self, fn, enabled)
                        if enabled == nil then enabled = true end
                        if enabled then
                            self:set(fn)
                        else
                            self:unset(fn)
                        end
                    end
                })
                events_data.map[event_name] = event
                create_event_handler(event_name)
            end

            return event
        end
    })

    if debug_enabled then
        local font = render.setup_font("C:/Windows/Fonts/Verdana.ttf", 14)
        local line_height = 16

        if type(register_callback) == "function" then
            register_callback("paint", function()
                local screen = render.screen_size()
                local pos = vec2_t(5, screen.y * 0.25)

                for event_name, metrics in pairs(events_data.performance or {}) do
                    render.text(event_name, font, pos + vec2_t(1, 1), color_t(0, 0, 0, 0.5))
                    render.text(event_name, font, pos, color_t(1, 1, 1, 1))
                    pos.y = pos.y + line_height

                    for i, handler in ipairs(events_data.setup[event_name] or {}) do
                        local time = metrics[handler] or 0
                        local text = string.format("  [%d]: %.3fms", i, time)
                        local color = time > 1 and color_t(1, 100 / 255, 100 / 255, 1) or color_t(1, 1, 1, 1)

                        render.text(text, font, pos + vec2_t(1, 1), color_t(0, 0, 0, .5))
                        render.text(text, font, pos, color)
                        pos.y = pos.y + line_height
                    end

                    pos.y = pos.y + 8
                end
            end)
        end
    end
end

return events

end)
__bundle_register("render/color", function(require, _LOADED, __bundle_register, __bundle_modules)
local color = {}; do
    local color_mt = getmetatable(color_t(0, 0, 0, 0));

    function string.rgba(hex)
        hex = hex:gsub("#", "")

        local r = tonumber(hex:sub(1, 2), 16) / 255
        local g = tonumber(hex:sub(3, 4), 16) / 255
        local b = tonumber(hex:sub(5, 6), 16) / 255
        local a = tonumber(hex:sub(7, 8), 16)

        a = a and a / 255 or 1

        return r, g, b, a
    end

    color_mt.__concat = function(self)
        return string.format("color_t(%s, %s, %s, %s)", self.r, self.g, self.b, self.a)
    end

    function color_t:init(r, g, b, a)
        self.r = r
        self.g = g
        self.b = b
        self.a = a

        return self
    end

    function color_t:unpack()
        return self.r, self.g, self.b, self.a
    end

    function color_t:clone()
        return color_t(self:unpack())
    end

    function color_t:to_hex()
        local r, g, b, a = self:unpack()
        r = r * 255
        g = g * 255
        b = b * 255
        a = a * 255

        return string.format("%02x%02x%02x%02x", r, g, b, a)
    end

    function color_t:alpha_modulate(alpha, self_modulate)
        return color_t(self.r, self.g, self.b, self_modulate and self.a * alpha or alpha)
    end

    local fn = {
        [0] = function()
            return 1, 1, 1, 1
        end,

        function(x)
            if type(x) == "string" then
                return string.rgba(x)
            elseif type(x) == "table" then
                return x[1] or x.r or 1, x[2] or x.g or 1, x[3] or x.b or 1, x[4] or x.a or 1
            end

            return x, x, x, 1
        end,

        function(x, a)
            return x, x, x, a
        end,

        function(r, g, b)
            return r, g, b, 1
        end,

        function(...)
            return ...
        end
    }

    function color:new(...)
        local len = math.min(select("#", ...), 4)
        return color_t(fn[len](...))
    end

    local colors = {
        white = color:new(),
        text  = color:new(1, 1, 1, .8),
        error = color:new "#FF5A5A",
        green = color:new "#5BFF62"
    }

    function color.hsv_to_rgb(h, s, v, a)
        local r, g, b
        local i = math.floor(h * 6)
        local f = h * 6 - i
        local p = v * (1 - s)
        local q = v * (1 - f * s)
        local t = v * (1 - (1 - f) * s)
        local m = i % 6
        if m == 0 then
            r, g, b = v, t, p
        elseif m == 1 then
            r, g, b = q, v, p
        elseif m == 2 then
            r, g, b = p, v, t
        elseif m == 3 then
            r, g, b = p, q, v
        elseif m == 4 then
            r, g, b = t, p, v
        elseif m == 5 then
            r, g, b = v, p, q
        end
        return color:new(r, g, b, a or 1)
    end

    function color.rgb_to_hsv(r, g, b)
        local max, min = math.max(r, g, b), math.min(r, g, b)
        local h, s, v
        v = max
        local d = max - min
        if max == 0 then s = 0 else s = d / max end
        if max == min then
            h = 0
        else
            if max == r then
                h = (g - b) / d + (g < b and 6 or 0)
            elseif max == g then
                h = (b - r) / d + 2
            elseif max == b then
                h = (r - g) / d + 4
            end
            h = h / 6
        end
        return h, s, v
    end

    setmetatable(color, {
        __call = color.new,
        __index = colors
    })
end

return color

end)
__bundle_register("render/render", function(require, _LOADED, __bundle_register, __bundle_modules)
function render.switch(from, to, background_color, circle_color, pct)
    if not pct then
        return
    end

    local height, width = to.y, to.x

    local radius = height * .5;
    local box_width = width - radius * 2;

    local circle_radius = radius * 0.75;
    local position = from + vec2_t(box_width * pct + circle_radius * 1.25 + .5, circle_radius * 1.25 + .2)
    render.rect_filled(from, from + to, background_color, radius)
    render.circle_filled(position + vec2_t(0, 1), circle_radius, 18, color_t(0, 0, 0, circle_color.a * 0.3))
    render.circle_filled(position + vec2_t(0, 2), circle_radius, 18, color_t(0, 0, 0, circle_color.a * 0.1))
    render.circle_filled(position,
        circle_radius, 18, circle_color)
    -- render.circle(position,
    --     circle_radius, 18, color_t(0, 0, 0, circle_color.a * .5))
end

-- local render = {}; do
local o_render = render.text
local o_render_calc_text_size = render.calc_text_size

local function render_text(text, font, position, size, clr, flags)
    local raw_text = text:gsub("\a%x%x%x%x%x%x%x%x", ""):gsub("\adefault", "");
    local shadow_color = color_t(0, 0, 0, clr.a * .5);
    local outline_color = color_t(0, 0, 0, clr.a * .25);

    if flags:find "d" then
        o_render(raw_text, font, position + 1, shadow_color, size);
    elseif flags:find "o" then
        o_render(raw_text, font, position + vec2_t(-1, -1), outline_color, size);
        o_render(raw_text, font, position + vec2_t(-1, 0), outline_color, size);
        o_render(raw_text, font, position + vec2_t(-1, 1), outline_color, size);

        o_render(raw_text, font, position + vec2_t(0, -1), outline_color, size);
        o_render(raw_text, font, position + vec2_t(0, 0), outline_color, size);
        o_render(raw_text, font, position + vec2_t(0, 1), outline_color, size);

        o_render(raw_text, font, position + vec2_t(1, -1), outline_color, size);
        o_render(raw_text, font, position + vec2_t(1, 0), outline_color, size);
        o_render(raw_text, font, position + vec2_t(1, 1), outline_color, size);
    end

    o_render(text, font, vec2_t(position.x, position.y), clr, size)
end

function render.calc_text_size(text, font)
    if text:find "\a" then
        text = text:gsub("\adefault", "");
        text = text:gsub("\a%x%x%x%x%x%x%x%x", "");
    end

    return o_render_calc_text_size(text, font)
end

function render.text(text, font, position, clr, size, flags)
    position = vec2_t(position.x, position.y);
    flags = flags or "";

    if flags:find "c" then
        position.x = position.x - render.calc_text_size(text, font).x * .5;
    elseif flags:find "r" then
        position.x = position.x - render.calc_text_size(text, font).x;
    end

    if text:find "\a" then
        local alpha_mult = clr.a

        for pattern in string.gmatch(text, "\a?[^\a]+") do
            local text = pattern:match "^\adefault(.-)$"

            if text ~= nil then
                render_text(text, font, vec2_t(position.x, position.y), size, clr, flags)
                position.x = position.x + render.calc_text_size(text, font).x

                goto continue
            end

            local clr, text = pattern:match "^\a(%x%x%x%x%x%x%x%x)(.-)$"

            if clr ~= nil then
                local r, g, b, a = string.rgba(clr)

                render_text(text, font, vec2_t(position.x, position.y), size, color_t(r, g, b, a * alpha_mult), flags)
                position.x = position.x + render.calc_text_size(text, font).x

                goto continue
            end

            render_text(pattern, font, vec2_t(position.x, position.y), size, clr, flags)
            position.x = position.x + render.calc_text_size(pattern, font).x

            ::continue::
        end

        return
    end

    render_text(text, font, position, size, clr, flags)
end

--     render.screen_size = o_render.screen_size
--     render.frame_count = o_render.frame_count
--     render.frame_time = o_render.frame_time
--     render.setup_texture = o_render.setup_texture
--     render.setup_texture_rgba = o_render.setup_texture_rgba
--     render.setup_texture_from_memory = o_render.setup_texture_from_memory
--     render.setup_font = o_render.setup_font
--     render.world_to_screen = o_render.world_to_screen
--     render.texture = o_renderure
--     render.line = o_render.line
--     render.rect = o_render.rect
--     render.rect_filled = o_render.rect_filled
--     render.rect_filled_fade = o_render.rect_filled_fade
--     render.circle = o_render.circle
--     render.circle_filled = o_render.circle_filled
--     render.circle_fade = o_render.circle_fade
--     render.arc = o_render.arc
--     render.polygon = o_render.polygon
--     render.concave_polygon = o_render.concave_polygon
--     render.poly_line = o_render.poly_line
--     render.push_clip_rect = o_render.push_clip_rect
--     render.pop_clip_rect = o_render.pop_clip_rect
--     render.circle_3d = o_render.circle_3d
--     render.circle_filled_3d = o_render.circle_filled_3d
--     render.circle_fade_3d = o_render.circle_fade_3d
-- end

end)
__bundle_register("core/logging", function(require, _LOADED, __bundle_register, __bundle_modules)
local function concat_args(...)
    local args = { ... };
    for i = 1, #args do
        args[i] = tostring(args[i]);
    end

    return table.concat(args);
end

local called_via_lua = false

function print_raw(...)
    called_via_lua = true
    local message = concat_args(...)

    local r, g, b, a = 1, 1, 1, 1

    if message:find "\a" then
        local segments = {}
        for pattern in string.gmatch(message, "\a?[^\a]+") do
            table.insert(segments, pattern)
        end

        for i, pattern in ipairs(segments) do
            local is_last = (i == #segments)
            local suffix = is_last and "" or "\0"

            local text = pattern:match "^\adefault(.-)$"
            if text ~= nil then
                color_print(text .. suffix, color_t(r, g, b, a))
                goto continue
            end

            local hex, text = pattern:match "^\a(%x%x%x%x%x%x%x%x)(.-)$"
            if hex ~= nil then
                local r, g, b, a = string.rgba(hex)
                color_print(text .. suffix, color_t(r, g, b, a))
                goto continue
            end

            color_print(pattern .. suffix, color_t(r, g, b, a))
            ::continue::
        end
        called_via_lua = false
        -- color_print("\n", color_t(1, 1, 1, a))
        return
    end

    color_print(message, color_t(1, 1, 1, a))
    called_via_lua = false
end

return {
    called_via_lua = called_via_lua
}

end)
return __bundle_require("__root")