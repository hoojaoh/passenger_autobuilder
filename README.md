# Getting started

Install:

    sudo mkdir /srv/passenger_autobuilder
    sudo git clone https://github.com/phusion/passenger_autobuilder.git /srv/passenger_autobuilder/app
    cd /srv/passenger_autobuilder/app
    sudo ./setup-system
    sudo ./setup-images

## Build binaries

Run as `psg_autobuilder_run`. It will call sudo automatically.

    ./autobuild-with-pbuilder https://github.com/FooBarWidget/passenger.git passenger
