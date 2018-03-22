# Docker volumes and permissions (Reborn)

[![Build Status](https://travis-ci.org/ypereirareis/docker-permissions-reborn.svg?branch=master)](https://travis-ci.org/ypereirareis/docker-permissions-reborn)

This repository shows you a way to deal with read/write/exec permissions
and how to define user and group ids using volumes from the host, when running containers.

Indeed, user uid and gid are often different in the container and on the host system.
And it's possible to use the same docker configuration on different hosts (local, test, stating,...)
and with possibly different users from a uid/gid point of view.

So if you want to use volumes, you need to understand how to configure the permissions of the project/folder
mapped into your containers.

:whale: **A second way of doing things is available at:** [ypereirareis/docker-permissions](https://github.com/ypereirareis/docker-permissions)

## Docker images

For this demo project we are relying on two simple docker alpine images:

* [Nginx (nginx:1.13.9-alpine)](https://hub.docker.com/_/nginx/)
* [PHP-FPM (php:7.2.3-fpm-alpine3.7)](https://hub.docker.com/_/php/)

We are using the nginx image directly simply overriding the configuration file with our own
to be able to use PHP-FPM running in the `php` container.

```bash
location ~ ^/index\.php(/|$) {
    fastcgi_pass php:9000;
    ...
    internal;
}
```

For the PHP-FPM image we are building our own form the `php:7.2.3-fpm-alpine3.7` because we need to
add a custom entry point to deal with permissions.

## The problem

We have a problem if we use a volume to share our code from host to container.

* The user running `php-fpm` in the container is `wwww-data` with `uid=82` and `gid=82`.
* Our host user often has `uid=1000` and `gid=1000` but not always.
* The `www-data` user will not be able to read/write/exec files from the volume if permissions are not defined properly.

But I do not recommend to change permissions with `chmod` directly.
The way I recommend is to change the owner of the shared directory to map uid and gid of the container user
to the host user.

## The Dockerfile and entry point to change uig/gid

The interesting part of the Dockerfile is this one:

```bash
RUN mkdir -p $PROJECT_DIR
COPY ./project $PROJECT_DIR
RUN chown -R www-data:www-data $PROJECT_DIR
WORKDIR $PROJECT_DIR
USER www-data
```

* Change the user uid when using a volume, the possible new values are coming from environment variables.

```yaml
version: '3'
services:
  php:
    build:
      context: .
    container_name: ypr-permissions-php
    user: ${PHPUID}
    volumes:
      - ./project:/usr/share/nginx/html
```

* We can define per-host custom UID/GID environment varaibles with a `.env` file.

```bash
PHPUID=1000
```

# Run the demo

```bash
$ git clone git@github.com:ypereirareis/docker-permissions-reborn.git && cd docker-permissions-reborn
```

* Copy `.env.dist` to `.env` and set your uid and gid values.
* Comment/Uncomment volume from `docker-compose.yml`

```yaml
services:
  php:
    volumes:
      - ./project:/usr/share/nginx/html
```

```bash
$ docker-compose build

```

```bash
$ docker-compose up
Starting ypr-permissions-reborn-php ... 
Starting ypr-permissions-reborn-php ... done
Starting ypr-permissions-reborn-nginx ... 
Starting ypr-permissions-reborn-nginx ... done
Attaching to ypr-permissions-reborn-php, ypr-permissions-reborn-nginx
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: [pool www] 'user' directive is ignored when FPM is not running as root
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: [pool www] 'user' directive is ignored when FPM is not running as root
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: [pool www] 'group' directive is ignored when FPM is not running as root
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: [pool www] 'group' directive is ignored when FPM is not running as root
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: fpm is running, pid 1
ypr-permissions-reborn-php | [08-Mar-2018 16:45:35] NOTICE: ready to handle connections
```

Go to [http://127.0.0.1:8889/](http://127.0.0.1:8889/)

If everything is ok, you should see:

![OK result](./img/ok.png)

# Tests

```bash
chmod +x tests.sh && ./tests.sh
```

# LICENSE

MIT License

Copyright (c) 2018 Yannick Pereira-Reis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
