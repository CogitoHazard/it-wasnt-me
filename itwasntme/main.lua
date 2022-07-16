-- Note: The name of the .toc file must  match the name of the addon's folder
-- Also, apparently Lua wants functions to be defined before they're used,
-- at least when they're thrown in ad hoc like this.

-- Group Utility functions attach to this
IWM_GroupUtility = {}

-- Roll Utility functions attach to this
IWM_RollUtility = {}

-----------------------------------------------
-- MAIN BLAME LOGIC
-----------------------------------------------

-- Register our addon's chat prefix
local addonMessagePrefix = 'IWM_CHAT_PREFIX'
C_ChatInfo.RegisterAddonMessagePrefix(addonMessagePrefix)

-- Initiates a raid-wide blame roll by sending an addon
-- message to the raid channel with the blame start token.
local startBlameToken = 'IWM_BLAME_START'
local function StartBlameProcess()
    -- TODO: Update to use raid channel when we can test that?
    local myName = UnitName('player')
    local addonPayload = startBlameToken .. ' ' .. myName
    local channel = 'RAID' -- will change to party if not in raid
    print('sending blame start')
    --SendChatMessage('Okay wise guys, whose fault is this?', channel)
    C_ChatInfo.SendAddonMessage(addonMessagePrefix, addonPayload, channel)
end

-- When the raid leader initiates a blame roll,
-- generate a random d100 value, and then send
-- it via addon message in the format
-- [rollToken] [playerName] [rollValue]
-- so that we can parse the roll & who rolled it.
-- Make an emote based on the roll.
local rollBlameToken = 'IWM_BLAME_ROLL'
local function MakeBlameRoll()
    local roll = math.random(100)
    IWM_RollUtility.EmoteForRoll(roll)
    local channel = 'RAID' -- will change to party if not in raid
    local addonPayload = rollBlameToken .. ' ' .. name .. ' ' .. roll
    -- print('local addon payload: ' .. addonPayload)
    C_ChatInfo.SendAddonMessage(addonMessagePrefix, addonPayload, channel)
    -- print('addon chat sent')
    -- if success then
    -- print('posting my local roll succeeded')
    -- else
    -- print('posting my local roll failed')
    -- end
end

-----------------------------------------------
-- REGISTER SLASH COMMAND
-----------------------------------------------

-- We'll register this later to run when our slash command is recognized.
local function SlashCommandHandler(msg, _) -- _ here is 'editBox'
    StartBlameProcess()
end

-- Name the slash command. When the game sees this /[command] input,
-- it takes the name from SLASH_[YourNameHere] (ITWASNTME in our case)
-- and then uses that to check the global SlashCmdList.
SLASH_ITWASNTME1 = '/iwm'

-- Tell the game's chat handler what to run when the slash command is entered.
SlashCmdList['ITWASNTME'] = SlashCommandHandler

-----------------------------------------------
-- EVENT HANDLING
-- List of events: https://wowpedia.fandom.com/wiki/Events
-----------------------------------------------

-- Create a frame for listening to events
-- Events must come through a frame
local frame = CreateFrame('Frame')

-- A container to hold events we want to register
local events = {}

-- Fired when an addon sends a chat message
-- It sounds like these are supposed to be visible to players,
-- but I haven't been able to verify that. I don't see the
-- whisper that is sent as part of PLAYER_ENTERING_WORLD.
function events:CHAT_MSG_ADDON(prefix, message, channel, sender, ...)
    -- Filter out other addon's messages
    if prefix ~= addonMessagePrefix then
        return
    end

    -- Debug log our addon's events
    print(sender .. ' sent \'' .. message .. '\' ' .. ' in ' .. channel)

    -- Split the message into its event & parameters.
    -- The first parameter should always be our custom event.
    local iwmEvent, parameters = strsplit(' ', message, 2)
    if iwmEvent == startBlameToken then
        local shouldRespondToBlame = IWM_GroupUtility.ShouldRespondToBlameRequest(parameters)
        if shouldRespondToBlame then
            MakeBlameRoll()
        end
    end
end

-- Parameters sent by the event are
local function DispatchEvent(self, event, ...)
    events[event](self, ...)
end

-- Register the events we added to the events var
for event, _ in pairs(events) do
    frame:RegisterEvent(event)
end

-- Pass incoming events to the correct event handler
frame:SetScript("OnEvent", DispatchEvent)
