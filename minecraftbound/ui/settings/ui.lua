widgets = {}

gbSettings = {
    crosshairColor = {255,255,255},
    autoReload = true,
    cameraPan = true
}

function call(wid)
    if widgets[wid] then
        widgets[wid]()
    end
end

function init()
    local loadedSettings = status.statusProperty("minecraftSettings", {})
    gbSettings = sb.mergeJson(gbSettings, loadedSettings)

end

function saveConfig()
    status.setStatusProperty("minecraftSettings", gbSettings)
end

function update(dt)

end