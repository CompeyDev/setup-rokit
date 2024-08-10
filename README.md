<div align="center">
  <h1><code>setup-rokit</code></h1>
  <p>
    <a href="https://github.com/CompeyDev/setup-rokit/actions?query=workflow%3Atest"><img src="https://github.com/CompeyDev/setup-rokit/workflows/test/badge.svg" alt="CI" /></a>
  </p>
</div>

GitHub action to install and run [rokit](https://github.com/rojo-rbx/rokit); a toolchain manager.

## Usage
Use the latest released version of `rokit` with default parameters:
```yaml
steps:
- uses: CompeyDev/setup-rokit@v0.1.0
```
For a list of default parameter values, [check here](https://github.com/CompeyDev/setup-rokit/blob/main/action.yml#L5-L20).

### Advanced
For more advanced cases, use the parameters below.
```yaml
steps:
- uses: CompeyDev/setup-rokit@v0.1.0
  with:
    version: v1.0.0 # name of git tag in rokit (uses latest tag by default)
    path: some_dir/my_project # path to project dir containing a `rokit.toml`, `aftman.toml`, or `foreman.toml` ("." (current dir) by default)
    cache: false # whether to enable binary caching between runs (false by default)
    token: ${{ github.token }} # GitHub token to bypass rate limit (${{ github.token }} set by default)
```

## Inputs
### `version`
The git tag of `rokit` to install from releases and use. By default this input will be assigned to the latest version of `rokit`.

### `path`
The path to the directory containing the `rokit.toml` to install tools from. The default is the current directory (`.`).

### `cache`
Enable to cache tools installed by `rokit`, the default value of this input is `false`. Note, in many cases enabling this feature will slow down the `setup-rokit` action.

There are a few reasons you may choose to enable caching:
* Action runs often, causing the GitHub rate-limit to be reached
* A large amount of tools to install
* Server downloading from is slow

In any case, it is recommended to benchmark before enabling this feature.

### `token`
Set to a GitHub token to be used by `rokit` to increase the GitHub rate-limit. Note, these two options, `${{ github.token }}` and `${{ secrets.GITHUB_TOKEN }}`, are equivalent and passed by default. **Thus, you do not need to specify this parameter unless you are using a token different from the owner of the repository.**

## Credits
[@ok-nick](https://github.com/ok-nick) - Creating `setup-aftman` which `setup-rokit` is a fork of

