# php web stack on alpine linux - _"just for shits and giggles"_

Hello! :wave: this is to see if multistage builds are viable for php/httpd stack. also I've never built this kind of image before (being more py oriented)

once built & deployed for docker compose, visit localhost/www/ for testing the php scripts and all

Prereqs:
* working Docker 17+
* working docker compose

How to build & enjoy:
```$ docker-compose up --build```

configs & content & log access is handled via mounted volumes.
tmp folder contains make install logging that's been used for indentifing the file locations for multistage build

docker build should yield an image ~240MB, which should be tolerable (best single step result was around 1GB :goberserk:)
