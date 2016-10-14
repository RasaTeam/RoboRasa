do
function run(msg)
	send_document("chat#id"..msg.to.id,"./file/qr.webp", ok_cb, false)
	return 'RoboRasa Telegram Bot v1.0'.. [[ 
	
	Website:
	http://RasaTeam.cf
	Antispam Bot : @RoboRasa
	Channel : @RCT_channel
	Sudo : @Dayan_AF
	
	Powered by:
	Rasa Cyber Team
	
	Special Thanks:
	Dark
	TeleSurena

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
