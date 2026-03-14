local registeredLanguages = {}
local defaultPhrases = {}
local mainLanguage = "en"

local langToId = {"en", "fr", "de", "it", "es", "pt", "pl", "ru", "ko", "zh", "ja", "me", "fa", "br", "sv", "ar", "tr"}

local DEFAULT_LANGUAGE = GetConvarInt("sh_defaultLanguage", 1)

if not GetCurrentLanguage then
	function GetCurrentLanguage()
		return DEFAULT_LANGUAGE or 0
	end

	function GetLabelText(label)
		return label
	end
end

local autoLanguage = langToId[GetCurrentLanguage() + 1]
local selectedLanguage = autoLanguage

function RegisterDefaultPhrases(phrases)
	defaultPhrases = phrases
end

function UpdateDefaultPhrase(key, name)
    defaultPhrases[key] = name
end
exports("UpdateDefaultPhrase", UpdateDefaultPhrase)

function AddLanguage(name, tbl)
    local old = registeredLanguages[name] or {}
    registeredLanguages[name] = tbl

    for k, v in pairs(old) do
        if not registeredLanguages[name][k] then
			registeredLanguages[name][k] = v
		end
    end
end

function AddPhrase(lang, name, phrase)
    registeredLanguages[lang] = registeredLanguages[lang] or {}
    registeredLanguages[lang][name] = phrase
end
exports("AddPhrase", AddPhrase)

function GetPreferredLanguageId()
	return selectedLanguage or mainLanguage
end
exports("GetPreferredLanguageId", GetPreferredLanguageId)

function GetPhrase(name, ...)
	if not name or not IsPhraseRegistered(name) then return name end

	local langTable = registeredLanguages[selectedLanguage] or registeredLanguages[mainLanguage]
	local arguments = {...}
	for k,v in pairs(arguments) do
		if type(v) == "string" then
			arguments[k] = GetPhrase(v)
		end
	end

	local phrase = langTable[name] or registeredLanguages[mainLanguage][name] or defaultPhrases[name]

	if phrase then
		if #arguments > 0 then
			return string.format(phrase, table.unpack(arguments))
		end

		return phrase
	end

	return (#arguments > 0 and string.format(name, table.unpack(arguments)) or name) or nil
end

function IsPhraseRegistered(name)
	if defaultPhrases[name] then
		return true
	end

	return registeredLanguages[mainLanguage][name] and true or false
end
exports("IsPhraseRegistered", IsPhraseRegistered)

function GetMissingPhrases(lang)
    lang = lang or selectedLanguage
    local res = {}
    local format = "%s = \"%s\","

    for k, v in pairs(registeredLanguages[mainLanguage]) do
        if not registeredLanguages[lang][k] then
			table.insert(res, string.format(format, k, v))
		end
    end

    return #res == 0 and "No language strings missing!" or table.concat(res, "\n")
end

exports("GetPhrase", GetPhrase)

local function getMissingPhrases(ply, args, cmd)
    if not args[1] then print("Please run the command with a language code e.g. darkrp_getphrases \"" .. mainLanguage .. "\"") return end
    local lang = registeredLanguages[args[1]]
    if not lang then print("This language does not exist! Make sure the casing is right.")
        print("Available languages:")
        for k in pairs(registeredLanguages) do print(k) end
        return
    end

    print(GetMissingPhrases(args[1]))
end

if IS_DEV then
	RegisterCommand("getphrases", getMissingPhrases)
end

if not SendNUIMessage then return end

CreateThread(function()

	SetTimeout(1000, function() 
		SendNUIMessage({ type = "getSystemLanguages" })
	end)
end)

local langMappingLanguageRequired = {
	["ko"] = { [8] = true },
	["zh"] = { [9] = true, [12] = true },
	["jo"] = { [10] = true },
}

local disabledLanguages = { ['ar'] = true }

RegisterNUICallback("getSystemLanguages", function(data, cb)
	if data and data[1] then
		local isoCode = data[1]:sub(0, 2):lower()

		if isoCode and isoCode ~= "en" and (not langMappingLanguageRequired[isoCode] or langMappingLanguageRequired[isoCode][GetCurrentLanguage()]) and not disabledLanguages[isoCode] then
			for _,v in pairs(langToId) do
				if v == isoCode then
					autoLanguage = isoCode
					selectedLanguage = isoCode
					break
				end
			end
		end
	end

	TriggerEvent("setGameMenuLanguage", selectedLanguage)
	cb("ok")
end)

function SetGameLanguage(language)
	if not language or language == "auto" then
		language = autoLanguage
	end

	selectedLanguage = language
	TriggerEvent("setGameMenuLanguage", selectedLanguage)
end
exports("SetGameLanguage", SetGameLanguage)