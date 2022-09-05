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

    if currentBuild == 10 then
        local classID = select(3, UnitClass("player"))
        local specIndex = GetSpecialization()
        local specId = GetSpecializationInfoForClassID(classID, specIndex)
        db[extension][specId] = {}
        local dbSpec = db[extension][specId]
        local configId = C_ClassTalents.GetActiveConfigID()
        if configId == nil then return end
        local configInfo = C_Traits.GetConfigInfo(configId)
        if configInfo == nil then return end
        for _, treeId in ipairs(configInfo.treeIDs) do
            local nodes = C_Traits.GetTreeNodes(treeId)
            for _, nodeId in ipairs(nodes) do
                local node = C_Traits.GetNodeInfo(configId, nodeId)
                if node.ID ~= 0 then
                    for idx, talentId in ipairs(node.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configId, talentId)
                        local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
                        local spellName = GetSpellInfo(definitionInfo.spellID)
                        if spellName then
                            local talentData = {
                                talentId,
                                definitionInfo.spellID,
                                { node.posX, node.posY, idx, #node.entryIDs },
                                {}
                            }
                            for _, edge in pairs(node.visibleEdges) do
                                local targetNodeId = edge.targetNode
                                local targetNode = C_Traits.GetNodeInfo(configId, targetNodeId)
                                local targetNodeTalentId1 = targetNode.entryIDs[1]
                                if targetNodeTalentId1 then
                                    -- add as target 1st talentId
                                    -- because we don't save nodes
                                    tinsert(talentData[4], targetNodeTalentId1)
                                end
                            end
                            tinsert(dbSpec, talentData)
                        end
                    end
                end
            end
        end
    elseif currentBuild == 9 then
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
        db[extension][class] = db[extension][class] or {}
        local dbClass = db[extension][class]
        local backgroundIndex = MAX_NUM_TALENTS * GetNumTalentTabs() + 1
        dbClass[backgroundIndex] = {}
        dbClass.background = nil
        for tab = 1, GetNumTalentTabs() do
            dbClass[backgroundIndex][tab] = select(4, GetTalentTabInfo(tab))
            for num_talent = 1, GetNumTalents(tab) do
                local name, icon, tier, column = GetTalentInfo(tab, num_talent)
                local talentId = (tab - 1) * MAX_NUM_TALENTS + num_talent
                if name == nil then
                    dbClass[talentId] = nil
                else
                    dbClass[talentId] = dbClass[talentId] or {}
                    dbClass[talentId][1] = icon
                    dbClass[talentId][2] = tier
                    dbClass[talentId][3] = column
                end
            end
        end
    end
    print("Talents saved")
end

if currentBuild < 9 then
    hooksecurefunc(GameTooltip, "SetTalent", function(self, i, j)
        local db = DB
        local _, class = UnitClass("player")
        local _, _, _, _, rank, maxRank = GetTalentInfo(i, j)
        if rank ~= maxRank then return end
        local dbClass = db[extension][class]
        local tab = PanelTemplates_GetSelectedTab(PlayerTalentFrame)
        if tab and PlayerTalentFrame:IsVisible() then
            local talentId = (tab - 1) * MAX_NUM_TALENTS + j
            local spellID = select(2, self:GetSpell())
            if spellID then
                dbClass[talentId][4] = select(2, self:GetSpell())
                local name = GetSpellInfo(dbClass[talentId][4])
                print("saved", dbClass[talentId][4], name)
            end
        end
    end)
end


local spec_frame = CreateFrame("Frame")
spec_frame:RegisterEvent("PLAYER_ENTERING_WORLD")
if currentBuild == 10 then
    spec_frame:RegisterEvent("TRAIT_CONFIG_CREATED")
    spec_frame:RegisterEvent("TRAIT_CONFIG_UPDATED")
end
spec_frame:RegisterEvent("PLAYER_TALENT_UPDATE")
spec_frame:SetScript("OnEvent", update_specs)