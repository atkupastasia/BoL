DisableOverlay()

local ProcessName = "OBS.exe"
local isStreamRunning = io.popen("tasklist /FI \"IMAGENAME eq "..ProcessName.."\"", "r")
if isStreamRunning then
	local output = (isStreamRunning:read("*all"))
	isStreamRunning:close()
	if not output:find(ProcessName) then
		EnableOverlay()
	end
end