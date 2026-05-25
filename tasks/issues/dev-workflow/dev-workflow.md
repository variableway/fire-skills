#  Dev-Workflow 

- review 当前目录的SKILL，用来方便后续的可组合性尝试
- review过程中需要生成一些skill的tag，role这样的后续的组合

## Task 1: Github Workflow/Local Workflow 

1. GITHUB Workflow 测试安装到本项目确认可以生效
2. GITHUB Workflow 测试安装到Codex/Opencode项目确认可以生效
3. Local Workflow也一样，确认可以生效
4. 测试方法和结论写入到文档docs validation 目录
5. 确认Trae/Trae Solo 也支持这个skill，同时分析当前SKILL的缺点是什么，目前看是GITHUB ISSUE会会有Comment，显得不太完整

## Task 2: 检查是否有可能在常见Issue之后把完整改动内容放到comment 2里面

1. 当前create issue 最后close issue，close issue的时候是否可以把这个任务完整内容放到github comment里面
2. 确认这个是否已经成可行的了
3. 创建按照当前github/local 相关的脚本，脚本名称是dev-workflow-install.sh 这样支持Mac/Windows/Linux

## Task 3: Please Test Create Release Skill

1. 测试github release skill是否可以
2. 如果成功添加gh skill和github release 到dev-workflow-install.sh中去，已经对应的其他操作系统的安装脚本
3. 提出一个方案，如何给这几个skill 打上标签，实在formatter header 数据里面吗？确认这种方法是可以的，如果可以安装脚本是否可以
变成扫描skill 目录，找到输入的tag值就可以安装所有的这个Tag的skilli

## Task 4: move install script into root level

1. 为了方便安装skill，把skill安装by tag的脚本放到的根目录
 
## Task 5: 测试安装的Trae/Trae Solo的Skill

1. 测试安装的skill在Trae/Trae Solo下可以使用
2. 测试workbuddy也可以使用这些skill

## Task 6: 请更新所有的文档

1. 请更新当前项目的docs文件
2. 同时检查github pages 工作正常

## Task 7: Please Refine the analysis skills

1. 把[分析](../../../analysis) skill都标准化，遵照Agent Skill的规范

## Task 8: 按照github workflow给Trae/Trae Solo 

1. 安装dev-workflow 相关的SKILL给Trae和Trae Solo
2. 对这些SKill进行测试，确认生效
