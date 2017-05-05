# Change Log

## [Unreleased](https://github.com/brigade/overcommit/tree/HEAD)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.25.0...HEAD)

**Implemented enhancements:**

- Link to hook homepages where available [\#210](https://github.com/brigade/overcommit/issues/210)

**Merged pull requests:**

- Add demo GIF to README.md [\#208](https://github.com/brigade/overcommit/pull/208) ([lencioni](https://github.com/lencioni))

- Add EmptyMessage commit-msg hook [\#207](https://github.com/brigade/overcommit/pull/207) ([jawshooah](https://github.com/jawshooah))

## [v0.25.0](https://github.com/brigade/overcommit/tree/v0.25.0) (2015-05-02)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.24.0...v0.25.0)

**Implemented enhancements:**

- Define and apply consistent hook naming scheme [\#199](https://github.com/brigade/overcommit/issues/199)

- RuboCop [\#198](https://github.com/brigade/overcommit/issues/198)

- Add pre-commit hook to check Scala formatting with Scalariform [\#192](https://github.com/brigade/overcommit/issues/192)

- Add section that documents the hooks? [\#189](https://github.com/brigade/overcommit/issues/189)

- Add pre-rebase hook that prevents rebasing already-merged commits [\#179](https://github.com/brigade/overcommit/issues/179)

- Add vint pre-commit hook [\#177](https://github.com/brigade/overcommit/issues/177)

**Fixed bugs:**

- `diff.submodule` config breaks submodule test cases when set to `log`  [\#204](https://github.com/brigade/overcommit/issues/204)

- Breaking change in detached HEAD reporting in Git 2.4.0  [\#203](https://github.com/brigade/overcommit/issues/203)

- Committing with an empty commit message causes all CommitMsg hooks to blow up [\#201](https://github.com/brigade/overcommit/issues/201)

- TrailingWhitespace hook fails when un-modified lines have trailing whitespace [\#197](https://github.com/brigade/overcommit/issues/197)

**Closed issues:**

- Pre Push Hook is not running all hooks [\#195](https://github.com/brigade/overcommit/issues/195)

**Merged pull requests:**

- Set diff.submodule to short for staged submodule test cases [\#206](https://github.com/brigade/overcommit/pull/206) ([jawshooah](https://github.com/jawshooah))

- Update regex to filter out detached HEAD for Git 2.4.0 [\#205](https://github.com/brigade/overcommit/pull/205) ([jawshooah](https://github.com/jawshooah))

- Pass commit-msg hooks when commit message is empty [\#202](https://github.com/brigade/overcommit/pull/202) ([jawshooah](https://github.com/jawshooah))

- Move contributing section from readme to CONTRIBUTING.md [\#200](https://github.com/brigade/overcommit/pull/200) ([lencioni](https://github.com/lencioni))

- Include \*.svg for XML checks [\#194](https://github.com/brigade/overcommit/pull/194) ([lencioni](https://github.com/lencioni))

- Add pre-commit hook for Scalariform [\#193](https://github.com/brigade/overcommit/pull/193) ([jawshooah](https://github.com/jawshooah))

- Replace '\s' with "\[ \t\]" for older versions of grep [\#190](https://github.com/brigade/overcommit/pull/190) ([jawshooah](https://github.com/jawshooah))

- Restore MERGE\_HEAD and CHERRY\_PICK\_HEAD without newline [\#188](https://github.com/brigade/overcommit/pull/188) ([jawshooah](https://github.com/jawshooah))

- Use overcommit CLI for integration tests [\#187](https://github.com/brigade/overcommit/pull/187) ([jawshooah](https://github.com/jawshooah))

- Cross-platform compatibility changes [\#186](https://github.com/brigade/overcommit/pull/186) ([jawshooah](https://github.com/jawshooah))

- Don't include trailing period in GIT\_VERSION [\#183](https://github.com/brigade/overcommit/pull/183) ([jawshooah](https://github.com/jawshooah))

- Add MergedCommits pre-rebase hook [\#182](https://github.com/brigade/overcommit/pull/182) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for Vint [\#178](https://github.com/brigade/overcommit/pull/178) ([jawshooah](https://github.com/jawshooah))

- Make IndexTags quiet by default [\#176](https://github.com/brigade/overcommit/pull/176) ([lencioni](https://github.com/lencioni))

- Add \*\*/\*.svg to ImageOptim default include configuration [\#175](https://github.com/brigade/overcommit/pull/175) ([lencioni](https://github.com/lencioni))

## [v0.24.0](https://github.com/brigade/overcommit/tree/v0.24.0) (2015-04-13)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.23.0...v0.24.0)

**Implemented enhancements:**

- Display warning about hook in .overcommit.yml without explicit `enabled: true` [\#173](https://github.com/brigade/overcommit/issues/173)

- Detect `git commit --amend` in pre-commit hooks so staged files include everything in commit [\#146](https://github.com/brigade/overcommit/issues/146)

- Add post-checkout hook to remind user to update submodules [\#145](https://github.com/brigade/overcommit/issues/145)

- Restore old hooks on uninstall [\#138](https://github.com/brigade/overcommit/issues/138)

- Change hook summary message to mention warnings if there were any [\#137](https://github.com/brigade/overcommit/issues/137)

- Extract built-in hooks a la pre-commit [\#122](https://github.com/brigade/overcommit/issues/122)

- `ALL` hook settings in config are overridden by defaults [\#117](https://github.com/brigade/overcommit/issues/117)

**Fixed bugs:**

- Error when removing submodule [\#168](https://github.com/brigade/overcommit/issues/168)

- Modify ScssLint pre-commit hook to gracefully handle case when no files are linted [\#163](https://github.com/brigade/overcommit/issues/163)

- \#setup\_environment should store modification times for unstaged files [\#159](https://github.com/brigade/overcommit/issues/159)

- Unable to commit only submodule updates [\#148](https://github.com/brigade/overcommit/issues/148)

- Hook symlinks remain after `overcommit --uninstall` [\#140](https://github.com/brigade/overcommit/issues/140)

- Unstaged changes lost when pre-commit plugin modified [\#129](https://github.com/brigade/overcommit/issues/129)

**Closed issues:**

- Various spec blocks return raw Boolean values rather than using should-matchers [\#150](https://github.com/brigade/overcommit/issues/150)

- Executing custom rake tasks on precommit [\#127](https://github.com/brigade/overcommit/issues/127)

**Merged pull requests:**

- Preserve modification times for both staged and unstaged files [\#172](https://github.com/brigade/overcommit/pull/172) ([jawshooah](https://github.com/jawshooah))

- Add \#amendment? delegator to Hook::PreCommit::Base [\#171](https://github.com/brigade/overcommit/pull/171) ([jawshooah](https://github.com/jawshooah))

- Use ChildProcess to spawn detached processes [\#169](https://github.com/brigade/overcommit/pull/169) ([jawshooah](https://github.com/jawshooah))

- Include changes in last commit when running pre-commit hooks after `git commit --amend` [\#167](https://github.com/brigade/overcommit/pull/167) ([jawshooah](https://github.com/jawshooah))

- Extract process logic from `Utils.execute\_in\_background` into `Subprocess.spawn\_detached` [\#166](https://github.com/brigade/overcommit/pull/166) ([jawshooah](https://github.com/jawshooah))

- Add support for pre-rebase hooks [\#165](https://github.com/brigade/overcommit/pull/165) ([jawshooah](https://github.com/jawshooah))

- Add SubmoduleStatus post-checkout, post-commit, post-merge, and post-rewrite hooks [\#164](https://github.com/brigade/overcommit/pull/164) ([jawshooah](https://github.com/jawshooah))

- Add Spellcheck commit-msg hook [\#162](https://github.com/brigade/overcommit/pull/162) ([jawshooah](https://github.com/jawshooah))

- Fix missing method error in PushedRef\#forced? [\#160](https://github.com/brigade/overcommit/pull/160) ([jawshooah](https://github.com/jawshooah))

- Add failing test case for restoring unstaged changes [\#158](https://github.com/brigade/overcommit/pull/158) ([jawshooah](https://github.com/jawshooah))

- Add ProtectedBranches pre-push hook [\#157](https://github.com/brigade/overcommit/pull/157) ([jawshooah](https://github.com/jawshooah))

- Add pre-push hook to run RSpec test suite [\#155](https://github.com/brigade/overcommit/pull/155) ([jawshooah](https://github.com/jawshooah))

- Add support for pre-push hooks [\#154](https://github.com/brigade/overcommit/pull/154) ([jawshooah](https://github.com/jawshooah))

- Change hook summary message to mention warnings [\#152](https://github.com/brigade/overcommit/pull/152) ([lencioni](https://github.com/lencioni))

- Fix some existing tests and make others more expressive [\#151](https://github.com/brigade/overcommit/pull/151) ([jawshooah](https://github.com/jawshooah))

- Properly handle submodule-only changes [\#149](https://github.com/brigade/overcommit/pull/149) ([jawshooah](https://github.com/jawshooah))

- Filter out irrelevant directories in SimpleCov reports [\#142](https://github.com/brigade/overcommit/pull/142) ([jawshooah](https://github.com/jawshooah))

- Save old hooks on install, restore on uninstall [\#141](https://github.com/brigade/overcommit/pull/141) ([jawshooah](https://github.com/jawshooah))

- Ensure environment is restored on error [\#134](https://github.com/brigade/overcommit/pull/134) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook to check XML syntax [\#133](https://github.com/brigade/overcommit/pull/133) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook to check for case conflicts [\#132](https://github.com/brigade/overcommit/pull/132) ([jawshooah](https://github.com/jawshooah))

- Add simplecov coverage tool to spec runs [\#131](https://github.com/brigade/overcommit/pull/131) ([sectioneight](https://github.com/sectioneight))

- Add GoVet pre-commit hook [\#130](https://github.com/brigade/overcommit/pull/130) ([sectioneight](https://github.com/sectioneight))

- Handle Golint errors output to stderr [\#128](https://github.com/brigade/overcommit/pull/128) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for JSLint [\#126](https://github.com/brigade/overcommit/pull/126) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for JSL \(JavaScript Lint\) [\#125](https://github.com/brigade/overcommit/pull/125) ([jawshooah](https://github.com/jawshooah))

- Exclude Markdown files from TrailingWhitespace [\#124](https://github.com/brigade/overcommit/pull/124) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for ruby-lint [\#123](https://github.com/brigade/overcommit/pull/123) ([jawshooah](https://github.com/jawshooah))

- Override default settings with user 'ALL' hook [\#121](https://github.com/brigade/overcommit/pull/121) ([jawshooah](https://github.com/jawshooah))

- Extract file, line from golint output [\#120](https://github.com/brigade/overcommit/pull/120) ([jawshooah](https://github.com/jawshooah))

- Extract file, line, type from coffeelint output [\#118](https://github.com/brigade/overcommit/pull/118) ([jawshooah](https://github.com/jawshooah))

- Allow extraction of messages with no line number [\#116](https://github.com/brigade/overcommit/pull/116) ([jawshooah](https://github.com/jawshooah))

- Ignore blank lines in csslint output [\#115](https://github.com/brigade/overcommit/pull/115) ([jawshooah](https://github.com/jawshooah))

- LocalPathsInGemfile ignores commented local paths [\#114](https://github.com/brigade/overcommit/pull/114) ([nevinera](https://github.com/nevinera))

- Ignore hard tabs in Godeps.json [\#119](https://github.com/brigade/overcommit/pull/119) ([sectioneight](https://github.com/sectioneight))

## [v0.23.0](https://github.com/brigade/overcommit/tree/v0.23.0) (2015-02-27)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.22.0...v0.23.0)

**Implemented enhancements:**

- Add ESLint pre-commit hook [\#91](https://github.com/brigade/overcommit/issues/91)

- Add post-merge, post-commit, and post-rebase hooks for indexing tags [\#72](https://github.com/brigade/overcommit/issues/72)

**Merged pull requests:**

- Remove :modified\_lines\_in\_file stubs in pre-commit hook specs [\#113](https://github.com/brigade/overcommit/pull/113) ([jawshooah](https://github.com/jawshooah))

- Parse errors and warnings in csslint output [\#112](https://github.com/brigade/overcommit/pull/112) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for Pylint [\#111](https://github.com/brigade/overcommit/pull/111) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for tidy [\#110](https://github.com/brigade/overcommit/pull/110) ([jawshooah](https://github.com/jawshooah))

- Improve message parsing for PythonFlake8 [\#109](https://github.com/brigade/overcommit/pull/109) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for pep257 [\#108](https://github.com/brigade/overcommit/pull/108) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for pyflakes [\#107](https://github.com/brigade/overcommit/pull/107) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for pep8 [\#106](https://github.com/brigade/overcommit/pull/106) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for xmllint [\#105](https://github.com/brigade/overcommit/pull/105) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hook for checkstyle [\#104](https://github.com/brigade/overcommit/pull/104) ([jawshooah](https://github.com/jawshooah))

- Quote `file\_path` in `extract\_modified\_lines` [\#103](https://github.com/brigade/overcommit/pull/103) ([jawshooah](https://github.com/jawshooah))

- Add scalastyle pre-commit hook [\#102](https://github.com/brigade/overcommit/pull/102) ([jawshooah](https://github.com/jawshooah))

- Fail image\_optim hook if gem not installed [\#101](https://github.com/brigade/overcommit/pull/101) ([jawshooah](https://github.com/jawshooah))

- Add pre-commit hooks for w3c\_validators [\#100](https://github.com/brigade/overcommit/pull/100) ([jawshooah](https://github.com/jawshooah))

- Add support for post-merge hooks [\#96](https://github.com/brigade/overcommit/pull/96) ([jawshooah](https://github.com/jawshooah))

- Add git-guilt post-commit hook [\#95](https://github.com/brigade/overcommit/pull/95) ([jawshooah](https://github.com/jawshooah))

- Add support for post-commit hooks [\#92](https://github.com/brigade/overcommit/pull/92) ([jawshooah](https://github.com/jawshooah))

- Add standard and semistandard pre-commit hooks [\#98](https://github.com/brigade/overcommit/pull/98) ([jawshooah](https://github.com/jawshooah))

- JSHint: report errors and warnings separately [\#97](https://github.com/brigade/overcommit/pull/97) ([jawshooah](https://github.com/jawshooah))

- Add ESLint pre-commit hook [\#94](https://github.com/brigade/overcommit/pull/94) ([jawshooah](https://github.com/jawshooah))

## [v0.22.0](https://github.com/brigade/overcommit/tree/v0.22.0) (2015-02-09)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.21.0...v0.22.0)

**Merged pull requests:**

- Add git-guilt post-commit hook [\#93](https://github.com/brigade/overcommit/pull/93) ([jawshooah](https://github.com/jawshooah))

## [v0.21.0](https://github.com/brigade/overcommit/tree/v0.21.0) (2015-01-06)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.20.0...v0.21.0)

**Merged pull requests:**

- Add docs badge to README [\#90](https://github.com/brigade/overcommit/pull/90) ([rrrene](https://github.com/rrrene))

## [v0.20.0](https://github.com/brigade/overcommit/tree/v0.20.0) (2014-12-17)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.19.0...v0.20.0)

**Implemented enhancements:**

- image\_optim integration [\#89](https://github.com/brigade/overcommit/issues/89)

- CLI commands for running overcommit [\#84](https://github.com/brigade/overcommit/issues/84)

**Merged pull requests:**

- Add run CLI option [\#88](https://github.com/brigade/overcommit/pull/88) ([alexbuijs](https://github.com/alexbuijs))

## [v0.19.0](https://github.com/brigade/overcommit/tree/v0.19.0) (2014-11-07)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.18.0...v0.19.0)

**Fixed bugs:**

- Workflow with submodules [\#82](https://github.com/brigade/overcommit/issues/82)

**Merged pull requests:**

- Reek pre-commit hook [\#86](https://github.com/brigade/overcommit/pull/86) ([eneeyac](https://github.com/eneeyac))

- Pass comma separated list of files to brakeman [\#85](https://github.com/brigade/overcommit/pull/85) ([alexbuijs](https://github.com/alexbuijs))

- Add --no-pngout flag for image\_optim command on :fail message [\#81](https://github.com/brigade/overcommit/pull/81) ([htanata](https://github.com/htanata))

## [v0.18.0](https://github.com/brigade/overcommit/tree/v0.18.0) (2014-09-21)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.17.0...v0.18.0)

**Implemented enhancements:**

- Add --list-hooks command line option [\#71](https://github.com/brigade/overcommit/issues/71)

**Fixed bugs:**

- Commit message gets lost after conflicted cherry-pick [\#77](https://github.com/brigade/overcommit/issues/77)

**Merged pull requests:**

- Add CLI option to list available hooks [\#76](https://github.com/brigade/overcommit/pull/76) ([ofctlo](https://github.com/ofctlo))

- Fix 'include' path for ChamberSecurity [\#79](https://github.com/brigade/overcommit/pull/79) ([jfelchner](https://github.com/jfelchner))

- Fix Chamber integration [\#78](https://github.com/brigade/overcommit/pull/78) ([jfelchner](https://github.com/jfelchner))

## [v0.17.0](https://github.com/brigade/overcommit/tree/v0.17.0) (2014-09-02)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.16.0...v0.17.0)

**Implemented enhancements:**

- Cannot execute piped commands [\#73](https://github.com/brigade/overcommit/issues/73)

- \[README\] Repo specific pre-commit hook [\#70](https://github.com/brigade/overcommit/issues/70)

- Add SCSS support for ctags [\#69](https://github.com/brigade/overcommit/issues/69)

**Fixed bugs:**

- Usernames with digits cause the schema check to fail [\#74](https://github.com/brigade/overcommit/issues/74)

- Rebasing with Gemfile conflicts causes changes to be lost [\#68](https://github.com/brigade/overcommit/issues/68)

- Some text appears white-on-white in terminal with light background [\#67](https://github.com/brigade/overcommit/issues/67)

- No such file or directory @ utime\_internal [\#55](https://github.com/brigade/overcommit/issues/55)

**Merged pull requests:**

- fixes code example for custom hook in README.md [\#75](https://github.com/brigade/overcommit/pull/75) ([Bertg](https://github.com/Bertg))

- Use travis-yaml gem instead of travis-lint [\#64](https://github.com/brigade/overcommit/pull/64) ([tabolario](https://github.com/tabolario))

- Add RSpec Focus Check [\#47](https://github.com/brigade/overcommit/pull/47) ([jfelchner](https://github.com/jfelchner))

## [v0.16.0](https://github.com/brigade/overcommit/tree/v0.16.0) (2014-08-01)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.15.0...v0.16.0)

## [v0.15.0](https://github.com/brigade/overcommit/tree/v0.15.0) (2014-07-28)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.14.1...v0.15.0)

**Implemented enhancements:**

- Overcommit should install default .overcommit.yml too [\#66](https://github.com/brigade/overcommit/issues/66)

- Add Configurable Error Levels for Checks [\#54](https://github.com/brigade/overcommit/issues/54)

**Fixed bugs:**

- Wipes working changes if git stash fails [\#65](https://github.com/brigade/overcommit/issues/65)

- Extremely slow with tons of files [\#63](https://github.com/brigade/overcommit/issues/63)

## [v0.14.1](https://github.com/brigade/overcommit/tree/v0.14.1) (2014-07-15)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.14.0...v0.14.1)

## [v0.14.0](https://github.com/brigade/overcommit/tree/v0.14.0) (2014-07-14)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.13.0...v0.14.0)

**Implemented enhancements:**

- Overcommit doesn't work with structure.sql [\#60](https://github.com/brigade/overcommit/issues/60)

**Fixed bugs:**

- Bug with image\_optim hook [\#43](https://github.com/brigade/overcommit/issues/43)

**Closed issues:**

- Stashes not dropping [\#62](https://github.com/brigade/overcommit/issues/62)

## [v0.13.0](https://github.com/brigade/overcommit/tree/v0.13.0) (2014-07-09)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.12.0...v0.13.0)

**Fixed bugs:**

- Overcommit won't commit submodule changes. [\#59](https://github.com/brigade/overcommit/issues/59)

**Closed issues:**

- Add golint support [\#58](https://github.com/brigade/overcommit/issues/58)

## [v0.12.0](https://github.com/brigade/overcommit/tree/v0.12.0) (2014-06-23)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.11.1...v0.12.0)

**Fixed bugs:**

- ctags illegal option [\#57](https://github.com/brigade/overcommit/issues/57)

- could not open .git/CHERRY\_PICK\_HEAD [\#56](https://github.com/brigade/overcommit/issues/56)

## [v0.11.1](https://github.com/brigade/overcommit/tree/v0.11.1) (2014-06-02)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.11.0...v0.11.1)

## [v0.11.0](https://github.com/brigade/overcommit/tree/v0.11.0) (2014-05-21)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.10.0...v0.11.0)

**Fixed bugs:**

- could not open .git/MERGE\_HEAD [\#52](https://github.com/brigade/overcommit/issues/52)

## [v0.10.0](https://github.com/brigade/overcommit/tree/v0.10.0) (2014-05-21)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.9.0...v0.10.0)

## [v0.9.0](https://github.com/brigade/overcommit/tree/v0.9.0) (2014-05-14)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.8.0...v0.9.0)

**Implemented enhancements:**

- Security concern with repo-based hooks [\#31](https://github.com/brigade/overcommit/issues/31)

**Fixed bugs:**

- Rubocop Check Not Using Local Rubocop Config File [\#53](https://github.com/brigade/overcommit/issues/53)

**Merged pull requests:**

- Add Chamber Security Verification Check [\#51](https://github.com/brigade/overcommit/pull/51) ([jfelchner](https://github.com/jfelchner))

- Add Brakeman Security Check [\#50](https://github.com/brigade/overcommit/pull/50) ([jfelchner](https://github.com/jfelchner))

- Add Check for Local Paths in Gemfile [\#49](https://github.com/brigade/overcommit/pull/49) ([jfelchner](https://github.com/jfelchner))

- Add Pry Binding Check [\#48](https://github.com/brigade/overcommit/pull/48) ([jfelchner](https://github.com/jfelchner))

- Add check for merge conflict markers [\#46](https://github.com/brigade/overcommit/pull/46) ([jfelchner](https://github.com/jfelchner))

- Add JSON Parsing check [\#45](https://github.com/brigade/overcommit/pull/45) ([jfelchner](https://github.com/jfelchner))

- Rails Migration/Schema Syncronization Check [\#44](https://github.com/brigade/overcommit/pull/44) ([jfelchner](https://github.com/jfelchner))

## [v0.8.0](https://github.com/brigade/overcommit/tree/v0.8.0) (2014-04-18)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.7.0...v0.8.0)

## [v0.7.0](https://github.com/brigade/overcommit/tree/v0.7.0) (2014-03-06)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.6.3...v0.7.0)

**Implemented enhancements:**

- JRuby incompatibility due to use of 'fork' [\#32](https://github.com/brigade/overcommit/issues/32)

- When installing, should complain if hooks already exist [\#7](https://github.com/brigade/overcommit/issues/7)

**Merged pull requests:**

- Return :warn instead of :fail on BundleCheck [\#40](https://github.com/brigade/overcommit/pull/40) ([htanata](https://github.com/htanata))

## [v0.6.3](https://github.com/brigade/overcommit/tree/v0.6.3) (2014-03-05)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.6.2...v0.6.3)

**Merged pull requests:**

- Display all error messages for TextWidth. [\#38](https://github.com/brigade/overcommit/pull/38) ([tgxworld](https://github.com/tgxworld))

- Allow users to configure maximum lengths of TextWidth. [\#36](https://github.com/brigade/overcommit/pull/36) ([tgxworld](https://github.com/tgxworld))

- Make RussianNovel length configurable. [\#35](https://github.com/brigade/overcommit/pull/35) ([tgxworld](https://github.com/tgxworld))

- Improve README. [\#34](https://github.com/brigade/overcommit/pull/34) ([tgxworld](https://github.com/tgxworld))

## [v0.6.2](https://github.com/brigade/overcommit/tree/v0.6.2) (2014-02-21)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.6.1...v0.6.2)

## [v0.6.1](https://github.com/brigade/overcommit/tree/v0.6.1) (2014-02-21)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.6.0...v0.6.1)

**Implemented enhancements:**

- Specify custom `overcommit.yml` template [\#21](https://github.com/brigade/overcommit/issues/21)

- \(Optionally\) ignore hard tabs in SVG files [\#20](https://github.com/brigade/overcommit/issues/20)

- Add automated tests for pre\_commit hooks [\#10](https://github.com/brigade/overcommit/issues/10)

**Fixed bugs:**

- Installed Ruby hooks don't have executable permissions [\#29](https://github.com/brigade/overcommit/issues/29)

## [v0.6.0](https://github.com/brigade/overcommit/tree/v0.6.0) (2014-02-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.5.0...v0.6.0)

## [v0.5.0](https://github.com/brigade/overcommit/tree/v0.5.0) (2013-12-04)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.4.1...v0.5.0)

## [v0.4.1](https://github.com/brigade/overcommit/tree/v0.4.1) (2013-11-08)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.4.0...v0.4.1)

## [v0.4.0](https://github.com/brigade/overcommit/tree/v0.4.0) (2013-11-07)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.3.2...v0.4.0)

**Merged pull requests:**

- Exclude submodules from modified\_files [\#27](https://github.com/brigade/overcommit/pull/27) ([dividedmind](https://github.com/dividedmind))

- Add image optimization pre-commit plugin [\#24](https://github.com/brigade/overcommit/pull/24) ([gsmendoza](https://github.com/gsmendoza))

## [v0.3.2](https://github.com/brigade/overcommit/tree/v0.3.2) (2013-10-28)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.3.1...v0.3.2)

**Merged pull requests:**

- Fix rubocop.yml not found in top-level directory [\#25](https://github.com/brigade/overcommit/pull/25) ([averell23](https://github.com/averell23))

- Find and use .rubocop.yml for staged files [\#23](https://github.com/brigade/overcommit/pull/23) ([averell23](https://github.com/averell23))

## [v0.3.1](https://github.com/brigade/overcommit/tree/v0.3.1) (2013-10-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.3.0...v0.3.1)

## [v0.3.0](https://github.com/brigade/overcommit/tree/v0.3.0) (2013-10-10)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.6...v0.3.0)

**Fixed bugs:**

- undefined method `modified\_lines' for nil:NilClass [\#15](https://github.com/brigade/overcommit/issues/15)

- Occasionally uses wrong Ruby version for linting [\#6](https://github.com/brigade/overcommit/issues/6)

**Merged pull requests:**

- Add --no-ext-diff option to git diff. [\#22](https://github.com/brigade/overcommit/pull/22) ([DawidJanczak](https://github.com/DawidJanczak))

## [v0.2.6](https://github.com/brigade/overcommit/tree/v0.2.6) (2013-09-15)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.5...v0.2.6)

## [v0.2.5](https://github.com/brigade/overcommit/tree/v0.2.5) (2013-09-11)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.4...v0.2.5)

## [v0.2.4](https://github.com/brigade/overcommit/tree/v0.2.4) (2013-08-28)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.3...v0.2.4)

**Fixed bugs:**

- Too many open files - git show :spec/search\_app/search\_app/simple\_result\_spec.rb \(Errno::EMFILE\) [\#16](https://github.com/brigade/overcommit/issues/16)

- Remove or fix erb\_syntax [\#13](https://github.com/brigade/overcommit/issues/13)

## [v0.2.3](https://github.com/brigade/overcommit/tree/v0.2.3) (2013-08-22)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.2...v0.2.3)

**Merged pull requests:**

- the path was not being created properly for coffee\_lint, this commit emu... [\#18](https://github.com/brigade/overcommit/pull/18) ([richsoni](https://github.com/richsoni))

- Replace native 'which' with Ruby version. [\#17](https://github.com/brigade/overcommit/pull/17) ([rpdillon](https://github.com/rpdillon))

## [v0.2.2](https://github.com/brigade/overcommit/tree/v0.2.2) (2013-07-25)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.1...v0.2.2)

**Implemented enhancements:**

- Doesn't syntax check .rake files [\#14](https://github.com/brigade/overcommit/issues/14)

## [v0.2.1](https://github.com/brigade/overcommit/tree/v0.2.1) (2013-07-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.2.0...v0.2.1)

## [v0.2.0](https://github.com/brigade/overcommit/tree/v0.2.0) (2013-07-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.11...v0.2.0)

## [v0.1.11](https://github.com/brigade/overcommit/tree/v0.1.11) (2013-07-10)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.10...v0.1.11)

## [v0.1.10](https://github.com/brigade/overcommit/tree/v0.1.10) (2013-06-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.9...v0.1.10)

## [v0.1.9](https://github.com/brigade/overcommit/tree/v0.1.9) (2013-06-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.8...v0.1.9)

## [v0.1.8](https://github.com/brigade/overcommit/tree/v0.1.8) (2013-06-20)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.7...v0.1.8)

**Fixed bugs:**

- Tests are being run against files as they exist on disk, not actual contents staged for commit [\#9](https://github.com/brigade/overcommit/issues/9)

## [v0.1.7](https://github.com/brigade/overcommit/tree/v0.1.7) (2013-06-10)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.6...v0.1.7)

**Fixed bugs:**

- Build fails on 1.8.7 due to use of 1.9 hash syntax [\#8](https://github.com/brigade/overcommit/issues/8)

- Whitespace check should be skipped for binary files [\#5](https://github.com/brigade/overcommit/issues/5)

- Color code should not be emitted in a non-terminal, eg GitHub for Mac [\#3](https://github.com/brigade/overcommit/issues/3)

## [v0.1.6](https://github.com/brigade/overcommit/tree/v0.1.6) (2013-06-04)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.5...v0.1.6)

## [v0.1.5](https://github.com/brigade/overcommit/tree/v0.1.5) (2013-06-04)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.4...v0.1.5)

**Merged pull requests:**

- Add uninstallation information to README.md [\#2](https://github.com/brigade/overcommit/pull/2) ([derwiki](https://github.com/derwiki))

## [v0.1.4](https://github.com/brigade/overcommit/tree/v0.1.4) (2013-05-29)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.2...v0.1.4)

**Fixed bugs:**

- SKIP\_CHECKS=all skips more than just checks [\#1](https://github.com/brigade/overcommit/issues/1)

## [v0.1.2](https://github.com/brigade/overcommit/tree/v0.1.2) (2013-05-24)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.1...v0.1.2)

## [v0.1.1](https://github.com/brigade/overcommit/tree/v0.1.1) (2013-05-23)

[Full Changelog](https://github.com/brigade/overcommit/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/brigade/overcommit/tree/v0.1.0) (2013-05-23)



\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*