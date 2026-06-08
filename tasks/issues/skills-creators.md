# Issues For Skill Usage

## Task 1:  Skill收集使用评估方案

1. 需要如何收集使用评估Skill的一个完整方案
2. 目前两个路径进行：
     -  本地AI Agent自己的调用和评估效果，记录过程
     - 进行Skill 管理的开发和实现本地评估的效果
3. 如何评估Skill的使用：
   - 从一个问题出发，进行结果这个问题的Skill收集
   - 使用Skill评估这个问题的Skill使用效果
   - 修改收集的Skill进行评估，查看效果是否有提升
4. 一个实际的例子如下：
     - 问题： 如何自动化本地开发的Github流程
     - 常见使用过程:
        -  本地编写一份任务
        - 使用AI Agent执行这个任务，任务开始提交Issue，如何任务通过测试关闭Issue，提交代码到Github
        - 需要一份Github和Local管理本地开发变更的Skill
    现在要解决的问题是，如何一整套流程解决这个实际问题，达到比较好的效果, 先手工运行到系统运行，请做分析和可行性评估，同时列出可能已经存在的问题和解决方案Top 20的github 资源和文章，写入到docs/reasearch目录下skill-mgr目录下

## Task 2: 测试Git Workflow/Local Workflow

1. 测试Git Workflow/Local Workflow的使用效果，是否可以再project和system level都起作用
2. 安装/删除都可以，同时按照最新的安装删除更新脚本，同时支持windows/mac/llinux/windows wsl2 系统，脚本统一放到scripts目录中，然后清理当前的scripts目录脚本如果有的话

## Task 3:   更新clean-skill脚本

1. 修改clean-skills.sh 脚本，使用skill-spark 进行skills的清理
2. 使用clean-skills.sh 脚本清理支持windows/mac/llinux/windows wsl2 系统的skills
3. 支持全部清除skill，包括所有skills的目录，也包括制定目录，或者制定的skill，假设base目录有两个skills，是否安装的时候也是完全一样的目录结构，如果不是一样的目录结构需要确认如何清理

## Task 4: 请确认base/devop skills 在claude code下面可以全局和项目级别生效

1. 请确认base/devops skills 在claude code下面可以全局和项目级别生效
2.. 可以先删除一下项目级别的.claude目录，然后测试全局和项目级别skill生效情况