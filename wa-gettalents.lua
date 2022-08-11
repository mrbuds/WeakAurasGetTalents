WAGETTALENTSDB = WAGETTALENTSDB or {}
local db = WAGETTALENTSDB

local currentBuild = floor(select(4, GetBuildInfo()) / 10000)
local TocToExpansion = {
    [1] = "Vanilla",
    [2] = "TBC",
    [3] = "Wrath",
    [9] = "Shadowlands",
    [10] = "Dragonflight"
}

local extension = TocToExpansion[currentBuild]
db[extension] = db[extension] or {}

local function update_specs()
    local _, class = UnitClass("player")
    db[extension][class] = db[extension][class] or {}
    local dbClass = db[extension][class]

    if currentBuild >= 9 then
        for specIndex = 1, GetNumSpecializations() do
            dbClass[specIndex] = dbClass[specIndex] or {}
            for tier = 1, MAX_TALENT_TIERS do
                dbClass[specIndex][tier] = dbClass[specIndex][tier] or {}
                for column = 1, NUM_TALENT_COLUMNS do
                    local talentID, name, texture, selected, available, spellID, unknown, row, column, known, grantedByAura = GetTalentInfoBySpecialization(specIndex, tier, column)
                    dbClass[specIndex][tier][column] = {
                        spellID = spellID,
                        icon = texture
                    }
                end
            end
        end
    else
        for tab = 1, GetNumTalentTabs() do
            dbClass[tab] = dbClass[tab] or {}
            for num_talent = 1, GetNumTalents(tab) do
                local name, icon, tier, column = GetTalentInfo(tab, num_talent)
                dbClass[tab][num_talent] = {
                    icon = icon,
                    tier = tier,
                    column = column
                }
            end
        end
    end
end


local spec_frame = CreateFrame("Frame")
spec_frame:RegisterEvent("PLAYER_LOGIN")
spec_frame:SetScript("OnEvent", update_specs)