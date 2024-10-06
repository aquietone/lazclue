local mq = require 'mq'

--[[
[Sun Sep 29 12:47:58 2024] Elias in the Penthouse says 'Where would you like to visit next?: Library, Dining Hall, Maze, Wedding Hall, Dragon Terrace, and Penthouse. We can go to any of these places if you wish. We are currently in the Penthouse. At any time we can come back here as well.'
[Sun Sep 29 13:06:32 2024] Tranquility says 'Who do you think the killer is? The Librarian, Disordered Spirit, Svartmane The Advisor, Ahhotep, Angry Chef, Daman The Bride'
[Sun Sep 29 13:06:37 2024] Tranquility says 'Where did the murder happen? Library, Dining Hall, Maze, Wedding Hall, Dragon Terrace, Penthouse'
[Sun Sep 29 13:06:40 2024] Tranquility says 'What weapon was used? Candlestick, Dagger, Crossbow, Flaming Mace, Rope, Battle Axe'
]]
local visitedLocationNPCs = {
    ['Commander Roland Grimblade'] = false,
    ['Alira Duskveil'] = false,
    ['Liriel Mooncrest'] = false,
    ['Thaddeus Ironspoon'] = false,
}
local visitedSuspects = {
    ['The Librarian'] = false,
    ['Angry Chef'] = false,
    ['Ahhotep'] = false,
    ['Daman The Bride'] = false,
    ['Disordered Spirit'] = false,
    ['Svartmane The Advisor'] = false,
}
local weapons = {['Candlestick']=true, ['Dagger']=true, ['Crossbow']=true, ['Flaming Mace']=true, ['Rope']=true, ['Battle Axe']=true}
local locations = {[1]='Library',['Library']=1,[2]='Dining Hall',['Dining Hall']=2,[3]='Maze',['Maze']=3,[4]='Wedding Hall',['Wedding Hall']=4,[5]='Dragon Terrace',['Dragon Terrace']=5,[6]='Penthouse',['Penthouse']=6}
local locationClues = {['Broken Staff']=true,['Burned Diary']=true,['Crushed Amulet']=true,['Torn Robe']=true}
local eliasSpawns = {['Library']='Elias in the Library',['Dining Hall']='Elias in the Dining Hall',['Maze']='Elias in the Maze',['Wedding Hall']='Elias in the Wedding Hall',['Dragon Terrace']='Elias in the Dragon Terrace',['Penthouse']='Elias in the Penthouse',}
local suspectsByLoc = {['Library']='The Librarian',['Dining Hall']='Angry Chef',['Maze']='Ahhotep',['Wedding Hall']='Daman The Bride',['Dragon Terrace']='Disordered Spirit',['Penthouse']='Svartmane The Advisor'}
local locNPCsByLoc = {['Library']='Liriel Mooncrest',['Dining Hall']='Thaddeus Ironspoon',['Maze']='Antediluvian',['Wedding Hall']='Alira Duskveil',['Dragon Terrace']='Black Drake',['Penthouse']='Commander Roland Grimblade'}
local clues = {What = 'Unknown',Where = 'Unknown',Who = 'Unknown'}
local groundspawns = {}
local weaponNPC = nil
local isOpen, shouldDraw = true, true
local currentLocation = 'Maze'
local recommendedWhere = nil
local openedPassage = false
local blackDrakeClue = nil
local redBlueDrakeClue = nil
local hailedElias = false

local function reportClue(where, who)
    if who:find('Elias') or who:find('Tranquility') then return end
    mq.cmd('/itemtarget')
    if mq.TLO.ItemTarget() then
        mq.cmdf('/popcustom 5 A clue spawned in %s', where, mq.TLO.ItemTarget.Name())
        table.insert(groundspawns, where)
        if currentLocation ~= where then recommendedWhere = where end
    end
end

mq.event('libraryclue', '#1# says \'#*#Library#*#', function(line, who) reportClue('Library', who) end)
mq.event('dininghallclue', '#1# says \'#*#Dining Hall#*#', function(line, who) reportClue('Dining Hall', who) end)
mq.event('mazeclue', '#1# says \'#*#Maze#*#', function(line, who) reportClue('Maze', who) end)
mq.event('weddinghallclue', '#1# says \'#*#Wedding Hall#*#', function(line, who) reportClue('Wedding Hall', who) end)
mq.event('dragonterraceclue', '#1# says \'#*#Dragon Terrace#*#', function(line, who) reportClue('Dragon Terrace', who) end)
mq.event('penthouseclue', '#1# says \'#*#Penthouse#*#', function(line, who) reportClue('Penthouse', who) end)

local function reportWhoClue(who)
    if clues.Who == 'Unknown' then
        mq.cmdf('/popcustom 5 The killer is %s', who)
        clues.Who = who
    end
end

mq.event('librarianclue', '#*#The Librarian glances around anxiously, hands fidgeting.#*#', function(line) reportWhoClue('The Librarian') end)
mq.event('angrychefclue', '#*#Angry Chef slams a fist on the table, eyes narrowing with irritation rather than remorse.#*#', function(line) reportWhoClue('Angry Chef') end)
mq.event('ahhotepclue', '#*#Ahhotep smirks slightly, his eyes gleaming with a hint of something... unsettling.#*#', function(line) reportWhoClue('Ahhotep') end)
mq.event('damanclue', '#*#Daman The Bride glares with a manic intensity, her eyes blazing with fury.#*#', function(line) reportWhoClue('Daman the Bride') end)
mq.event('disorderedclue', '#*#Disordered Spirit says \'No... it wasn#*#t me... was it? I don’t... remember. Shadows... they hide so much...\'#*#', function(line) reportWhoClue('Disordered Spirit') end)
mq.event('svartmaneclue', '#*#Svartmane The Advisor smiles slightly, his eyes calculating and calm.#*#', function(line) reportWhoClue('Svartmane') end)

mq.event('bluedrake1', '#*#If you ask the Red Drake, he would say I lie#*#', function() mq.cmdf('/popcustom 5 Blue Drake') redBlueDrakeClue = 'Blue Drake' end)
mq.event('reddrake1', '#*#If you ask the Blue Drake, he would say I lie#*#', function() mq.cmdf('/popcustom 5 Red Drake') redBlueDrakeClue = 'Red Drake' end)
mq.event('bluedrake2', '#*#If you ask the Red Drake, he would say I tell the truth#*#', function() mq.cmdf('/popcustom 5 Red Drake') redBlueDrakeClue = 'Red Drake' end)
mq.event('reddrake2', '#*#If you ask the Blue Drake, he would say I tell the truth#*#', function() mq.cmdf('/popcustom 5 Blue Drake') redBlueDrakeClue = 'Blue Drake' end)

mq.event('blackdrake1', '#*#cities, but no houses#*#', function() mq.cmdf('/popcustom 5 Map') blackDrakeClue = 'map' end)
mq.event('blackdrake2', '#*#speak without a mouth#*#', function() mq.cmdf('/popcustom 5 Echo') blackDrakeClue = 'echo' end)
mq.event('blackdrake3', '#*#not alive, yet I can grow#*#', function() mq.cmdf('/popcustom 5 Fire') blackDrakeClue = 'fire' end)
mq.event('blackdrake4', '#*#What has one eye#*#', function() mq.cmdf('/popcustom 5 Needle') blackDrakeClue = 'needle' end)
mq.event('blackdrake5', '#*#light as a feather#*#', function() mq.cmdf('/popcustom 5 Breath') blackDrakeClue = 'breath' end)
mq.event('blackdrake6', '#*#disappear as soon as you say my name#*#', function() mq.cmdf('/popcustom 5 Silence') blackDrakeClue = 'silence' end)
mq.event('blackdrake7', '#*#the less you see#*#', function() mq.cmdf('/popcustom 5 Darkness') blackDrakeClue = 'darkness' end)
mq.event('blackdrake8', '#*#What has keys#*#', function() mq.cmdf('/popcustom 5 Piano') blackDrakeClue = 'piano' end)

mq.event('antediluvianWho', '#*#The flames whisper... the murderer is #1#.', function(line, who) reportWhoClue(who) end)
mq.event('antediluvianWhere', '#*#The flames show... the crime took place in the #1#.', function(line, where) clues.Where = where mq.cmdf('/popcustom 5 The crime took place in the %s', where) end)
-- mq.event('antediluvianWhat', '#*#The flames whisper... the #1#.', function(line, what)  end)

local function updateLocation(line, where)
    if locations[where] then
        currentLocation = where
    end
end
mq.event('location', 'You say, \'#1#\'', updateLocation)

local function looted(line, item)
    if weapons[item] then
        clues.What = item
    end
end
mq.event('looted', '#*#You have looted a #1#.--#*#', looted)

local function reportVisited(line, who)
    if visitedLocationNPCs[who] ~= nil then visitedLocationNPCs[who] = true end
    if visitedSuspects[who] ~= nil then visitedSuspects[who] = true end
end
mq.event('visitedNPC', '#1# says \'#*#', reportVisited)

local function draw()
    if not isOpen then return end
    ImGui.SetNextWindowSize(600, 400)
    isOpen, shouldDraw = ImGui.Begin('Clue', isOpen)
    if shouldDraw then
        local zone = mq.TLO.Zone.ShortName()
        if zone == 'mischiefplane' then
            if (mq.TLO.Spawn('Clue').Distance3D() or 100) < 30 then
                if ImGui.Button('Get Task') then
                    mq.cmdf('/multiline ; /nav spawn clue ; /timed 10 /mqt clue ; /timed 13 /say clue ; /timed 20 /say ready')
                end
            else
                if ImGui.Button('Nav to Clue') then
                    mq.cmd('/nav spawn clue')
                end
            end
        elseif zone == 'frozenshadow' and not hailedElias then
            if ImGui.Button('Hail Elias before proceeding') then
                hailedElias = true
                mq.cmd('/multiline ; /mqt elias ; /timed 2 /keypress HAIL ; /timed 3 /keypress HAIL ; /timed 4 /say where')
            end
        elseif zone ~= 'frozenshadow' then
            ImGui.Text('Go to Plane of Mischief (mischiefplane)')
        elseif zone == 'frozenshadow' then
            ImGui.Text('Who: ') ImGui.SameLine()
            if clues.Who == 'Unknown' then ImGui.TextColored(1,0,0,1,'%s',clues.Who) else ImGui.TextColored(0,1,0,1,'%s',clues.Who) end ImGui.SameLine()
            ImGui.Text('Where: ') ImGui.SameLine()
            if clues.Where == 'Unknown' then ImGui.TextColored(1,0,0,1,'%s',clues.Where) else ImGui.TextColored(0,1,0,1,'%s',clues.Where) end ImGui.SameLine()
            ImGui.Text('What: ') ImGui.SameLine()
            if clues.What == 'Unknown' then ImGui.TextColored(1,0,0,1,'%s',clues.What) else ImGui.TextColored(0,1,0,1,'%s',clues.What) end
            ImGui.Separator()
            ImGui.Columns(2)
            ImGui.Text('Suspects:')
            ImGui.NextColumn()
            ImGui.Text('Location Clue NPCs:')
            ImGui.NextColumn()
            ImGui.Separator()
            for name,visited in pairs(visitedSuspects) do
                if not visited then ImGui.TextColored(1,0,0,1,'%s',name) else ImGui.TextColored(0,1,0,1,'%s',name) end
            end
            ImGui.NextColumn()
            for name,visited in pairs(visitedLocationNPCs) do
                if not visited then ImGui.TextColored(1,0,0,1,'%s',name) else ImGui.TextColored(0,1,0,1,'%s',name) end
            end
            ImGui.Columns(1)
            ImGui.Separator()
            ImGui.PushItemWidth(100)
            ---@diagnostic disable-next-line: param-type-mismatch, cast-local-type
            currentLocation = locations[ImGui.Combo('Current Floor', locations[currentLocation], 'Library\0Dining Hall\0Maze\0Wedding Hall\0Dragon Terrace\0Penthouse\0')]
            ImGui.PopItemWidth()
            if ImGui.Button('Nav To Elias') then
                mq.cmdf('/nav spawn %s', eliasSpawns[currentLocation])
            end
            ImGui.SameLine()
            if (mq.TLO.Spawn(suspectsByLoc[currentLocation]).Distance3D() or 100) < 20 then
                if ImGui.Button(('Talk to %s'):format(suspectsByLoc[currentLocation])) then
                    mq.cmdf('/multiline ; /mqt %s ; /timed 2 /keypress HAIL ; /timed 3 /say what', suspectsByLoc[currentLocation])
                end
            else
                if ImGui.Button(('Nav To %s'):format(suspectsByLoc[currentLocation])) then
                    mq.cmdf('/nav spawn %s', suspectsByLoc[currentLocation])
                end
            end
            ImGui.SameLine()
            if currentLocation == 'Penthouse' and mq.TLO.Spawn('Red Drake')() then
                if (mq.TLO.Spawn('Red Drake').Distance3D() or 100) < 20 then
                    if not redBlueDrakeClue then
                        if ImGui.Button('Say Truth') then
                            mq.cmd('/multiline ; /mqt red drake ; /timed 2 /say truth')
                        end
                    else
                        if ImGui.Button('Say '..redBlueDrakeClue) then
                            mq.cmdf('/multiline ; /mqt drake ; /say %s', redBlueDrakeClue)
                        end
                    end
                else
                    if ImGui.Button('Nav To Red Drake') then
                        mq.cmd('/nav spawn red drake | dist=15')
                    end
                end
            else
                if (mq.TLO.Spawn(locNPCsByLoc[currentLocation]).Distance3D() or 100) < 20 then
                    if currentLocation == 'Dragon Terrace' and blackDrakeClue and not mq.TLO.Spawn('Secret Passage')() then
                        if ImGui.Button('Say '..blackDrakeClue) then
                            mq.cmdf('/multiline ; /mqt black drake ; /timed 2 /say %s', blackDrakeClue)
                            blackDrakeClue = nil
                        end
                    elseif currentLocation ~= 'Maze' then
                        if ImGui.Button(('Talk to %s'):format(locNPCsByLoc[currentLocation])) then
                            mq.cmdf('/multiline ; /mqt %s ; /timed 2 /keypress HAIL', locNPCsByLoc[currentLocation])
                        end
                    end
                else
                    if ImGui.Button(('Nav To %s'):format(locNPCsByLoc[currentLocation])) then
                        mq.cmdf('/nav spawn %s', locNPCsByLoc[currentLocation])
                    end
                end
            end
            if ImGui.Button('Nav To Groundspawn') then
                mq.cmd('/itemtar')
                if mq.TLO.ItemTarget() then
                    mq.cmd('/squelch /nav item click')
                end
            end
            if currentLocation == 'Dining Hall' then
                ImGui.SameLine()
                if ImGui.Button('Nav To Secret Passage') then
                    mq.cmd('/nav spawn secret passage')
                end
            end
            ImGui.Separator()
            ImGui.Text('Click next to Elias to go to:')
            for i,location in ipairs(locations) do
                local shouldPopColor = false
                if recommendedWhere == location then ImGui.PushStyleColor(ImGuiCol.Button, 0,1,0,1) shouldPopColor = true end
                if ImGui.Button(location) then
                    if (mq.TLO.Spawn(eliasSpawns[currentLocation]).Distance3D() or 200) > 100 then
                        mq.cmdf('/nav spawn %s', eliasSpawns[currentLocation])
                    else
                        mq.cmd('/tar npc elias')
                        mq.cmdf('/timed 5 /say %s', location)
                        if recommendedWhere == location then recommendedWhere = nil end
                    end
                end
                if shouldPopColor then ImGui.PopStyleColor() shouldPopColor = false end
                if i ~= 6 then ImGui.SameLine() end
            end
            ImGui.Separator()
            ImGui.Text('Spawns:')
            for _,groundspawn in ipairs(groundspawns) do
                ImGui.Text('Ground Spawn in: %s', groundspawn)
            end
            if weaponNPC then
                ImGui.Text('Weapon Mob Spawned: %s', weaponNPC)
            end
        end
    end
    ImGui.End()
end

mq.imgui.init('Clue', draw)

while isOpen do
    mq.doevents()
    if clues.Where == 'Unknown' and mq.TLO.Cursor() then
        for item,_ in pairs(locationClues) do
            if mq.TLO.Cursor.Name() and mq.TLO.Cursor.Name():find(item) then
                mq.cmdf('/popcustom 5 Found strong location evidence Tserrina\'s %s', item)
                clues.Where = currentLocation
            end
        end
    end
    if clues.What == 'Unknown' and mq.TLO.Cursor() and weapons[mq.TLO.Cursor()] then
        mq.cmdf('/popcustom 5 Found weapon %s', mq.TLO.Cursor())
        clues.What = mq.TLO.Cursor()
    end
    if mq.TLO.Cursor() then
        for i,loc in ipairs(groundspawns) do if loc == currentLocation then table.remove(groundspawns,i) break end end
    end
    if not weaponNPC then
        if mq.TLO.Spawn('Cloaked Confidante')() then
            weaponNPC = 'Cloaked Confidante in the Dining Hall'
        elseif mq.TLO.Spawn('Elusive Henchman')() then
            weaponNPC = 'Elusive Henchman in the Wedding Hall'
        elseif mq.TLO.Spawn('Dark Associate')() then
            weaponNPC = 'Dark Associate in the Dragon Terrace'
        elseif mq.TLO.Spawn('Sinister Conspirator')() then
            weaponNPC = 'Sinister Conspirator in the Library'
        end
    end
    if not openedPassage and mq.TLO.Spawn('Secret Passage')() then
        openedPassage = true
    end
    if clues.Who ~= 'Unknown' and clues.Where ~= 'Unknown' and clues.What ~= 'Unknown' then
        if not openedPassage and currentLocation ~= 'Dragon Terrace' then
            recommendedWhere = 'Dragon Terrace'
        elseif openedPassage and currentLocation ~= 'Dining Hall' then
            recommendedWhere = 'Dining Hall'
        elseif not openedPassage and currentLocation == 'Dragon Terrace' then
            recommendedWhere = nil
        elseif openedPassage and currentLocation == 'Dining Hall' then
            recommendedWhere = nil
        end
    end
    mq.delay(500)
end