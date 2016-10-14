local add_user_cfg = load_from_file('data/add_user_cfg.lua')
local function template_add_user(base, to_username, from_username, chat_name, chat_id)
	base = base or ''
	to_username = '@' .. (to_username or '')
	from_username = '@' .. (from_username or '')
	chat_name = string.gsub(chat_name, '_', ' ') or ''
	chat_id = "chat#id" .. (chat_id or '')
	if to_username == "@" then
		to_username = ''
	end
	if from_username == "@" then
		from_username = ''
	end
	base = string.gsub(base, "{to_username}", to_username)
	base = string.gsub(base, "{from_username}", from_username)
	base = string.gsub(base, "{chat_name}", chat_name)
	base = string.gsub(base, "{chat_id}", chat_id)
	return base
end

function chat_new_user_link(msg)
	local pattern = add_user_cfg.initial_chat_msg
	local to_username = msg.from.username
	local from_username = 'link (@' .. (msg.action.link_issuer.username or '') .. ')'
	local chat_name = msg.to.print_name
	local chat_id = msg.to.id
	pattern = template_add_user(pattern, to_username, from_username, chat_name, chat_id)
	if pattern ~= '' then
		local receiver = get_receiver(msg)
		send_msg(receiver, pattern, ok_cb, false)
	end
end

function chat_new_user(msg)
	local pattern = add_user_cfg.initial_chat_msg
	local to_username = msg.action.user.username
	local from_username = msg.from.username
	local chat_name = msg.to.print_name
	local chat_id = msg.to.id
	pattern = template_add_user(pattern, to_username, from_username, chat_name, chat_id)
	if pattern ~= '' then
		local receiver = get_receiver(msg)
		send_msg(receiver, pattern, ok_cb, false)
	end
end

local function description_rules(msg, nama)
	local data = load_data(_config.moderation.data)
	if data[tostring(msg.to.id)] then
		local about = ""
		local rules = ""
		if data[tostring(msg.to.id)]["description"] then
			about = data[tostring(msg.to.id)]["description"]
			about = "\nتوضيحات گروه :\n"..about.."\n"
		end
		if data[tostring(msg.to.id)]["rules"] then
			rules = data[tostring(msg.to.id)]["rules"]
			rules = "\nقوانين :\n"..rules.."\n"
		end
		local sambutan = "سلام "..nama.."\nبه گروه "..string.gsub(msg.to.print_name, "_", " ").." خوش آمديد\nبراي آشنايي با دستورات help را ارسال کنيد\n"
		local text = sambutan..about..rules.."\n"
		local receiver = get_receiver(msg)
		if is_sudo(msg) then
			local text = "سلام بابایی ^_^\nخـــــــــــــــــوش اومدی"
			send_large_msg(receiver, text, ok_cb, false)
		else
			send_large_msg(receiver, text, ok_cb, false)
		end
	end
end

local function run(msg, matches)
	if not msg.service then
		return "ان آقا ;-|"
	end
	if matches[1] == "chat_add_user" then
		local hash = 'banned:'..msg.to.id..':'..msg.action.user.id
		local banned = redis:get(hash)
		if banned then
			return
		end
		local hash = 'superbanned:'..msg.action.user.id
		local superbanned = redis:get(hash)
		if superbanned then
			return
		end
		local file = io.open("./info/"..msg.action.user.id..".txt", "r")
		if file ~= nil then
			usertype = file:read("*all")
		else
			usertype = nil
		end
		if usertype == nil then
			nama = string.gsub(msg.action.user.print_name, "_", " ")
			chat_new_user(msg)
			description_rules(msg, nama)
		else
			nama = usertype
			chat_new_user(msg)
			description_rules(msg, nama)
		end
	elseif matches[1] == "chat_add_user_link" then
		local hash = 'banned:'..msg.to.id..':'..msg.from.id
		local banned = redis:get(hash)
		if banned then
			return
		end
		local hash = 'superbanned:'..msg.from.id
		local superbanned = redis:get(hash)
		if superbanned then
			return
		end
		local file = io.open("./info/"..msg.from.id..".txt", "r")
		if file ~= nil then
			usertype = file:read("*all")
		else
			usertype = nil
		end
		if usertype == nil then
			nama = string.gsub(msg.from.print_name, "_", " ")
			chat_new_user_link(msg)
			description_rules(msg, nama)
		else
			nama = usertype
			chat_new_user_link(msg)
			description_rules(msg, nama)
		end
	elseif matches[1] == "chat_del_user" then
		local hash = 'banned:'..msg.to.id..':'..msg.action.user.id
		local banned = redis:get(hash)
		if banned then
			return
		end
		local hash = 'superbanned:'..msg.action.user.id
		local superbanned = redis:get(hash)
		if superbanned then
			return
		end
		if is_sudo(msg) then
			return 'اودافظ بابایی ;-('
		else
			local file = io.open("./info/"..msg.action.user.id..".txt", "r")
			if file ~= nil then
				usertype = file:read("*all")
			else
				usertype = nil
			end
			if usertype == nil then
				local bye_name = msg.action.user.first_name
				return 'به سلامت '..bye_name
			else
				return 'خدافظ '..usertype
			end
		end
	end
end

return {
	description = "Welcoming Message",
	usagehtm = '<tr><td align="center">(Welcome)</td><td align="right">این افزونه برای ارسال پیام خوش آمدگویی به افراد، هنگام ورود به گروه میباشد همچنین پیامی را نیز موقع خروج از گروه ارسال میکند. اگر گروه دارای متن توضیحات یا قوانین باشد، آن را نیز به کاربر جدید گوشزد خواهد کرد. ربات این قابلیت را دارد که اگر کاربر رجیستر شده باشید و مقام داشته باشید. به جای نام شما را با مقامتان خطاب کند</td></tr>',
	patterns = {
		"^!!tgservice (chat_add_user)$",
		"^!!tgservice (chat_add_user_link)$",
		"^!!tgservice (chat_del_user)$",
	},
	run = run
}
