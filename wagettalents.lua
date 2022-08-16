local currentBuild = floor(select(4, GetBuildInfo()) / 10000)
local TocToExpansion = {
    [1] = "Vanilla",
    [2] = "TBC",
    [3] = "Wrath",
    [9] = "Shadowlands",
    [10] = "Dragonflight"
}

local extension = TocToExpansion[currentBuild]

local function update_specs()
    DB = DB or {}
    local db = DB
    db[extension] = db[extension] or {}

    if currentBuild >= 9 then
        for specIndex = 1, GetNumSpecializations() do
            local specId = GetSpecializationInfo(specIndex)
            db[extension][specId] = db[extension][specId] or {}
            local dbSpec = db[extension][specId]
            local talentIndex = 1
            for tier = 1, MAX_TALENT_TIERS do
                for column = 1, NUM_TALENT_COLUMNS do
                    local talentID, name, texture, selected, available, spellID, unknown, row, column, known, grantedByAura = GetTalentInfoBySpecialization(specIndex, tier, column)
                    dbSpec[talentIndex] = spellID
                    talentIndex = talentIndex + 1
                end
            end
        end
    else
        local class = select(2, UnitClass("player"))
        db[extension][class] = {}
        local dbClass = db[extension][class]
        local backgroundIndex = MAX_NUM_TALENTS * GetNumTalentTabs() + 1
        dbClass[backgroundIndex] = {}
        dbClass.background = nil
        for tab = 1, GetNumTalentTabs() do
            dbClass[backgroundIndex][tab] = select(4, GetTalentTabInfo(tab))
            for num_talent = 1, GetNumTalents(tab) do
                local name, icon, tier, column = GetTalentInfo(tab, num_talent)
                local talentId = (tab - 1) * MAX_NUM_TALENTS + num_talent
                dbClass[talentId] = {icon,tier,column}
            end
        end
    end
    print("Talents saved")
end


local spec_frame = CreateFrame("Frame")
spec_frame:RegisterEvent("PLAYER_LOGIN")
spec_frame:SetScript("OnEvent", update_specs)