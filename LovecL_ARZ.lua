--[[ Информация о скрипте ]]
script_name("LovecL ARZ")
script_author("Koora")
script_version("2.2")

local update_json_url = "https://raw.githubusercontent.com/Josu2003/LovecL_ARZ/refs/heads/main/update.json"
local updateVersion = ""
local updateChangelog = ""
local updateUrl = ""

--[[ Подключение библиотек ]]
local missingLibraries = {}

local function loadLibrary(moduleName)
    local ok, library = pcall(require, moduleName)
    if not ok then
        table.insert(missingLibraries, moduleName)
        return nil
    end
    return library
end

local cef = loadLibrary('arizona-cef-dialogs')
local ti = loadLibrary('tabler_icons')
local imgui = loadLibrary('mimgui')
loadLibrary('lib.sampfuncs')
local samp = loadLibrary('samp.events')
local ffi = loadLibrary('ffi')
local vkeys = loadLibrary('vkeys')
local encoding = loadLibrary('encoding')
local inicfg = loadLibrary('inicfg')

if #missingLibraries > 0 then
    function main()
        while not isSampAvailable() do
            wait(100)
        end

        sampAddChatMessage('{FF0000}[LovecL] Не удалось загрузить необходимые библиотеки:', -1)
        for _, moduleName in ipairs(missingLibraries) do
            sampAddChatMessage('{0ABDC6}[LovecL] {FFFF00}Установите библиотеку: ' .. moduleName, -1)
        end
        sampAddChatMessage('{0ABDC6}[LovecL] {FF0000}Скрипт остановлен. Установите библиотеки и перезапустите игру или прожмите комбинацию CTRL + R', -1)
    end
    return
end

--[[ Шрифты для предупреждений на экране ]]
local renderFont = renderCreateFont("Arial", 8, 5)
local renderFontSmall = renderCreateFont("Arial", 10, 5)

--[[ Загрузка шрифта иконок ]]
local function loadIconicFont(fontSize)
    local config = imgui.ImFontConfig()
    config.MergeMode = true
    config.PixelSnapH = true
    local iconRanges = imgui.new.ImWchar[3](ti.min_range, ti.max_range, 0)
    imgui.GetIO().Fonts:AddFontFromMemoryCompressedBase85TTF(ti.get_font_data_base85(), fontSize, config, iconRanges)
end

imgui.OnInitialize(function()
    loadIconicFont(20)
    imgui.GetIO().IniFilename = nil
end)

--[[ Проверка и создание папки конфигурации ]]
local dirLovecL = getWorkingDirectory() .. '/config/LovecL/'
if not doesDirectoryExist(dirLovecL) then
    createDirectory(dirLovecL)
end

--[[ Загрузка и создание конфигурации ]]
local directIni = "LovecL/LovecL.ini"
local ini = inicfg.load({
    main = {
        shopName = "",
        theme = 0,
        delay = 1,
        offFloodChatMessage = true,
        silentMode = false,
        selectedColor = 0,
        isRandomColor = false,
        autoSell = false,
        autoSellPrice = 1000000,
        autoSellPriceVC = 10000,
        disableDistanceCheck = false,
        searchSellingShops = true,
        autoLuxuryZavoz = true,
        showFloodStats = false,
        renderLineColorR = 0.47,
        renderLineColorG = 1.0,
        renderLineColorB = 0.0,
        renderLineColorA = 1.0,
        renderTextColorR = 0.47,
        renderTextColorG = 1.0,
        renderTextColorB = 0.0,
        renderTextColorA = 1.0,
        saleLineColorR = 0.0,
        saleLineColorG = 0.0,
        saleLineColorB = 1.0,
        saleLineColorA = 1.0,
        saleTextColorR = 0.0,
        saleTextColorG = 0.0,
        saleTextColorB = 1.0,
        saleTextColorA = 1.0,
        renderLineThickness = 1.0

    }
}, directIni)

if not doesFileExist(getWorkingDirectory() .. '/' .. directIni) then
    inicfg.save(ini, directIni)
end

--[[ Кодировка ]]
encoding.default = 'CP1251'
local u8 = encoding.UTF8

--[[ Состояние окон и вкладок ]]
local WinState = imgui.new.bool(false)
local InfoWindow = imgui.new.bool(false)
local LavkaSettingsWindow = imgui.new.bool(false)
local RenderSettings = imgui.new.bool(false)
local showDonateWindowFlag = imgui.new.bool(false)
local currentTab = 1
local mainWindowPos = nil
local windowUpdate = imgui.new.bool(false)

--[[ Настройки тем оформления ]]
local themes = {u8"Березовая", u8"Тёмная (Тёмно-красная)", u8"Неоновый киберпанк (Пурпурно-розовая)", u8"Электрический синий (Кобальт)", u8"Мятный сад"}
local currentTheme = imgui.new.int(ini.main.theme or 0)

--[[ Данные лавки ]]
local shopName = ini.main.shopName and u8:decode(ini.main.shopName) or ""
local delay = imgui.new.int(ini.main.delay or 0)
local shopNameBuf = imgui.new.char[64](u8(shopName))
local autoSell = imgui.new.bool(ini.main.autoSell or false)
local autoSellPrice = imgui.new.int(math.min(math.max(tonumber(ini.main.autoSellPrice) or 1000000, 500000), 50000000))
local autoSellPriceVC = imgui.new.int(math.min(math.max(tonumber(ini.main.autoSellPriceVC) or 10000, 10000), 1000000))

--[[ Цвета чата ]]
local colors = {
    turquoise   = "{0ABDC6}", -- Бирюзовый
    red         = "{FF0000}", -- Красный
    white       = "{FFFFFF}", -- Белый
    green       = "{00FF00}", -- Зеленый
    greenBright = "{0eff0e}", -- Ярко-зеленый
    redLower    = "{ff0000}", -- Красный (нижний регистр)
    whiteLower  = "{ffffff}", -- Белый (нижний регистр)
}

--[[ Ссылки и QR-код ]]
local donatalertsURL = "https://www.donationalerts.com/r/koora"
local qrBase64 = "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"
local qrTexture = nil

-- Список названий цветов для Combo
local selectedColor = imgui.new.int(ini.main.selectedColor or 0)
local isRandomColor = imgui.new.bool(ini.main.isRandomColor or false)
local colorList = {
    { name = u8"Красный", col = imgui.ImVec4(1.0, 0.25, 0.25, 1.0) },
    { name = u8"Розовый", col = imgui.ImVec4(1.0, 0.3, 0.75, 1.0) },
    { name = u8"Фиолетовый", col = imgui.ImVec4(0.7, 0.25, 1.0, 1.0) },
    { name = u8"Сине-фиолетовый", col = imgui.ImVec4(0.35, 0.3, 1.0, 1.0) },
    { name = u8"Голубой", col = imgui.ImVec4(0.25, 0.75, 1.0, 1.0) },
    { name = u8"Бирюзовый", col = imgui.ImVec4(0.25, 1.0, 0.95, 1.0) },
    { name = u8"Мятный", col = imgui.ImVec4(0.25, 1.0, 0.7, 1.0) },
    { name = u8"Салатовый", col = imgui.ImVec4(0.25, 1.0, 0.25, 1.0) },
    { name = u8"Желто-зеленый", col = imgui.ImVec4(0.7, 1.0, 0.25, 1.0) },
    { name = u8"Желтый", col = imgui.ImVec4(1.0, 0.95, 0.25, 1.0) },
    { name = u8"Оранжевый", col = imgui.ImVec4(1.0, 0.75, 0.25, 1.0) },
    { name = u8"Темно-оранжевый", col = imgui.ImVec4(1.0, 0.45, 0.25, 1.0) },
    { name = u8"Темно-красный", col = imgui.ImVec4(0.7, 0.1, 0.1, 1.0) },
    { name = u8"Темно-синий", col = imgui.ImVec4(0.1, 0.2, 0.7, 1.0) },
    { name = u8"Темно-зеленый", col = imgui.ImVec4(0.1, 0.6, 0.1, 1.0) },
    { name = u8"Белый", col = imgui.ImVec4(0.95, 0.95, 0.95, 1.0) }
}

--[[ Тексты скрипта ]]
local nameScript = "[LovecL] "
local text_shopName = "Текущее название лавки: "
local text_saveNameShop = "Название лавки сохранено: "
local text_checkCharacters = "Пожалуйста, укажите новое название лавки (от 3 до 20 символов)"

--[[ Состояние функций и статистика ловли ]]
local isActiveFlood = false
local isSpammingAlt = false
local autoSellFlow = false
local isActiveRender = false
local isActiveCleaner = false
local isActiveLuxury = false
local floodLuxury = false
local floodKeyRepeats = 2
local floodStartedAt = 0
local floodElapsedMs = 0
local floodKeyPresses = {}
local floodCps = 0
local luxuryCount = 0

--[[ Переключатели поведения и сообщений ]]
local disableDistanceCheck = imgui.new.bool(ini.main.disableDistanceCheck or false)
local offFloodChatMessage = imgui.new.bool(ini.main.offFloodChatMessage ~= false)
local silentMode = imgui.new.bool(ini.main.silentMode or false)
local showFloodStats = imgui.new.bool(ini.main.showFloodStats or false)
local renderEnabled = imgui.new.bool(false)
local autoLuxuryZavoz = imgui.new.bool(ini.main.autoLuxuryZavoz ~= false)


--[[ Данные рендера лавок и цветов ]]
local renderMassive = {}
local shopStatus = {}
local reserveTimerObj = {}
local reserveLabelObjects = {}
local reserveLabelData = {}
local pendingReserveLabels = {}
local objectDrawDistanceAvailable = true
local searchSellingShops = imgui.new.bool(ini.main.searchSellingShops ~= false)
local lineColor = imgui.new.float[4](
    tonumber(ini.main.renderLineColorR) or 0.47,
    tonumber(ini.main.renderLineColorG) or 1.0,
    tonumber(ini.main.renderLineColorB) or 0.0,
    tonumber(ini.main.renderLineColorA) or 1.0
)
local textColor = imgui.new.float[4](
    tonumber(ini.main.renderTextColorR) or 0.47,
    tonumber(ini.main.renderTextColorG) or 1.0,
    tonumber(ini.main.renderTextColorB) or 0.0,
    tonumber(ini.main.renderTextColorA) or 1.0
)
local saleLineColor = imgui.new.float[4](
    tonumber(ini.main.saleLineColorR) or 0.0,
    tonumber(ini.main.saleLineColorG) or 0.0,
    tonumber(ini.main.saleLineColorB) or 1.0,
    tonumber(ini.main.saleLineColorA) or 1.0
)
local saleTextColor = imgui.new.float[4](
    tonumber(ini.main.saleTextColorR) or 0.0,
    tonumber(ini.main.saleTextColorG) or 0.0,
    tonumber(ini.main.saleTextColorB) or 1.0,
    tonumber(ini.main.saleTextColorA) or 1.0
)
local lineThickness = imgui.new.float(tonumber(ini.main.renderLineThickness) or 1.0)
local defaultLineColor = {0.47, 1.0, 0.0, 1.0}
local defaultTextColor = {0.47, 1.0, 0.0, 1.0}
local defaultSaleLineColor = {0.0, 0.0, 1.0, 1.0}
local defaultSaleTextColor = {0.0, 0.0, 1.0, 1.0}

--[[Функция проврки обновы]]
function checkUpdate()
    local update_path = getWorkingDirectory() .. "/config/LovecL/update.json"
    local current_version = thisScript().version

    downloadUrlToFile(update_json_url, update_path, function(id, status, p1, p2)
        if status == 6 then 
            if os.rename(update_path, update_path) then
                local f = io.open(update_path, "r")
                if f then
                    local content = f:read("*a")
                    f:close()
                    os.remove(update_path)

                    local ok, data = pcall(decodeJson, content)
                    if ok and data and data.version then
                        if tostring(data.version) ~= current_version then
                            updateVersion = tostring(data.version)
                            updateChangelog = data.changelog or "Описание изменений отсутствует."
                            updateUrl = data.url
                            
                            -- Уведомление в чат с правильным именем команды
                            sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Доступно новое обновление" .. colors.green .. " v" .. updateVersion .. colors.white .. "! Введите" .. colors.red .. " /updatelovecl" .. colors.white .. ", чтобы обновиться.", -1)
                        end
                    end
                end
            end
        end
    end)
end

--[[ Запуск обновы ]]
function startUpdate(download_url)
    local script_path = thisScript().path

    downloadUrlToFile(download_url, script_path, function(id, status, p1, p2)
        if status == 6 then
            sampAddChatMessage(colors.turquoise .. nameScript .. colors.green .. " Скрипт успешно обновлен! Перезагрузка...", -1)
            thisScript():reload()
        elseif status == 3 then
            sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. " Ошибка скачивания обновления!", -1)
        end
    end)
end

local function saveColorToIni(prefix, color)
    ini.main[prefix .. "R"] = color[0]
    ini.main[prefix .. "G"] = color[1]
    ini.main[prefix .. "B"] = color[2]
    ini.main[prefix .. "A"] = color[3]
    inicfg.save(ini, directIni)
end
--[[ Данные клавиш для проверки нажатия ]]
local keysData = {
    [1024] = {structElement = 4, size = 2}, -- ALT
    [64] = {structElement = 36, size = 1},  -- Y
    [128] = {structElement = 36, size = 1}, -- N / RMB
    [192] = {structElement = 36, size = 1}  -- H
}

--[[ Функция для сброса цвета к значению по умолчанию ]]
local function resetColorToDefault(color, defaultColor, prefix)
    for index = 0, 3 do
        color[index] = defaultColor[index + 1]
    end
    saveColorToIni(prefix, color)
end

--[[ Функция для конвертации RGBA в ARGB ]]
local function rgbaToARGB(color)
    local red = math.floor((color[1] or 1) * 255)
    local green = math.floor((color[2] or 1) * 255)
    local blue = math.floor((color[3] or 1) * 255)
    local alpha = math.floor((color[4] or 1) * 255)
    return bit.bor(bit.lshift(alpha, 24), bit.lshift(red, 16), bit.lshift(green, 8), blue)
end

--[[ Функция для сброса рендера лавок ]]
local function resetRender()
    renderMassive = {}
    shopStatus = {}
    reserveTimerObj = {}
    reserveLabelObjects = {}
    reserveLabelData = {}
    pendingReserveLabels = {}
    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Рендер лавок обновлён. Обновите зону стрима.", -1)
end

--[[ Прикрепляет таймер брони к ближайшей свободной лавке ]]
local function attachReserveTimer(position, minutes, labelId, expiresAt)
    local timerEnd = expiresAt or (os.time() + math.max(minutes, 0) * 60)
    local linkedObject = labelId and reserveLabelObjects[labelId]
    if linkedObject and doesObjectExist(linkedObject) and shopStatus[linkedObject] == "free" then
        reserveTimerObj[linkedObject] = timerEnd
        reserveLabelData[labelId] = {position = position, expiresAt = timerEnd}
        return true
    end

    local nearestObject = nil
    local nearestDistance = 3.0

    for _, object in ipairs(renderMassive) do
        if shopStatus[object] == "free" and not reserveTimerObj[object] and doesObjectExist(object) then
            local success, x, y, z = getObjectCoordinates(object)
            if success then
                local distance = math.sqrt(
                    (x - position.x) ^ 2 +
                    (y - position.y) ^ 2 +
                    (z - position.z) ^ 2
                )
                if distance < nearestDistance then
                    nearestObject = object
                    nearestDistance = distance
                end
            end
        end
    end

    if nearestObject then
        reserveTimerObj[nearestObject] = timerEnd
        if labelId then
            reserveLabelObjects[labelId] = nearestObject
            reserveLabelData[labelId] = {position = position, expiresAt = timerEnd}
        end
        return true
    end

    return false
end

--[[ Прикрепляет отложенные таймеры после появления лавок ]]
local function attachPendingReserveLabels()
    for index = #pendingReserveLabels, 1, -1 do
        local label = pendingReserveLabels[index]
        if attachReserveTimer(label.position, label.minutes, label.id, label.expiresAt) then
            table.remove(pendingReserveLabels, index)
        end
    end
end

--[[ Очищает таймер текста или объекта и сохраняет его при выгрузке ]]
local function clearReserveData(labelId, object, preserveLabels)
    if labelId then
        local linkedObject = reserveLabelObjects[labelId]
        if linkedObject then
            reserveTimerObj[linkedObject] = nil
        end
        reserveLabelObjects[labelId] = nil
        reserveLabelData[labelId] = nil
    end

    if object then
        reserveTimerObj[object] = nil
        for currentLabelId, linkedObject in pairs(reserveLabelObjects) do
            if linkedObject == object then
                reserveLabelObjects[currentLabelId] = nil
                if preserveLabels and reserveLabelData[currentLabelId] then
                    local labelData = reserveLabelData[currentLabelId]
                    table.insert(pendingReserveLabels, {
                        id = currentLabelId,
                        position = labelData.position,
                        expiresAt = labelData.expiresAt,
                        minutes = math.max(0, (labelData.expiresAt - os.time()) / 60)
                    })
                else
                    reserveLabelData[currentLabelId] = nil
                end
            end
        end
    end

    for index = #pendingReserveLabels, 1, -1 do
        if pendingReserveLabels[index].id == labelId then
            table.remove(pendingReserveLabels, index)
        end
    end
end

--[[ Функция отрисовки рендера ]]
local function drawRender()
    if not isActiveRender or #renderMassive == 0 then
        return
    end

    local input = sampGetInputInfoPtr()
    if not input then
        return
    end

    local inputStruct = getStructElement(input, 0x8, 4)
    local posX = getStructElement(inputStruct, 0x8, 4)
    local posY = getStructElement(inputStruct, 0xC, 4)
    local saleCount = 0

    for _, object in ipairs(renderMassive) do
        if searchSellingShops[0] and shopStatus[object] == "sale" then
            saleCount = saleCount + 1
        end
    end

    local headerY = posY + 60
    local freeCount = 0
    for _, object in ipairs(renderMassive) do
        if shopStatus[object] ~= "sale" then
            freeCount = freeCount + 1
        end
    end
    local headerX = posX
    local prefixText = colors.turquoise .. nameScript .. colors.white .. " "
    local freeText = string.format("Свободных: %d", freeCount)
    local separatorText = " | "
    local saleText = string.format("Продаются: %d", saleCount)

    renderFontDrawText(renderFont, prefixText, headerX, headerY, 0xFFFFFFFF, 0x90000000)
    headerX = headerX + renderGetFontDrawTextLength(renderFont, prefixText)
    renderFontDrawText(renderFont, freeText, headerX, headerY, 0xFF00FF00, 0x90000000)

    if searchSellingShops[0] then
        headerX = headerX + renderGetFontDrawTextLength(renderFont, freeText)
        renderFontDrawText(renderFont, separatorText, headerX, headerY, 0xFFFFFFFF, 0x90000000)
        headerX = headerX + renderGetFontDrawTextLength(renderFont, separatorText)
        renderFontDrawText(renderFont, saleText, headerX, headerY, 0xFF0000FF, 0x90000000)
    end

    for _, object in ipairs(renderMassive) do
        if (searchSellingShops[0] or shopStatus[object] ~= "sale") and doesObjectExist(object) then
            local success, x, y, z = getObjectCoordinates(object)
            if success then
                local playerX, playerY, playerZ = getCharCoordinates(PLAYER_PED)
                local distance = getDistanceBetweenCoords3d(playerX, playerY, playerZ, x, y, z)
                if isObjectOnScreen(object) and distance < 50000 then
                    local screenX, screenY = convert3DCoordsToScreen(x, y, z)
                    local myX, myY = convert3DCoordsToScreen(playerX, playerY, playerZ)
                    if screenX and screenY and myX and myY then
                        local status = shopStatus[object] or "free"
                        local line = {lineColor[0], lineColor[1], lineColor[2], lineColor[3]}
                        local text = {textColor[0], textColor[1], textColor[2], textColor[3]}
                        local label = "Свободная"
                        local timer = ""
                        local timerColor = {1, 1, 1, 1}

                        if status == "sale" then
                            line = {saleLineColor[0], saleLineColor[1], saleLineColor[2], saleLineColor[3]}
                            text = {saleTextColor[0], saleTextColor[1], saleTextColor[2], saleTextColor[3]}
                            label = "Продаётся"
                        elseif reserveTimerObj[object] then
                            label = "Бронь заканчивается через:"
                            local remaining = math.max(0, reserveTimerObj[object] - os.time())
                            timer = string.format("[%d:%02d]", math.floor(remaining / 60), remaining % 60)

                            if remaining <= 0 then
                                timerColor = {1, 0, 0, 1}
                            elseif remaining > 10 * 60 then
                                timerColor = {0, 1, 0, 1}
                            elseif remaining > 5 * 60 then
                                timerColor = {1, 1, 0, 1}
                            else
                                timerColor = {1, 0, 0, 1}
                            end
                        end

                        renderDrawLine(screenX, screenY, myX, myY, lineThickness[0], rgbaToARGB(line))
                        local dotColor = rgbaToARGB(line)
                        renderDrawPolygon(screenX, screenY, 5, 5, 5, 0, dotColor)
                        renderDrawPolygon(myX, myY, 5, 5, 5, 0, dotColor)

                        local labelX = screenX - 30
                        local labelY = screenY - 20
                        renderFontDrawText(renderFontSmall, label, labelX, labelY, rgbaToARGB(text), 0x90000000)
                        if timer ~= "" then
                            local timerX = labelX + renderGetFontDrawTextLength(renderFontSmall, label) + 4
                            renderFontDrawText(renderFontSmall, timer, timerX, labelY, rgbaToARGB(timerColor), 0x90000000)
                        end
                    end
                end
            end
        end
    end
end

--[[ Переключает состояние рендера лавок ]]
local function toggleRender()
    isActiveRender = not isActiveRender
    renderEnabled[0] = isActiveRender
    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Рендер лавок: " .. (isActiveRender and colors.greenBright .. "ВКЛ" or colors.redLower .. "ВЫКЛ"), -1)
end

--[[ Основной цикл скрипта ]]
function main()
    while not isSampAvailable() do
        wait(10)
    end
    checkUpdate()
    wait(1000)

    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. "Скрипт загружен! Версия: 2.2 | Автор:" .. colors.turquoise .. " Koora")
    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. "Используйте /lmenu или Alt + 1 чтобы открыть меню.")
    if shopName == "" then
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. "Текущее название лавки: не установлено.")
    else
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. text_shopName .. colors.green .. " " .. shopName, -1)
    end

    sampRegisterChatCommand("lmenu", function()
        WinState[0] = not WinState[0]
    end)
    sampRegisterChatCommand("namelavka", changeShopName)
    sampRegisterChatCommand("lovecl", toggleFlood)
    sampRegisterChatCommand("clear", cleaner)
    sampRegisterChatCommand("render", toggleRender)
    sampRegisterChatCommand("resrender", resetRender)
    sampRegisterChatCommand("luxury", toggleLuxury)
    sampRegisterChatCommand('updatelovacl', function()
    if updateVersion ~= "" then
        windowUpdate[0] = not windowUpdate[0]
    else
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Обновления не найдены или у вас уже установлена последняя версия.", -1)
    end
    end)

    while true do 
        wait(0)
        
        if isKeyDown(vkeys.VK_MENU) and isKeyJustPressed(vkeys.VK_1) then
            WinState[0] = not WinState[0]
        end

        if isKeyDown(vkeys.VK_MENU) and isKeyJustPressed(vkeys.VK_2) then
            toggleFlood()
        end

        wait(5)
    end
end

--[[ Декодирует строку Base64 в двоичные данные ]]
local function base64_decode(data)
    local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '[^' .. b .. '=]', '')

    return (data:gsub('.', function(x)
        if x == '=' then
            return ''
        end

        local r, f = '', (b:find(x) - 1)

        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) >= 2 ^ (i - 1) and '1' or '0')
        end

        return r
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        local c = 0

        for i = 1, 8 do
            c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0)
        end

        return string.char(c)
    end))
end

--[[ Создаёт текстуру ImGui из встроенной Base64-строки ]]
imgui.OnInitialize(function()
    local ok, result = pcall(function()
        if type(qrBase64) ~= "string" or qrBase64 == "" then
            return nil
        end

        local data = base64_decode(qrBase64)

        if type(imgui.CreateTextureFromFileInMemory) ~= "function" then
            return nil
        end

        return imgui.CreateTextureFromFileInMemory(data, #data)
    end)

    if ok then
        qrTexture = result
    else
        qrTexture = nil
    end
end)

--[[ Тема 1: бирюзовая ]]
function applyStyleTurquoise()
    local rgba = imgui.ImVec4
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.FrameBorderSize = 1.0
    style.ChildBorderSize = 1.0
    style.WindowBorderSize = 1.0

    colors[imgui.Col.WindowBg]         = rgba(0, 0, 0, 0.6)
    colors[imgui.Col.ChildBg]          = rgba(0, 0, 0, 0.45)
    colors[imgui.Col.PopupBg]          = rgba(15 / 255, 15 / 255, 15 / 255, 0.98)
    colors[imgui.Col.Border]           = rgba(64 / 255, 224 / 255, 208 / 255, 1)
    colors[imgui.Col.TitleBg]          = rgba(64 / 255, 224 / 255, 208 / 255, 0.7)
    colors[imgui.Col.TitleBgActive]    = rgba(64 / 255, 224 / 255, 208 / 255, 1)
    colors[imgui.Col.Text]             = rgba(1, 1, 1, 1)
    colors[imgui.Col.Button]           = rgba(119 / 255, 119 / 255, 119 / 255, 1)
    colors[imgui.Col.ButtonHovered]    = rgba(64 / 255, 224 / 255, 208 / 255, 0.8)
    colors[imgui.Col.ButtonActive]     = rgba(220 / 255, 40 / 255, 40 / 255, 1)
    colors[imgui.Col.CheckMark]        = rgba(64 / 255, 224 / 255, 208 / 255, 1)
    colors[imgui.Col.FrameBg]          = rgba(0.2, 0.2, 0.2, 1.0)
    colors[imgui.Col.FrameBgHovered]   = rgba(64 / 255, 224 / 255, 208 / 255, 0.4)
    colors[imgui.Col.FrameBgActive]    = rgba(64 / 255, 224 / 255, 208 / 255, 0.7)
    colors[imgui.Col.SliderGrab]       = rgba(64 / 255, 224 / 255, 208 / 255, 1)
    colors[imgui.Col.SliderGrabActive] = rgba(40 / 255, 190 / 255, 175 / 255, 1)
    colors[imgui.Col.Header]        = rgba(64 / 255, 224 / 255, 208 / 255, 0.4)
    colors[imgui.Col.HeaderHovered] = rgba(64 / 255, 224 / 255, 208 / 255, 0.7)
    colors[imgui.Col.HeaderActive]  = rgba(64 / 255, 224 / 255, 208 / 255, 1.0)

    style.FrameRounding = 6
    style.WindowRounding = 6
    style.ChildRounding = 6
    style.PopupRounding = 6
    style.ScrollbarRounding = 6
    style.GrabRounding = 6
    style.TabRounding = 6
end

--[[ Тема 2: тёмная, тёмно-красная ]]
function applyStyleRed()
    local rgba = imgui.ImVec4
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.FrameBorderSize = 1.0
    style.ChildBorderSize = 1.0
    style.WindowBorderSize = 1.0

    colors[imgui.Col.WindowBg]         = rgba(24 / 255, 24 / 255, 26 / 255, 0.95)
    colors[imgui.Col.ChildBg]          = rgba(30 / 255, 30 / 255, 32 / 255, 0.80)
    colors[imgui.Col.PopupBg]          = rgba(20 / 255, 20 / 255, 22 / 255, 0.98)
    colors[imgui.Col.Border]           = rgba(50 / 255, 50 / 255, 55 / 255, 1.0)
    colors[imgui.Col.TitleBg]          = rgba(20 / 255, 20 / 255, 22 / 255, 1.0)
    colors[imgui.Col.TitleBgActive]    = rgba(35 / 255, 35 / 255, 38 / 255, 1.0)
    colors[imgui.Col.Text]             = rgba(240 / 255, 240 / 255, 240 / 255, 1.0)
    colors[imgui.Col.Button]           = rgba(230 / 255, 57 / 255, 70 / 255, 0.85)
    colors[imgui.Col.ButtonHovered]    = rgba(240 / 255, 75 / 255, 88 / 255, 1.0)
    colors[imgui.Col.ButtonActive]     = rgba(200 / 255, 40 / 255, 53 / 255, 1.0)
    colors[imgui.Col.CheckMark]        = rgba(255 / 255, 255 / 255, 255 / 255, 1.0)
    colors[imgui.Col.FrameBg]          = rgba(42 / 255, 42 / 255, 45 / 255, 1.0)
    colors[imgui.Col.FrameBgHovered]   = rgba(55 / 255, 55 / 255, 60 / 255, 1.0)
    colors[imgui.Col.FrameBgActive]    = rgba(230 / 255, 57 / 255, 70 / 255, 1.0)
    colors[imgui.Col.SliderGrab]       = rgba(230 / 255, 57 / 255, 70 / 255, 1.0)
    colors[imgui.Col.SliderGrabActive] = rgba(250 / 255, 80 / 255, 90 / 255, 1.0)
    colors[imgui.Col.Header]        = rgba(230 / 255, 57 / 255, 70 / 255, 0.5)
    colors[imgui.Col.HeaderHovered] = rgba(230 / 255, 57 / 255, 70 / 255, 0.8)
    colors[imgui.Col.HeaderActive]  = rgba(230 / 255, 57 / 255, 70 / 255, 1.0)

    style.FrameRounding = 4.0
    style.WindowRounding = 6.0
    style.ChildRounding = 5.0
    style.PopupRounding = 4.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 4.0
    style.TabRounding = 4.0
end

--[[ Тема 3: неоновый киберпанк, пурпурно-розовая ]]
function applyStyleCyberpunk()
    local rgba = imgui.ImVec4
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.FrameBorderSize = 1.0
    style.ChildBorderSize = 1.0
    style.WindowBorderSize = 1.0

    colors[imgui.Col.WindowBg]         = rgba(15 / 255, 12 / 255, 22 / 255, 0.95)
    colors[imgui.Col.ChildBg]          = rgba(22 / 255, 18 / 255, 32 / 255, 0.85)
    colors[imgui.Col.PopupBg]          = rgba(25 / 255, 15 / 255, 35 / 255, 0.98)
    colors[imgui.Col.Border]           = rgba(186 / 255, 85 / 255, 211 / 255, 1.0)
    colors[imgui.Col.TitleBg]          = rgba(25 / 255, 15 / 255, 35 / 255, 1.0)
    colors[imgui.Col.TitleBgActive]    = rgba(60 / 255, 20 / 255, 80 / 255, 1.0)
    colors[imgui.Col.Text]             = rgba(245 / 255, 245 / 255, 255 / 255, 1.0)
    colors[imgui.Col.Button]           = rgba(140 / 255, 40 / 255, 220 / 255, 0.85)
    colors[imgui.Col.ButtonHovered]    = rgba(180 / 255, 60 / 255, 240 / 255, 1.0)
    colors[imgui.Col.ButtonActive]     = rgba(255 / 255, 45 / 255, 120 / 255, 1.0)
    colors[imgui.Col.CheckMark]        = rgba(255 / 255, 45 / 255, 120 / 255, 1.0)
    colors[imgui.Col.FrameBg]          = rgba(35 / 255, 25 / 255, 50 / 255, 1.0)
    colors[imgui.Col.FrameBgHovered]   = rgba(55 / 255, 35 / 255, 75 / 255, 1.0)
    colors[imgui.Col.FrameBgActive]    = rgba(140 / 255, 40 / 255, 220 / 255, 1.0)
    colors[imgui.Col.SliderGrab]       = rgba(255 / 255, 45 / 255, 120 / 255, 1.0)
    colors[imgui.Col.SliderGrabActive] = rgba(255 / 255, 90 / 255, 150 / 255, 1.0)

    colors[imgui.Col.Header]           = rgba(140 / 255, 40 / 255, 220 / 255, 0.5)
    colors[imgui.Col.HeaderHovered]    = rgba(180 / 255, 60 / 255, 240 / 255, 0.8)
    colors[imgui.Col.HeaderActive]     = rgba(255 / 255, 45 / 255, 120 / 255, 1.0)

    style.FrameRounding = 5.0
    style.WindowRounding = 8.0
    style.ChildRounding = 6.0
    style.PopupRounding = 5.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 5.0
    style.TabRounding = 5.0
end

--[[ Тема 4: электрический синий, кобальт ]]
function applyStyleElectricBlue()
    local rgba = imgui.ImVec4
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.FrameBorderSize = 1.0
    style.ChildBorderSize = 1.0
    style.WindowBorderSize = 1.0

    colors[imgui.Col.WindowBg]         = rgba(12 / 255, 18 / 255, 28 / 255, 0.95)
    colors[imgui.Col.ChildBg]          = rgba(18 / 255, 26 / 255, 40 / 255, 0.85)
    colors[imgui.Col.PopupBg]          = rgba(15 / 255, 22 / 255, 35 / 255, 0.98)
    colors[imgui.Col.Border]           = rgba(0 / 255, 162 / 255, 232 / 255, 1.0)
    colors[imgui.Col.TitleBg]          = rgba(15 / 255, 22 / 255, 35 / 255, 1.0)
    colors[imgui.Col.TitleBgActive]    = rgba(0 / 255, 100 / 255, 180 / 255, 1.0)
    colors[imgui.Col.Text]             = rgba(240 / 255, 245 / 255, 250 / 255, 1.0)
    colors[imgui.Col.Button]           = rgba(0 / 255, 120 / 255, 215 / 255, 0.85)
    colors[imgui.Col.ButtonHovered]    = rgba(0 / 255, 160 / 255, 255 / 255, 1.0)
    colors[imgui.Col.ButtonActive]     = rgba(0 / 255, 90 / 255, 170 / 255, 1.0)
    colors[imgui.Col.CheckMark]        = rgba(0 / 255, 220 / 255, 255 / 255, 1.0)
    colors[imgui.Col.FrameBg]          = rgba(25 / 255, 38 / 255, 58 / 255, 1.0)
    colors[imgui.Col.FrameBgHovered]   = rgba(35 / 255, 52 / 255, 78 / 255, 1.0)
    colors[imgui.Col.FrameBgActive]    = rgba(0 / 255, 120 / 255, 215 / 255, 1.0)
    colors[imgui.Col.SliderGrab]       = rgba(0 / 255, 160 / 255, 255 / 255, 1.0)
    colors[imgui.Col.SliderGrabActive] = rgba(0 / 255, 200 / 255, 255 / 255, 1.0)

    colors[imgui.Col.Header]           = rgba(0 / 255, 120 / 255, 215 / 255, 0.5)
    colors[imgui.Col.HeaderHovered]    = rgba(0 / 255, 160 / 255, 255 / 255, 0.8)
    colors[imgui.Col.HeaderActive]     = rgba(0 / 255, 200 / 255, 255 / 255, 1.0)

    style.FrameRounding = 5.0
    style.WindowRounding = 6.0
    style.ChildRounding = 5.0
    style.PopupRounding = 5.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 5.0
    style.TabRounding = 5.0
end

--[[ Тема 5: светлая, мятно-коралловая ]]
function applyStyleMintGarden()
    local rgba = imgui.ImVec4
    local style = imgui.GetStyle()
    local colors = style.Colors

    style.FrameBorderSize = 1.0
    style.ChildBorderSize = 1.0
    style.WindowBorderSize = 1.0

    colors[imgui.Col.WindowBg]         = rgba(235 / 255, 247 / 255, 241 / 255, 0.98)
    colors[imgui.Col.ChildBg]          = rgba(247 / 255, 252 / 255, 249 / 255, 0.95)
    colors[imgui.Col.PopupBg]          = rgba(247 / 255, 252 / 255, 249 / 255, 0.99)
    colors[imgui.Col.Border]           = rgba(72 / 255, 150 / 255, 126 / 255, 1.0)
    colors[imgui.Col.TitleBg]          = rgba(196 / 255, 228 / 255, 213 / 255, 1.0)
    colors[imgui.Col.TitleBgActive]    = rgba(155 / 255, 204 / 255, 183 / 255, 1.0)
    colors[imgui.Col.Text]             = rgba(34 / 255, 57 / 255, 47 / 255, 1.0)
    colors[imgui.Col.Button]           = rgba(72 / 255, 150 / 255, 126 / 255, 0.9)
    colors[imgui.Col.ButtonHovered]    = rgba(224 / 255, 126 / 255, 111 / 255, 1.0)
    colors[imgui.Col.ButtonActive]     = rgba(194 / 255, 91 / 255, 78 / 255, 1.0)
    colors[imgui.Col.CheckMark]        = rgba(224 / 255, 126 / 255, 111 / 255, 1.0)
    colors[imgui.Col.FrameBg]          = rgba(217 / 255, 237 / 255, 226 / 255, 1.0)
    colors[imgui.Col.FrameBgHovered]   = rgba(196 / 255, 228 / 255, 213 / 255, 1.0)
    colors[imgui.Col.FrameBgActive]    = rgba(155 / 255, 204 / 255, 183 / 255, 1.0)
    colors[imgui.Col.SliderGrab]       = rgba(72 / 255, 150 / 255, 126 / 255, 1.0)
    colors[imgui.Col.SliderGrabActive] = rgba(224 / 255, 126 / 255, 111 / 255, 1.0)
    colors[imgui.Col.Header]           = rgba(72 / 255, 150 / 255, 126 / 255, 0.35)
    colors[imgui.Col.HeaderHovered]    = rgba(72 / 255, 150 / 255, 126 / 255, 0.6)
    colors[imgui.Col.HeaderActive]     = rgba(224 / 255, 126 / 255, 111 / 255, 0.75)

    style.FrameRounding = 6.0
    style.WindowRounding = 8.0
    style.ChildRounding = 6.0
    style.PopupRounding = 6.0
    style.ScrollbarRounding = 6.0
    style.GrabRounding = 6.0
    style.TabRounding = 6.0
end

--[[ Отображает подсказку с иконкой вопроса ]]
function helpMarker(text)
    local rgba = imgui.ImVec4
    local themeColors = {
        rgba(64 / 255, 224 / 255, 208 / 255, 1.0),
        rgba(230 / 255, 57 / 255, 70 / 255, 1.0),
        rgba(180 / 255, 60 / 255, 240 / 255, 1.0),
        rgba(0 / 255, 160 / 255, 255 / 255, 1.0),
        rgba(224 / 255, 126 / 255, 111 / 255, 1.0)
    }

    local currentIdx = currentTheme[0] + 1
    local color = themeColors[currentIdx] or themeColors[1]

    imgui.TextColored(color, ti.ICON_HELP_CIRCLE)
    if imgui.IsItemHovered() then
        local tooltipTextColor = currentTheme[0] == 4
            and imgui.ImVec4(34 / 255, 57 / 255, 47 / 255, 1.0)
            or imgui.ImVec4(245 / 255, 250 / 255, 247 / 255, 1.0)
        imgui.PushStyleColor(imgui.Col.Text, tooltipTextColor)
        imgui.SetTooltip(text)
        imgui.PopStyleColor()
    end
end

--[[ Главное окно скрипта ]]
imgui.OnFrame(
    function()
        if wasKeyPressed(vkeys.VK_ESCAPE) then
            WinState[0] = false
        end
        return WinState[0]
    end,
    function()
        imgui.SetNextWindowPos(imgui.ImVec2(890, 530), imgui.Cond.Once, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(400, 300), imgui.Cond.Always)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
        local activeTheme = currentTheme[0]
        if activeTheme == 0 then
            applyStyleTurquoise()
        elseif activeTheme == 1 then
            applyStyleRed()
        elseif activeTheme == 2 then
            applyStyleCyberpunk()
        elseif activeTheme == 3 then
            applyStyleElectricBlue()
        else
            applyStyleMintGarden()
        end

            imgui.Begin("LovecL ARZ v2.2 by Koora", WinState, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize)
            local pos = imgui.GetWindowPos()
            mainWindowPos = {
                x = pos.x,
                y = pos.y
            }
                            
            local tabs = {
                {name = u8"Основное", icon = ti.ICON_HOME},
                {name = u8"Настройки", icon = ti.ICON_SETTINGS}
            }

            for tabIndex, tabData in ipairs(tabs) do
                if imgui.Button(tabData.icon .. " " .. tabData.name .. "##tab_" .. tabIndex, imgui.ImVec2(90, 33)) then
                    currentTab = tabIndex
                end
            end
            imgui.PushStyleVarVec2(imgui.StyleVar.ButtonTextAlign, imgui.ImVec2(0.0, 0.5))
            if imgui.Button(ti.ICON_INFO_CIRCLE .. " " .. u8'Инфо', imgui.ImVec2(90, 33)) then
                InfoWindow[0] = not InfoWindow[0]
            end
            imgui.PopStyleVar()
            
            if updateVersion ~= "" then
                imgui.PushStyleColor(imgui.Col.Button,        imgui.ImVec4(0.16, 0.65, 0.27, 1.00)) 
                imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(0.20, 0.75, 0.32, 1.00)) 
                imgui.PushStyleColor(imgui.Col.ButtonActive,  imgui.ImVec4(0.12, 0.52, 0.21, 1.00)) 

                if imgui.Button(ti.ICON_BOOK_DOWNLOAD .. u8' Update', imgui.ImVec2(90, 33)) then
                    windowUpdate[0] = not windowUpdate[0]
                end

                imgui.PopStyleColor(3) 
            end

            imgui.SetCursorPos(imgui.ImVec2(6, 262))
            imgui.SetWindowFontScale(1.3)
            if imgui.Button(ti.ICON_COFFEE, imgui.ImVec2(30, 30)) then
                showDonateWindowFlag[0] = not showDonateWindowFlag[0]
            end
            imgui.SetWindowFontScale(1.0)

            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Поддержать разработчика")
            end

            imgui.SetCursorPos(imgui.ImVec2(101, 28))
            if imgui.BeginChild("Name##" .. currentTab, imgui.ImVec2(294, 264), true, imgui.WindowFlags.HorizontalScrollbar) then
                if currentTab == 1 then 
                    imgui.Text(u8"Активация функций")
                    
                    if imgui.RadioButtonBool(u8"Flood", isActiveFlood) then
                        toggleFlood()
                    end
                    imgui.SameLine()
                    helpMarker(u8 "Подойди к лавке, встань рядом и включи чекбокс [Flood].\nЛибо прожми комбинацию [ALT + 2], или напиши команду [/lovecl] в чат.\nВыбирай, как удобнее — эффект будет один.")
                   
                    if imgui.RadioButtonBool(u8"Render", isActiveRender) then
                        toggleRender()
                    end
                    imgui.SameLine()
                    helpMarker(u8 "Включает рендер лавок на экране.\nТакже рендер можно включить командой: /render\nА сбросить настройки рендера командой: /resrender")

                    if imgui.RadioButtonBool(u8"Cleaner", isActiveCleaner) then
                        cleaner()
                    end
                    imgui.SameLine()
                    helpMarker(u8("Очищает зону стрима от транспорта и игроков.\nЭто повышает FPS и увеличивает шанс успешно словить лавку.\nТакже очистку можно вызвать командой: /clear"))
                    
                    if imgui.RadioButtonBool(u8"Luxury", isActiveLuxury) then
                       toggleLuxury()
                    end
                    imgui.SameLine()
                    helpMarker(u8("Включает режим ловли ларцов Concept Car Luxury.\nТакже режим можно включить командой: /luxury"))
                end

                if currentTab == 2 then 
                    imgui.Text(u8"Настройки" .. " " .. ti.ICON_SETTINGS)
                    imgui.Separator()

                    imgui.Text(u8"Тема оформления:")
                    imgui.SameLine()
                    helpMarker(u8("Позволяет изменить внешний вид интерфейса скрипта.\nТема применяется сразу и автоматически сохраняется в конфиг."))

                    if imgui.BeginCombo("##ThemeSelector", themes[currentTheme[0] + 1]) then
                        for i, name in ipairs(themes) do
                            local isSelected = (currentTheme[0] == i - 1)
                            if imgui.Selectable(name, isSelected) then
                                currentTheme[0] = i - 1
                                ini.main.theme = currentTheme[0]
                                inicfg.save(ini, directIni)
                            end
                            if isSelected then
                                imgui.SetItemDefaultFocus()
                            end
                        end
                        imgui.EndCombo()
                    end

                    if imgui.Button(ti.ICON_SETTINGS .. " " .. u8"Настройки лавки", imgui.ImVec2(130, 25)) then
                        LavkaSettingsWindow[0] = not LavkaSettingsWindow[0]
                        if LavkaSettingsWindow[0] then
                            RenderSettings[0] = false
                        end
                    end

                    if imgui.Button(ti.ICON_EYE .. " " .. u8"Настройки рендера", imgui.ImVec2(145, 25)) then
                        RenderSettings[0] = not RenderSettings[0]
                        if RenderSettings[0] then
                            LavkaSettingsWindow[0] = false
                        end
                    end

                    if imgui.Checkbox(ti.ICON_MESSAGE_OFF .. " " .. u8'Скрывать системный флуд лавки', offFloodChatMessage) then
                        ini.main.offFloodChatMessage = offFloodChatMessage[0]
                        inicfg.save(ini, directIni)
                    end
                    imgui.SameLine()
                    helpMarker(u8 "Скрывает из чата повторяющиеся сообщения сервера:\n«Данная лавка временно забронирована за игроком...»\nчтобы чат не забивался во время ловли.")

                    if imgui.Checkbox(ti.ICON_VOLUME_OFF .. " " .. u8'Тихий режим (без сообщений)', silentMode) then
                        ini.main.silentMode = silentMode[0]
                        inicfg.save(ini, directIni)
                    end
                    imgui.SameLine()
                    helpMarker(u8 "При включении этого режима скрипт не выводит свои сообщения в чат.\nСостояние сохраняется в конфиге и работает после перезагрузки.")
                    
                    if imgui.Checkbox(ti.ICON_CURRENT_LOCATION_OFF .. " " .. u8'Отключить проверку расстояния', disableDistanceCheck) then
                        ini.main.disableDistanceCheck = disableDistanceCheck[0]
                        inicfg.save(ini, directIni)
                    end
                    imgui.SameLine()
                    helpMarker(u8 "При включении этого режима скрипт перестанет проверять расстояние до лавки.\nЭто дает включать функцию флуда даже если вы находитесь далеко от лавки.\nСостояние сохраняется в конфиг и работает после перезагрузки.")

                    if imgui.Checkbox(ti.ICON_EYE .. " " .. u8'Показывать время ловли и CPS', showFloodStats) then
                        ini.main.showFloodStats = showFloodStats[0]
                        inicfg.save(ini, directIni)
                    end
                    imgui.SameLine()
                        helpMarker(u8 "Показывает время текущей или последней ловли и количество нажатий ALT за последнюю секунду.")

                    if imgui.Checkbox(ti.ICON_CLOCK_PLAY .. " " .. u8'Автоматическая ловля Luxury', autoLuxuryZavoz) then
                        ini.main.autoLuxuryZavoz = autoLuxuryZavoz[0]
                        inicfg.save(ini, directIni)

                        if isActiveLuxury then
                            if autoLuxuryZavoz[0] then
                                isSpammingAlt = false
                            else
                                isSpammingAlt = isActiveFlood or isActiveLuxury
                            end
                        end
                    end
                    imgui.SameLine()
                    helpMarker(u8 "При включённом чекбоксе скрипт начнёт флудить только тогда, когда спавнятся ларцы, и выключится сам, когда они исчезнут.\nЕсли чекбокс выключен, скрипт будет флудить постоянно, пока вы не выключите его вручную.")                end
            end
            imgui.EndChild()
            imgui.End()
            imgui.PopStyleVar()
        end
)

--[[ Окно обновления скрипта ]]
imgui.OnFrame(function()
        if wasKeyPressed(vkeys.VK_ESCAPE) then
            windowUpdate[0] = false
        end
        return windowUpdate[0]
        end, function()

        imgui.PushStyleVarVec2(imgui.StyleVar.WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
        if mainWindowPos then
            imgui.SetNextWindowPos(imgui.ImVec2(mainWindowPos.x + 0, mainWindowPos.y - 271), imgui.Cond.Always)
        end
        local activeTheme = currentTheme[0]
        if activeTheme == 0 then
            applyStyleTurquoise()
        elseif activeTheme == 1 then
            applyStyleRed()
        elseif activeTheme == 2 then
            applyStyleCyberpunk()
        elseif activeTheme == 3 then
            applyStyleElectricBlue()
        else
            applyStyleMintGarden()
        end
        imgui.Begin(u8'Обновление скрипта', windowUpdate, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)

        imgui.Text(u8('Версия: v' .. thisScript().version .. '  ->  v') .. u8(updateVersion))
        imgui.Separator()

        imgui.TextColored(imgui.ImVec4(0.0, 0.8, 1.0, 1.0), u8'Что будет обновлено:')

        imgui.BeginChild('##ChangelogArea', imgui.ImVec2(320, 100), true)
        if updateChangelog ~= "" then
            imgui.TextWrapped(updateChangelog) -- Данные из JSON уже в UTF-8!
        else
            imgui.TextWrapped(u8'Описание изменений отсутствует.')
        end
        imgui.EndChild()

        imgui.Separator()

        if imgui.Button(u8'Подтвердить', imgui.ImVec2(160, 30)) then
            sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. ' Обновление подтверждено, скачивание...', -1)
            startUpdate(updateUrl) -- Функция скачивания .lua файла
            windowUpdate[0] = false
        end
        
        imgui.SameLine()
        
        if imgui.Button(u8'Отмена', imgui.ImVec2(100, 30)) then
            windowUpdate[0] = false
        end
        imgui.End()
        imgui.PopStyleVar()
end)

--[[ Окно: Настройки лавки ]]
imgui.OnFrame(function()
    if wasKeyPressed(vkeys.VK_ESCAPE) then
        LavkaSettingsWindow[0] = false
    end
    return LavkaSettingsWindow[0]
    end, function()
        imgui.SetNextWindowSize(imgui.ImVec2(400, 200), imgui.Cond.FirstUseEver)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
        if mainWindowPos then
            imgui.SetNextWindowPos(imgui.ImVec2(mainWindowPos.x + 0, mainWindowPos.y - 271), imgui.Cond.Always)
        end
        local activeTheme = currentTheme[0]
        if activeTheme == 0 then
            applyStyleTurquoise()
        elseif activeTheme == 1 then
            applyStyleRed()
        elseif activeTheme == 2 then
            applyStyleCyberpunk()
        elseif activeTheme == 3 then
            applyStyleElectricBlue()
        else
            applyStyleMintGarden()
        end

        imgui.Begin("Store Settings", LavkaSettingsWindow, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)

        imgui.Text(ti.ICON_SETTINGS .. " " .. u8"Настройка для лавки")
        imgui.SetNextItemWidth(100)
        if imgui.SliderInt(u8 "Задержка (сек)", delay, 0, 5, u8 "%d сек") then
            ini.main.delay = delay[0]
            inicfg.save(ini, directIni)
        end
        imgui.SameLine()
        helpMarker(u8 "Здесь можно задать задержку ввода названия лавки\n" ..
                    u8 "Указывается в секундах\n" ..
                    u8 "Когда вы словите лавку, скрипт подождёт указанное время\n" ..
                    u8 "и только потом введёт название")

        imgui.Text(ti.ICON_PENCIL .. " " .. u8"Название лавки")
        imgui.SetNextItemWidth(100)
        
        imgui.InputText("##shop_name", shopNameBuf, 64)

        imgui.SameLine()
        if imgui.Button(u8 "Сохранить", imgui.ImVec2(70, 19)) then
            local inputNameUtf8 = ffi.string(shopNameBuf)
            local inputNameCp1251 = u8:decode(inputNameUtf8)

            if #inputNameCp1251 >= 3 and #inputNameCp1251 <= 20 then
                shopName = inputNameCp1251
                ini.main.shopName = inputNameUtf8
                inicfg.save(ini, directIni)
                sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. text_saveNameShop .. colors.green .. " " .. shopName, -1)
            else
                sampAddChatMessage(colors.turquoise .. nameScript .. text_checkCharacters, -1)
            end
        end

        imgui.SameLine()
        helpMarker(
            u8 "Здесь вы можете ввести название, которое будет использоваться для лавки\n" ..
            u8 "Оно сохраняется, и вам не нужно будет вводить его каждый раз\n" ..
            u8 "Вы можете изменить его в любой момент — через поле слева\n" ..
            u8 "или с помощью команды [/namelavka название]")
        imgui.Separator()
        imgui.Text(ti.ICON_PALETTE .. " " .. u8"Цвет названия лавки:")

        imgui.SameLine()
        helpMarker(u8("Вы можете выбрать цвет, в котором будет отображаться название лавки: доступен случайный выбор (рандом) или индивидуальная настройка.\nНастройки цвета сохраняются в конфиге и будут работать после перезагрузки скрипта."))

        local curColor = colorList[selectedColor[0] + 1] or colorList[1]

        imgui.ColorButton("##preview_color", curColor.col, imgui.ColorEditFlags.NoTooltip, imgui.ImVec2(18, 18))
        imgui.SameLine()

        imgui.SetNextItemWidth(150)
        if imgui.BeginCombo("##color_combo", curColor.name) then
            for i, item in ipairs(colorList) do
                local isSelected = (selectedColor[0] == i - 1)
                
                imgui.ColorButton("##col_btn_" .. i, item.col, imgui.ColorEditFlags.NoTooltip, imgui.ImVec2(14, 14))
                imgui.SameLine()
                
                if imgui.Selectable(item.name, isSelected) then
                    selectedColor[0] = i - 1
                    ini.main.selectedColor = selectedColor[0]
                    inicfg.save(ini, directIni)
                end
                
                if isSelected then
                    imgui.SetItemDefaultFocus()
                end
            end
            imgui.EndCombo()
        end

        imgui.SameLine()

        if imgui.Checkbox(u8"Рандом", isRandomColor) then
            ini.main.isRandomColor = isRandomColor[0]
            inicfg.save(ini, directIni)
        end
        if imgui.Checkbox(ti.ICON_SHOPPING_BAG .. " " .. u8'Автопродажа лавки', autoSell) then
            ini.main.autoSell = autoSell[0]
            inicfg.save(ini, directIni)
        end
        imgui.SameLine()
        helpMarker(u8 "При включенной опции лавка автоматически выставляется на продажу сразу после поимки.\nЖелаемая цена настраивается в поле ниже.")
        
        imgui.Text(u8"Цена автопродажи (Обычный сервер):")
        if imgui.InputInt("##autoSellPriceInput", autoSellPrice) then
            if autoSellPrice[0] < 500000 then autoSellPrice[0] = 500000 end
            if autoSellPrice[0] > 50000000 then autoSellPrice[0] = 50000000 end
            
            ini.main.autoSellPrice = autoSellPrice[0]
            inicfg.save(ini, directIni)
        end

        imgui.Text(u8"Цена автопродажи (Vice City):")
        if imgui.InputInt("##autoSellPriceInputVC", autoSellPriceVC) then
            if autoSellPriceVC[0] < 10000 then autoSellPriceVC[0] = 10000 end
            if autoSellPriceVC[0] > 1000000 then autoSellPriceVC[0] = 1000000 end
            
            ini.main.autoSellPriceVC = autoSellPriceVC[0]
            inicfg.save(ini, directIni)
        end
        imgui.End()
        imgui.PopStyleVar()
end)

--[[ Окно: Настройки рендера ]]
imgui.OnFrame(function()
    if wasKeyPressed(vkeys.VK_ESCAPE) then
        RenderSettings[0] = false
    end
    return RenderSettings[0]
    end, function()
        imgui.SetNextWindowSize(imgui.ImVec2(400, 200), imgui.Cond.FirstUseEver)
        imgui.PushStyleVarVec2(imgui.StyleVar.WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
        if mainWindowPos then
            imgui.SetNextWindowPos(imgui.ImVec2(mainWindowPos.x + 0, mainWindowPos.y - 352), imgui.Cond.Always)
        end
        local activeTheme = currentTheme[0]
        if activeTheme == 0 then
            applyStyleTurquoise()
        elseif activeTheme == 1 then
            applyStyleRed()
        elseif activeTheme == 2 then
            applyStyleCyberpunk()
        elseif activeTheme == 3 then
            applyStyleElectricBlue()
        else
            applyStyleMintGarden()
        end

        imgui.Begin(u8"Render Settings", RenderSettings, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)
        imgui.Text(ti.ICON_EYE .. " " .. u8"Настройка рендера лавок")
        imgui.Separator()

        if imgui.Checkbox(u8"Показывать лавки на продаже", searchSellingShops) then
            ini.main.searchSellingShops = searchSellingShops[0]
            inicfg.save(ini, directIni)
        end

        if imgui.Checkbox(u8"Рендер включён", renderEnabled) then
            toggleRender()
        end

        imgui.Separator()
        imgui.Text(u8"Свободные лавки")
        if imgui.ColorEdit4(u8"Цвет линии##renderline", lineColor) then
            saveColorToIni("renderLineColor", lineColor)
        end
        if imgui.ColorEdit4(u8"Цвет текста##rendertext", textColor) then
            saveColorToIni("renderTextColor", textColor)
        end
        if imgui.Button(u8"Сбросить цвет свободных") then
            resetColorToDefault(lineColor, defaultLineColor, "renderLineColor")
            resetColorToDefault(textColor, defaultTextColor, "renderTextColor")
        end

        imgui.Separator()
        imgui.Text(u8"Лавки на продаже")
        if imgui.ColorEdit4(u8"Цвет линии##saleline", saleLineColor) then
            saveColorToIni("saleLineColor", saleLineColor)
        end
        if imgui.ColorEdit4(u8"Цвет текста##saletext", saleTextColor) then
            saveColorToIni("saleTextColor", saleTextColor)
        end
        if imgui.Button(u8"Сбросить цвет продажи") then
            resetColorToDefault(saleLineColor, defaultSaleLineColor, "saleLineColor")
            resetColorToDefault(saleTextColor, defaultSaleTextColor, "saleTextColor")
        end

        if imgui.SliderFloat(u8"Толщина линии", lineThickness, 0.5, 5.0, u8"%.1f") then
            ini.main.renderLineThickness = lineThickness[0]
            inicfg.save(ini, directIni)
        end

        imgui.Separator()
        if imgui.Button(ti.ICON_REFRESH .. " " .. u8"Обновить список лавок", imgui.ImVec2(180, 28)) then
            resetRender()
        end

        imgui.End()
        imgui.PopStyleVar()
    end)

--[[ Окно: Donate ]]
imgui.OnFrame(function()
    if wasKeyPressed(vkeys.VK_ESCAPE) then
        showDonateWindowFlag[0] = false
    end
    return showDonateWindowFlag[0]
end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(260, 0), imgui.Cond.Always)
    
    if mainWindowPos then
        imgui.SetNextWindowPos(imgui.ImVec2(mainWindowPos.x - 263, mainWindowPos.y), imgui.Cond.Always)
    end

    local activeTheme = currentTheme[0]
    if activeTheme == 0 then
        applyStyleTurquoise()
    elseif activeTheme == 1 then
        applyStyleRed()
    elseif activeTheme == 2 then
        applyStyleCyberpunk()
    elseif activeTheme == 3 then
        applyStyleElectricBlue()
    else
        applyStyleMintGarden()
    end

    imgui.PushStyleVarVec2(imgui.StyleVar.WindowTitleAlign, imgui.ImVec2(0.5, 0.5))
    local isBegin = imgui.Begin(ti.ICON_HEART .. " " .. u8"Донат###DonateWin", showDonateWindowFlag, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
    imgui.PopStyleVar()

    if isBegin then
        imgui.Spacing()
        
        local titleText = ti.ICON_COFFEE .. " " .. u8"Поддержка автора"
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(titleText).x) / 2)
        imgui.TextDisabled(titleText)
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        local qrSize = 160
        if qrTexture then
            imgui.SetCursorPosX((imgui.GetWindowWidth() - qrSize) / 2)
            imgui.Image(qrTexture, imgui.ImVec2(qrSize, qrSize))
            
            if imgui.IsItemHovered() then
                imgui.SetTooltip(u8"Отсканируйте QR-код камерой телефона")
            end
        else
            imgui.SetCursorPosX((imgui.GetWindowWidth() - qrSize) / 2)
            if imgui.BeginChild("ErrorQR", imgui.ImVec2(qrSize, qrSize), true) then
                local errText1 = u8"QR-код"
                local errText2 = u8"не найден"
                
                imgui.SetCursorPosY((qrSize - imgui.CalcTextSize(errText1).y * 2) / 2 - 5)
                
                imgui.SetCursorPosX((qrSize - imgui.CalcTextSize(errText1).x) / 2)
                imgui.TextColored(imgui.ImVec4(1.0, 0.3, 0.3, 1.0), errText1)
                
                imgui.SetCursorPosX((qrSize - imgui.CalcTextSize(errText2).x) / 2)
                imgui.TextColored(imgui.ImVec4(1.0, 0.3, 0.3, 1.0), errText2)
                
                imgui.EndChild()
            end
        end

        imgui.Spacing()
        imgui.Spacing()

        local desc1 = u8"Отсканируйте QR-код"
        local desc2 = u8"или нажмите кнопку ниже"
        local desc3 = u8"для перехода на страницу доната."
        
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(desc1).x) / 2)
        imgui.Text(desc1)
        
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(desc2).x) / 2)
        imgui.Text(desc2)
        
        imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(desc3).x) / 2)
        imgui.Text(desc3)
        
        imgui.Spacing()
        imgui.Separator()
        imgui.Spacing()

        if imgui.Button(ti.ICON_HEART .. " " .. u8"Открыть DonateAlerts", imgui.ImVec2(-1, 35)) then
            os.execute('start "" "' .. donatalertsURL .. '"')
        end
        if imgui.IsItemHovered() then
            imgui.SetTooltip(u8"Открыть страницу доната в браузере")
        end

        imgui.End()
    end
end)

--[[ Окно: информация о скрипте ]]
imgui.OnFrame(function()
    if wasKeyPressed(vkeys.VK_ESCAPE) then
        InfoWindow[0] = false
    end
    return InfoWindow[0]
end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(400, 500), imgui.Cond.FirstUseEver)

    if mainWindowPos then
        imgui.SetNextWindowPos(imgui.ImVec2(mainWindowPos.x + 402, mainWindowPos.y - 300), imgui.Cond.Always)
    end

    local activeTheme = currentTheme[0]
    if activeTheme == 0 then
        applyStyleTurquoise()
    elseif activeTheme == 1 then
        applyStyleRed()
    elseif activeTheme == 2 then
        applyStyleCyberpunk()
        elseif activeTheme == 3 then
        applyStyleElectricBlue()
        else
            applyStyleMintGarden()
    end

    imgui.Begin(u8 "Информация", InfoWindow, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse)

    imgui.PushTextWrapPos(0)
    imgui.Text(u8 "Скрипт: LovecL ARZ v2.2")
    imgui.Text(u8 "Автор: Koora")
    imgui.Text(u8 " ")
    imgui.Text(u8 "ОПИСАНИЕ:")
    imgui.BulletText(u8 "Рендер свободных лавок и лавок на продажу")
    imgui.BulletText(u8 "Таймер окончания брони")
    imgui.BulletText(u8 "Отображение времени текущей ловли и количества нажатий ALT в секунду (CPS)")
    imgui.BulletText(u8 "Настройка задержки выставления названия")
    imgui.BulletText(u8 "Возможность отключить проверку расстояния до лавки")
    imgui.BulletText(u8 "Настройка цвета линии и текста")
    imgui.BulletText(u8 "Отдельное отображение и настройка цветов лавок, выставленных на продажу")
    imgui.BulletText(u8 "Настройка толщины линий рендера")
    imgui.BulletText(u8 "Отключение рендера для лавок на продаже")
    imgui.BulletText(u8 "Очиститель стрима: удаляет транспорт и игроков для повышения FPS (активация через /clear или меню).")
    imgui.BulletText(u8 "Автоматическое название лавки (можно вводить через окно или с помощью команды /namelavka)")
    imgui.BulletText(u8 "Возможность начать флуд возле лавки: команда /lovecl, комбинация ALT + 2 или через меню")
    imgui.BulletText(u8 "Активация меню: ALT + 1 или команда /lmenu")
    imgui.BulletText(u8 "Удалён спам в чате («Данная лавка забронирована»); настройка скрытия находится в меню.")
    imgui.BulletText(u8 "Команда /render для включения рендера (также доступно в меню)")
    imgui.BulletText(u8 "Команда /resrender для перезагрузки рендера")
        imgui.BulletText(u8 "Присутствует автопродажа лавки после поимки с настройкой цены")
        imgui.SameLine()
        helpMarker(u8"Цена для обычного сервера: от 500 000 до 50 000 000. Цена для Vice City: от 10 000 до 1 000 000. Обе цены настраиваются в меню.")
    imgui.BulletText(u8 "Возможность выбора цвета названия лавки вручную или случайно (также доступно в меню)")
    imgui.BulletText(u8 "Возможность выбора темы оформления интерфейса (также доступно в меню)")
    imgui.BulletText(u8 "Возможность включить тихий режим без сообщений скрипта в чат — сохраняется в конфиге и работает после перезагрузки.")
    imgui.BulletText(u8"Возможность включить ловлю ларцов Concept Car Luxury через меню или командой /luxury")
    imgui.BulletText(u8"Автоматический флуд по времени спавна ларцов")
    imgui.SameLine()
    helpMarker(u8"При включённом чекбоксе скрипт начнёт флудить только тогда, когда спавнятся ларцы, и выключится сам, когда они исчезнут.\nЕсли чекбокс выключен, скрипт будет флудить постоянно, пока вы не выключите его вручную.")

    imgui.Text(u8 " ")

    imgui.Text(u8 "ГОРЯЧИЕ КЛАВИШИ:")
    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Alt + 1")
    imgui.SameLine()
    imgui.Text(u8 "— открыть/закрыть меню скрипта.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Alt + 2")
    imgui.SameLine()
    imgui.Text(u8 "— включить/выключить флуд (ловлю лавки).")

    imgui.Text(u8 " ")

    imgui.Text(u8 "КОМАНДЫ:")
    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/lovecl")
    imgui.SameLine()
    imgui.Text(u8 "— Включить/выключить ловлю.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/lmenu")
    imgui.SameLine()
    imgui.Text(u8 "— Открыть главное меню.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/render")
    imgui.SameLine()
    imgui.Text(u8 "— Включить/выключить рендер.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/resrender")
    imgui.SameLine()
    imgui.Text(u8 "— Перезагрузить рендер.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), u8 "/namelavka [название]")
    imgui.SameLine()
    imgui.Text(u8 "— Установить имя лавки.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/clear")
    imgui.SameLine()
    imgui.Text(u8 "— Удалить транспорт и игроки (повышение FPS).")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "/luxury")
    imgui.SameLine()
    imgui.Text(u8 "— Включить/выключить ловлю ларцов Concept Car Luxury.")

    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), '/updatelovacl')
    imgui.SameLine()
    imgui.Text(u8 "— Проверить обновление скрипта.")

    imgui.Text(u8 " ")

    imgui.Text(u8 "ТРЕБОВАНИЯ:")
    imgui.BulletText(u8 "Обязательно указать название лавки перед ловлей.")
    imgui.BulletText(u8 "Название должно быть от 3 до 20 символов.")

    imgui.Text(u8 " ")

    imgui.Text(u8 " ")
    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), u8 "ОТКАЗ ОТ ОТВЕТСТВЕННОСТИ:")
    imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(1, 0, 0, 1)) -- красный текст
    imgui.BulletText(
        u8 "Автор не несёт ответственности за возможные последствия использования скрипта.")
    imgui.BulletText(u8 "Используйте на свой страх и риск.")
    imgui.PopStyleColor()

    imgui.Text(u8 " ")
    imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), u8 "Если проебал что то дайте знать.")
    imgui.Text(u8 "СВЯЗЬ:")
    imgui.SameLine()
    if imgui.Button(u8 "Тема на BlastHack") then
        os.execute("start https://www.blast.hk/threads/233895/")
    end

    imgui.SameLine()

    if imgui.Button(u8 "Telegram") then
        os.execute("start https://t.me/xx00xxdanu")
    end
    imgui.SameLine()
    imgui.SetCursorPos(imgui.ImVec2(248, 920))
    imgui.SetWindowFontScale(1.3)
    if imgui.Button(ti.ICON_COFFEE, imgui.ImVec2(30, 30)) then
        showDonateWindowFlag[0] = not showDonateWindowFlag[0]
    end
    imgui.SetWindowFontScale(1.0)

    if imgui.IsItemHovered() then
        imgui.SetTooltip(u8"Поддержать разработчика")
    end

    imgui.PopTextWrapPos()

    imgui.End()
end)

--[[ Отправляет нажатие клавиши в игру ]]
function sendkey(keyCode)
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local mem = allocateMemory(68)
    local data = keysData[keyCode]

    if data then
        if keyCode == 1024 and isActiveFlood and isSpammingAlt then
            table.insert(floodKeyPresses, getGameTimer())
        end

        sampStorePlayerOnfootData(id, mem)
        setStructElement(mem, data.structElement, data.size, keyCode, false)
        sampSendOnfootData(mem)
        setStructElement(mem, data.structElement, data.size, 0, false)
        sampSendOnfootData(mem)
    end

    freeMemory(mem)
end

--[[ Включает или выключает ловлю свободной лавки ]]
function toggleFlood()
    if shopName == nil or shopName == "" then
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. " Ошибка: нельзя включить скрипт без названия лавки! Введите /namelavka [название].")
        return
    end

    if not disableDistanceCheck[0] and not isNearObject(19475) then
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. " Вы далеко от лавки!", -1)
        return
    end

    local shouldEnable = not isActiveFlood

    if shouldEnable then
        isActiveLuxury = false
    end

    isActiveFlood = shouldEnable
    isSpammingAlt = isActiveFlood or isActiveLuxury

    if isActiveFlood then
        floodStartedAt = getGameTimer()
        floodElapsedMs = 0
        floodKeyPresses = {}
        floodCps = 0
    elseif floodStartedAt > 0 then
        floodElapsedMs = math.max(0, getGameTimer() - floodStartedAt)
    end

    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Ловля лавок: " .. (isActiveFlood and colors.greenBright .. "ВКЛ" or colors.redLower .. "ВЫКЛ"))

    if isActiveFlood then
        lua_thread.create(function()
            while isActiveFlood do
                if not disableDistanceCheck[0] and not isNearObject(19475) then
                    sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. " Вы отошли от лавки. Флуд выключен.", -1)
                    if floodStartedAt > 0 then
                        floodElapsedMs = math.max(0, getGameTimer() - floodStartedAt)
                    end
                    isActiveFlood = false
                    isSpammingAlt = false
                    break
                end

                if isSpammingAlt then
                    for repeatIndex = 1, floodKeyRepeats do
                        sendkey(1024)
                    end
                end

                if cef.IsDialogActive() then
                    local text = cef.GetDialogText()
                    if text and text:find("Стоимость аренды лавки") then
                        isSpammingAlt = false
                        cef.CloseWithButton(1)
                        wait(100)
                    end
                end
                wait(0)
            end
        end)
    end
end

--[[ Устанавливает название лавки через чат-команду ]]
function changeShopName(arg)
    if arg and #arg >= 3 and #arg <= 20 then
        shopName = arg
        ffi.copy(shopNameBuf, u8(shopName))
        ini.main.shopName = u8(shopName)
        inicfg.save(ini, directIni)

        sampAddChatMessage(text_saveNameShop .. shopName)
    else
        sampAddChatMessage(text_checkCharacters, -1)
    end
end

--[[ Проверяет, находится ли игрок рядом со свободной лавкой ]]
function isNearObject(targetId, maxDist)
    maxDist = maxDist or 1.0
    local px, py, pz = getCharCoordinates(PLAYER_PED)

    for _, obj in ipairs(getAllObjects()) do
        if doesObjectExist(obj) and getObjectModel(obj) == targetId then
            local success, x, y, z = getObjectCoordinates(obj)
            if success then
                local dist = math.sqrt((px - x) ^ 2 + (py - y) ^ 2 + (pz - z) ^ 2)
                if dist <= maxDist then
                    return true
                end
            end
        end
    end
    return false
end

--[[ Фильтрует повторяющееся системное сообщение о брони лавки ]]
function samp.onServerMessage(_, text)
    if type(text) ~= "string" then return end

    local cleanText = text:gsub("{......}", "")

    if cleanText:find("Данная лавка временно забронирована за игроком", 1, true) then
        if offFloodChatMessage[0] then
            return false
        end
    end

    if isActiveLuxury then
        if cleanText:find("Вы купили ларец 'Concept Car Luxury'", 1, true) then
            local amount = cleanText:match("Вы купили ларец 'Concept Car Luxury' %((%d+) шт%.%)")
            
            if amount then
                luxuryCount = luxuryCount + tonumber(amount)
            else
                luxuryCount = luxuryCount + 1
            end
        end
    end
end

--[[ Обрабатывает диалоги ловли и автоматической продажи ]]
function samp.onShowDialog(id, style, title, button1, button2, text)
    local cleanText = text:gsub("%[.-%]", ""):gsub("{......}", "")
    if isActiveFlood then
        if id == 3020 or title:find("[Нн]азвание") or text:find("[Нн]азвание") then
            isSpammingAlt = false
            lua_thread.create(function()
                local delaySec = (delay and delay[0]) or (ini and ini.main and ini.main.delay) or 0
                local waitMs = delaySec * 1000

                if waitMs > 0 then
                    wait(waitMs)
                end

                sampSendDialogResponse(id, 1, -1, shopName)
                
                if not (silentMode and silentMode[0]) then
                    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Установлено название лавки: ".. colors.green .. shopName, -1)
                end
            end)
            return false 

        elseif id == 3030 or title:find("[Цц]вет") or text:find("[Цц]вет") then
            isSpammingAlt = false
            local listIndex = 0

            if isRandomColor[0] then
                listIndex = math.random(0, #colorList - 1)
            else
                listIndex = selectedColor[0]
            end

            sampSendDialogResponse(id, 1, listIndex, "")
            
            if floodStartedAt > 0 then
                floodElapsedMs = math.max(0, getGameTimer() - floodStartedAt)
            end
            isActiveFlood = false
            if autoSell[0] then
                autoSellFlow = true
                lua_thread.create(function()
                    wait(1500)
                    setVirtualKeyDown(vkeys.VK_MENU, true)
                    wait(200)
                    setVirtualKeyDown(vkeys.VK_MENU, false)
                end)
            end
            return false
        end
    end

    if autoSellFlow and id == 3040 then
        sampSendDialogResponse(id, 1, 5, "")
        return false
    end

    if autoSellFlow and (
        id == 27360 or 
        title:find("[Вв]ыставление лавки") or 
        text:find("[Кк]омиссия за продажу") or
        text:find("стоимость продажи лавки")
    ) then

        autoSellFlow = false

        local priceToSend = autoSellPrice[0]

        if cleanText:find(":CASHV:", 1, true) then
            priceToSend = autoSellPriceVC[0]
        end
        
        sampSendDialogResponse(id, 1, -1, tostring(priceToSend))
        return false
    end

    if isActiveLuxury then
        local cleanText = text:gsub("{......}", "")
        if id == 25190 or cleanText:find('Нельзя покупать более 2 ларцов за 10 секунд.') then
            sampSendDialogResponse(id, 1, -1, "")
            return false
        end
    end
end

--[[ Обновляет статус лавки по тексту 3D-объекта ]]
function samp.onSetObjectMaterialText(id, data)
    if not data or type(data.text) ~= "string" then
        return
    end

    local object = sampGetObjectHandleBySampId(id)
    if not object or object == 0 then
        return
    end

    if objectDrawDistanceAvailable and type(setObjectDrawDistance) == "function" then
        local ok = pcall(setObjectDrawDistance, object, 3000.0)
        if not ok then
            objectDrawDistanceAvailable = false
        end
    end

    local shopNumber = tonumber(data.text:match("Номер (%d+)%. {......}Свободная!"))
    local isFree = shopNumber ~= nil and shopNumber < 39
    local isForSale = data.text:lower():find("Лавка продается")

    if isFree then
        local known = false
        for _, storedObject in ipairs(renderMassive) do
            if storedObject == object then
                known = true
                break
            end
        end
        if not known then
            table.insert(renderMassive, object)
        end
        shopStatus[object] = "free"
        attachPendingReserveLabels()
    elseif isForSale then
        local known = false
        for _, storedObject in ipairs(renderMassive) do
            if storedObject == object then
                known = true
                break
            end
        end
        if not known then
            table.insert(renderMassive, object)
        end
        shopStatus[object] = "sale"
        attachPendingReserveLabels()
    else
        for index = #renderMassive, 1, -1 do
            if renderMassive[index] == object then
                table.remove(renderMassive, index)
                break
            end
        end
        shopStatus[object] = nil
        clearReserveData(nil, object, false)
    end
end

--[[ Удаляет уничтоженный объект лавки из списков рендера ]]
function samp.onDestroyObject(id)
    local object = sampGetObjectHandleBySampId(id)
    for index = #renderMassive, 1, -1 do
        if renderMassive[index] == object then
            table.remove(renderMassive, index)
            break
        end
    end
    shopStatus[object] = nil
    clearReserveData(nil, object, true)
end

--[[ Сохраняет актуальный таймер окончания брони из 3D-текста ]]
local function updateReserveLabel(id, position, text)
    clearReserveData(id)

    if type(text) ~= "string" or not text:find("Завершение брони") then
        return
    end

    local minutesText = text:match("через%s*([%d%.,]+)")
    local minutes = minutesText and tonumber((minutesText:gsub(",", ".")))
    if not minutes then
        return
    end

    local label = {
        id = id,
        position = {x = position.x, y = position.y, z = position.z},
        minutes = minutes
    }

    if not attachReserveTimer(label.position, minutes, id) then
        table.insert(pendingReserveLabels, label)
    end
end

--[[ Обрабатывает создание 3D-текста с таймером брони ]]
function samp.onCreate3DText(id, _, position, _, _, _, _, text)
    updateReserveLabel(id, position, text)
end

--[[ Обрабатывает обновление 3D-текста с таймером брони ]]
function samp.onUpdate3DText(id, _, position, _, _, _, _, text)
    updateReserveLabel(id, position, text)
end

--[[ Удаляет таймер и отложенную запись уничтоженного 3D-текста ]]
function samp.onDestroy3DText(id)
    clearReserveData(id)
end

--[[ Запускает постоянный цикл отрисовки лавок ]]
lua_thread.create(function()
    while true do
        wait(0)
        drawRender()
    end
end)

--[[ Включает или выключает очиститель игроков и транспорта ]]
function cleaner()
    isActiveCleaner = not isActiveCleaner

    if not isActiveCleaner then
        for _, ped in ipairs(getAllChars()) do
            if doesCharExist(ped) and ped ~= PLAYER_PED then
                local ok = sampGetPlayerIdByCharHandle(ped)

                if not ok then
                    setCharVisible(ped, true)
                end
            end
        end

        sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. "Очиститель" .. colors.green .. " ВЫКЛЮЧЕН!", -1)
        return
    end

    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. "Очиститель" .. colors.red .. " ВКЛЮЧЕН!", -1)

    lua_thread.create(function()
        local _, myPlayerId = sampGetPlayerIdByCharHandle(PLAYER_PED)

        while isActiveCleaner do
            for playerId = 0, 1000 do
                if playerId ~= myPlayerId and sampIsPlayerConnected(playerId) then
                    local ok, ped = sampGetCharHandleBySampPlayerId(playerId)

                    if ok and ped and doesCharExist(ped) then
                        local bs = raknetNewBitStream()

                        if bs then
                            raknetBitStreamWriteInt16(bs, playerId)
                            raknetEmulRpcReceiveBitStream(163, bs)
                            raknetDeleteBitStream(bs)
                        end
                    end
                end
            end

            for _, ped in ipairs(getAllChars()) do
                if doesCharExist(ped) and ped ~= PLAYER_PED then
                    local ok = sampGetPlayerIdByCharHandle(ped)

                    if not ok then
                        setCharVisible(ped, false)
                    end
                end
            end

            local myVeh = 0

            if isCharInAnyCar(PLAYER_PED) then
                myVeh = storeCarCharIsInNoSave(PLAYER_PED)
            end

            for _, vehicle in ipairs(getAllVehicles()) do
                if doesVehicleExist(vehicle) and vehicle ~= myVeh then
                    local ok, vehicleId = sampGetVehicleIdByCarHandle(vehicle)

                    if ok and vehicleId then
                        local bs = raknetNewBitStream()

                        if bs then
                            raknetBitStreamWriteInt16(bs, vehicleId)
                            raknetEmulRpcReceiveBitStream(165, bs)
                            raknetDeleteBitStream(bs)
                        end
                    end
                end
            end

            wait(1000)
        end

        for _, ped in ipairs(getAllChars()) do
            if doesCharExist(ped) and ped ~= PLAYER_PED then
                local ok = sampGetPlayerIdByCharHandle(ped)

                if not ok then
                    setCharVisible(ped, true)
                end
            end
        end
    end)

    lua_thread.create(function()
        while true do
            wait(0)

            if isActiveCleaner then
                local sw, sh = getScreenResolution()

                renderFontDrawText(
                    renderFontSmall,
                    "ОЧИСТИТЕЛЬ ВКЛЮЧЕН! БУДЬТЕ ОСТОРОЖНЫ",
                    sw / 2 - 210,
                    sh - 55,
                    0xFFFF0000
                )
            end
        end
    end)
end

--[[ Возвращает цвет в формате HEX на основе CPS ]]
function getCpsColorHex(cps, maxCps)
    maxCps = maxCps or 120
    local t = math.min(1.0, math.max(0.0, cps / maxCps))
    local r, g, b = 0, 0, 0

    if t < 0.5 then
        r = 255
        g = math.floor(255 * (t * 2))
    else
        r = math.floor(255 * (1 - (t - 0.5) * 2))
        g = 255
    end

    return string.format("{%02X%02X%02X}", r, g, b)
end

--[[ Показывает время ловли и количество нажатий независимо от очистителя ]]
lua_thread.create(function()
    while true do
        wait(0)

        if showFloodStats[0] or isActiveLuxury then
            local sw, sh = getScreenResolution()
            local now = getGameTimer()
            local elapsedMs = floodElapsedMs

            if isActiveFlood and floodStartedAt > 0 then
                elapsedMs = math.max(0, now - floodStartedAt)
            end

            for index = #floodKeyPresses, 1, -1 do
                if now - floodKeyPresses[index] > 1000 then
                    table.remove(floodKeyPresses, index)
                end
            end
            floodCps = #floodKeyPresses
            local cpsColor = getCpsColorHex(floodCps, 120)

            if isActiveLuxury then
                local cpsDisplay = isSpammingAlt and string.format("%s%d", cpsColor, floodCps) or "{FF0000}Пауза"
                renderFontDrawText(
                    renderFontSmall,
                    string.format("{00FFFF}Нажатий {FFD700}ALT {00FFFF}в секунду: %s {FFFF00}/ {00FFFF}Ларцов: {ff0000}%d", cpsDisplay, luxuryCount),
                    sw / 2 - 100,
                    sh - 75,
                    0xFFFFFFFF
                )
            elseif showFloodStats[0] then
                renderFontDrawText(
                    renderFontSmall,
                    string.format("{A7F3D0}Время ловли: {FFFF00}%02d:%02d.%d", math.floor(elapsedMs / 60000), math.floor(elapsedMs / 1000) % 60, math.floor(elapsedMs / 100) % 10),
                    sw / 2 - 100,
                    sh - 75,
                    0xFFFFFFFF
                )

                renderFontDrawText(
                    renderFontSmall,
                    string.format("{A7F3D0}Нажатий в секунду: %s%d", cpsColor, floodCps),
                    sw / 2 - 100,
                    sh - 95,
                    0xFFFFFFFF
                )
            end
        end
    end
end)

--[[ Отключает сообщения скрипта в чате ]]
local orig_sampAddChatMessage = sampAddChatMessage
function sampAddChatMessage(text, color)
    if silentMode and silentMode[0] then
        return
    end
    if orig_sampAddChatMessage then
        orig_sampAddChatMessage(text, color or -1)
    end
end

--[[ Логика Concept Car Luxury ]]
function toggleLuxury(state)
    local shouldEnable = (state ~= nil) and state or (not isActiveLuxury)

    if not isNearObject(19300, 1.1) then
        sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. "Вы далеко от места ловли!", -1)
        return
    end

    if shouldEnable == isActiveLuxury then
        return
    end

    isActiveLuxury = shouldEnable

    if autoLuxuryZavoz and autoLuxuryZavoz[0] and isActiveLuxury then
        isSpammingAlt = false
    else
        isSpammingAlt = isActiveFlood or isActiveLuxury
    end

    if isActiveLuxury then
        floodStartedAt = getGameTimer()
        luxuryCount = 0
    end

    sampAddChatMessage(colors.turquoise .. nameScript .. colors.white .. " Ловля ларцов: " .. (isActiveLuxury and colors.greenBright .. "ВКЛ" or colors.redLower .. "ВЫКЛ"))

    lua_thread.create(function()
        while isActiveLuxury do
            if not isNearObject(19300, 1.1) then
                sampAddChatMessage(colors.turquoise .. nameScript .. colors.red .. "Вы отошли от места ловли. Флуд выключен.", -1)
                isActiveLuxury = false
                isSpammingAlt = false
                break
            end
            wait(0)
            if isSpammingAlt then
                for repeatIndex = 1, floodKeyRepeats do
                    sendkey(1024)
                    table.insert(floodKeyPresses, getGameTimer())
                end
            end
        end
    end)
end

--[[Поток для автоматического включения флудера ларцов Concept Car Luxury]]
lua_thread.create(function()
    while true do
        wait(500)

        if isNearObject(19300, 1.1) and autoLuxuryZavoz and autoLuxuryZavoz[0] then
            local time = os.date("*t")

            if time.min == 59 and time.sec >= 58 then
                if not isActiveLuxury then
                    toggleLuxury(true)
                end
                isSpammingAlt = true
            end

            if time.min == 1 and time.sec == 0 then
                if isSpammingAlt then
                    isSpammingAlt = false
                end
            end
        end
    end
end)