local modemPort = 1337

-- Check for and initialize modem
local modem = peripheral.find("modem")
if not modem then
    error("A Modem is required", 0)
end
modem.open(modemPort)

-- Check for and initialize manipulator
local manipulator = peripheral.find("manipulator")
if not manipulator then
    error("A Manipulator is required", 0)
end

-- Verify required modules
if not manipulator.hasModule("plethora:chat") then
    error("The chat module is required", 0)
end

local hasClock = manipulator.hasModule("minecraft:clock")

-- Capture the time-based chat command
manipulator.capture("getTime()")

-- Main Loop
parallel.waitForAny(
    function()
        while true do
            local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
            if event == "modem_message" then
                print("Received message: " .. message)
                manipulator.tell(message)
            end
        end
    end,
    function()
        while true do
            local event, message, pattern = os.pullEvent("chat_capture")
            if message == "getTime()" and hasClock then
                local day = manipulator.getDay() + 1
                local gameTime = manipulator.getTime()
                
                local hours = math.floor(gameTime / 1000) + 6
                local minutes = math.floor((gameTime % 1000) * 60 / 1000)

                if hours >= 24 then
                    hours = hours - 24
                end

                if hours == 0 then
                    hours = 24
                end

                if string.len(minutes) < 2 then
                    minutes = "0" .. minutes
                end

                local finalTime = string.format("%02d:%02d", hours, minutes)
                manipulator.tell("It's " .. finalTime .. " on the " .. day .. ". day.")
            end
        end
    end
)
