// =============================================================================
// AdapterX2 - USB-C UART 调试转接板设计文档
// =============================================================================
// 文件编号: 31.01
// 版本: 1.0.0
// 日期: 2026-01-12
// =============================================================================

#import "template.typ": *

#show: project.with(
  title: [USB-C UART 调试转接板\ 设计文档],
  subtitle: [AdapterX2 Project],
  authors: (
    (name: "作者", affiliation: ""),
  ),
  date: datetime.today().display("[year]年[month]月[day]日"),
  version: "v1.0.0",
)

// -----------------------------------------------------------------------------
// 目录
// -----------------------------------------------------------------------------

#outline(
  title: [目录],
  indent: auto,
  depth: 3,
)

#pagebreak()

// =============================================================================
// 第一章：项目概述
// =============================================================================

= 项目概述 <ch:overview>

== 背景

在嵌入式开发和设备调试中，UART (Universal Asynchronous Receiver-Transmitter) 串口是最常用的调试接口之一。随着 USB Type-C 接口的普及，许多现代设备支持通过 USB-C 接口访问 UART 调试功能，这种技术被称为 *UART over USB*。

然而，不同厂商对 UART over USB 的实现方式存在显著差异，导致无法使用通用的调试线缆。本项目旨在设计两款专用的 USB-C 转 UART 调试转接板。

== 项目目标

本项目将设计并实现两款独立的 USB-C UART 调试转接板：

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: (center, left, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*项目代号*], [*目标平台*], [*关键特性*],
    [Project-S], [Samsung Galaxy S9 系列], [1.8V 电平，MUIC 激活],
    [Project-R], [Rockchip / PineNote 系列], [3.3V 电平，标准 DAM],
  ),
  caption: [两款转接板设计目标],
) <tab:targets>

#warning-box[
  *安全警告*：这两款转接板#underline[绝对不可互换使用]！
  
  - 使用 3.3V 转接板连接 Samsung 设备 → *立即烧毁主板*
  - 使用 1.8V 转接板连接 Rockchip 设备 → 信号无法识别
]

#pagebreak()

// =============================================================================
// 第二章：技术分析
// =============================================================================

= 技术分析 <ch:analysis>

== 行业现状

并没有一个强制统一的 Android "UART over USB" 规范。虽然 USB Type-C 标准定义了 Debug Accessory Mode (DAM)，但各厂商的实现极其混乱。

== 方案对比

#figure(
  table(
    columns: (1.2fr, 2fr, 2fr, 2fr),
    align: (left, left, left, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else if calc.odd(y) { luma(250) } else { none },
    
    [*特性*], [*Samsung (S9)*], [*Rockchip (PineNote)*], [*差异分析*],
    
    [激活方式], 
    [专有电阻 ID 检测\ B12 引脚对地 619KΩ], 
    [USB-C DAM 标准\ CC1/CC2 上拉激活], 
    [完全不同的激活机制],
    
    [信号引脚], 
    [D+ / D- (USB 2.0)\ A6=Rx, A7=Tx], 
    [SBU1 / SBU2\ A8=Tx, B8=Rx], 
    [物理引脚不同],
    
    [逻辑电压], 
    [#text(fill: red, weight: "bold")[1.8V]], 
    [#text(fill: blue, weight: "bold")[3.3V]], 
    [#text(fill: red)[*致命差异*]],
    
    [波特率], 
    [115200 / 921600], 
    [1,500,000], 
    [软件可配置],
    
    [USB 透传], 
    [❌ 不可能], 
    [✅ 可以], 
    [架构差异],
  ),
  caption: [Samsung vs Rockchip UART 方案对比],
) <tab:comparison>

== 工作原理

=== Samsung 方案 - MUIC 机制

Samsung 使用专用的 *MUIC (Micro USB Interface Controller)* 芯片（如 `max77705`）。

#info-box[
  *MUIC 工作流程*：
  + 检测 ID 引脚（B12）的电阻值
  + 识别到特定阻值（619kΩ = "JIG UART" 模式）
  + 物理切断 D+/D- 与 USB 控制器的连接
  + 将 D+/D- 重新路由到 CPU 的 UART 模块
]

=== Rockchip 方案 - 标准 DAM

Rockchip 遵循 USB Type-C 标准定义的 *Debug Accessory Mode (DAM)*。

#info-box[
  *DAM 工作流程*：
  + 检测 CC1/CC2 引脚被上拉（通过 1kΩ 电阻到 3.3V）
  + USB 控制器识别为 Debug Accessory 模式
  + SBU1/SBU2 引脚直通到 SoC 的 UART 模块
  + D+/D- 保持正常 USB 功能（可透传）
]

#pagebreak()

// =============================================================================
// 第三章：硬件设计 - Project-S (Samsung)
// =============================================================================

= Project-S: Samsung 专用转接板 <ch:project-s>

== 设计约束

#warning-box[
  *关键约束*：此转接板不能做成数据透传（Data Passthrough）。
  
  因为三星的 MUIC 机制会把 USB 的 D+/D- 引脚切换成 UART。如果把这个板子的另一头插到电脑 USB 口，电脑会送出 5V 的 USB 信号，直接撞上手机的 1.8V UART 信号，必定炸机。
  
  右侧 Type-C 母座只能用于充电（仅连接 VBUS 和 GND）。
]

== 接口定义

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (center, center, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*接口*], [*类型*], [*用途*],
    [J1], [USB-C 公头], [连接手机端],
    [J2], [USB-C 母座], [连接充电器（仅供电）],
    [J3], [2.54mm 排针], [连接 USB 转 TTL 工具],
  ),
  caption: [Project-S 接口定义],
) <tab:project-s-interfaces>

== 核心芯片规格

=== U2: XC6206P182MR (1.8V LDO 稳压器)

由于 S9 的 MUIC 机制不通过接口输出 1.8V，需要 XC6206 将 VBUS 的 5V 转换为 1.8V。

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: (left, left, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*参数*], [*值*], [*说明*],
    [型号], [XC6206P182MR], [Torex 低功耗 LDO],
    [输出电压], [1.8V ±2%], [固定输出],
    [最大输出电流], [200mA], [UART 仅需 µA 级],
    [压差], [250mV \@ 100mA], [],
    [静态电流], [1µA (typ)], [极低功耗],
    [封装], [SOT-23-3], [3 引脚],
  ),
  caption: [XC6206 规格参数],
)

*引脚定义 (SOT-23-3):*

#figure(
  table(
    columns: (auto, auto, auto, 1fr),
    align: (center, center, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*引脚号*], [*名称*], [*网络名*], [*连接*],
    [1], [VSS], [`GND`], [公共地],
    [2], [VOUT], [`VCC_1V8`], [输出 1.8V → TXS0108E.VCCA],
    [3], [VIN], [`VBUS_5V`], [输入 5V ← USB-C VBUS],
  ),
  caption: [XC6206 引脚定义],
)

*外围电路要求:*

- *C1 (输入电容)*: 1µF，连接 `VBUS_5V` ↔ `GND`，靠近 VIN 引脚
- *C2 (输出电容)*: 1µF，连接 `VCC_1V8` ↔ `GND`，*必须*，用于相位补偿

=== U1: TXS0108E (8 路双向电平转换器)

该芯片将手机端的 1.8V UART 信号转换为调试器的 3.3V 信号。

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: (left, left, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*参数*], [*值*], [*说明*],
    [型号], [TXS0108E], [TI 双向电平转换器],
    [通道数], [8 路], [本设计仅用 2 路],
    [VCCA 范围], [1.2V ~ 3.6V], [低压侧],
    [VCCB 范围], [1.65V ~ 5.5V], [高压侧],
    [内部上拉], [约 40kΩ], [无需外加],
    [封装], [TSSOP-20], [20 引脚],
  ),
  caption: [TXS0108E 规格参数],
)

*引脚定义 (TSSOP-20):*

#figure(
  table(
    columns: (auto, auto, auto, 1.5fr),
    align: (center, center, center, left),
    stroke: 0.5pt + gray,
    inset: 5pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*引脚*], [*名称*], [*网络名*], [*连接*],
    [1], [VCCA], [`VCC_1V8`], [低压侧电源 1.8V ← XC6206],
    [2], [A1], [`PHONE_RX`], [手机 RX ← USB-C A6 (D+)],
    [3], [A2], [`PHONE_TX`], [手机 TX ← USB-C A7 (D-)],
    [4-9], [A3-A8], [—], [NC (不连接)],
    [10], [OE], [`OE_EN`], [使能引脚 ← 10kΩ 上拉至 VCC_1V8],
    [11], [GND], [`GND`], [公共地],
    [12-17], [B8-B3], [—], [NC (不连接)],
    [18], [B2], [`TTL_TX`], [调试器 TX → 排针],
    [19], [B1], [`TTL_RX`], [调试器 RX → 排针],
    [20], [VCCB], [`VCC_3V3`], [高压侧电源 3.3V ← 调试器],
  ),
  caption: [TXS0108E 引脚定义],
)

*外围电路要求:*

- *C3 (VCCA 去耦)*: 100nF，连接 `VCC_1V8` ↔ `GND`
- *C4 (VCCB 去耦)*: 100nF，连接 `VCC_3V3` ↔ `GND`
- *R2 (OE 上拉)*: 10kΩ，连接 `OE_EN` → `VCC_1V8`

#warning-box[
  *关键设计约束:*
  - 必须满足 *VCCA ≤ VCCB* (1.8V < 3.3V ✓)
  - OE 引脚 *绝对不能悬空*，否则输出状态不确定
  - 内部已集成 40kΩ 上拉，UART 信号线 *不需要* 外加上拉电阻
]

== MUIC 激活电路

```
Pin B12 (手机端) ----[R1: 619kΩ ±1%]---- GND
```

作用：告诉手机"我是 UART 线，请切断 USB，开启串口"。

#info-box[
  *电阻精度要求:* R1 必须使用 *±1%* 精度的电阻。普通 ±5% 电阻可能导致 MUIC 无法识别。
]

== 完整网络命名表 (Netlist)

=== 电源网络

#figure(
  table(
    columns: (auto, auto, 2fr),
    align: (left, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*网络名*], [*电压*], [*连接节点*],
    [`VBUS_5V`], [5V], [USB-C VBUS (A4/A9/B4/B9), U2.VIN, C1, J2 透传],
    [`VCC_1V8`], [1.8V], [U2.VOUT, C2, U1.VCCA, C3, R2],
    [`VCC_3V3`], [3.3V], [J3.VCC, U1.VCCB, C4],
    [`GND`], [0V], [所有芯片 GND, 所有电容负极, USB-C GND, J3.GND],
  ),
  caption: [电源网络定义],
)

=== 信号网络

#figure(
  table(
    columns: (auto, auto, auto, 1.5fr),
    align: (left, center, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*网络名*], [*电压域*], [*方向*], [*连接节点*],
    [`PHONE_RX`], [1.8V], [手机 ← 调试器], [USB-C A6 (D+), U1.A1],
    [`PHONE_TX`], [1.8V], [手机 → 调试器], [USB-C A7 (D-), U1.A2],
    [`TTL_RX`], [3.3V], [调试器 ← 手机], [U1.B1, J3.RX],
    [`TTL_TX`], [3.3V], [调试器 → 手机], [U1.B2, J3.TX],
    [`OE_EN`], [1.8V], [—], [U1.OE, R2],
    [`MUIC_JIG`], [—], [—], [USB-C B12, R1],
  ),
  caption: [信号网络定义],
)

== 完整 BOM 清单

#figure(
  table(
    columns: (auto, 1.2fr, auto, 1fr, 1fr),
    align: (center, left, center, left, left),
    stroke: 0.5pt + gray,
    inset: 5pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*编号*], [*描述*], [*数量*], [*封装/规格*], [*网络*],
    [J1], [USB Type-C 公头], [1], [24P 全功能], [多个],
    [J2], [USB Type-C 母座], [1], [24P 全功能], [VBUS_5V, GND],
    [J3], [2.54mm 排针], [1], [1×4P], [VCC_3V3, TTL_TX, TTL_RX, GND],
    [U1], [TXS0108E], [1], [TSSOP-20], [多个],
    [U2], [XC6206P182MR], [1], [SOT-23-3], [VBUS_5V, VCC_1V8, GND],
    [R1], [619kΩ ±1%], [1], [0603], [MUIC_JIG, GND],
    [R2], [10kΩ], [1], [0603], [OE_EN, VCC_1V8],
    [C1], [1µF (输入)], [1], [0603 X5R], [VBUS_5V, GND],
    [C2], [1µF (输出)], [1], [0603 X5R], [VCC_1V8, GND],
    [C3], [100nF (VCCA)], [1], [0603], [VCC_1V8, GND],
    [C4], [100nF (VCCB)], [1], [0603], [VCC_3V3, GND],
  ),
  caption: [Project-S 完整 BOM 清单],
) <tab:project-s-bom>

== 安全检查清单

#figure(
  table(
    columns: (auto, 2fr, 1fr),
    align: (center, left, center),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*序号*], [*检查项*], [*预期值*],
    [1], [U2 输出电压 (VCC_1V8 网络)], [1.8V ±2%],
    [2], [U1 OE 引脚电压 (OE_EN 网络)], [≈ 1.8V],
    [3], [VCCA < VCCB 条件], [1.8V < 3.3V ✓],
    [4], [所有 GND 连通 (万用表蜂鸣档)], [导通],
    [5], [R1 阻值 (619kΩ ±1%)], [613kΩ ~ 625kΩ],
    [6], [J3 排针 VCC 电压], [3.3V (非 5V!)],
  ),
  caption: [调试前安全检查清单],
)

#pagebreak()

// =============================================================================
// 第四章：硬件设计 - Project-R (Rockchip)
// =============================================================================

= Project-R: Rockchip 专用转接板 <ch:project-r>

== 设计约束

与 Samsung 方案不同，Rockchip 方案可以实现完美的 *数据透传 (Data Passthrough)*。

#info-box[
  *优势*：你可以一边通过 USB 连电脑传文件/ADB，一边通过 UART 看日志。
]

== 接口定义

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (center, center, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*接口*], [*类型*], [*用途*],
    [J1], [USB-C 公头], [连接设备端],
    [J2], [USB-C 母座], [连接电脑（USB 透传）],
    [J3], [2.54mm 排针], [连接 USB 转 TTL 工具],
    [SW1], [拨动开关], [DAM 模式使能],
  ),
  caption: [Project-R 接口定义],
) <tab:project-r-interfaces>

== 核心电路

=== DAM 激活电路

```
    3.3V
     |
    [1kΩ]----+---- CC1 (Pin A5)
             |
    [1kΩ]----+---- CC2 (Pin B5)
     |
  [SW1] (可选开关，用于禁用 DAM 模式)
     |
    GND
```

注意：如果把 CC 强行上拉，可能破坏原有的 PD 协议握手。建议加一个开关来断开那两个 1k 电阻，这样平时可以当普通延长线用。

== 信号连接表

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    align: (center, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*设备端引脚*], [*调试端/透传*], [*说明*],
    [A8 (SBU1)], [TX (TTL)], [设备发送，调试器接收],
    [B8 (SBU2)], [RX (TTL)], [调试器发送，设备接收],
    [A5 (CC1)], [1kΩ 上拉至 3.3V], [DAM 激活],
    [B5 (CC2)], [1kΩ 上拉至 3.3V], [DAM 激活],
    [D+/D-], [直通至 J2], [USB 数据透传],
    [VBUS/GND], [直通至 J2], [供电透传],
  ),
  caption: [Project-R 信号连接表],
) <tab:project-r-signals>

== BOM 清单

#figure(
  table(
    columns: (auto, 1fr, auto, 1fr),
    align: (center, left, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*编号*], [*描述*], [*数量*], [*封装/规格*],
    [J1], [USB Type-C 公头], [1], [24P 全功能],
    [J2], [USB Type-C 母座], [1], [24P 全功能],
    [J3], [2.54mm 排针], [1], [1×3P (TX, RX, GND)],
    [R1, R2], [电阻 1kΩ], [2], [0603, ±5%],
    [SW1], [拨动开关], [1], [SPST],
  ),
  caption: [Project-R BOM 清单],
) <tab:project-r-bom>

#info-box[
  *注意*：SBU 引脚的定义可能会根据线缆正反插变化。如果发现没信号，把转接板翻个面插设备试试。
]

#pagebreak()

// =============================================================================
// 第五章：使用指南
// =============================================================================

= 使用指南 <ch:usage>

== 通用软件设置

推荐使用 `minicom` 作为串口终端工具：

```bash
# 识别 USB-UART 适配器
ls /dev/ttyUSB*

# 添加用户到 dialout 组
sudo usermod -aG dialout $USER

# 连接 (根据方案选择波特率)
minicom -D /dev/ttyUSB0 -b <波特率>
```

== Project-S 使用步骤

#figure(
  table(
    columns: (auto, 1fr),
    align: (center, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*步骤*], [*操作*],
    [1], [将 USB 转 TTL 工具连接到 J3 排针],
    [2], [将 J1 (公头) 插入 Samsung 手机],
    [3], [如需充电，将充电器通过线缆连接到 J2],
    [4], [运行 `minicom -D /dev/ttyUSB0 -b 115200`],
    [5], [重启手机，观察串口输出],
  ),
  caption: [Project-S 使用步骤],
)

== Project-R 使用步骤

#figure(
  table(
    columns: (auto, 1fr),
    align: (center, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*步骤*], [*操作*],
    [1], [确保 SW1 开关处于"DAM 使能"位置],
    [2], [将 USB 转 TTL 工具连接到 J3 排针],
    [3], [将 J1 (公头) 插入 PineNote 设备],
    [4], [如需 USB 连接，将电脑 USB 线连接到 J2],
    [5], [运行 `minicom -D /dev/ttyUSB0 -b 1500000`],
    [6], [重启设备，观察串口输出],
  ),
  caption: [Project-R 使用步骤],
)

#pagebreak()

// =============================================================================
// 附录
// =============================================================================

= 附录 <ch:appendix>

== USB Type-C 引脚参考

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (center, center, left),
    stroke: 0.5pt + gray,
    inset: 6pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*引脚*], [*名称*], [*功能*],
    [A1, B1], [GND], [接地],
    [A4, A9, B4, B9], [VBUS], [电源 (5V/20V)],
    [A5], [CC1], [配置通道 1],
    [B5], [CC2], [配置通道 2],
    [A6], [D+], [USB 2.0 差分信号 +],
    [A7], [D-], [USB 2.0 差分信号 -],
    [A8], [SBU1], [辅助信号 1],
    [B8], [SBU2], [辅助信号 2],
    [A12, B12], [GND], [接地],
  ),
  caption: [USB Type-C 关键引脚定义],
) <tab:usbc-pinout>

== 参考资料

+ Samsung MUIC 驱动源码: `max77705-muic.c`
+ PineNote UART 文档: https://wiki.pine64.org/wiki/PineNote
+ USB Type-C 规范: USB Type-C Specification Rev. 2.0

== 修订历史

#figure(
  table(
    columns: (auto, auto, 1fr),
    align: (center, center, left),
    stroke: 0.5pt + gray,
    inset: 8pt,
    fill: (x, y) => if y == 0 { luma(240) } else { none },
    
    [*版本*], [*日期*], [*变更说明*],
    [1.0.0], [2026-01-12], [初始版本],
  ),
  caption: [文档修订历史],
)
