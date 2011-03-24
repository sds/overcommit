###Usage

`rake install [REPOS=one[,two...]] [SOURCE_DIR=/path/to/src]`
`rake install:all [SOURCE_DIR=/path/to/src]`

* `REPOS` is a comma-separated list of repositories you want to install hooks in
    * Eg: `REPOS=causes,git_hooks`
    * Default: `causes`
* `SOURCE_DIR` is the directory you keep your projects in
    * Eg: `SOURCE_DIR=/all/my/code/`
    * Default: `~/src/`

---

###Adding hooks

Simply drop a new script into `hooks/`. It will be noticed, copied
to `project/.git/hooks`, and made executable when you run
 `rake install`.
