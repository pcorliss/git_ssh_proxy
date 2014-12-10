# GIT SSH Proxy

A handy tool for diagnosing the git wire protocol over SSH.

## Usage

```
chmod a+x ssh_proxy.rb
export GIT_SSH=[./path/too/]ssh_proxy.rb
git fetch
tail -f git.log
```
