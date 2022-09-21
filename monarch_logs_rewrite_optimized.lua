-- local variables for API functions. any changes to the line below will be lost on re-generation
local cheat_set_event_callback, color_new, config_get, config_load, config_save, config_set, cvar_console_print, engine_get_local_player_index, engine_get_player_for_user_id, engine_get_player_info, engine_get_screen_size, engine_is_in_game, event_register_event, globals_frametime, globals_realtime, math_floor, render_draw_text, render_text_size, surface_create_font, table_insert, table_remove, ui_new_checkbox, ui_new_slider, ui_new_text, ipairs, utils_get_player_data = cheat.set_event_callback, color.new, config.get, config.load, config.save, config.set, cvar.console_print, engine.get_local_player_index, engine.get_player_for_user_id, engine.get_player_info, engine.get_screen_size, engine.is_in_game, event.register_event, globals.frametime, globals.realtime, math.floor, render.draw_text, render.text_size, surface.create_font, table.insert, table.remove, ui.new_checkbox, ui.new_slider, ui.new_text, ipairs, utils.get_player_data

-- Global settings 😃
local screenSize = engine_get_screen_size()

-- Hitlog settings 😌
local notify = {}
local hitlogFont = surface_create_font("Verdana", 12, 500, 0, fontflags.antialias)
local hitlogFontBold = surface_create_font("Verdana", 12, 700, 0, fontflags.antialias)
local hitgroup_names = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?"}

-- Vader menu settings
-- Da big switch
ui_new_checkbox("screenlog_cb", "Screen logs")
config_set("screenlog_cb", true)
ui_new_checkbox("consolelog_cb", "Console logs")
-- Want bold?
ui_new_checkbox("logfont_cb", "Render bold font")
-- Offset for da logs!
ui_new_slider("screenlog_y_slider", "Screen logs Y offset", 0, 240, "%1.fpx")
config_set("screenlog_y_slider", 160)
-- Da space between logs!!1!
ui_new_slider("screenlog_spacing_slider", "Screen logs spacing", 0, 30, "%1.fpx")
config_set("screenlog_spacing_slider", 15)
-- xXAnimationSpeedXx
ui_new_slider("screenlog_speed_slider", "Screen logs animation speed", 4, 24, "%1.fs")
config_set("screenlog_speed_slider", 12)
-- Time on screen
ui_new_slider("screenlog_time_slider", "Screen logs expire time", 1, 10, "%1.fs")
config_set("screenlog_time_slider", 5)

-- Config saving
ui_new_text("\n")
ui_new_checkbox("savelog_cb", "Save log settings")
ui_new_checkbox("loadlog_cb", "Load log settings")

-- HELPER FUNCTIONS BEGIN

-- Function for that smooth sexy movement 😍 linear interpolation ftw!!
local lerp = function(start, vend)
    return start + (vend - start) * (globals_frametime() * config_get("screenlog_speed_slider"))
end

--[[
-- Can take unlimited amount of arguments
-- This will automatically append state, alpha, and timer 
--]]
local add_log = function(...) 
	local temp_table = { display = {...}, metadata = {alpha = 0, state = 0, timer = globals_realtime()} }

	table_insert(notify, temp_table)
end

local animate = {
	-- For alpha control and fade distance of the text
	fade = function(value, startpos, endpos, condition)
		if condition == nil then return lerp(value, startpos) end
			
		if condition then
			return lerp(value, startpos)
		else
			return lerp(value, endpos)
		end
	end,

	-- For position control of the text
	state = function(value, firstpos, secondpos, condition)
		if condition then
			return lerp(value, secondpos)
		else
			return lerp(value, firstpos)
		end
	end,
}

local multitext = {
	-- Takes a table of text to render
	render = function(x, y, table, alpha)
		for _, item in ipairs(table) do
			if not config_get("logfont_cb") then
				render_draw_text(x + 1, y + 1, hitlogFont, item.text, false, color_new(5, 5, 5, 200 * alpha)) -- ghetto dropshadow, until exon fixes fonts
				render_draw_text(x, y, hitlogFont, item.text, false, color_new(item.color.r, item.color.g, item.color.b, 255 * alpha))
				local text_size_x = render_text_size(hitlogFont, item.text).x
				x = x + text_size_x
			else
				render_draw_text(x + 1, y + 1, hitlogFontBold, item.text, false, color_new(5, 5, 5, 200 * alpha)) -- ghetto dropshadow, until exon fixes fonts
				render_draw_text(x, y, hitlogFontBold, item.text, false, color_new(item.color.r, item.color.g, item.color.b, 255 * alpha))
				local text_size_x = render_text_size(hitlogFontBold, item.text).x
				x = x + text_size_x
			end
		end
	end,
	
	-- Measures a table of text as a whole
	measure = function(table) -- only measures X cause we don't need dat Y
		local textSize_x = 0
		for _, item in ipairs(table) do
			if not config_get("logfont_cb") then
				textSize_x = textSize_x + render_text_size(hitlogFont, item.text).x
			else
				textSize_x = textSize_x + render_text_size(hitlogFontBold, item.text).x
			end
		end

		return textSize_x
	end,
}

local cfg_management = {
	save = function()
		config_set("savelog_cb", false)
		config_save()
		add_log(
		{text = "[", color = {r = 255, g = 255, b = 255}},
		{text = "monarch logs", color = {r = 175, g = 105, b = 239}},
		{text = "] ", color = {r = 255, g = 255, b = 255}},
		{text = "config saved", color = {r = 255, g = 255, b = 255}}
		)
	end,
	
	load = function()
		config_set("loadlog_cb", false)
		config_load()
		add_log(
		{text = "[", color = {r = 255, g = 255, b = 255}},
		{text = "monarch logs", color = {r = 175, g = 105, b = 239}},
		{text = "] ", color = {r = 255, g = 255, b = 255}},
		{text = "config loaded", color = {r = 255, g = 255, b = 255}}
		)
	end,
}

-- HELPER FUNCTIONS END

-- Start of the big bad logs 🤩
local _update_screenlog = function()
	
    local y = (screenSize.y / 1.75) + config_get("screenlog_y_slider")

    for index, info in ipairs(notify) do
        if info == nil then return end
			
		if #notify > 6 then
			notify[1].metadata.timer = notify[1].metadata.timer - 0.5
		end

		info.metadata.alpha = animate.fade(info.metadata.alpha, 0, 1, (info.metadata.timer + config_get("screenlog_time_slider") - 0.2 < globals_realtime()))
		info.metadata.state = animate.state(info.metadata.state, 1, 2, (info.metadata.timer + config_get("screenlog_time_slider") - 0.2 < globals_realtime()))
		
		local multiTextX = multitext.measure(info.display)

		multitext.render(
				screenSize.x / 2 - multiTextX / 2 + math_floor(config_get("screenlog_spacing_slider") * info.metadata.state), 
				y, 
				info.display, 
				info.metadata.alpha
				)

		y = y + math_floor(config_get("screenlog_spacing_slider") * info.metadata.alpha)

		if info.metadata.timer + config_get("screenlog_time_slider") < globals_realtime() then
			table_remove(notify, index)
		end
    end
end

local function hurtthatbiddy(game_event) -- for grenades only!
	local hitgroup = game_event:get_int("hitgroup")
	if hitgroup ~= 0 then return end -- nope out if not a nade
	
	local attackerIndex = engine_get_player_for_user_id(game_event:get_int("attacker"))
	local localIndex = engine_get_local_player_index()
	local victimIndex = engine_get_player_for_user_id(game_event:get_int("userid"))
	
	if attackerIndex == localIndex and victimIndex ~= localIndex then -- check that we are the attacker and not the victim
		
		local group = hitgroup_names[hitgroup + 1] or "?"
		local damage = game_event:get_int("dmg_health")
		local health = game_event:get_int("health")
		local victimName = utils_get_player_data(engine_get_player_info(victimIndex)).name

		add_log(
			{text = "Hit ", color = {r = 255, g = 255, b = 255}},
			{text = victimName, color = {r = 137, g = 253, b = 0}},
			{text = " in the ", color = {r = 255, g = 255, b = 255}},
			{text = group, color = {r = 137, g = 253, b = 0}},
			{text = " for ", color = {r = 255, g = 255, b = 255}},
			{text = damage, color = {r = 137, g = 253, b = 0}},
			{text = " damage (", color = {r = 255, g = 255, b = 255}},
			{text = health, color = {r = 137, g = 253, b = 0}},
			{text = " health remaining)", color = {r = 255, g = 255, b = 255}}
		)
	end
end

local function shotthatbiddy(shot_data)
	local intHealth    = shot_data.player:get_health()
	local intIndex     = shot_data.player:get_index()
	local intHitchance = shot_data.hitchance
	local strResponse  = shot_data.result
	local strVictim    = utils_get_player_data(engine_get_player_info(intIndex)).name
	local strClHitbox  = shot_data.client_hitbox
	local intClDamage  = shot_data.client_damage
	
	if strResponse == "hit" then
		local strSvHitbox = shot_data.server_hitbox
		local intSvDamage = shot_data.server_damage
		
		-- Client leg fix
		if strClHitbox == "leg" and (strSvHitbox == "right leg" or strSvHitbox == "left leg") then
			strClHitbox = strSvHitbox
		end
		
		-- Zeus fix 
		if strSvHitbox == "generic" then
			strClHitbox = strSvHitbox
		end
		
		if strClHitbox == strSvHitbox then -- accurate shot!
			add_log(
				{text = "Hit ", color = {r = 255, g = 255, b = 255}},
				{text = strVictim, color = {r = 137, g = 253, b = 0}},
				{text = " in the ", color = {r = 255, g = 255, b = 255}},
				{text = strClHitbox, color = {r = 137, g = 253, b = 0}},
				{text = " for ", color = {r = 255, g = 255, b = 255}},
				{text = intSvDamage, color = {r = 137, g = 253, b = 0}},
				{text = " damage (", color = {r = 255, g = 255, b = 255}},
				{text = intHealth, color = {r = 137, g = 253, b = 0}},
				{text = " health remaining)", color = {r = 255, g = 255, b = 255}}
			)

			if not config_get("consolelog_cb") then return end
			
			cvar_console_print("monarch logs | Hit Target: " .. strVictim .. 
							   " | Client Damage: " .. intClDamage .. 
							   " | Server Damage: " .. intSvDamage .. 
							   " | Client Hitbox: " .. strClHitbox .. 
							   " | Server Hitbox: " .. strSvHitbox .. 
							   " | Hitchance: "     .. intHitchance ..
							   " | Backtrack: "     .. shot_data.backtrack_ticks ..
							   "\n"
							   )
							   
		else -- Hitbox mismatch
			add_log(
				{text = "Hit ", color = {r = 255, g = 255, b = 255}},
				{text = strVictim, color = {r = 238, g = 210, b = 2}},
				{text = " in the ", color = {r = 255, g = 255, b = 255}},
				{text = strClHitbox, color = {r = 238, g = 210, b = 2}},
				{text = " for ", color = {r = 255, g = 255, b = 255}},
				{text = intSvDamage, color = {r = 238, g = 210, b = 2}},
				{text = " damage (hitbox mismatch ", color = {r = 255, g = 255, b = 255}},
				{text = strClHitbox, color = {r = 238, g = 210, b = 2}},
				{text = ":", color = {r = 255, g = 255, b = 255}},
				{text = strSvHitbox, color = {r = 238, g = 210, b = 2}},
				{text = ")", color = {r = 255, g = 255, b = 255}}
			)
		
			if not config_get("consolelog_cb") then return end
			
			cvar_console_print("monarch logs | Hit Target: " .. strVictim .. 
							   " | Client Damage: " .. intClDamage .. 
							   " | Server Damage: " .. intSvDamage .. 
							   " | Client Hitbox: " .. strClHitbox .. 
							   " | Server Hitbox: " .. strSvHitbox .. 
							   " | Hitchance: "     .. intHitchance ..
							   " | Backtrack: "     .. shot_data.backtrack_ticks ..
							   "\n"
							   )
		end
	else -- All misses go here
		add_log(
			{text = "Missed ", color = {r = 255, g = 255, b = 255}},
			{text = strVictim, color = {r = 255, g = 0, b = 0}},
			{text = "'s ", color = {r = 255, g = 255, b = 255}},
			{text = strClHitbox, color = {r = 255, g = 0, b = 0}},
			{text = " due to ", color = {r = 255, g = 255, b = 255}},
			{text = strResponse, color = {r = 255, g = 0, b = 0}},
			{text = " ( ", color = {r = 255, g = 255, b = 255}},
			{text = intHitchance, color = {r = 255, g = 0, b = 0}},
			{text = "% hitchance)", color = {r = 255, g = 255, b = 255}}
		)
		
		if not config_get("consolelog_cb") then return end
			
		cvar_console_print("monarch logs | Missed Target: " .. strVictim .. 
						   " | Reason: "        .. strResponse ..
						   " | Client Damage: " .. intClDamage .. 
						   " | Client Hitbox: " .. strClHitbox .. 
						   " | Hitchance: "     .. intHitchance ..
						   " | Backtrack: "     .. shot_data.backtrack_ticks ..
						   "\n"
						   )
	end
end

local drawthatbiddy = function()
	if not engine_is_in_game() then return end
	
	if config_get("screenlog_cb") then _update_screenlog() end
	
	-- config management loops here
	if config_get("savelog_cb") then cfg_management.save() end
	if config_get("loadlog_cb") then cfg_management.load() end
end

add_log(
	{text = "Made with ", color = {r = 255, g = 255, b = 255}},
	{text = "<3", color = {r = 253, g = 92, b = 99}},
	{text = " by Gender Bender", color = {r = 255, g = 255, b = 255}}
)

event_register_event("player_hurt", hurtthatbiddy)
cheat_set_event_callback("on_shot", shotthatbiddy)
cheat_set_event_callback("paint", drawthatbiddy)