# fengpt-pet.sh 使用文档

## 目录结构

```
/usr/local/apps/fengpt-pet/
├── fengpt-pet.sh          (部署脚本)
├── repo/                  (Git 代码仓库)
│   ├── .git/
│   ├── pom.xml
│   ├── src/
│   └── target/
│       └── fengpt-pet.jar
└── logs/                  (日志目录)
    ├── fengpt-pet/
    │   └── v1/
    │       └── fengpt-pet.log
    ├── back/              (备份日志)
    └── log/
```

## 配置说明

脚本顶部可配置的参数：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| APP_NAME | fengpt-pet | 应用名称 |
| GIT_REPO | https://gitee.com/fengpt/fengpt-pet.git | Git 仓库地址 |
| GIT_BRANCH | master | Git 分支 |
| WORK_DIR | /usr/local/apps/fengpt-pet | 工作目录 |
| PORT | 8080 | 服务端口 |
| SPRING_PROFILES_ACTIVE | dev | Spring 环境 |

---

## 快速开始

### 1. 首次部署
```bash
# 给脚本添加执行权限
chmod +x fengpt-pet.sh

# 完整部署（拉取代码 + 构建 + 启动）
./fengpt-pet.sh deploy
```

### 2. 查看帮助
```bash
./fengpt-pet.sh
```

---

## 部署命令

| 命令 | 说明 |
|------|------|
| `deploy` | 完整部署：拉取代码 → 构建 → 停止 → 启动 |
| `pull` | 仅拉取最新代码 |
| `build` | 拉取代码并执行 Maven 构建 |
| `start` | 启动服务 |
| `stop` | 停止服务 |
| `restart` | 重启服务 |
| `status` | 查看服务状态 |

### 部署命令示例

```bash
# 完整部署
./fengpt-pet.sh deploy

# 仅拉取代码
./fengpt-pet.sh pull

# 仅构建
./fengpt-pet.sh build

# 启动服务
./fengpt-pet.sh start

# 停止服务
./fengpt-pet.sh stop

# 重启服务
./fengpt-pet.sh restart

# 查看状态
./fengpt-pet.sh status
```

---

## 日志查询命令

### 当前日志（仅搜索当前日志文件）

| 命令 | 说明 |
|------|------|
| `log` | 实时查看日志 |
| `grep <关键词> [行数]` | 按关键词搜索日志 |
| `time <开始> [结束]` | 按时间范围筛选日志 |
| `search <时间> <关键词> [行数]` | 时间+关键词组合搜索 |
| `stats` | 查看日志统计信息 |

### 当前日志示例

```bash
# 实时查看日志
./fengpt-pet.sh log

# 搜索 ERROR（最近100行）
./fengpt-pet.sh grep ERROR 100

# 按时间范围筛选
./fengpt-pet.sh time '10:00' '12:00'

# 时间+关键词搜索
./fengpt-pet.sh search '14:30' 'Exception' 300

# 查看日志统计
./fengpt-pet.sh stats
```

---

## 所有日志（含备份）

**注意：** 以 `b` 开头的命令会搜索所有日志文件，包括备份日志。

| 命令 | 说明 |
|------|------|
| `listlogs` | 列出所有日志文件 |
| `bgrep <关键词> [行数]` | 在所有日志中按关键词搜索 |
| `btime <开始> [结束]` | 在所有日志中按时间范围搜索 |
| `bsearch <时间> <关键词> [行数]` | 所有日志时间+关键词搜索 |
| `bstats` | 查看所有日志统计信息 |
| `bfullsearch <开始> <结束> <关键词>` | 开始时间+结束时间+关键词搜索（显示前后20行） |

### 所有日志示例

```bash
# 列出所有日志文件
./fengpt-pet.sh listlogs

# 在所有日志中搜索 ERROR
./fengpt-pet.sh bgrep ERROR 100

# 在所有日志中按时间范围搜索
./fengpt-pet.sh btime '09:00' '18:00'

# 在所有日志中时间+关键词搜索
./fengpt-pet.sh bsearch '09:00' 'Exception' 500

# 查看所有日志统计
./fengpt-pet.sh bstats

# 完整搜索：时间范围 + 关键词 + 前后20行
./fengpt-pet.sh bfullsearch '2026-04-04' '2026-04-05' 'test'
```

---

## 时间格式说明

日志时间格式：`2026-04-04 15:14:12.811`

支持的时间匹配方式：

| 格式 | 示例 | 说明 |
|------|------|------|
| 完整日期时间 | `'2026-04-04 15:14'` | 精确匹配日期和时间 |
| 仅时间 | `'15:14'` | 匹配任意日期的该时间 |
| 仅日期 | `'2026-04-04'` | 匹配该日期的所有日志 |

---

## bfullsearch 详解

**功能：** 在所有日志文件中搜索指定时间范围内的关键词，并显示匹配行前后各20行。

**语法：**
```bash
./fengpt-pet.sh bfullsearch <开始时间> <结束时间> <关键词>
```

**示例：**
```bash
# 按日期范围搜索
./fengpt-pet.sh bfullsearch '2026-04-02' '2026-04-05' 'test'

# 按时间范围搜索
./fengpt-pet.sh bfullsearch '09:00' '18:00' 'ERROR'

# 精确时间搜索
./fengpt-pet.sh bfullsearch '2026-04-04 09:00' '2026-04-04 18:00' 'Exception'
```

**工作原理：**
1. 找到所有包含关键词的行
2. 检查这些行是否在指定时间范围内
3. 输出匹配行及其前后各20行上下文

---

## 常见问题

### Q: 如何修改服务端口？
A: 编辑脚本，修改 `PORT` 变量的值。

### Q: 如何切换 Git 分支？
A: 编辑脚本，修改 `GIT_BRANCH` 变量的值。

### Q: 日志文件在哪里？
A: 运行 `./fengpt-pet.sh listlogs` 查看所有日志文件位置。

### Q: bfullsearch 搜索不到结果？
A: 
1. 先确认关键词是否正确（不区分大小写）
2. 尝试放宽时间范围
3. 先用 `bgrep` 确认关键词能搜到

### Q: 如何查看实时日志？
A: 运行 `./fengpt-pet.sh log`，按 `Ctrl+C` 退出。

---

## 命令速查表

| 场景 | 命令 |
|------|------|
| 首次部署 | `./fengpt-pet.sh deploy` |
| 更新代码并重启 | `./fengpt-pet.sh deploy` |
| 查看服务状态 | `./fengpt-pet.sh status` |
| 实时看日志 | `./fengpt-pet.sh log` |
| 搜索错误 | `./fengpt-pet.sh bgrep ERROR` |
| 查某时段日志 | `./fengpt-pet.sh btime '09:00' '12:00'` |
| 完整搜索（含上下文） | `./fengpt-pet.sh bfullsearch '2026-04-04' '2026-04-05' 'test'` |
