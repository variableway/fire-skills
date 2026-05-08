# Dev Workflow Setup

## Task 1: Retest Skills after folder Structure change

1. Add create issue by file for github-cli-skill
2. Test github-cli-skill after folder structure change


## Task 2: Please create  an install script for github-cli-skill

please create a skill install script for github-cli-skill in both system level and project level,
support Mac,Linux,Windows.

Write the script into scripts/ folder


## Task 3: Create A workflow skill based on github-cli-skill

based on github-cli-skill, create a workflow skill for create issue by task input:
1. Input: task description
2. Output: issue created
3. after Agent execute the task with test, close this issue. 
4. Make sure, when close this issue, the whole message should update the first comment of the issue, original comments is the task description, after agent complete the task, then send the updated message to update the original comments, but not rewrite the comment, just append the updated message to the end of the original comment.
5. Create install script for both project and system level for different agents at least kimi,claude code,codex,opencode.
Write the script into scripts/ folder

The skill folder in dev/ folder, the skill name is git-workflow, and clean installed current github-workflow skill first.

## Task 4: create an skill to post issues by tasks input

1. Given a Markdown file, then create issues based on the tasks in the file.
2. Input: Markdown file, in this markdown file, a lot of tasks by start with `## Task <id>`
3. Output: issues created
4. please use golang script to complete it.

## Task 5:  Test git workflow skill
1. Test git workflow skill after folder structure change
2. Test git workflow skill after install script
3. Test git workflow skill after create issue by task input

确认git workflow 工作，并且在当前项目工作，是因为在全局起作用的，所以可能先需要删除当前目录的agent的，然后再测试。

## Task 6: Check work locally

1. I have create an cleanup script for cleanup global skill, it is already done.
2. please install github issue and git workflow skills in local project,then try to a task to trigger this skill for both kimi and claude code
3. then try to create issue by task input

## Task 7: merge github-task-workflow and git-workflow

1. please check github-task-workflow skill in local project
2. if the whole skill is same as git-worklfow, please remove github-task-workflow

## Task 8: Add Local Tracking
1. please add local tracking for git-workflow skill
2. and also check local tracking only skill works? 
3. After these two skills worked cleanup github-workflow-skill

local-workflow skill have moved into dev folder

## Task 9: Testing Create Github Relese Skill

1. check current skills，gh-create-release skill
2. if existing，please test it in this reo

## Task 10: 测试claude code 下面git workflow 和local workflow的工作情况

1. 测试claude code 下面git workflow 和local workflow的工作情况
2. 需要都work，不管是global还是project level，同时验证install.sh 文件的工作情况

## Task 11: update docs

1. 请分析着些skill的对应文档

## Task 12: update README

1. update README file
2. Update install script into README file