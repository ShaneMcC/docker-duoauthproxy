# Duo Auth Proxy

This is an automatically updating repo for running the [Duo auth proxy](https://duo.com/docs/authproxy-reference)

This is built to replace [jumanjihouse/docker-duoauthproxy](https://github.com/jumanjihouse/docker-duoauthproxy) which I was using previously, but is no longer kept up to date.

## Building

The proxy image is built in multiple stages and based on a minimal almalinux docker image.

There are some github actions to keep it up to date and rebuild it periodically.

## Usage

Run using:

```
docker run --name duoproxy -v ./authproxy.cfg:/opt/duoauthproxy/conf/authproxy.cfg -p 1812:1812 shanemcc/docker-duoauthproxy:latest
```

You can also bind mount `/opt/duoauthproxy/log ` if you require the logs to persist.
