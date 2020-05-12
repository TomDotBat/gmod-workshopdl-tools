
--[[-------------------------------------------------------------------------
Tom's WorkshopDL Tools - A few functions to help make Steam Workshop ForceDL easier for server owners to manage.
Created by Tom.bat (STEAM_0:0:127595314)
Website: https://tomdotbat.dev
Email: tom@tomdotbat.dev
Discord: Tom.bat#0001
---------------------------------------------------------------------------]]

local failedCollections = {}

local function addCollections(ids)
    http.Post("https://api.steampowered.com/ISteamRemoteStorage/GetCollectionDetails/v1/",
        {
            ["collectioncount"] = tostring(#ids),
            ["publishedfileids[0]"] = table.concat(ids, ",")
        },
        function(body, len, headers, status)
            local json = util.JSONToTable(body)
            if status != 200 or !json or !json.response then
                if #ids == 1 then
                    print("Failed to add collection '" .. ids[1] .. "' to WorkshopDL due to an invalid response from the API:\n" .. body)
                    return
                end

                for k,v in ipairs(ids) do
                    if failedCollections[v] then continue end

                    addCollections({v})
                    failedCollections[v] = true
                end
                return
            end

            for i,collection in ipairs(json.response.collectiondetails) do
                if !collection.children then continue end

                for k,v in ipairs(collection.children) do
                    resource.AddWorkshop(v.publishedfileid)
                end

                print("Successfully added " .. #collection.children .. " addons to WorkshopDL from '" .. collection.publishedfileid .. "'.")
            end
        end,
        function(err)
            print("Failed to add collection(s) '" .. table.concat(ids, ", ") .. "' to WorkshopDL, please investigate the error below:\n" .. err)
    end)
end

local waitingCollections = {}

function resource.AddWorkshopCollection(id)
    if hook.GetTable()["Think"]["TomWorkshopDL.WaitForFirstThink"] then
        waitingCollections[#waitingCollections + 1] = id
        return
    end

    addCollections({id})
end

hook.Add("Think", "TomWorkshopDL.WaitForFirstThink", function()
    hook.Remove("Think", "TomWorkshopDL.WaitForFirstThink")

    addCollections(waitingCollections)
    waitingCollections = nil
end)