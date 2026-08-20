# Lancet Global Health 投稿终审清单（2026-08-14，程序化核查版）

> 状态标记：✅ 已合规并核验 / 🔧 已修复 / ⚠️ 待用户决策 / 📋 提交时执行

---

## 维度一 · 学术规范

| # | 位置 | 性质 | 方案 | 状态 |
|---|------|------|------|------|
| 1-1 | 三文件标题 | 格式 | 统一为 "Domestic Government Health Expenditure, Out-of-Pocket Spending, and Healthy Life Expectancy in 190 Countries, 2000–2022"（118字符；running title: GHE and HALE: 190-country panel） | ✅ 三文件逐字一致（本轮含空白容差核验） |
| 1-2 | 字体/字号/行距 | 格式 | 主文12pt Times New Roman、2.5cm页边距；补充10pt单倍距、12pt加粗标题、8pt表格 | ✅ |
| 1-3 | 页码编排 | 格式 | 主文fancyhdr页眉running title+页脚页码；补充article默认页脚页码 | ✅ |
| 1-4 | 章节编号 | 格式 | 全无编号（Lancet体例）；声明区块顺序 Contributors→Declaration→Acknowledgments→Data sharing→Funding→Ethics→References→Figures | ✅ 程序化验证 |
| 1-5 | 图表编号 | 格式 | 主文3表3图、补充19表+1长表+14图；标签严格S1–S16/S1–S14顺序；补充文献S1–S17连续 | ✅ |
| 1-6 | 参考文献30条 | 格式 | ≤30上限；Vancouver首现顺序1–30严格单调 | ✅ 程序化验证 |
| 1-7 | 引用真实性 | 诚信 | 主文30条历史多轮核验；补充S5–S14经PubMed esummary+CrossRef核验卷页；29篇纳入文献全带验证DOI | ✅ |
| 1-8 | 引用标注准确性 | 诚信 | HALE出处=GBD Burden capstone (406:1873–1922, DOI 01637-X)；8处数据库引用access date；无不当自引 | ✅ |
| 1-9 | 小数点 | 格式 | 中圆点全文统一，句点残留0 | ✅ |
| 1-10 | AI声明 | 合规 | 通用表述不点名工具（遵用户禁令），声明"no AI tool used for data generation or statistical analysis" | ✅ |
| 1-11 | AI痕迹 | 合规 | AI工具名残留0；审稿痕迹（"REVISED"/"(revised)"）已清零；"consistent with"≤3；em-dash≈7 | ✅ 本轮已复查并补落4处 |
| 1-12 | 缩写首次展开 | 格式 | TWFE/HALE/GHE/DiD/SDG/**MDG**(本轮补)/UHC/OOP/SCM/GBD 全部首次展开 | ✅ |
| 1-13 | 作者信息 | 规范 | CRediT缩写与署名一致（PC等）；通讯作者ORCID 0009-0001-0779-2245已写入 | ✅ |
| 1-14 | 字数声明 | 规范 | 标题页如实声明 Summary 280词 / Text ~3,335词 / References 30 | 🔧 已如实（修剪决策见5-1） |

## 维度二 · 核心内容

| # | 位置 | 性质 | 方案 | 状态 |
|---|------|------|------|------|
| 2-1 | Methods estimand | 逻辑 | 明确"adjusted within-country association…not a total causal effect" | ✅ |
| 2-2 | 样本流 | 数据 | 4,370(190×23)→4,314→4,304(189国)；Somalia零完整行说明；缺失率实测(OOP 0.2%/gov 4.8%/tax 36.0%) | ✅ |
| 2-3 | LIC推断 | 统计 | wild cluster bootstrap为主推断；Table 2双推断并列；方向稳健/显著性脆弱显式分离 | ✅ |
| 2-4 | 排除检验 | 统计 | one-sided exclusion术语统一；MDE post hoc表述；MDE vs CI上界逻辑澄清句 | ✅ |
| 2-5 | 中介 | 统计 | a×b bootstrap CI +0.02至+0.24（不含零）；关联性措辞；≈11%相对降幅三文件一致 | ✅ |
| 2-6 | 异质性 | 统计 | GHE×收入交互联合p=0.056（8/17复算）；人口加权TWFE β=−0.34 | ✅ |
| 2-7 | 事件研究 | 统计 | CSV真值(0.070/0.050/0.090)；stacked设计S8b；austerity t+5=+0.17(p=0.39)、spike t+5=−0.49(p=0.037)、no-COVID −0.54(p=0.094)；危机共变解释；事件研究规格ref=−5/窗口−4..−1（与代码一致） | ✅ |
| 2-8 | 时代分期 | 数据 | MDG 2000–2015 / SDG 2016–2022（2022截断）；LIC MDG +1.270(p=0.038)/SDG +0.030(p=0.928)（C3 CSV同步重跑） | ✅ |
| 2-9 | 文献证据 | 诚信 | 真实检索重建：PubMed 155→126排除→29纳入；全台账screening_records.csv；S14真实10篇带PMID | ✅ |
| 2-10 | 政策口径 | 逻辑 | GHE/GDP vs GHE/GGE解耦；"不直接检验Abuja达标"边界句 | ✅ |

## 维度三 · 写作表达

| # | 位置 | 性质 | 方案 | 状态 |
|---|------|------|------|------|
| 3-1 | Summary | 结构 | 280词；Background缺口→Methods协变量→Findings三层证据(CI齐全)→Interpretation审慎 | ✅ |
| 3-2 | 引言 | 叙事 | 三点缺口显化+三贡献+UHC/ODA时效段；开场去绝对化 | ✅ |
| 3-3 | 术语 | 统一 | healthy life expectancy / comparative standardised-coefficient model / one-sided exclusion / external health expenditure | ✅ |
| 3-4 | 因果措辞 | 分寸 | effect→association全扫；仅研究问题框架句保留improves | ✅ |
| 3-5 | 过渡 | 连贯 | §3.5/§3.8过渡句；Discussion三发现引导句 | ✅ |
| 3-6 | 图表解读 | 支撑 | Fig1–3 caption数值与CSV实测一致（r=−0.16/0.54/−0.05残差化标注）；Fig2含CI误差棒 | ✅ |
| 3-7 | 局限与展望 | 完整性 | 5类局限重组+未来研究3方向+2补充局限（收入分组时不变/领地排除） | ✅ |
| 3-8 | 图表规范 | 视觉 | Wong色盲调色板全切换；矢量PDF；≥8pt；S8橙白蓝分歧色 | ✅ |

## 维度四 · 补充文稿适配

| # | 位置 | 性质 | 方案 | 状态 |
|---|------|------|------|------|
| 4-1 | 主↔补充对应 | 关联 | 16表14图全部被正文引用零孤儿；目录分组Tables./Figures. | ✅ |
| 4-2 | 目录编排 | 可读性 | 首页支撑声明+编号索引；S9–S12注明"Figure 3放大版" | ✅ |
| 4-3 | 内容准确性 | 排查 | 检索策略真实化；S14真实10篇+PMID；S5–S14引用卷页核验 | ✅ |
| 4-4 | 篇幅形式 | 合规 | 单PDF+页码+10pt/单倍距/8pt表格；STROBE+GATHER清单随稿 | ✅ |
| 4-5 | 复现包 | 合规 | data/raw/README、session_info、screening台账、匿名核查(无作者信息) | ✅ |

## 维度五 · 提交前待办

| # | 事项 | 性质 | 方案 | 预期效果 |
|---|------|------|------|---------|
| 5-1 | **正文字数** | ✅ 已完成 | 5,310→**~3,335词**，标题页如实申报"~3,335 words"；Summary 280词；所有数值与R实跑一致 | 与指南~3,500对齐 |
| 5-2 | 公卫专家作者 | ⚠️ 待定 | 加入后更新三文件作者列表+CRediT+封面信多学科背景句 | 编辑对专业匹配度的疑虑 |
| 5-3 | 推荐审稿人 | 📋 | 名单已备：Tandon(WB)/Dieleman(IHME)/Moreno-Serra(York)/Barasa(KEMRI-WT)，备选Yip(Harvard)/Ataguba(UCT)；系统如要求3人用前三位 | 送审对口专家 |
| 5-4 | STROBE/GATHER页码 | ✅ | 2026-08-20已按定稿PDF填入（MM=26页/SA=21页实页码）；标题同步定稿版 | 报告规范完整 |
| 5-5 | 投稿包 | 📋 | 3 PDF + submission/（STROBE、GATHER、screening_records、投稿清单）打包 | 提交即用 |

---

**当前编译状态**：三份PDF零错误、零overfull（主文26页/补充21页/封面2页，2026-08-20终检）。
