# pcc_cangjie

一个基于仓颉语言实现的部分约束检查系统。

项目从事件上下文流中读取数据，依据 `patterns.xml` 与 `constraints.xml` 构造检查逻辑，并使用不同检查方法（ECC/PCC）对约束进行验证。当前支持两种运行模式：

- 在线模式：按时间间隔注入上下文并在新鲜度窗口内自动过期
- 离线模式：按时间线批量回放上下文的新增/删除事件，不依赖实时定时器

## 主要功能

- 从数据目录加载三类输入文件：`contexts.txt`、`patterns.xml`、`constraints.xml`
- 支持约束公式解析（`forall`、`exists`、`and`、`or`、`implies`、`not`、`bfunc`）
- 支持公式转换策略：`kernel`、`notleaf`、`none`，分别代表核心转换（仅含`forall`, `and`, `not`, `bfunc`），非叶子节点转换（`not`节点仅出现在最底层，即只含`not(bfunc)`），以及不转换
- 支持检查方法：`ecc`、`pcc`
- 支持离线检测：通过 `--offline` 启用，支持自定义 `--context`、`--pattern`、`--constraint` 输入文件
- 支持通过 `freshness` 与 `interval` 控制时效窗口与事件注入节奏
- 支持自定义布尔函数（BFunc），当前示例为 `WithinTrans`

## 环境要求

- 仓颉编译工具链（`cjc`）
- `cjpm`
- `cjc` 版本建议：`1.0.5`（与 `cjpm.toml` 中配置一致）

## 快速开始

在项目根目录执行：

```bash
cjpm run --run-args "--data data/smoke --freshness 2"
```

这条命令会：

- 使用 `data/smoke` 作为输入数据目录
- 将 freshness 设置为 `2` 秒
- 其余参数使用默认值

离线模式示例（以你当前数据组织方式为例）：

```bash
cjpm run --run-args "--data data/data_with_link_oracles --context data/data_1/0-1.txt --pattern consistency_patterns_48.xml --constraint consistency_rules_48.xml --convert none --offline --outdir link_oracle/data_1 --outfile 0-1_answer_pcc.txt --method pcc"
```

说明：

- `--offline` 启用离线检测路径
- `--context`、`--pattern`、`--constraint` 都是相对于 `--data` 的路径
- 离线模式下会按上下文时间戳生成 Add/Delete 事件并排序后依次处理

## 命令行参数

程序入口支持以下参数（长选项）：

| 参数 | 是否必需 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `--data` | 是 | 无 | 数据目录路径，目录内需包含 `contexts.txt`、`patterns.xml`、`constraints.xml` |
| `--context` | 否 | `context.txt` | 离线模式下的上下文文件路径（相对于 `--data`） |
| `--pattern` | 否 | `patterns.xml` | 离线模式下的模式文件路径（相对于 `--data`） |
| `--constraint` | 否 | `constraints.xml` | 离线模式下的约束文件路径（相对于 `--data`） |
| `--convert` | 否 | `kernel` | 公式转换策略，可选：`kernel`、`notleaf`、`none` |
| `--method` | 否 | `ecc` | 检查方法，可选：`ecc`、`pcc` |
| `--freshness` | 否 | `20` | 上下文新鲜度窗口（秒） |
| `--outdir` | 否 | `log` | 日志输出目录 |
| `--outfile` | 否 | `context_check_{convert}_{method}_{freshness}_{interval}.log` | 输出文件名 |
| `--interval` | 否 | `400` | 上下文流注入间隔（毫秒） |
| `--start_time` | 否 | 第一条上下文的时间戳 | 模拟起始时间戳（Unix 时间戳，秒） |
| `--offline` | 否 | 不启用 | 启用离线检测模式（存在该参数即启用） |

完整示例：

```bash
cjpm run --run-args "--data data/smoke --convert kernel --method ecc --freshness 20 --interval 400 --outdir log"
```

Windows CMD 下可选 GC 相关环境变量（用于大数据离线回放时降低内存压力）：

```cmd
set cjRegionSize=2048kb
set cjHeapSize=15gb
```

## 输入数据格式

### 1) contexts.txt

每行一个上下文事件，字段以 `, ` 分隔：

```txt
category, subject, predicate, object, lifespan, site, timestamp
```

示例：

```txt
object movement, case5, reach, gate2, at 1181269200, warehouse4, 1181269200
object movement, case5, reach, dock3, at 1181269080, warehouse4, 1181269080
```

### 2) patterns.xml

- 根节点为 `<patterns>`
- 每个 `<pattern>` 需要 `name` 属性
- 子字段包括：`category`、`subject`、`predicate`、`object`、`lifespan`、`site`、`timestamp`
- 字段值为 `any` 或没有时，表示该字段通配

与上下文事件匹配时为精准匹配，要求字段值完全相同。

示例（节选）：

```xml
<patterns>
	<pattern name="REACH">
		<category>object movement</category>
		<subject>any</subject>
		<predicate>reach</predicate>
		<object>gate2</object>
		<lifespan>any</lifespan>
		<site>warehouse4</site>
		<timestamp>any</timestamp>
	</pattern>
</patterns>
```

### 3) constraints.xml

- 根节点为 `<constraints>`
- 每个 `<constraint>` 需要 `name` 属性
- 约束体支持：`forall`、`exists`、`and`、`or`、`implies`、`not`、`bfunc`
- `forall` 和 `exists` 需要 `var` 和 `in` 属性，表示变量名和所属模式，模式名需在 `patterns.xml` 中定义
- `bfunc` 使用 `name` 指定函数名，参数通过 `<param var="..." />` 指定

示例（节选）：

```xml
<constraints>
	<constraint name="transit">
		<forall var="reach" in="REACH">
			<not>
				<exists var="dock" in="DOCK">
					<bfunc name="WithinTrans">
						<param var="reach" />
						<param var="dock" />
					</bfunc>
				</exists>
			</not>
		</forall>
	</constraint>
</constraints>
```

## 自定义 BFunc

项目会从 `src/user/user_bfunc.cj` 中加载用户自定义布尔函数。

当前示例函数：

- `WithinTrans(ctx1, ctx2)`：判断两个上下文时间差是否在 5 分钟内

如果你在约束中使用新的 `bfunc name`，需要在该文件中实现同名静态函数，且参数个数一致。

## 输出说明

- 运行时会打印约束和匹配信息
- 日志文件输出到 `--outdir` 指定目录
- 若未传 `--outfile`，日志文件名格式为：

```txt
context_check_{convert}_{method}_{freshness}_{interval}.log
```

## 目录结构（核心部分）

```txt
src/
	main.cj                 # 程序入口与参数解析
	check/                  # 检查器实现（ECC/PCC、语法树、上下文集等）
	parse/                  # XML/时间解析
	defs/                   # 领域模型定义（Context/Pattern/Constraint 等）
	user/user_bfunc.cj      # 用户自定义布尔函数
    logger/                 # 日志工具
    timing/                 # 时间工具
    collection/             # 数据结构工具
data/
	smoke/                  # 示例数据集
log/                      # 默认日志目录
```

## 常见问题

### 1) 程序启动后报参数或文件错误

请确认：

- 已传入 `--data`
- 数据目录中同时存在 `contexts.txt`、`patterns.xml`、`constraints.xml`

### 2) 提示不支持的 convert 或 method

可用值如下：

- `convert`: `kernel` / `notleaf` / `none`
- `method`: `ecc` / `pcc`

### 3) BFunc 找不到或参数不匹配

检查 `constraints.xml` 中 `bfunc` 的名称和参数个数，是否与 `src/user/user_bfunc.cj` 中函数定义一致。
