ServerConfig = {}
ServerConfig.debug = true

ServerConfig.token = GetConvar("discordToken", "none")
ServerConfig.guildId = "1193864526291021865"

ServerConfig.refreshCommandEnabled = true
ServerConfig.refreshCommandCooldown = 60 * 1000 -- 1 minute
ServerConfig.refreshCommandName = "refreshDiscord"
