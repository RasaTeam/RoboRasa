do
function run(msg)
	send_document("chat#id"..msg.to.id,"./file/qr.webp", ok_cb, false)
	return 'RoboRasa Telegram Bot v1.0'.. [[ 
	💻 وبسایت : http://RasaTeam.cf

⚙ توسعه دهنده : https://telegram.me/Dayan_AF

🛡 کانال : https://telegram.me/RCT_channel

💰 قدرت گرفته از : تیم سایبری راسا

🔱 با تشکر از : سازمان امنیتی دارک
end

return {
	description = "Robot and Creator About", 
	usagehtm = '<tr><td align="center">ver</td><td align="right">+ ارائه اطلاعات ورژن ربات</td></tr>',
	usage = "ver : ورژن",
	patterns = {
		"^[Vv]er$"
	}, 
	run = run 
}
end
