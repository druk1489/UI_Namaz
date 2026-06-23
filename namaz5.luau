--==================================================================
-- DEX EXPLORER for Solara (Luau) | PART 5/6 : PLAYERS PANEL
--==================================================================

assert(getgenv().DEX and getgenv().DEX.Loaded and getgenv().DEX.Loaded.Core,
	"[DEX] Сначала запусти PART 1 (Foundation)")

local DEX = getgenv().DEX
DEX.Loaded.Players = true

DEX.PlayersPanel = DEX.PlayersPanel or {
	Selected = nil,
	Spectating = nil,
	Filter = "",
	Rows = {},
}

local Players = DEX.Services.Players
local Workspace = DEX.Services.Workspace

----------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНОЕ
----------------------------------------------------------------
local function getCharacter(plr)
	local char = nil
	pcall(function()
		char = plr.Character
	end)
	return char
end

local function getHRP(plr)
	local hrp = nil
	local char = getCharacter(plr)
	if char then
		pcall(function()
			hrp = char:FindFirstChild("HumanoidRootPart")
				or char:FindFirstChild("Torso")
				or char:FindFirstChild("UpperTorso")
		end)
	end
	return hrp
end

local function getHumanoid(plr)
	local hum = nil
	local char = getCharacter(plr)
	if char then
		pcall(function()
			hum = char:FindFirstChildOfClass("Humanoid")
		end)
	end
	return hum
end

local function getPing(plr)
	local ping = nil
	pcall(function()
		ping = plr:GetNetworkPing() * 1000
	end)
	if ping then
		return string.format("%d ms", math.floor(ping))
	end
	return "n/a"
end

local function getTeam(plr)
	local team = "—"
	pcall(function()
		if plr.Team then
			team = plr.Team.Name
		end
	end)
	return team
end

local function loadAvatar(imageLabel, userId)
	task.spawn(function()
		local content = nil
		local ok = pcall(function()
			content = Players:GetUserThumbnailAsync(
				userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok and content then
			pcall(function()
				imageLabel.Image = content
			end)
		end
	end)
end

----------------------------------------------------------------
-- СТРАНИЦА И РАЗМЕТКА
----------------------------------------------------------------
local page = DEX.addTab("Players", 4)

-- ЛЕВО: список
local listHolder = DEX.new("Frame", {
	Size = UDim2.new(0, 250, 1, -16),
	Position = UDim2.new(0, 8, 0, 8),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(listHolder, 8)

local filterBox = DEX.new("TextBox", {
	Size = UDim2.new(1, -12, 0, 24),
	Position = UDim2.new(0, 6, 0, 6),
	BackgroundColor3 = DEX.Theme.Panel2,
	Font = Enum.Font.Gotham,
	PlaceholderText = "Поиск игрока...",
	Text = "",
	TextColor3 = DEX.Theme.Text,
	PlaceholderColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	ClearTextOnFocus = false,
	BorderSizePixel = 0,
	Parent = listHolder,
})
DEX.corner(filterBox, 6)
DEX.new("UIPadding", { PaddingLeft = UDim.new(0, 6), Parent = filterBox })

local refreshBtn = DEX.new("TextButton", {
	Size = UDim2.new(1, -12, 0, 22),
	Position = UDim2.new(0, 6, 0, 34),
	BackgroundColor3 = DEX.Theme.Accent,
	Font = Enum.Font.GothamMedium,
	Text = "Обновить список",
	TextColor3 = DEX.Theme.Text,
	TextSize = 12,
	BorderSizePixel = 0,
	Parent = listHolder,
})
DEX.corner(refreshBtn, 6)

local listScroll = DEX.makeScroll(listHolder)
listScroll.Position = UDim2.new(0, 0, 0, 62)
listScroll.Size = UDim2.new(1, 0, 1, -62)
DEX.new("UIListLayout", {
	Padding = UDim.new(0, 2),
	SortOrder = Enum.SortOrder.LayoutOrder,
	Parent = listScroll,
})
DEX.new("UIPadding", {
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 4),
	PaddingTop = UDim.new(0, 4),
	Parent = listScroll,
})

-- ПРАВО: детали
local detailHolder = DEX.new("Frame", {
	Size = UDim2.new(1, -274, 1, -16),
	Position = UDim2.new(0, 266, 0, 8),
	BackgroundColor3 = DEX.Theme.Panel,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Parent = page,
})
DEX.corner(detailHolder, 8)

local bigAvatar = DEX.new("ImageLabel", {
	Size = UDim2.new(0, 90, 0, 90),
	Position = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = DEX.Theme.Panel2,
	BorderSizePixel = 0,
	Image = "",
	Parent = detailHolder,
})
DEX.corner(bigAvatar, 8)

local detailLabel = DEX.new("TextLabel", {
	Size = UDim2.new(1, -120, 0, 90),
	Position = UDim2.new(0, 112, 0, 12),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "Выбери игрока слева",
	TextColor3 = DEX.Theme.Text,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextWrapped = true,
	Parent = detailHolder,
})

local function actionButton(text, offsetY, color)
	local btn = DEX.new("TextButton", {
		Size = UDim2.new(0, 150, 0, 30),
		Position = UDim2.new(0, 12, 0, offsetY),
		BackgroundColor3 = color,
		Font = Enum.Font.GothamMedium,
		Text = text,
		TextColor3 = DEX.Theme.Text,
		TextSize = 13,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Parent = detailHolder,
	})
	DEX.corner(btn, 6)
	return btn
end

local tpBtn       = actionButton("Телепорт к игроку", 118, DEX.Theme.Accent)
local spectateBtn = actionButton("Спектейт: OFF", 154, DEX.Theme.Panel2)
local copyIdBtn   = actionButton("Копировать UserId", 190, DEX.Theme.Panel2)

local statusLabel = DEX.new("TextLabel", {
	Size = UDim2.new(1, -24, 0, 24),
	Position = UDim2.new(0, 12, 0, 230),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	Text = "",
	TextColor3 = DEX.Theme.SubText,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = detailHolder,
})

----------------------------------------------------------------
-- ДЕТАЛИ ВЫБРАННОГО
----------------------------------------------------------------
local function updateSpectateBtn()
	if DEX.PlayersPanel.Spectating then
		spectateBtn.Text = "Спектейт: ON"
		spectateBtn.BackgroundColor3 = DEX.Theme.Good
	else
		spectateBtn.Text = "Спектейт: OFF"
		spectateBtn.BackgroundColor3 = DEX.Theme.Panel2
	end
end

local function selectPlayer(plr)
	DEX.PlayersPanel.Selected = plr
	local nm, disp, uid = "?", "?", 0
	pcall(function() nm = plr.Name end)
	pcall(function() disp = plr.DisplayName end)
	pcall(function() uid = plr.UserId end)

	detailLabel.Text = "@" .. nm
		.. "\nИмя: " .. disp
		.. "\nUserId: " .. tostring(uid)
		.. "\nПинг: " .. getPing(plr)
		.. "\nКоманда: " .. getTeam(plr)

	bigAvatar.Image = ""
	if uid > 0 then
		loadAvatar(bigAvatar, uid)
	end
	updateSpectateBtn()
end

----------------------------------------------------------------
-- СПИСОК ИГРОКОВ
----------------------------------------------------------------
local function clearList()
	for _, child in pairs(listScroll:GetChildren()) do
		if child:IsA("TextButton") then
			pcall(function() child:Destroy() end)
		end
	end
end

local function makePlayerRow(plr, order)
	local nm, uid = "?", 0
	pcall(function() nm = plr.Name end)
	pcall(function() uid = plr.UserId end)

	local row = DEX.new("TextButton", {
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = DEX.Theme.Panel2,
		Text = "",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		LayoutOrder = order,
		Parent = listScroll,
	})
	DEX.corner(row, 6)

	local avatar = DEX.new("ImageLabel", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundColor3 = DEX.Theme.Panel,
		BorderSizePixel = 0,
		Image = "",
		Parent = row,
	})
	DEX.corner(avatar, 15)
	if uid > 0 then
		loadAvatar(avatar, uid)
	end

	DEX.new("TextLabel", {
		Size = UDim2.new(1, -42, 1, 0),
		Position = UDim2.new(0, 40, 0, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		Text = nm,
		TextColor3 = DEX.Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = row,
	})

	DEX.connect(row.MouseEnter, function()
		row.BackgroundColor3 = DEX.Theme.Hover
	end)
	DEX.connect(row.MouseLeave, function()
		row.BackgroundColor3 = DEX.Theme.Panel2
	end)
	DEX.connect(row.MouseButton1Click, function()
		selectPlayer(plr)
	end)
end

local function renderList()
	clearList()
	local filter = string.lower(DEX.PlayersPanel.Filter)
	local list = {}
	pcall(function()
		list = Players:GetPlayers()
	end)
	local order = 0
	for _, plr in ipairs(list) do
		local nm = "?"
		pcall(function() nm = plr.Name end)
		local show = (filter == "" or string.find(string.lower(nm), filter, 1, true) ~= nil)
		if show then
			order = order + 1
			makePlayerRow(plr, order)
		end
	end
end

----------------------------------------------------------------
-- ДЕЙСТВИЯ
----------------------------------------------------------------
DEX.connect(tpBtn.MouseButton1Click, function()
	local target = DEX.PlayersPanel.Selected
	if not target then
		DEX.notify("Сначала выбери игрока")
		return
	end
	local myHRP = getHRP(DEX.LocalPlayer)
	local targetHRP = getHRP(target)
	if not myHRP then
		statusLabel.Text = "Твой персонаж не найден (мёртв?)"
		return
	end
	if not targetHRP then
		statusLabel.Text = "Персонаж игрока не найден"
		return
	end
	local ok = pcall(function()
		myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 3)
	end)
	if ok then
		statusLabel.Text = "Телепорт выполнен"
	else
		statusLabel.Text = "Ошибка телепорта"
	end
end)

DEX.connect(spectateBtn.MouseButton1Click, function()
	local cam = nil
	pcall(function()
		cam = Workspace.CurrentCamera
	end)
	if not cam then
		statusLabel.Text = "Камера не найдена"
		return
	end

	-- если уже спектатим — вернуться к себе
	if DEX.PlayersPanel.Spectating then
		local myHum = getHumanoid(DEX.LocalPlayer)
		pcall(function()
			cam.CameraSubject = myHum
		end)
		DEX.PlayersPanel.Spectating = nil
		statusLabel.Text = "Спектейт выключен"
		updateSpectateBtn()
		return
	end

	local target = DEX.PlayersPanel.Selected
	if not target then
		DEX.notify("Сначала выбери игрока")
		return
	end
	local targetHum = getHumanoid(target)
	if not targetHum then
		statusLabel.Text = "Humanoid игрока не найден"
		return
	end
	local ok = pcall(function()
		cam.CameraSubject = targetHum
	end)
	if ok then
		DEX.PlayersPanel.Spectating = target
		local nm = "?"
		pcall(function() nm = target.Name end)
		statusLabel.Text = "Спектейт: " .. nm
		updateSpectateBtn()
	else
		statusLabel.Text = "Ошибка спектейта"
	end
end)

DEX.connect(copyIdBtn.MouseButton1Click, function()
	local target = DEX.PlayersPanel.Selected
	if not target then
		return
	end
	local uid = 0
	pcall(function() uid = target.UserId end)
	pcall(function()
		setclipboard(tostring(uid))
	end)
	DEX.notify("UserId скопирован: " .. tostring(uid))
end)

DEX.connect(filterBox:GetPropertyChangedSignal("Text"), function()
	DEX.PlayersPanel.Filter = filterBox.Text
end)
DEX.connect(filterBox.FocusLost, function()
	renderList()
end)
DEX.connect(refreshBtn.MouseButton1Click, function()
	renderList()
end)

----------------------------------------------------------------
-- АВТО-ОБНОВЛЕНИЕ СПИСКА
----------------------------------------------------------------
if Players then
	DEX.connect(Players.PlayerAdded, function()
		task.wait(0.2)
		renderList()
	end)
	DEX.connect(Players.PlayerRemoving, function(plr)
		if DEX.PlayersPanel.Spectating == plr then
			DEX.PlayersPanel.Spectating = nil
			updateSpectateBtn()
		end
		task.delay(0.2, function()
			renderList()
		end)
	end)
end

----------------------------------------------------------------
-- СТАРТ
----------------------------------------------------------------
updateSpectateBtn()
renderList()

print("[DEX] PART 5/6 Players Panel загружена.")
