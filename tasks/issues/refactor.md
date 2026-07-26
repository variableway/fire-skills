# Refactor

- 当前这个项目会作为一个完整的Skill仓库，用来保存个人使用的仓库
- 这个项目后构建一个管理Skill使用的应用，Web版本和Desktop Application版本
- 当前项目的Skill会主要包括不同的话题，这些话题可能会有通用性的，有些是用来作为开发使用，使用这是开发相关的人员，有些就是没有开发经验的人来处理
  所以需要做一些分类，当前最初的想法就是类似有一个registry的机制，可以把不同categories的skills注册，然后后续给应用统一管理
- 这是一个庞大的工程，主要解决的问题就是Skill一定是通过筛选的，Skill管理筛选本身就包括了：
  - Sesarch
  - 安装
  - 评估
  - 使用和优化，再评估
- 完成这个项目期望是使用多个AI Agent进行同时操作，因此拆分任务的时候，任务文档一定要考虑是给不同的AI Agent使用，哪些是分享的Context，任务一定要是独立的，并且是有依赖关系的(如果有)
- 如何记录哪个Agent再运行哪个任务似乎也是挺关键的一个事情

## Task 1： 计划和可行性分析

1. 先计划这个项目当前使用什么样的文档结构，和技术架构，已经目前已经实现了哪些
2. 指定具体的MVP版本的任务，先可以手工运行，然后再进行工具化和程序化
3. 这部分计划写入到docs目录projects

### Status: done (2026-07-13)

产出：

- `docs/projects/architecture-and-mvp.md` — 文档结构、技术架构、已实现盘点、MVP-0~3 任务拆分
- `docs/projects/README.md` / `docs/README.md` — 文档索引
- 根 `README.md`、`docs/skill-spark/*` 已与当前 CLI 目录结构对齐

下一步建议：MVP-1（Category Registry：M1.1 → M1.3）


## Refactor Commands

skill-cli commands 有很多，需要对这些commands 做一个refactor：
1. 对每个command 都添加一个description
2. 对每个command 都添加一个example
3. 对每个command 都添加一个prerequisite
4. 提取通用的Model/types出来，如果命令是在同一个commands下面放一个目录，如果不是需要放到另外一个目录下去
5. 目前Skill肯定是一个，其他commands 需要做一个完整的检查，然后确认是否需要放到同一个目录下面

## Task 2: Simplify Add Command
pnpm build   如何把spark-skill 安装到system 里面去呢，同时参数add参数过多了，安装都适用复制方式吧，不去做--no-symlink这种参数了，现有仓库都是使用git管理了，版本问题都问题不大，scope 就是系统和项目就可以，其他不用--slient了，就是都把安装过程全部展示，唯一可能要做的就是是否覆盖这个，有一个提示吧，默认是有提示的，加一个参数强制就可以，请检查当前add 命令参数

## Task 3: Simplfy  commands

1. 去除outdated command，这个不需要这个命令
2. update实际也不需要，因为add可以强制覆盖，似乎也不需要这个
3. use这个命令也不需要，请移除
4. profile这个命令但是也不需要，请移除

## Task 4:  请更新所有的cli的文档

1. 请更新cli文档，一个命令一个文档，都是docs/cli目录中