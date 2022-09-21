-- gamesense globals
local render = _G['render']
-- local client = _G['client']
local logFont = surface.create_font("Verdana", 12, 100, 0, fontflags.antialias)
-- start of function that encompasses the lua
local animate_speed = 12
local add_y = 15

local animate = (function()
    local anim = {}

    local lerp = function(start, vend)
        return start + (vend - start) * (globals.frametime() * animate_speed)
    end


    anim.fade = function(value,startpos,endpos,condition)
        if condition ~= nil then
            if condition then
                return lerp(value,startpos)
            else
                return lerp(value,endpos)
            end
        else
            return lerp(value,startpos)
        end

    end
	
	anim.state = function(value,firstpos,secondpos,condition)
        if condition then
			return lerp(value,secondpos)
        else
			return lerp(value,firstpos)
        end
		return 0
    end


    return anim
end)()

local multitext = function(x,y,_table, alpha)
    for _, item in pairs(_table) do
		render.draw_text(x + 1, y + 1, logFont, item.text, false, color.new(0, 0, 0, 200 * alpha))
        render.draw_text(x, y, logFont, item.text, false, color.new(item.color[1], item.color[2], item.color[3], item.color[4]))
        local text_size_x = render.text_size(logFont, item.text).x
        x = x + text_size_x
    end
end

local multitext_measure = function(_table)

    local textSize_x, textSize_y = 0, 0
    for _, item in pairs(_table) do
        textSize_x = textSize_x + render.text_size(logFont, item.text).x
		textSize_y = textSize_y + render.text_size(logFont, item.text).y
    end

    return vector2d.new(textSize_x, textSize_y)
end

local screenSize = engine.get_screen_size()

local notify = {}

local paint = function()
    
    local y = screenSize.y / 1.75
	
    for index, info in pairs(notify) do
        if info ~= nil then
			if #notify > 6 then
				notify[1].timer = notify[1].timer - 0.5
			end
			
            local r, g, b = info.color.r,info.color.g,info.color.b

			info.alpha = animate.fade(info.alpha,0,1,(info.timer + 3.8 < globals.realtime() ))
			info.state = animate.state(info.state,1,2,(info.timer + 3.8 < globals.realtime() ))
			
            local _table = {
				{text = info.hit_miss, color = {255, 255, 255, info.alpha * 255}},
				{text = info.target_name, color = {r, g, b, info.alpha * 255}},
				{text = info.group, color = {255, 255, 255, info.alpha * 255}},
				{text = info.group_idx, color = {r, g, b, info.alpha * 255}},
				{text = info.reason, color = {255, 255, 255, info.alpha * 255}},
				{text = info.reason_idx, color = {r, g, b, info.alpha * 255}},
				{text = info.damage, color = {255, 255, 255, info.alpha * 255}},
				{text = info.damage_idx, color = {r, g, b, info.alpha * 255}},
				{text = info.health, color = {255, 255, 255, info.alpha * 255}},
				{text = info.health_idx, color = {r, g, b, info.alpha * 255}},
				{text = info.suffix, color = {255, 255, 255, info.alpha * 255}},
            }

            local multiTextSize = multitext_measure(_table)
			
            multitext(screenSize.x / 2 - multiTextSize.x / 2 + math.floor(add_y * info.state), y, _table, info.alpha)

            y = y + math.floor(add_y * info.alpha)
			-- y = y + math.floor(add_y * 1)

            if info.timer + 4 < globals.realtime() then
                table.remove(notify,index)
            end
        end
    end
end

local hitgroup_names = { "body", "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg", "neck", "?"}

local function hurtthatbiddy(game_event)
	local attackerIndex = engine.get_player_for_user_id(game_event:get_int("attacker"))
	local localIndex = engine.get_local_player_index()
	local victimIndex = engine.get_player_for_user_id(game_event:get_int("userid"))
	
	if attackerIndex == localIndex and victimIndex ~= localIndex then
		local hitgroup = game_event:get_int("hitgroup")
		local group = hitgroup_names[hitgroup + 1] or "?"
		local damage = game_event:get_int("dmg_health")
		local health = game_event:get_int("health")
		local victimName = utils.get_player_data(engine.get_player_info(victimIndex)).name
		
		table.insert(notify,{
			hit_miss = "Hit ",
			target_name = victimName,
			group = " in the ",
			group_idx = group,
			reason = '',
			reason_idx = '',
			damage = " for ",
			damage_idx  = damage,
			health = " damage (",
			health_idx = health,
			suffix = " health remaining)",
			alpha = 0,
			state = 0,
			color = {r = 137, g = 253, b = 0},
			timer = globals.realtime(),
		})
	end
end
	
event.register_event("player_hurt", hurtthatbiddy)
cheat.set_event_callback("paint", paint)


-- local player_hurt = function(e)
    -- if not ui.get(menu.master_switch) then
        -- return
    -- end
    -- local attacker_id = client.userid_to_entindex(e.attacker)
    -- if attacker_id == nil then
        -- return
    -- end

    -- if attacker_id ~= entity.get_local_player() then
        -- return
    -- end

    -- local hitgroup_names = { "Body", "Head", "Chest", "Stomach", "Left arm", "Right arm", "Left leg", "Right leg", "Neck", "?"}
    -- local group = hitgroup_names[e.hitgroup + 1] or "?"
    -- local target_id = client.userid_to_entindex(e.userid)
    -- local target_name = entity.get_player_name(target_id)
    -- local enemy_health = entity.get_prop(target_id, "m_iHealth")
    -- local rem_health = enemy_health - e.dmg_health
    -- if rem_health <= 0 then
        -- rem_health = 0
    -- end

    -- table.insert(notify,{
        -- hit_miss = "Hit ",
        -- target_name = string.lower(target_name),
        -- group = "in the ",
        -- group_idx = group,
        -- reason = '',
        -- reason_idx = '',
        -- damage = " for ",
        -- damage_idx  = e.dmg_health,
        -- health = " damage (",
        -- health_idx = rem_health,
		-- suffix = " health remaining)",
        -- alpha = 0,
		-- state = 0,
        -- color = {
            -- r = 137, g = 253, b = 0
        -- },
        -- timer = globals.realtime(),
    -- })
-- end

-- local aimmiss = function(e)
    -- if not ui.get(menu.master_switch) then
        -- return
    -- end

    -- if e == nil then return end
    -- local hitgroup_names = { "Body", "Head", "Chest", "Stomach", "Left arm", "Right arm", "Left leg", "Right leg", "Neck", "?"}
    -- local group = hitgroup_names[e.hitgroup + 1] or "?"
    -- local target_name = entity.get_player_name(e.target)
    -- local reason
    -- if e.reason == "?" then
        -- reason = "resolver"
    -- else
        -- reason = e.reason
    -- end

    -- table.insert(notify,{
        -- hit_miss = "Missed ",
        -- target_name = string.lower(target_name),
        -- group = "'s ",
        -- group_idx = group,
        -- reason = ' due to ',
        -- reason_idx = reason,
        -- damage = '',
        -- damage_idx  = '',
        -- health = ' (',
        -- health_idx = e.hitchance,
		-- suffix = "% hitchance)",
        -- alpha = 0,
		-- state = 0,
        -- color = {
            -- r = 255 ,g = 49 , b = 49
        -- },
        -- timer = globals.realtime(),
    -- })
-- end