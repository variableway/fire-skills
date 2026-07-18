# REFACTOR

## Refactor Commands

skill-cli commands 有很多，需要对这些commands 做一个refactor：
1. 对每个command 都添加一个description
2. 对每个command 都添加一个example
3. 对每个command 都添加一个prerequisite
4. 提取通用的Model/types出来，如果命令是在同一个commands下面放一个目录，如果不是需要放到另外一个目录下去
5. 目前Skill肯定是一个，其他commands 需要做一个完整的检查，然后确认是否需要放到同一个目录下面