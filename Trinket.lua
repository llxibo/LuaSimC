local simc = require("simc")
local util = require("simc.util")

local log = util.printf

local base_profiles = {
	{ baseChar = "Tier17H/Death_Knight_Frost_1h_T17H",	mainStat = "Str",	bestGem = "50mastery", title = "死亡骑士 - 冰霜 - 双持",	class_icon = "320", },
	{ baseChar = "Tier17H/Death_Knight_Frost_2h_T17H",	mainStat = "Str",	bestGem = "50haste", title = "死亡骑士 - 冰霜 - 双手",	class_icon = "320", },
	{ baseChar = "Tier17H/Death_Knight_Unholy_T17H",	mainStat = "Str",	bestGem = "50mult", title = "死亡骑士 - 邪恶",			class_icon = "320", },
	{ baseChar = "Tier17H/Druid_Balance_T17H",			mainStat = "Int",	bestGem = "50haste", title = "德鲁伊 - 平衡",			class_icon = "186", },
	{ baseChar = "Tier17H/Druid_Feral_T17H",			mainStat = "Agi",	bestGem = "50crit", title = "德鲁伊 - 野性",			class_icon = "186", },
	{ baseChar = "Tier17H/Hunter_BM_T17H",				mainStat = "Agi",	bestGem = "50mastery", title = "猎人 - 野兽控制",			class_icon = "187", },
	{ baseChar = "Tier17H/Hunter_MM_T17H",				mainStat = "Agi",	bestGem = "50mult", title = "猎人 - 射击",				class_icon = "187", },
	{ baseChar = "Tier17H/Hunter_SV_T17H",				mainStat = "Agi",	bestGem = "50mult", title = "猎人 - 生存",				class_icon = "187", },
	{ baseChar = "Tier17H/Mage_Arcane_T17H",			mainStat = "Int",	bestGem = "50mastery", title = "法师 - 奥术",				class_icon = "182", },
	{ baseChar = "Tier17H/Mage_Fire_T17H",				mainStat = "Int",	bestGem = "50crit", title = "法师 - 火焰",				class_icon = "182", },
	{ baseChar = "Tier17H/Mage_Frost_T17H",				mainStat = "Int",	bestGem = "50mult", title = "法师 - 冰霜",				class_icon = "182", },
	{ baseChar = "Tier17H/Monk_Windwalker_1h_T17H",		mainStat = "Agi",	bestGem = "50mult", title = "武僧 - 踏风 - 双持",		class_icon = "390", },
	{ baseChar = "Tier17H/Monk_Windwalker_2h_T17H",		mainStat = "Agi",	bestGem = "50mult", title = "武僧 - 踏风 - 双手",		class_icon = "390", },
	{ baseChar = "Tier17H/Paladin_Retribution_T17H",	mainStat = "Str",	bestGem = "50mastery", title = "圣骑士 - 惩戒",			class_icon = "184", },
	{ baseChar = "Tier17H/Priest_Shadow_T17H_AS",		mainStat = "Int",	bestGem = "50crit", title = "牧师 - 暗影",				class_icon = "183", },
	{ baseChar = "Tier17H/Priest_Shadow_T17H_COP",		mainStat = "Int",	bestGem = "50mastery", title = "牧师 - 暗影",				class_icon = "183", },
	{ baseChar = "Tier17H/Priest_Shadow_T17H_VE",		mainStat = "Int",	bestGem = "50haste", title = "牧师 - 暗影",				class_icon = "183", },
	{ baseChar = "Tier17H/Rogue_Assassination_T17H",	mainStat = "Agi",	bestGem = "50crit", title = "潜行者 - 刺杀",			class_icon = "189", },
	{ baseChar = "Tier17H/Rogue_Combat_T17H",			mainStat = "Agi",	bestGem = "50haste", title = "潜行者 - 战斗",			class_icon = "189", },
	{ baseChar = "Tier17H/Rogue_Subtlety_T17H",			mainStat = "Agi",	bestGem = "50mastery", title = "潜行者 - 敏锐",			class_icon = "189", },
	{ baseChar = "Tier17H/Shaman_Elemental_T17H",		mainStat = "Int",	bestGem = "50mult", title = "萨满祭司 - 元素",			class_icon = "185", },
	{ baseChar = "Tier17H/Shaman_Enhancement_T17H",		mainStat = "Agi",	bestGem = "50mult", title = "萨满祭司 - 增强",			class_icon = "185", },
	{ baseChar = "Tier17H/Warlock_Affliction_T17H",		mainStat = "Int",	bestGem = "50haste", title = "术士 - 痛苦",				class_icon = "188", },
	{ baseChar = "Tier17H/Warlock_Demonology_T17H",		mainStat = "Int",	bestGem = "50mastery", title = "术士 - 恶魔学识",			class_icon = "188", },
	{ baseChar = "Tier17H/Warlock_Destruction_T17H",	mainStat = "Int",	bestGem = "50crit", title = "术士 - 毁灭",				class_icon = "188", },
	{ baseChar = "Tier17H/Warrior_Arms_T17H",			mainStat = "Str",	bestGem = "50mastery", title = "战士 - 武器",				class_icon = "181", },
	{ baseChar = "Tier17H/Warrior_Fury_1h_T17H",		mainStat = "Str",	bestGem = "50crit", title = "战士 - 狂怒 - 双持",		class_icon = "181", },
	{ baseChar = "Tier17H/Warrior_Fury_2h_T17H",		mainStat = "Str",	bestGem = "50crit", title = "战士 - 狂怒 - 双手",		class_icon = "181", },
}

local templates = {
	BRF = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 665, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 671, bonus_id = 560,			},
		{ suffix = "H",		ilvl = 680, bonus_id = 566,			},
		{ suffix = "HWF",	ilvl = 686, bonus_id = "561/566",	},
		{ suffix = "M",		ilvl = 695, bonus_id = 567,			},
		{ suffix = "MWF",	ilvl = 701, bonus_id = "562/567",	},
	}, },
	Highmaul = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 655, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 661, bonus_id = 560,			},
		{ suffix = "H",		ilvl = 670, bonus_id = 566,			},
		{ suffix = "HWF",	ilvl = 676, bonus_id = "561/566",	},
		{ suffix = "M",		ilvl = 685, bonus_id = 567,			},
		{ suffix = "MWF",	ilvl = 691, bonus_id = "562/567",	},
	}, },
	BRF_LFR = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 650, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 656, bonus_id = 560,			},
	}, },
	Highmaul_LFR = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 640, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 646, bonus_id = 560,			},
	}, },
	Heroic = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 615, bonus_id = 522,			},
		{ suffix = "H",		ilvl = 630, bonus_id = 524,			},
		{ suffix = "HWF",	ilvl = 636, bonus_id = "499/524",	},
	}, },
	World_Drop_665 = { varies = {
		{ suffix = "N",		ilvl = 665,							},
	}, },
	World_Drop_597 = { varies = {
		{ suffix = "N",		ilvl = 597,							},
	}, },
	Inscription = {	varies = {
		{ suffix = "S1",	ilvl = 640, bonus_id = 525,			},
		{ suffix = "S2",	ilvl = 655, bonus_id = 526,			},
		{ suffix = "S3",	ilvl = 670, bonus_id = 527,			},
	}, },
	Follower_645 = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 645, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 651, bonus_id = 560,			},
	}, },
	Follower_630 = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 630, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 636, bonus_id = 560,			},
	}, },
	Follower_615 = { has_gem = true, varies = {
		{ suffix = "N",		ilvl = 615, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 621, bonus_id = 560,			},
	}, },
	Alchemy = { varies = {
		{ suffix = "N",		ilvl = 620, 						},
	}, },
	Alchemy_Stones = { varies = {
		{ suffix = "N",		ilvl = 620, id = 109262, 			},
		{ suffix = "1",		ilvl = 640, id = 122601, 	name = "Stone of Wind", 		ptr = true, },
		{ suffix = "2",		ilvl = 655, id = 122602, 	name = "Stone of the Earth", 	ptr = true, },
		{ suffix = "3",		ilvl = 670, id = 122603, 	name = "Stone of the Waters", 	ptr = true, },
		{ suffix = "4",		ilvl = 680, id = 122604, 	name = "Stone of Fire", 		ptr = true, },
	}, },
	PvP_Conquest = { varies = {
		{ suffix = "N",		ilvl = 660, bonus_id = 0,			},
	}, },
	PvP_Honor = { varies = {
		{ suffix = "N",		ilvl = 620, bonus_id = 0,			},
		{ suffix = "NWF",	ilvl = 626, bonus_id = 547,			},
	}, },
}

function GetTrinkets()
	return {
		-- Blackrock Foundry
		{ id = 113931, name = "跳动的山脉之心",			template = "BRF",				mainStat = "Agi", },
		{ id = 113985, name = "蜂鸣黑铁触发器",			template = "BRF",				mainStat = "Agi", },
		{ id = 118114, name = "多肉龙脊奖章",			template = "BRF",				mainStat = "Agi", },
		{ id = 113969, name = "抽搐暗影之瓶",			template = "BRF",				mainStat = "Str", },
		{ id = 113983, name = "熔炉主管的徽记",			template = "BRF",				mainStat = "Str", },
		{ id = 119193, name = "尖啸之魂号角",			template = "BRF",				mainStat = "Str", },
		{ id = 113948, name = "达玛克的无常护符",		template = "BRF",				mainStat = "Int", },
		{ id = 113984, name = "黑铁微型坩埚",			template = "BRF",				mainStat = "Int", },
		{ id = 119194, name = "鬣蜥人灵魂容器",			template = "BRF",				mainStat = "Int", },
		-- Highmaul
		{ id = 113853, name = "被捕获的微型畸变怪",		template = "Highmaul",			mainStat = "Agi", },
		{ id = 113612, name = "毁灭之鳞",				template = "Highmaul",			mainStat = "Agi", },
		{ id = 113645, name = "泰克图斯的脉动之心",		template = "Highmaul",			mainStat = "Str", },
		{ id = 113658, name = "感染孢子瓶",				template = "Highmaul",			mainStat = "Str", },
		{ id = 113835, name = "虚无碎片",				template = "Highmaul",			mainStat = "Int", },
		{ id = 113859, name = "沉寂符石",				template = "Highmaul",			mainStat = "Int", },
		-- Blackrock Foundry LFR
		{ id = 116314, name = "黑心执行者勋章",			template = "BRF_LFR",			mainStat = "Agi", },
		{ id = 116317, name = "储藏室钥匙",				template = "BRF_LFR",			mainStat = "Str", },
		{ id = 116315, name = "狂怒之心护符",			template = "BRF_LFR",			mainStat = "Int", },
		-- Highmaul LFR
		{ id = 116289, name = "血喉之牙",				template = "Highmaul_LFR",		mainStat = "Agi", },
		{ id = 116292, name = "活体之山微粒",			template = "Highmaul_LFR",		mainStat = "Str", },
		{ id = 116290, name = "龟裂创伤徽章",			template = "Highmaul_LFR",		mainStat = "Int", },
		-- World drop
		{ id = 118876, name = "双面幸运金币",			template = "World_Drop_665",	mainStat = "Agi", },
		{ id = 118882, name = "奇亚诺斯的剑鞘",			template = "World_Drop_665",	mainStat = "Str", },
		{ id = 118878, name = "科普兰的清醒",			template = "World_Drop_665",	mainStat = "Int", },
		-- { id = 118875, name = "帕吉诺夫的永恒之谜",		template = "World_Drop_597",	mainStat = "Agi", },
		-- 5-man Heroic
		{ id = 109995, name = "阿扎凯尔的鲜血之印",		template = "Heroic",			mainStat = "Agi", },
		{ id = 109998, name = "高尔山的磁石针",			template = "Heroic",			mainStat = "Agi", },
		{ id = 109997, name = "琪拉的激素注射器",		template = "Heroic",			mainStat = "Agi", },
		{ id = 109996, name = "雷塔的准心",				template = "Heroic",			mainStat = "Agi", },
		{ id = 109999, name = "枯木的树枝",				template = "Heroic",			mainStat = "Agi", },
		{ id = 110010, name = "腐蚀微粒",				template = "Heroic",			mainStat = "Str", },
		{ id = 110011, name = "骄阳烈火",				template = "Heroic",			mainStat = "Str", },
		{ id = 110012, name = "骨喉的大脚趾",			template = "Heroic",			mainStat = "Str", },
		{ id = 110013, name = "烬鳞护符",				template = "Heroic",			mainStat = "Str", },
		{ id = 110014, name = "轻盈孢子",				template = "Heroic",			mainStat = "Str", },
		{ id = 110000, name = "库鲁斯托的符文报警器",	template = "Heroic",			mainStat = "Int", },
		{ id = 110001, name = "托瓦拉的电容器",			template = "Heroic",			mainStat = "Int", },
		{ id = 110002, name = "血肉撕裂者的肉钩",		template = "Heroic",			mainStat = "Int", },
		{ id = 110003, name = "怒翼的火焰之牙",			template = "Heroic",			mainStat = "Int", },
		{ id = 110004, name = "凝固的原祖荆兽血",		template = "Heroic",			mainStat = "Int", },
		-- Crafted from token
		{ id = 114549, name = "豪华之预判",				template = "Follower_645",		mainStat = "Agi", },
		{ id = 114488, name = "动荡剧毒药瓶",			template = "Follower_630",		mainStat = "Agi", }, -- Gem bonus_id 563
		{ id = 114427, name = "慷慨恐惧徽章",			template = "Follower_615",		mainStat = "Agi", },
		{ id = 114552, name = "豪华之杀戮",				template = "Follower_645",		mainStat = "Str", },
		{ id = 114491, name = "动荡徽记",				template = "Follower_630",		mainStat = "Str", }, -- Gem bonus_id 563
		{ id = 114430, name = "慷慨愤怒之骨",			template = "Follower_615",		mainStat = "Str", },
		{ id = 114550, name = "豪华之能量",				template = "Follower_645",		mainStat = "Int", },
		{ id = 114489, name = "动荡聚焦水晶",			template = "Follower_630",		mainStat = "Int", }, -- Gem bonus_id 563
		{ id = 114428, name = "慷慨寒冰宝珠",			template = "Follower_615",		mainStat = "Int", },
		-- Professions
		{ id = 112318, name = "战争之颅",				template = "Inscription",		mainStat = "Agi/Str", },
		{ id = 112320, name = "睡魔之袋",				template = "Inscription",		mainStat = "Int", },
		{ id = 109262, name = "德拉诺点金石",			template = "Alchemy_Stones",	mainStat = "Agi/Str/Int", },
		-- PvP Conquest
		{ id = 111222, name = "原祖角斗士的征服徽章",	template = "PvP_Conquest",		mainStat = "Agi", },
		{ id = 111223, name = "原祖角斗士的征服徽记",	template = "PvP_Conquest",		mainStat = "Agi", },
		{ id = 115759, name = "原祖角斗士的胜利徽章",	template = "PvP_Conquest",		mainStat = "Str", },
		{ id = 115760, name = "原祖角斗士的胜利徽记",	template = "PvP_Conquest",		mainStat = "Str", },
		{ id = 111227, name = "原祖角斗士的统御徽章",	template = "PvP_Conquest",		mainStat = "Int", },
		{ id = 111228, name = "原祖角斗士的统御徽记",	template = "PvP_Conquest",		mainStat = "Int", },
		{ id = 115496, name = "原祖角斗士的冥想徽章",	template = "PvP_Conquest",		mainStat = "Agi/Str/Int", },
		-- PvP Honor
		{ id = 119926, name = "原祖争斗者的征服徽章",	template = "PvP_Honor",			mainStat = "Agi", },
		{ id = 119927, name = "原祖争斗者的征服徽记",	template = "PvP_Honor",			mainStat = "Agi", },
		{ id = 115159, name = "原祖争斗者的胜利徽章",	template = "PvP_Honor",			mainStat = "Str", },
		{ id = 115160, name = "原祖争斗者的胜利徽记",	template = "PvP_Honor",			mainStat = "Str", },
		{ id = 115159, name = "原祖争斗者的胜利徽章",	template = "PvP_Honor",			mainStat = "Int", },
		{ id = 115160, name = "原祖争斗者的胜利徽记",	template = "PvP_Honor",			mainStat = "Int", },
		{ id = 115521, name = "原祖争斗者的冥想徽章",	template = "PvP_Honor",			mainStat = "Agi/Str/Int", },
	}
end

function AssertTrinket(info, name)
	-- print("Asserting trinket", print_table(info))
	local item = util.GetItemInfo(info)
	local itemEnglish = util.GetItemInfo(info, "enUS")
	assert(item.name == name or itemEnglish.name == name, itemEnglish.name)
end

function WriteBBCode(session)
	local bbcode = io.open([[Reports/Report.bbcode]], "a+")
	local version = simc.GetSimCVersion(session.ptr)

	bbcode:write("[img]http://img4.ngacn.cc/ngabbs/nga_classic/f/", session.class_icon, ".png[/img]")
	bbcode:write("[size=140%][color=royalblue][b]", session.title, "[/b][/color]")
	if session.ptr then
		bbcode:write(" [color=red][b]", version.clientDesc, "[/b][/color]")
	end
	bbcode:write("[/size]\n")
	bbcode:write("配置文件: ", session.name, "\n")
	bbcode:write("[table]", "\n")

	-- Header of table - name of trinkets
	log("Writing headers of bbcode ...")
	bbcode:write("[tr]", "\n")
	bbcode:write("[td]", "[/td]", "\n")	-- Corner

	local ilvlLookup = {}
	for index, trinket in ipairs(session.trinkets) do
		for index, vary in ipairs(trinket.varies) do
			ilvlLookup[vary.ilvl] = true
		end
	end
	local ilvlList = {}
	for ilvl in pairs(ilvlLookup) do
		table.insert(ilvlList, ilvl)
	end
	table.sort(ilvlList, function (v1, v2) return v1 > v2 end)

	for index, ilvl in ipairs(ilvlList) do 	-- Header
		bbcode:write("[td][b]", ilvl, "[/b][/td]", "\n")
	end
	bbcode:write("[/tr]", "\n")

	local function FindVary(trinket, ilvl)
		for index, vary in ipairs(trinket.varies) do
			if vary.ilvl == ilvl then
				return index, vary
			end
		end
	end

	log("Writing bbcode contents ...")
	local baseDPS, baseErr = simc.GetResultDPS(session.baselineResult)
	local maxErr = 0

	for index, trinket in ipairs(session.trinkets) do
		bbcode:write("[tr]")

		local lastVary = trinket.varies[#trinket.varies]
		bbcode:write("[td]", util.GetItemBBCode(lastVary.trinket.id), "[/td]")

		for _, ilvl in ipairs(ilvlList) do
			bbcode:write("[td]")
			local varyIndex, vary = FindVary(trinket, ilvl)
			if vary then
				local dps, err = simc.GetResultDPS(vary.result)
				bbcode:write(("%d"):format(dps - baseDPS))
				maxErr = math.max(maxErr, err)
				if trinket.variesGem then
					assert(trinket.variesGem[varyIndex])
					local dps, err = simc.GetResultDPS(trinket.variesGem[varyIndex].result)
					bbcode:write(("\n[color=silver](%d)[/color]"):format(dps - baseDPS))
					maxErr = math.max(maxErr, err)
				end
			end
			bbcode:write("[/td]")
		end
		bbcode:write("[/tr]", "\n")
	end
	bbcode:write("[/table]", "\n")
	bbcode:write("表中所有评分误差不高于", maxErr, "。", "\n")
	bbcode:write(("基于SimC版本 %s，子版本最后更改日期 %s，WoW %s。"):format(version.versionFull, version.date, version.clientDesc))
	bbcode:write("\n")
	bbcode:close()
end

local colorTable = {
	"#7cb5ec",
	"#434348",
	"#90ed7d",
	"#f7a35c",
	"#8085e9",
	"#f15c80",
	"#e4d354",
	"#8085e8",
	"#8d4653",
	"#91e8e1",
	"#2f7ed8",
	"#0d233a",
	"#8bbc21",
	"#910000",
	"#1aadce",
	"#492970",
	"#f28f43",
	"#77a1e5",
	"#c42525",
	"#a6c96a",
	"#4572a7",
	"#aa4643",
	"#89a54e",
	"#80699b",
	"#3d96ae",
	"#db843d",
	"#92a8cd",
	"#a47d7c",
	"#b5ca92",
}

function WriteHighchart(session)
	log("Generating highchart table...")
	local version = simc.GetSimCVersion(session.ptr)
	local chart = {
		chart = {
			type = "spline",
			width = 1200,
			height = 700,
		},
		credits = { text = ("llxibo @NGACN | %s | %s | WoW %s"):format(
			version.versionFull, version.date, version.clientDesc
		), },
		title = {
			text = "饰品评分 - " .. session.title,
		},
		subtitle = {
			text = session.subtitle,
		},
		xAxis = {
			type = "linear",
			gridLineWidth = 1,
			-- tickInterval = 10
			minorTickInterval = 5,
			minorTickWidth = 1,
			title = { text = "物品等级", },
			plotLines = {
				{
					value = 630,
					label = { text = "五人<br/>英雄", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 640,
					label = { text = "悬锤堡<br/>团队随机", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 655,
					label = { text = "悬锤堡<br/>普通", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 670,
					label = { text = "悬锤堡<br/>英雄", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 685,
					label = { text = "悬锤堡<br/>史诗", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 650,
					label = { text = "黑石铸造厂<br/>团队随机", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 665,
					label = { text = "黑石铸造厂<br/>普通", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 680,
					label = { text = "黑石铸造厂<br/>英雄", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				{
					value = 695,
					label = { text = "黑石铸造厂<br/>史诗", rotation = 0, },
					color = "#3f3f3f",
					width = 2,
				},
				___isarray = true,
			},
		},
		yAxis = {
			title = { text = "评分", },
		},
		series = util.NewArray(),
		plotOptions = {
			spline = {
				marker = { symbol = "circle" },
			},
			line = {
				width = 1,
				-- marker = { symbol = "triangle-down", },
			},
		},
		legend = {
			layout = "vertical",
			verticalAlign = "middle",
			align = "right",
			borderRadius = 10,
			itemMarginTop = 5,
			itemMarginBottom = 5,
			-- useHTML = true,
		},
	}

	if session.ptr then
		chart.title.text = chart.title.text .. (" <font color='#ff0000'>PTR %s build %s</font>"):format(version.clientVer, version.clientBuild)
		chart.title.useHTML = true
	end

	local baseDPS, baseErr = simc.GetResultDPS(session.baselineResult)
	for index, trinket in ipairs(session.trinkets) do
		local color = colorTable[((index - 1) % #colorTable) + 1]
		assert(color, "Color not exist " .. index)

		local trinketData = util.NewArray()
		local trinketIcon = util.GetItemInfo(trinket.varies[1].trinket).icon
		for varyIndex, vary in ipairs(trinket.varies) do
			local icon = util.GetItemInfo(vary.trinket).icon

			local dps, err = simc.GetResultDPS(vary.result)
			local rating = dps - baseDPS
			table.insert(trinketData, {
				x = vary.ilvl,
				y = rating,
				marker = {
					symbol = icon and ("url(http://img.db.178.com/wow/icons/s/%s.jpg)"):format(icon),
				},
			})
			if trinket.has_gem then
				local varyGem = trinket.variesGem[varyIndex]
				assert(varyGem.ilvl and varyGem.ilvl == vary.ilvl)
				local dpsGem, errGem = simc.GetResultDPS(varyGem.result)
				local ratingGem = dpsGem - baseDPS
				table.insert(chart.series, {
					type = "line",
					color = color,
					showInLegend = false,
					data = {
						{x = vary.ilvl, y = rating, marker = {enabled = false,}},
						{x = varyGem.ilvl, y = ratingGem, marker = {symbol = "triangle-down",}},
						___isarray = true,
					},
				})
			end
		end
		table.insert(chart.series, {
			name = trinket.name,
			type = "spline",
			color = color,
			data = trinketData,
			-- marker = {
			-- 	symbol = trinketIcon and ("url(http://wow.zamimg.com/images/wow/icons/small/%s.jpg)"):format(trinketIcon),
			-- },
		})
	end
	log("Writing highchart table...")

	local highchart = io.open([[highchart_output.js]], "w")
	util.WriteJson(highchart, chart)
	highchart:close()

	log("Rendering with phantomjs...")
	os.execute([[D:\phantomjs-1.9.8-windows\phantomjs.exe D:\phantomjs-1.9.8-windows\Highcharts-4.0.4\exporting-server\phantomjs\highcharts-convert.js -infile highchart_output.js -outfile Reports/']] .. session.global_index .. ". " .. session.name .. ".png'")
end

function RateTrinketGroup(session_index, base_profile)
	local session = util.CopyTable(base_profile)

	session.trinkets = {}
	for index, trinket in ipairs(GetTrinkets()) do
		if trinket.mainStat:find(session.mainStat) then
			table.insert(session.trinkets, trinket)
		end
	end
	local session_name = session.baseChar:match("[^/]+$")
	print("Using base profile", session.baseChar)

	local func = loadfile([[Sessions/]] .. session_name .. [[.lua]])			-- Load prev session
	if func then
		log("Loading session from file ...")
		func()
	end

	session.name = session_name
	session.global_index = session_index
	session.min_ilvl = 630
	session.iterations = 100

	local globals = {
		default_actions = 1,
		ptr = session.ptr,
		-- threads = -2,
	}

	log("=== Starting process for %s ===", session.name)

	log("Generating baseline char")
	session.baselineResult = simc.SimulateChar(
		{baseChar = session.baseChar, trinket1 = "", trinket2 = ""},
		globals,
		session.iterations * 5,
		session.baselineResult
	)
	util.SaveSession(session)

	-- Sanity check, expand and filtering
	for index, trinket in ipairs(session.trinkets) do
		assert(trinket.name, "Trinket must have a name")

		-- Expand templates
		local template = templates[trinket.template]
		if template then
			for key, value in pairs(template) do
				trinket[key] = util.CopyTable(value)
			end
			trinket.template = nil
		end

		-- Filter low level varies
		local variesFiltered = {}
		for index, vary in ipairs(trinket.varies) do
			if vary.ilvl >= session.min_ilvl and (session.ptr or not vary.ptr) then
				table.insert(variesFiltered, vary)
			end
		end
		trinket.varies = variesFiltered

		-- Expand varies
		for index, vary in ipairs(trinket.varies) do
			vary.trinket = {
				id = vary.id or trinket.id,
				bonus_id = vary.bonus_id,
			}
			AssertTrinket(vary.trinket, vary.name or trinket.name)
		end
	end

	-- Filter empty trinkets (all varies filtered)
	local trinketsNonEmpty = {}
	for index, trinket in ipairs(session.trinkets) do
		if #trinket.varies > 0 then
			table.insert(trinketsNonEmpty, trinket)
		end
	end
	session.trinkets = trinketsNonEmpty
	log("Processing %d valid trinkets", #session.trinkets)

	-- Do ratings
	for index, trinket in ipairs(session.trinkets) do
		print("Processing trinket", trinket.name)
		-- Copy if varies needs to be expanded as (gem) and (no gem)
		if trinket.has_gem and not trinket.variesGem then
			trinket.variesGem = util.CopyTable(trinket.varies)
			assert(session.bestGem, "Best gem not specified")
			for index, vary in ipairs(trinket.variesGem) do
				vary.trinket.enchant = session.bestGem
				local char = {
					baseChar = session.baseChar,
					trinket1 = vary.trinket,
					trinket2 = "",
				}
				vary.result = simc.SimulateChar(char, globals, session.iterations, vary.result)
			end
		end
		-- Default varies (no gem)
		for index, vary in ipairs(trinket.varies) do
			local char = {
				baseChar = session.baseChar,
				trinket1 = vary.trinket,
				trinket2 = "",
			}
			vary.result = simc.SimulateChar(char, globals, session.iterations, vary.result)
			trinket.maxDPS = math.max(trinket.maxDPS or 0, simc.GetResultDPS(vary.result))
		end

		util.SaveSession(session, true)
	end

	log("Writing output files ...")
	WriteBBCode(session)
	WriteHighchart(session)

	log("===Process finished===")
end

os.execute("mkdir Reports")
os.remove("Reports/Report.bbcode")

for session_index, base_profile in ipairs(base_profiles) do
	RateTrinketGroup(session_index, base_profile)
end
