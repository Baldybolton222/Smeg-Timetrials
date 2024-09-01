Config = Config or {}

Config.START_PROMPT_DISTANCE = 5.0              -- distance to prompt to start race
Config.DRAW_TEXT_DISTANCE = 10.0                -- distance to start rendering the race name text
Config.DRAW_SCORES_DISTANCE = 5.0               -- Distance to start rendering the race scores
Config.DRAW_SCORES_COUNT_MAX = 5                -- Maximum number of scores to draw above race title
Config.DRAW_MARKER_DISTANCE = 25.0              -- distance to draw markers
Config.CHECKPOINT_Z_OFFSET = -5.00              -- checkpoint offset in z-axis
Config.RACING_HUD_COLOR = { 238, 198, 78, 255 } -- color for racing HUD above map
Config.CHECKPOINT_DIFFERENCE_POSITIVE_COLOUR = { 102, 0, 0, 255 } -- colour of delta HUD when delta is positive
Config.CHECKPOINT_DIFFERENCE_NEGATIVE_COLOUR = { 0, 204, 102, 255 } -- colour of delta HUD when delta is negative
Config.COOLDOWN = 3 * 60 * 1000 -- cooldown time, 3 minutes by default
Config.ALLOW_PLAYER_OWNED_VEHICLES_ONLY = false -- whether to allow player owned vehicles only or not
Config.ALLOW_PLAYER_TO_CANCEL_RACE = true -- whether to allow the player to cancel an ongoing race or not
Config.PLAYER_RACE_RESTART_KEY = 182 -- key to restart the race, defaults to L. See https://docs.fivem.net/docs/game-references/controls/#controls
Config.REWARD_CASH_OR_BANK = "cash" -- whether to give the player cash or deposit to bank - only set "cash" or "bank", unless you have another custom setting.