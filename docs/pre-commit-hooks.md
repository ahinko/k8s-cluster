# pre-commit-hooks

Install [pre-commit](https://pre-commit.com/). On mac: `brew install pre-commit`.

Install the hooks in the repo using: `pre-commit install`.

Each time you do a `git commit` the pre-hooks will run. But it's also possible to run the checks on request: `pre-commit run --all-files`
