package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

VERSION = '1.0'

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  local receiver = get_receiver(msg)
  print (receiver)

  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)
end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < now then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
  	local login_group_id = 1
  	--It will send login codes to this chat
    send_large_msg('chat#id'..login_group_id, msg.text)
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end

  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        send_msg(receiver, warning, ok_cb, false)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Allowed user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "onservice",
    "inrealm",
    "ingroup",
    "inpm",
    "banhammer",
    "stats",
    "anti_spam",
    "owners",
    "arabic_lock",
    "set",
    "get",
    "broadcast",
    "download_media",
    "invite",
    "all",
    "leave_ban",
    "admin"
    },
    sudo_users = {110626080,103649648,143723991,111020322,0,tonumber(91112540)},--Sudo users
    disabled_channels = {},
    moderation = {data = 'data/moderation.json'},
    about_text = [[Teleseed v2 - Open Source
An advance Administration bot based on yagop/telegram-bot 

https://github.com/SEEDTEAM/TeleSeed

Editors:
Dayan (@Dayan_AF)
ZAMAN (@Z4M4N)
Special thanks to:
Mr.King
Our channel:
official channel of rasa @RCT_channel
]],
    help_text_realm = [[
		⚔راهنمای ربات #راسا برای مدیران و اعضا

💠!creategroup (نام)
+ جهت ساختن یک گروه جدید توسط ربات

💠!createrealm (نام)
+ جهت ساختن یک محدوده جدید توسط ربات

💠!setname (نام)
+ جهت تعویض نام گروه

💠!setrules (متن)
+ جهت تعیین و یا تعویض قوانین گروه

💠!setabout (متن)
+ جهت تعیین و یا تعویض متن درباره گروه

💠!lock (آیدی گروه)(setting)
+ قفل کردن تنظیمات یک گروه بر اساس آیدی گروه

💠!unlock (آیدی گروه)(setting)
+ باز کردن قفل کردن تنظیمات یک گروه بر اساس آیدی گروه

💠!wholist
+ جهت دریافت یک لیست از اطلاعات گروه/محدوده

💠!who
+ جهت دریافت یک فایل از اطلاعات گروه/محدوده

💠!type
+ اطلاع از نوع گروه

💠!kill chat (آیدی گروه)
+حذف کردن تمام اعضای یک گروه و پاک کردن گروه بر اساس آیدی گروه

💠!kill realm (آیدی محدوده)
+حذف کردن تمام اعضای یک محدوده و پاک کردن محدوده بر اساس آیدی محدوده

💠!addadmin (یوزرنیم / آیدی)
+ اضافه کردن یک شخص بر اساس یوزرنیم/آیدی به ادمینها

💠!removeadmin (یوزرنیم / آیدی)
+ حذف کردن یک شخص بر اساس یوزرنیم/آیدی از ادمینها

💠!list groups
+ دریافت یک لیست از اطلاعات تمام گروه ها

💠!list realms
+ دریافت یک لیست از اطلاعات تمام محدوده ها

💠!log
+ دریافت یک فایل از وقایع یک گروه/محدوده
]],
    help_text = [[
		🔰راهنمای دستورات ربات راسا🔰


🛡Kick (ریپلای / یوزرنیم / آیدی)
+ جهت اخراج کردن یک فرد/ربات از گروه

🛡 Ban (ریپلای / یوزرنیم / آیدی)
+ جهت محروم کردن یک فرد /ربات از گروه

🛡 Unban (ریپلای / یوزرنیم / آیدی)
+ جهت آزاد کردن یک فرد/ربات از محرومیت

🛡 Who
+ دریافت لیست اعضای گروه

🛡 Modlist 
+ دریافت لیست مدیران ربات

🛡 Promote (یوزرنیم)
+ دادن مقام به یک فرد در یک گروه

🛡 Demote (یوزرنیم) 
+ سلب مقام از یک فرد در یک گروه

🛡 Kickme
+ جهت خروج از گروه

🛡 About
+ دریافت متن درباره گروه

🛡 Setphoto
+ جهت تعیین و یا تعویض کردن نمایه گروه

🛡 Setname (نام)
+ جهت تعیین و یا تعویض نام گروه

🛡 Rules
+ جهت دریافت متن قوانین گروه

🛡 Id
+ جهت دریافت آیدی شخص/گروه

🛡 Help
+ جهت دریافت راهنمای ربات

🛡 Lock (member/ name / photo / bots / leave)
+ جهت قفل کردن (اعضا / نام / نمایه / رباتها / خروج)

🛡 Unlock (member/ name / photo / bots / leave)
+ جهت باز کردن (اعضا / نام / نمایه / رباتها / خروج)

🛡 Set rules (متن)
+ تنظیم متن قوانین گروه

🛡 Set about (متن)
+ تنظیم متن درباره گروه

🛡 Settings
+ دریافت تنظیمات گروه

🛡 Newlink
+ ساخت و یا تعیض لینک گروه

🛡Link
+ دریافت لینک گروه

🛡 Owner
+ دریافت اطلاعات مالک گروه

🛡 Setowner (آیدی)
+ انتقال مالکیت گروه با آیدی شخص

🛡 Setflood (عدد)
+ تنظیم حساسیت اسپم (تعداد)

🛡 Stats
+ آمار

🛡 Save (متن)(عدد)
+ ذخیره متن با عدد

🛡 Get
+ دریافت متن ذخیره شده در یک عدد

🛡 Clean (modlist / rules / about)
+ پاک کردن لیست مدیران / قوانین / درباره

🛡 Res (یوزرنیم)
+ دریافت اطلاعات از طریق یوزرنیم

🛡 Log
+ دریافت آمار گروه

🛡 Banlist
+ دریافت لیست افراد محروم شده



🔰شما میتوانید برای علائم از علامتهای ( ! ) و ( / ) استفاده کنید

🔰فقط سودو ادمین و مالک گروه میتوانند ربات به گروه اضافه کنند

🔰تنها سودو ادمین و مالک گروه میتوانند از عبارات kick,ban,unban,newlink,link,setphoto,setname,lock,unlock,set rules,set about و settings استفاده کنند

🔰در گروه به جز ادمین های اصلی تنها مالک گروه میتواند از عبارات res,setowner,promote,demote و log استفاده کند


💻ویرایش شده توسط اعضای تیم راسا
📲کانال رسمی: @RCT_channel
📲سایت: www.RasaTeam.cf
]]
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)

end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
      print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end


-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end

-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
