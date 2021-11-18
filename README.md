# cloak-dockerfile
Dockerfile for Cloak censorship circumvention tool to evade detection against state adversaries server on Alpine Linux 

Features
--------
- Automatic creation of a configuration file

Build
-----
```
$ docker build -t grffio/cloak .
```
- Supported Args: `CLOAK_VER=`

Quick Start
-----------
```
$ docker run --name cloak -d -p 443:443/tcp                       \
             -e CK_PROXYBOOK_SHADOWSOCKS="tcp://shadowsocks:8388" \
             -e CK_PROXYBOOK_OPENVPN="udp://openvpn:1194"          \
             grffio/cloak
```
- Supported Environment variables:
  - `CK_PROXYBOOK_<ProxyMethod>` - A list of ProxyMethod and endpoint of the upstream proxy server, format: '<protocol>://<host>:<port>' (required)
  - `CK_PRIVATEKEY`   - The static private key encoded in base64 (default: auto generation)
  - `CK_PUBLICKEY`    - The static public key encoded in base64, if specified, it is displayed in the client configuration (default: auto generation)
  - `CK_BYPASSUID`    - A list of unrestricted users UIDs, '<UID1>,<UID1>' (default: auto generation)
  - `CK_ADMINUID`     - The UID of the admin user (default: auto generation)
  - `CK_BINDADDR`     - A list of addresses Cloak will bind and listen, format '<IP:PORT1>,<IP:PORT2>' (default: 0.0.0.0:443)
  - `CK_REDIRADDR`    - The redirection address when the incoming traffic is not from a Cloak client  (default: bing.com)
  - `CK_DATABASEPATH` - The path to userinfo.db (default: /opt/cloak/userinfo.db)
  - `CK_KEEPALIVE`    - The number of seconds to tell the OS to wait after no activity before sending TCP KeepAlive probes to the upstream proxy server (default: 0)

- Exposed Ports:
  - 443/tcp

An example how to use with docker-compose [shadownet-compose](https://github.com/grffio/shadownet-compose)
