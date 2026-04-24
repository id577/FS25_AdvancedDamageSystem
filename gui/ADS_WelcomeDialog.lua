ADS_WelcomeDialog = {}
ADS_WelcomeDialog.INSTANCE = nil

local ADS_WelcomeDialog_mt = Class(ADS_WelcomeDialog, MessageDialog)
local modDirectory = g_currentModDirectory

function ADS_WelcomeDialog.register()
    local dialog = ADS_WelcomeDialog.new()
    g_gui:loadGui(modDirectory .. "gui/ADS_WelcomeDialog.xml", "ADS_WelcomeDialog", dialog)
    ADS_WelcomeDialog.INSTANCE = dialog
end

function ADS_WelcomeDialog.new(target, customMt)
    local dialog = MessageDialog.new(target, customMt or ADS_WelcomeDialog_mt)
    dialog.callback = nil
    dialog.callbackTarget = nil
    dialog.disableTutorial = false
    return dialog
end

function ADS_WelcomeDialog.show(text, callback, callbackTarget)
    if ADS_WelcomeDialog.INSTANCE == nil then
        ADS_WelcomeDialog.register()
    end

    local dialog = ADS_WelcomeDialog.INSTANCE
    dialog.callback = callback
    dialog.callbackTarget = callbackTarget
    dialog.disableTutorial = false

    dialog.dialogTitleElement:setText(g_i18n:getText("ads_tutorial_welcome_dialog_title"))
    dialog.messageTextElement:setText(text or "")

    g_gui:showDialog("ADS_WelcomeDialog")
end

function ADS_WelcomeDialog:onClickDisableTips()
    self.disableTutorial = true
    self:close()
end

function ADS_WelcomeDialog:onClickEnableTips()
    self.disableTutorial = false
    self:close()
end

function ADS_WelcomeDialog:onClose()
    ADS_WelcomeDialog:superClass().onClose(self)

    if self.callback ~= nil then
        if self.callbackTarget ~= nil then
            self.callback(self.callbackTarget, self.disableTutorial)
        else
            self.callback(self.disableTutorial)
        end
    end

    self.callback = nil
    self.callbackTarget = nil
    self.disableTutorial = false
end
