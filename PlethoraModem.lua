local modemPort = 1337
--------------------------------
local modem = peripheral.find("modem")
if not modem then
	error("We need a Modem", 0)
end
modem.open(1337)

local manipulator = peripheral.find("manipulator")
if not manipulator then
	error("We need a manipulator", 0)
end
if manipulator.hasModule("plethora:chat") == false then
	error("We need the chat module", 0)
end

manipulator.capture("getTime()")
--Main Loop
parallel.waitForAny(
	function()
		while true do
			local event, modemSide, senderChannel, replyChannel, message, senderDistance = os.pullEvent("modem_message")
			if event == "modem_message" then
				print("The message was: "..message)
				manipulator.tell(message)
			end
		end
	end,
	function()
		while true do
			os.pullEvent("getTime()")
			local day = manipulator.getDay()
			local gameTime = manipulator.getTime();
        	local hours = gameTime / 1000 + 6
        	local minutes = (gameTime % 1000) * 60 / 1000
        	local ampm = "AM"
        	if (hours >= 12) then
            	hours -= 12 
				ampm = "PM"
        	end
 
        	if (hours >= 12) then
            	hours -= 12
 				ampm = "AM"
        	end
 
       	 	if (hours == 0) then hours = 12 end
 
        	local mm = "0" .. minutes
        	mm = strsub(mm, strlen(mm) - 2, strlen(mm));
 
        	local finaltime = hours .. ":" .. mm .. " " .. ampm;
			manipulator.tell("It's " .. finaltime .. " on the " .. day .. ". day.")
		end
	end
)