# My-luas

个人自用的 **gamesense (skeet.cc)** Lua 脚本合集 —— 一部分是自己写的，一部分是从社区收集、按功能整理归档的。

> ⚠️ **使用前请先读 [安全提示](#-安全提示)。** 本仓库中有两个脚本含硬编码远程服务器 / 远程加载行为。

[English](#english) · [中文](#中文)

---

## 中文

### 目录结构

```
My-luas/
├── luas/
│   ├── AntiAim/          反瞄准 / fakelag / 慢走
│   ├── Misc/             杂项（聊天、音效、动画、购买机器人、辅助工具）
│   │   ├── Chat/         聊天相关
│   │   ├── Helper/       场景辅助（1way、helper、Fastsetup）
│   │   ├── Sound/        音效与声音
│   │   └── player_animation/  玩家动画
│   ├── Rage/             Rage bot 相关
│   │   ├── Adaptive_Weapon/   自适应武器（8 个版本，见下）
│   │   ├── airstop/      急停
│   │   └── autopeek/     自动 peek
│   └── Visual/           视觉类
│       ├── ESP/          人物 / 投掷物透视
│       ├── Grenade/      投掷物相关
│       ├── HUD+Menu/     菜单与 HUD 改动
│       ├── Hitmarker/    命中反馈
│       ├── Indicator/    各类指示器
│       ├── Keybinds/     按键面板（Solus 系列）
│       ├── Log/          战斗日志
│       ├── Thirdperson/  第三人称
│       └── World/        世界渲染（天空盒、雾、光照、拖影……）
└── materials/            天空盒材质包（**不是 Lua**，见下）
```

### 安装与使用

把这些 `.lua` 丢进 gamesense 的脚本目录即可（菜单 `Scripts` 里加载）。每个脚本在游戏内菜单的具体位置见下表「菜单位置」列。

### 脚本索引

| 脚本 | 说明 | 菜单位置 |
|---|---|---|
| **AntiAim** | | |
| `!fakelag_syr.lua` | fakelag 变体 | AA > Fake Lag |
| `Anti-backstab.lua` | 防背刺（Anti-knife） | AA > Other |
| `Slowwalk.lua` | 慢走 | lua > b |
| `fakelag.lua` | Q1ng fakelag Release V3，带自定义触发条件 | AA > Fake lag |
| **Misc** | | |
| `Automute_server_mvp_music(tea).lua` | 服务器 MVP 音乐自动静音 | — |
| `Fast_ladder.lua` | 快速上下梯子 | AA > Anti-aimbot angles |
| `Fast_throw.lua` | 快速投掷 | — |
| `Pilot_s_buybot.lua` | **Pilot 原作**购买机器人 | LUA > B |
| `Rare_weapon_animations.lua` | 稀有武器动画 | — |
| `Remove_Collision.lua` | 关闭地图碰撞 | VISUALS > Effects |
| `model_changer.lua` | 模型替换 | skins > model options |
| **Misc / Chat** | | |
| `Enemy_team_chat_revealer.lua` | 显示敌方队内聊天 | MISC > Miscellaneous |
| `killsay.lua` | 击杀后自动喊话（中文） | — |
| `rs.lua` | 无限 RS 刷屏 | — |
| `say_same.lua` | 复读 | — |
| **Misc / Helper** | | |
| `Fastsetup.lua` | 服务器快速设置（单地图列表版） | LUA > B |
| `Saya_1way.lua` | Saya 1way 辅助（1.1 MB，含地图数据） | LUA > A / B |
| `helper.lua` | Helper 主程序，支持远程地图数据 | LUA > A / B、VISUALS > Other ESP |
| **Misc / Sound** | | |
| `Hit_sound.lua` | 终极音效系统（FFI），可选详细设置 | LUA > B |
| `Hit_sound_original.lua` | 原始命中音效 | LUA > B |
| `Microphone_Kill_Message.lua` | 麦克风击杀消息 | — |
| `Sound_volume_modifiers.lua` | 音量调节 | Lua > B |
| `Soundboard.lua` | 声音面板（含 SamzSakerz 的 UI/FS 库） | LUA > A |
| `weapon_sounds.lua` | 武器音效 | — |
| **Misc / player_animation** | | |
| `anim.lua` | 动画基础 | — |
| `anim_moonwalk.lua` | 太空步（仙-跳蹲 / 仙-行走） | lua > b |
| `animcustom.lua` | 自定义动画 | — |
| `animfix.lua` | 动画修复 | AA > Fake lag |
| `earthquake.lua` | 地震效果（FFI） | AA > Other |
| `funny_animations.lua` | 搞笑动画 | Lua > B |
| **Rage** | | |
| `+H1TCHANCE_OVR.lua` | 命中率覆盖（引用原生 MD Override） | — |
| `+HC+MP_OVR.lua` | HC/MP 覆盖（引用原生控件） | — |
| `+Unsafe_Charge_In_Air.lua` | 空中蓄力 | — |
| `Dormant_aimbot.lua` | 睡眠目标瞄准（实验性，带日志与指示器） | RAGE > Aimbot / Other |
| `Friendly_fire.lua` | 友伤 | rage > other |
| `Roll_Resolver.lua` | ⚠️ **见安全提示** | — |
| `disable_airstrafe_when_standing.lua` | 站立时禁用空中加速 | RAGE > Other |
| `fakelag_on_while_double_tap_teleporting.lua` | 双击传送期间开 fakelag | RAGE > Other |
| **Rage / Adaptive_Weapon** | | |
| `+02_weapon.lua` | 自适应武器版本 | RAGE > Aimbot / Other |
| `+Adaptive_Weapon.lua` | 自适应武器版本 | RAGE > Other / aimbot |
| `+Ev1-weapon.lua` | Ev1 自适应武器（带武器 HUD） | Rage > Aimbot / Other |
| `+Ev1_Weapon_new.lua` | Ev1 自适应武器新版 | Lua > A / B |
| `+Seripk_adaptive_weapon.lua` | **Seripk 原作**，由 zebrald 修复并加新功能 | Rage > Aimbot / Other |
| `+Seripk_wpn_old.lua` | Seripk 旧版 | LUA > B、VISUALS > Other ESP |
| `+adap.lua` | 自适应武器（混淆压缩） | RAGE > Aimbot / Other |
| `+unfailer_weapon.lua` | ⚠️ **见安全提示** | — |
| **Rage / airstop** | | |
| `airstop.lua` | 急停 | — |
| `air_autostope.lua` | 自动急停 | — |
| **Rage / autopeek** | | |
| `!mlc_aipeek.lua` | 自动 peek（高级设置、个人 peek 组） | MISC > Movement |
| `AI_Peek.lua` | 自动 peek | — |
| **Visual / ESP** | | |
| `Chicken_esp.lua` | 霓虹鸡 ESP（作者自研） | LUA > B |
| `Chicken_ESP_beta.lua` | 鸡 ESP beta（带 Chickenbot） | LUA > B |
| `Custom_health_bar.lua` | 自定义血条 | — |
| `Fishesp_beta.lua` | 鱼类 ESP beta | — |
| `Last_dormant_position.lua` | 最后睡眠位置 | — |
| `Profile_picture_by_name.lua` | 按名字显示头像 | — |
| `better_player_grenade_esp.lua` | 更好的投掷物 ESP | VISUALS > Player ESP |
| `esp_damage.lua` | 伤害 ESP | RAGE > Other |
| `esp_lagcomp.lua` | Exploit Detector | VISUALS > Other ESP |
| `snap_lines_on_aimbot_target.lua` | 瞄准目标拖影线 | LUA > B |
| **Visual / Grenade** | | |
| `Grenade_radius.lua` | 投掷物半径 | — |
| `Molotov_particles.lua` | 燃烧瓶粒子 | Visuals > Effects |
| `Wireframe_smoke.lua` | 烟雾线框 | Visuals > Effects |
| `molotov_dormant.lua` | 燃烧瓶睡眠 | VISUALS > Other ESP |
| **Visual / HUD+Menu** | | |
| `Custom_killfeed.lua` | 自定义击杀提示 | — |
| `Menu_effect.lua` | 菜单粒子 / 模糊 / 背景 | Misc > Settings |
| `Panorama_Removal.lua` | 移除全景模糊 | MISC > Miscellaneous |
| `Scoreboard_equipment.lua` | 记分板装备显示 | VISUALS > Other ESP |
| `console_color_changer.lua` | 控制台颜色 | misc > settings |
| `hud.lua` | Bassn's HUD | — |
| **Visual / Hitmarker** | | |
| `Custom_Font_Hitmarker.lua` | 自定义字体命中标记（Bassn） | — |
| `Electric_Spark_On_Hit.lua` | 命中电火花 | VISUALS > Effects |
| `Fortnite_damage.lua` | 堡垒之夜伤害数字 | VISUALS > Effects |
| `Missmarker.lua` | 未命中标记 | — |
| `Numbers.lua` | 数字命中标记 | — |
| `hitmarker.lua` / `hitmarker+.lua` | 命中标记 | — |
| `martix_hitboxes.lua` | 命中盒标记 | — |
| **Visual / Indicator** | | |
| `Fade_indicator.lua` | 淡出指示器 | — |
| `Gamesense_RPG.lua` | RPG 风格指示器 | — |
| `Slowdown_indicator.lua` | 减速指示器 | VISUALS > Other ESP |
| `death_indicator.lua` | 死亡警告 | LUA > B |
| `dmg_ind.lua` | 伤害指示器 | — |
| `hitrate.lua` | 命中率指示器 | VISUALS > Other ESP |
| `offscreen_circle.lua` | 屏幕外目标圆圈 | — |
| **Visual / Keybinds** | | |
| `~Simple_keybinds.lua` | 简易按键面板 | — |
| `~Solus_UI_v1.lua` / `~Solus_ui_v2.lua` / `~solus.lua` | Solus 按键面板三个版本 | — |
| **Visual / Log** | | |
| `Aimbot_log.lua` | 瞄准日志（日文命名） | Rage > Other |
| `Aimlog.lua` | 瞄准日志 | — |
| `Chinese_Hitlog.lua` | 中文命中日志 | Misc > Settings |
| `Simple_hitlog.lua` | 简易命中日志 | VISUALS > Effects |
| `Vote_log.lua` | 投票日志 | — |
| `animlog_before.lua` | 瞄准/动画日志（旧版） | RAGE > Other |
| `chatlog.lua` | 聊天日志 | — |
| `hit_log.lua` | 命中日志 | Rage > Other |
| **Visual / Thirdperson** | | |
| `3rdperson.lua` | 第三人称碰撞 | Visuals > Effects |
| `Camera.lua` | 摄像机（混淆压缩） | — |
| `Thirdperson_Animations.lua` | 第三人称动画（Exodouding） | Visuals > Effects |
| **Visual / World** | | |
| `Bloom.lua` | 泛光 / 墙色 | VISUALS > Effects |
| `Cascade_Light.lua` | 级联光照（qhouz） | — |
| `Chinese_Hat.lua` | 中国帽子（可渐变） | LUA > A |
| `Force_aspect_ratio.lua` | 强制宽高比 | — |
| `Player_Trails.lua` | 玩家拖影 | LUA > a |
| `Skybox_fixed.lua` | 天空盒修改（3yozk1 修复版） | VISUALS > Effects |
| `bullet_tracers.lua` | 子弹轨迹 | VISUALS > Effects |
| `fog.lua` | 雾 | — |
| `o_post_processing.lua` | 后期处理开关 | — |
| `remap.lua` | 材质重映射 | — |
| `skybox_2.lua` | 天空盒 | LUA > A |
| **Visual** | | |
| `Viewmodel_Changer_+_Animations.lua` | 视图模型替换与动画 | — |

### materials/

两个 **CS 材质包**，不是 Lua 脚本：

- `skybox_sky_z.zip`（8.7 MB）— 天空盒材质，含 `sky_z*.vmt` / `sky_z*.vtf`
- `skybox.7z`（3.8 MB）— `mr_night_*.vmt` / `mr_night_*.vtf`

配合 `luas/Visual/World/Skybox_fixed.lua` 或 `skybox_2.lua` 使用；解压到 CS 的 `csgo/materials/` 对应目录。

### ⚠️ 安全提示

**本仓库脚本均未经过完整代码审计**，以下两个脚本含**远程通信**行为，请自行评估风险后再使用：

| 文件 | 行为 | 风险 |
|---|---|---|
| `luas/Rage/Roll_Resolver.lua` | 代码混淆，硬编码 `http://43.138.209.94/login.php` 与 `ws://43.138.209.94:545`，并把 `gamesense/http`、`gamesense/websockets` 替换为只对该 IP 响应的实现 | **高** —— 疑似第三方植入的验证/回传逻辑，来源不明 |
| `luas/Rage/Adaptive_Weapon/+unfailer_weapon.lua` | 通过 `http.get` 从 `pastebin.com/raw/kRMqsN5S` 拉取内容判断是否运行 | **中** —— pastebin 内容可被发布者随时替换为任意代码 |

其余脚本只做静态检查，未发现网络请求；但**任何第三方 Lua 都应视为不可信**。建议在虚拟机 / 小号上先测试。

### 已知来源

以下脚本内嵌了明确的来源标注：

- **Pilot** — `Pilot_s_buybot.lua`（原作，控件名 `Pilot's buybot`、存档键 `pilotbuybot`）
- **s0daa/CSGO-HVH-LUAS**（**转载来源，非作者**）— `Fishesp_beta.lua`、`fog.lua`、`Chinese_Hat.lua`、`Player_Trails.lua` 的文件头均标注 `Downloaded from` 该仓库；原始作者未在文件中署名
- **skeet.cc / gamesense.pub 论坛** — `Thirdperson_Animations.lua`、`Panorama_Removal.lua`、`molotov_dormant.lua` 等
- **sapphyrus** — `helper.lua`（远程地图数据）、`Bloom.lua` 与 `Sound_volume_modifiers.lua` 的 API 生成脚本
- **Bassn (hitome56)** — `hud.lua`、`Custom_Font_Hitmarker.lua`
- **SamzSakerz** — `Soundboard.lua` 内嵌的 UI / FS 库
- **Exodouding** — `Thirdperson_Animations.lua`、`Panorama_Removal.lua`
- **havoc** — `offscreen_circle.lua` 的 vector / shader / menu 依赖
- **qhouz** — `Cascade_Light.lua`
- **3yozk1** — `Skybox_fixed.lua`
- **BaKa** — `Aimbot_log.lua`
- **Seripk** — `+Seripk_adaptive_weapon.lua`（原作）、`+Seripk_wpn_old.lua`、`Aimlog.lua` 的 `[Seripk] Aimbot log`
- **作者自研（zebrald，部分借助 Gemini AI）** — `Fastsetup.lua`、`Chicken_esp.lua`、`fakelag_on_while_double_tap_teleporting.lua`

> `+Seripk_adaptive_weapon.lua` 的原作者是 **Seripk**，zebrald 仅做修复与功能维护（文件头注明 `--fix and new features by zebrald`）。

### 声明

本仓库仅作**个人备份与归档**用途。所有转载脚本版权归原作者所有，如有侵犯请提 Issue 联系删除。**不提供任何担保**，使用风险自负。

---

## English

My personal collection of **gamesense (skeet.cc)** Lua scripts — partly written by me, partly collected from the community and archived by function.

> ⚠️ **Read [Security Notes](#-security-notes) before use.** Two scripts here contain hardcoded remote servers / remote code loading.

### Layout

```
My-luas/
├── luas/
│   ├── AntiAim/          Anti-aim / fakelag / slowwalk
│   ├── Misc/             Chat, sound, animation, buybot, helpers
│   ├── Rage/             Rage bot (Adaptive_Weapon, airstop, autopeek)
│   └── Visual/           ESP, Grenade, HUD+Menu, Hitmarker, Indicator,
│                         Keybinds, Log, Thirdperson, World
└── materials/            Skybox material packs (NOT Lua)
```

### Usage

Drop the `.lua` files into your gamesense scripts folder and load them from the `Scripts` menu. The in-game menu location for each script is listed in the Chinese table above (「菜单位置」column).

### ⚠️ Security Notes

**None of these scripts have been fully audited.** Two of them contain **remote communication**:

| File | Behavior | Risk |
|---|---|---|
| `luas/Rage/Roll_Resolver.lua` | Obfuscated; hardcodes `http://43.138.209.94/login.php` and `ws://43.138.209.94:545`, and replaces `gamesense/http` / `gamesense/websockets` with stubs that only respond to that IP | **High** — appears to be third-party injected auth/callback logic of unknown origin |
| `luas/Rage/Adaptive_Weapon/+unfailer_weapon.lua` | Uses `http.get` to fetch `pastebin.com/raw/kRMqsN5S` to decide whether to run | **Medium** — pastebin content can be swapped for arbitrary code at any time |

All other scripts passed static inspection with no network requests found — but **treat any third-party Lua as untrusted**. Test in a VM / on a throwaway account first.

### Credits

See the Chinese section above for the full list of embedded credits (Pilot, s0daa/CSGO-HVH-LUAS as a reupload source, the skeet.cc community, sapphyrus, Bassn, SamzSakerz, Exodouding, havoc, qhouz, 3yozk1, BaKa, Seripk, and zebrald's own scripts).

> Note: `s0daa/CSGO-HVH-LUAS` is where several files were **reuploaded from**, not necessarily their author. Where a file names its original author (e.g. `Pilot's buybot`), that author is credited separately.

> `+Seripk_adaptive_weapon.lua` was originally written by **Seripk**; zebrald only fixes and maintains it (the file header notes `--fix and new features by zebrald`).

### Disclaimer

This repository is for **personal backup and archival** only. All reposted scripts remain the property of their original authors — open an issue if you want something removed. **No warranty of any kind**; use at your own risk.

---

Contact:

- Bilibili: <https://space.bilibili.com/470048179>
- QQ: 2059326645
