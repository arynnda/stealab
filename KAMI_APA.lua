if getgenv().AUTO_GRAB_ACTIVE then return end
getgenv().AUTO_GRAB_ACTIVE = true

repeat task.wait() until game:IsLoaded()
print("KAMI•APA")

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

getgenv().TARGET_LIST = {
	"Ketchuru and Musturu",
	"Nuclearo Dinossauro",
	"Chicleteira Bicicleteira",
	"La Grande Combinasion",
	"Nooo My Hotspot",
	"Meowl",
	"Dragon Cannelloni",
	"Money Money Puggy",
	"Ketupat Kepat",
	"Tictac Sahur",
	"Strawberry Elephant",
	"Garama and Madundung",
	"Tang Tang Keletang",
	"Cooki and Milki",
	"Lavadorito Spinito",
	"Secret Lucky Block",
	"Festive Lucky Block",
	"Burguro And Fryuro",
	"Smurf Cat",
	"Money Money Reindeer",
	"List List List Sahur",
	"Ginger Gerat",
	"Jolly Jolly Sahur",
	"Capitano Moby",
	"Noobini Pizzanini",
	"Gold Elf"
}

getgenv().GRAB_RADIUS = 8
getgenv().HOLD_TIME = 2.5
getgenv().TARGET_TIMEOUT = 12
getgenv().WEBHOOK_URL = getgenv().WEBHOOK_URL or ""

getgenv().currentTarget = nil
getgenv().pendingItem = nil
getgenv().promptBusy = false
getgenv().targetStartTime = 0
getgenv()._AUTO_GRAB_HEARTBEAT = tick()

local function getChar()
	return player.Character
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function sendWebhook(msg)
	if getgenv().WEBHOOK_URL == "" then return end
	pcall(function()
		HttpService:PostAsync(
			getgenv().WEBHOOK_URL,
			HttpService:JSONEncode({ content = msg }),
			Enum.HttpContentType.ApplicationJson
		)
	end)
end

local function isTarget(model)
	local idx = model:GetAttribute("Index")
	if not idx then return false end
	for _, n in ipairs(getgenv().TARGET_LIST) do
		if idx == n then
			return true
		end
	end
	return false
end

local MONEY_NAMES = { "Cash","Money","Coins","Coin","Gold","Credits" }

task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	for _, v in ipairs(stats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			for _, n in ipairs(MONEY_NAMES) do
				if v.Name:lower() == n:lower() then
					local last = v.Value
					v.Changed:Connect(function(nv)
						if getgenv().currentTarget and nv < last then
							sendWebhook(
								"🛒 ITEM DIBELI\n" ..
								"📦 "..(getgenv().pendingItem or "Unknown").."\n" ..
								"💰 "..(last - nv)
							)
							getgenv().currentTarget = nil
							getgenv().pendingItem = nil
							getgenv().promptBusy = false
						end
						last = nv
					end)
					return
				end
			end
		end
	end
end)

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("Model") and isTarget(obj) then
		if not getgenv().currentTarget then
			getgenv().currentTarget = obj
			getgenv().pendingItem = obj:GetAttribute("Index") or obj.Name
			getgenv().targetStartTime = tick()
		end
	end
end)

ProximityPromptService.PromptShown:Connect(function(prompt)
	if not getgenv().currentTarget then return end
	if getgenv().promptBusy then return end
	if not prompt:IsDescendantOf(getgenv().currentTarget) then return end

	getgenv().promptBusy = true

	task.delay(0.3, function()
		if prompt and prompt.Parent
			and getgenv().currentTarget
			and getgenv().currentTarget.Parent then
			pcall(function()
				fireproximityprompt(prompt, getgenv().HOLD_TIME)
			end)
		end
		task.delay(getgenv().HOLD_TIME + 0.4, function()
			getgenv().promptBusy = false
		end)
	end)
end)

task.spawn(function()
	while true do
		getgenv()._AUTO_GRAB_HEARTBEAT = tick()

		local tgt = getgenv().currentTarget
		if tgt then
			if not tgt.Parent or tick() - getgenv().targetStartTime > getgenv().TARGET_TIMEOUT then
				getgenv().currentTarget = nil
				getgenv().pendingItem = nil
				getgenv().promptBusy = false
			else
				local part = tgt:FindFirstChildWhichIsA("BasePart")
				local hum = getHumanoid()
				local hrp = getHRP()
				if part and hum and hrp then
					if (hrp.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
						hum:MoveTo(part.Position)
					end
				end
			end
		end
		task.wait(0.7)
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		if tick() - getgenv()._AUTO_GRAB_HEARTBEAT > 60 then
			getgenv().currentTarget = nil
			getgenv().pendingItem = nil
			getgenv().promptBusy = false
			getgenv()._AUTO_GRAB_HEARTBEAT = tick()
		end
	end
end)

player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
end)

sendWebhook("✅ KAMI•APA Auto-Grab FINAL Aktif")
