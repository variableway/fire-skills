## GitHub CLI | Take GitHub to the command line

**Source**: https://cli.github.com/

---

# Take GitHub to the command line

GitHub CLI brings GitHub to your terminal. Free and open source.

`             brew install gh           `

or
[Download for Mac](https://github.com/cli/cli/releases/download/v2.93.0/gh_2.93.0_macOS_amd64.zip)

[Download for Windows](https://github.com/cli/cli/releases/download/v2.93.0/gh_2.93.0_windows_amd64.msi)

[Install for Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

[View installation instructions →](https://github.com/cli/cli#installation)

## 
$

gh copilot

gh issue list

gh pr status

gh pr checkout

gh pr create

gh pr checks

gh release create

gh repo view

gh alias set

Run GitHub Copilot CLI.

View and filter a repository's open issues.

Check on the status of your pull requests.

Check out pull requests locally.

Create a new pull request.

View your pull requests' checks.

Create a new release.

View repository READMEs.

Create a shortcut for a gh command.

$

gh copilot

```
╭────────────────────────────────────────────────────────────────────────╮
│ ╭─╮╭─╮  GitHub Copilot v1.0.39                                         │
│ ╰─╯╰─╯  Describe a task to get started.                                │
│ █ ▘▝ █                                                                 │
│  ▔▔▔▔                                                                  │
│                                                                        │
│ Tip: /init Initialize Copilot instructions for this repository.        │
│ Copilot uses AI. Check for mistakes.                                   │
╰────────────────────────────────────────────────────────────────────────╯
```

●

Environment loaded: 2 custom instructions, 19 skills, 6 MCP servers, 4 plugins, 3 agents

●

GitHub MCP Server: Connected

gh issue list

**Showing 4 of 4 issues in cli/cli**

#16

Improving interactions with protected branches

#14

PR commands on a detached head

#13

Support for GitHub Enterprise
 (enhancement)     

#8

Add an easier upgrade command
 (bug)     

gh pr status

Relevant pull requests in cli/cli

**Current branch**

       There is no pull request associated with 
[fix-homepage-bug]

**Created by you**

You have no open pull requests

**Requesting a code review from you**

#100

Fix footer on homepage

[fix-homepage-footer]

✓ Checks passing

- Review pending

gh pr checkout 12

       remote: Enumerating objects: 66, done.
       remote: Counting objects: 100% (66/66), done.
       remote: Total 83 (delta 66), reused 66 (delta 66), pack-reused 17
       Unpacking objects: 100% (83/83), done.
       From https://github.com/owner/repo
       * [new ref] refs/pull/8896/head -> patch-2
       M README.md
       Switched to branch 'patch-2'     

gh pr create

       Creating pull request for 
feature-branch
 into       
main
 in ampinsk/test     

**
?
 Title** My new pull request     

**
?
 Body**
 [(e) to launch vim, enter to skip]

**
?
 What's next?**
 Submit

https://github.com/owner/repo/pull/1

gh pr checks

**All checks were successful**

1 failing, 3 successful, and 1 pending checks

-

CodeQL

3m43s

https://github.com/cli/cli/runs/123

✓

build (macos-latest)

4m18s

https://github.com/cli/cli/runs/123

✓

build (ubuntu-latest)

1m23s

https://github.com/cli/cli/runs/123

✓

build (windows-latest)

4m43s

https://github.com/cli/cli/runs/123

×

lint

47s

https://github.com/cli/cli/runs/123

gh release create 1.0

**
?
 Title**
 GitHub CLI 1.0

**
?
 Release notes**
 Write my own

**
?
 Is this a prerelease?**
 No

**
?
 Submit?**
 Publish release

       https://github.com/octocat/.github/releases/tag/1.0     

gh repo view

**cli/cli**

GitHub’s official command line tool

**GitHub CLI**

gh
 is GitHub on the command line. It brings pull         requests, issues, and other GitHub concepts to the terminal next to where you are already working with         
git
 and your code.       

Image: screenshot of gh pr status →

https://user-images.githubusercontent.com/98482/84171218-327e7a80-aa40-11ea-8cd1-5177fc2d0e72.png

View this repository on GitHub: https://github.com/cli/cli

gh alias set bugs 'issue list --label="bugs"'

       - Adding alias for bugs: issue list --label="bugs"

✓
 Added alias.

$ gh bugs

**Showing 2 of 7 issues in cli/cli that match your search**

#19

Pagination request returns empty JSON

 (bug)

#21

Error raised when passing valid parameters

 (bug)

[View all GitHub CLI commands →](/manual/gh)

##            Goodbye, context switching. Hello, terminal.         

### Your entire GitHub workflow

Work with issues, pull requests, checks, releases and more.

[View all GitHub CLI commands →](/manual/gh)

### Script and customize

               Call the GitHub API to script almost any action, and set a custom alias for any command.             

[Learn about aliases and API →](/manual)

### Enterprise-ready

Connect to GitHub Enterprise Server in addition to GitHub.com.

[Get set up with Enterprise →](/manual#github-enterprise)

### We <3 community

GitHub CLI is open source and ready for your contributions.

[Contribute to CLI →](https://github.com/cli/cli)

## Try GitHub on the command line

GitHub CLI brings GitHub to your terminal. Free and open source.

`                   brew install gh                 `
or

[Download for Mac](https://github.com/cli/cli/releases/download/v2.93.0/gh_2.93.0_macOS_amd64.zip)

[Download for Windows](https://github.com/cli/cli/releases/download/v2.93.0/gh_2.93.0_windows_amd64.msi)

[Install for Linux](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)
[View installation instructions →](https://github.com/cli/cli#installation)
![Windows](/assets/images/icon-windows.svg)![Mac](/assets/images/icon-mac.svg)![Linux](/assets/images/icon-linux.svg)

![](/assets/images/square-pattern.png)
