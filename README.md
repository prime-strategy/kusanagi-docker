# KUSANAGI Runs on Docker
KUSANAGI Runs on Docker (hereinafter RoD) provides the functions of KUSANAGI using Docker compose.

## How to Install
For install kusanagi RoD, run this commands localy. And install kusanagi-docker command and other files in ```$HOME/.kusanagi```. 

```
curl https://raw.githubusercontent.com/prime-strategy/kusanagi-docker/master/install.sh | bash
```

## How to Run
For use KUSANAGI RoD, run kusanagi-docker command. Recommended to add "$HOME /.kusanagi/bin" in the environment variable PATH.
And simple help is run kusanagi-docker help.

## Recommends or Requires
### Recommends OS
- CentOS7 or later
- Ubuntu18.04 or later
- Windows10(WSL2+DockerCE)
- Windows10(WSL2 + Docker Desktop for Windows)
- Mac(with Docker Desktop for mac)

### Requre commands.
- bash(over 4.x)
- git
- sed
- awk
- grep
- gettext(gettext.sh, envsubst)
- curl
- docker(over 18.0x)
- docker-compose
- docker-machine

