local notify = {}
notify.__index = notify

-- Green 150, 185, 1
-- Red 255, 24, 24

notify.invoke_callback = function(timeout)
    return setmetatable({
        active = false,
        delay = 0,
        laycoffset = -11, 
        layboffset = -11
    }, notify)
end

notify.setup_color = function(color, sec_color)
    -- Reset function
    if type(color) ~= 'table' then
        notify:setup()
        return
    end

    if notify.color == nil then notify:setup() end

    if color ~= nil then notify.color[1] = color end
    if sec_color ~= nil then notify.color[2] = sec_color end
end

notify.add = function(time, is_right, ...)
    if notify.color == nil then
        notify:setup()
    end

    table.insert(notify.__list, {
        ["tick"] = globals.tickcount(),
        ["invoke"] = notify.invoke_callback(),
        ["text"] = { ... }, ["time"] = time,
        ["color"] = notify.color,
        ["right"] = is_right,
        ["first"] = false
    })
end

function notify:setup()
    notify.color = { 
        { 150, 185, 1 },
        { 0, 0, 0 }
    }

    -- Due to security reasons
    if notify.__list == nil then
        notify.__list = {}
        client.delay_call(0.05, function()
            -- useless but ok
            -- notify.setup_color({ 25, 118, 210 })
        end)
    end
end

function notify:listener()
    local count_left = 0
    local count_right = 0
    local old_tick = 0

    if notify.__list == nil then
        notify:setup()
    end

    for i=1, #notify.__list do
        local layer = notify.__list[i]
        if layer.tick ~= old_tick then
            notify:setup()
        end

        if layer.right == true then
            layer.invoke:show_right(count_right, layer.color, layer.text)
            if layer.invoke.active then
                count_right = count_right + 1
            end
        else
            layer.invoke:show(count_left, layer.color, layer.text)
            if layer.invoke.active then
                count_left = count_left + 1
            end
        end

        if layer.first == false then
            layer.invoke:start(layer.time)
            notify.__list[i]["first"] = true
        end

        old_tick = layer.tick
    end
end

function notify:start(timeout)
    self.active = true
    self.delay = globals.realtime() + timeout
end

function notify:get_text_size(lines_combo)
    local x_offset_text = 0

    for i=1, #lines_combo do
        local r, g, b, message = unpack(lines_combo[i])
        local width, height = renderer.measure_text("", message)
        x_offset_text = x_offset_text + width
    end

    return x_offset_text
end

function notify:string_ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
 end

function notify:multicolor_text(x, y, flags, lines_combo)
    local line_height_temp = 0
    local x_offset_text = 0
    local y_offset = 0

    for i=1, #lines_combo do
        local r, g, b, message = unpack(lines_combo[i])

        message = message .. "\0"
        renderer.text(x + x_offset_text, y + y_offset, r, g, b, 255, flags, 0, message)

        if self:string_ends_with(message, "\0") then
            local width, height = renderer.measure_text(flags, message)
            x_offset_text = x_offset_text + width
        else
            x_offset_text = 0
            y_offset = y_offset + line_height_temp
        end
    end
end

function notify:show(count, color, text)
    if self.active ~= true then
        return
    end

    local x, y = client.screen_size()
    local y = 5 + (27 * count)
    local text_w, text_h = self:get_text_size(text)
    
    local max_width = text_w 
    local max_width = max_width < 150 and 150 or max_width 

    if color == nil then color = self.color end
    local factor = 255 / 25 * globals.frametime()

    if globals.realtime() < self.delay then
        if self.laycoffset < max_width then self.laycoffset = self.laycoffset + (max_width - self.laycoffset) * factor end
        if self.laycoffset > max_width then self.laycoffset = max_width end
        if self.laycoffset > max_width / 1.09 then
            if self.layboffset < max_width - 6 then
                self.layboffset = self.layboffset + ((max_width - 6) - self.layboffset) * factor
            end
        end

        if self.layboffset > max_width - 6 then
            self.layboffset = max_width - 6
        end
    else
        if self.layboffset > -11 then
            self.layboffset = self.layboffset - (((max_width-5)-self.layboffset) * factor) + 0.01
        end

        if self.layboffset < (max_width - 11) and self.laycoffset >= 0 then
            self.laycoffset = self.laycoffset - (((max_width + 1) - self.laycoffset) * factor) + 0.01
        end

        if self.laycoffset < 0 then 
            self.active = false
        end
    end

    renderer.rectangle(self.laycoffset - self.laycoffset, y, self.laycoffset + 16, 25, color[1][1], color[1][2], color[1][3], 255)
    renderer.rectangle(self.layboffset - self.laycoffset, y, self.layboffset + 22, 25, color[2][1], color[2][2], color[2][3], 255)
    self:multicolor_text(self.layboffset - max_width + 11, y + 6, "", text)
end

function notify:show_right(count, color, text)
    if self.active ~= true then
        return
    end

    local x, y = client.screen_size()
    local y = y - 68 - (27 * count)
    local text_w, text_h = self:get_text_size(text)
    
    local max_width = text_w + 22
    local max_width = max_width < 150 and 150 or max_width 

    if color == nil then color = self.color end
    local factor = 255 / 25 * globals.frametime()

    if globals.realtime() < self.delay then
        if self.laycoffset < max_width then self.laycoffset = self.laycoffset + (max_width - self.laycoffset) * factor end
        if self.laycoffset > max_width then self.laycoffset = max_width end
        if self.laycoffset > max_width / 1.09 then
            if self.layboffset < max_width - 6 then
                self.layboffset = self.layboffset + ((max_width - 6) - self.layboffset) * factor
            end
        end

        if self.layboffset > max_width - 6 then
            self.layboffset = max_width - 6
        end
    else
        if self.layboffset > 0 then
            self.layboffset = self.layboffset - (((max_width-5)-self.layboffset) * factor) + 0.01
        end

        if self.layboffset < (max_width - 11) and self.laycoffset >= 0 then
            self.laycoffset = self.laycoffset - (((max_width + 1) - self.laycoffset) * factor) + 0.01
        end

        if self.laycoffset < 0 then 
            self.active = false
        end
    end

    renderer.rectangle(x - self.laycoffset + 3, y, self.laycoffset + 3 + self.laycoffset, 25, color[1][1], color[1][2], color[1][3], 255)
    renderer.rectangle(x - self.layboffset + 3, y, self.layboffset + 3 + self.layboffset, 25, color[2][1], color[2][2], color[2][3], 255)
    self:multicolor_text(x - self.layboffset + 10, y + 6, "", text)
end

notify.__index = notify
client.set_event_callback("paint", function()
    notify:listener()
end)
local Votes = {
	IndicesNoteam = {
		[0] = "kick",
		[1] = "changelevel",
		[3] = "scrambleteams",
		[4] = "swapteams",
	},
	IndicesTeam = {
		[1] = 'starttimeout',
		[2] = 'surrender'
	},
	Descriptions = {
		changelevel = 'change the map',
		scrambleteams = 'scramble the teams',
		starttimeout = 'start a timeout',
		surrender = 'surrender',
		kick = 'kick'
	},

	OnGoingVotes = {},
	VoteOptions = {}
}

client.set_event_callback("run_command", function(e)
        for team, vote in pairs(Votes.OnGoingVotes) do
            if (entity.get_prop(vote.controller, 'm_iActiveIssueIndex') ~= vote.IssueIndex) then
                Votes.OnGoingVotes[team] = nil
            end
        end
end)

client.set_event_callback("vote_options", function(e)
    Votes.VoteOptions = {e.option1, e.option2, e.option3, e.option4, e.option5}
        for i =#Votes.VoteOptions, 1, -1 do
            if (Votes.VoteOptions[i] == '') then
                table.remove(Votes.VoteOptions, i)
            end
        end
end)

client.set_event_callback("vote_cast", function(e)
    client.delay_call(0.3, function()
        
            local team = e.team
            local base = Votes

            if (Votes.VoteOptions) then
                local controller
                local voteControllers = entity.get_all('CVoteController')

                for i = 1, #voteControllers do
                    if entity.get_prop(voteControllers[i], 'm_iOnlyTeamToVote') == team then
                        controller = voteControllers[i]
                        break
                    end
                end

                if (controller) then
                    local ongoingVote = {
                        team = team,
                        options = Votes.VoteOptions,
                        controller = controller,
                        IssueIndex = entity.get_prop(controller, 'm_iActiveIssueIndex'),
                        votes = {}
                    }

                    for i = 1, #Votes.VoteOptions do
                        ongoingVote.votes[Votes.VoteOptions[i]] = {}
                    end

                    ongoingVote.type = Votes.IndicesNoteam[ongoingVote.IssueIndex]
                    
                    if (team ~= -1 and Votes.IndicesTeam[ongoingVote.IssueIndex]) then
                        ongoingVote.type = Votes.IndicesTeam[ongoingVote.IssueIndex]
                    end

                    Votes.OnGoingVotes.team = ongoingVote
                end

                Votes.VoteOptions = nil
            end

            local ongoingVote = Votes.OnGoingVotes.team
            if (ongoingVote) then
                local player = e.entityid
                local voteText = ongoingVote.options[e.vote_option + 1]

                table.insert(ongoingVote.votes[voteText], player)

                if (voteText == 'Yes' and ongoingVote.caller == nil) then
                    ongoingVote.caller = player

                    if (ongoingVote.type ~= 'kick') then
                        local msg = entity.get_player_name(player) ..' called a vote to: '.. Votes.Descriptions[ongoingVote.type]
                        client.log(msg)
                        notify.setup_color({ 255, 255, 0 })
                        notify.add(15, true, { 150, 185, 1, entity.get_player_name(player)}, { 255, 255, 255, ' called a vote to: '}, { 0, 255, 255, Votes.Descriptions[ongoingVote.type]})
                    end
                end

                if (ongoingVote.type == 'kick') then
                    if (voteText == 'No') then
                        if (ongoingVote.target == nil) then
                            ongoingVote.target = player

                            local teamName = (team == 3 and 'CT\'s' or 'T\'s')
                            local msg = teamName ..' called a vote to '.. Votes.Descriptions[ongoingVote.type] .. ': ' .. entity.get_player_name(ongoingVote.target)
                            client.log(msg)
                            notify.setup_color({ 255, 0, 255 })
                            notify.add(15, true, { 255, 255, 255, teamName}, { 255, 255, 255, ' called a vote to '}, { 0, 255, 255, Votes.Descriptions[ongoingVote.type]}, { 255, 255, 255, ": "}, { 255, 178, 102, entity.get_player_name(ongoingVote.target)})
                        end
                    end
                end

                local msg = entity.get_player_name(player) ..' voted: '.. voteText
                client.log(msg)
                if voteText == 'No' then notify.setup_color({ 255, 24, 24 }) end
                if voteText == 'Yes' then notify.setup_color({ 127, 176, 0 }) end
                notify.add(15, true, { 150, 185, 1, entity.get_player_name(player)}, { 255, 255, 255, ': voted '}, { 25, 118, 210, voteText})
            end
        
    end)
end)