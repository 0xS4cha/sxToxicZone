fx_version 'cerulean'
game 'gta5'

name 'sxGroup'
description 'Sacha | Development'
author 'sacha-development'
lua54 'yes'

ui_page "web/dist/index.html"
ui_page_preload 'yes'

files {
	"MINIMAP_LOADER.gfx",
  "web/dist/sounds/*.mp3",
  "web/dist/assets/*.css",
  "web/dist/assets/*.js",
  "web/dist/index.html",
}

shared_script {
	"translations/sh_i18n.lua",
	"translations/rp-translations/*.lua",
	"translations/sh_default.lua",
  "srcs/shared/*.lua"
}

client_script {
    "srcs/client/polyzone/*.lua",
    "srcs/client/main.lua"
}
