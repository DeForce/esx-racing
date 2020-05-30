fx_version 'bodacious'

game 'gta5'

description 'Racing Stuff'

version '0.0.1'


ui_page {
	'html/index.html'
}

files {
	'html/script.js',
	'html/main.css',
	'html/index.html',
}

client_scripts {
	'@es_extended/locale.lua',
	'config.lua',
	'client/ui.lua',
	'client/events.lua',
	'client/functions.lua',
	'client/main.lua',
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'@es_extended/locale.lua',
    'config.lua',
	'server/events.lua',
	'server/main.lua',
}

dependencies {
	'mysql-async',
	'es_extended',
}
