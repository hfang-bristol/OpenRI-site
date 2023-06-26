# [Source code for the OpenRI web-server](https://github.com/hfang-bristol/OpenRI-site)

## @ Overview

> The [OpenRI](http://www.openridb.com/OpenRI) web-server enables interactive exploration of multimodal regulatory interactions (e/pQTL, promoter capture Hi-C, and enhancer-gene maps) and their use for data mining inclusive of non-coding genome.

> To learn how to use OpenRI, a user manual is made available [here](http://www.openridb.com:3080/OpenRIbooklet/index.html) with step-by-step instructions.

## @ Development

> The OpenRI web-server is developed using [Mojolicious](https://www.mojolicious.org) and [Bootstrap](https://getbootstrap.com), being mobile-first and responsive across all major platform browsers.

> The folder `my_openri` has a tree-like directory structure with three levels:
```ruby
my_openri
├── lib
│   └── My_openri
│       └── Controller
├── public
│   ├── OpenRIbooklet
│   │   ├── index_files
│   │   └── libs
│   ├── app
│   │   ├── ajex
│   │   ├── css
│   │   ├── examples
│   │   ├── img
│   │   └── js
│   └── dep
│       ├── HighCharts
│       ├── Select2
│       ├── bootstrap
│       ├── bootstrapselect
│       ├── bootstraptoggle
│       ├── dataTables
│       ├── fontawesome
│       ├── jcloud
│       ├── jqcloud
│       ├── jquery
│       ├── tabber
│       └── typeahead
├── script
├── t
└── templates
    └── layouts
```


## @ Installation

Assume you have a `ROOT (sudo)` privilege on `Ubuntu`

### 1. Install Mojolicious and other perl modules

```ruby
sudo su
# here enter your password

curl -L cpanmin.us | perl - Mojolicious
perl -e "use Mojolicious::Plugin::PODRenderer"
perl -MCPAN -e "install Mojolicious::Plugin::PODRenderer"
perl -MCPAN -e "install DBI"
perl -MCPAN -e "install Mojo::DOM"
perl -MCPAN -e "install Mojo::Base"
perl -MCPAN -e "install LWP::Simple"
perl -MCPAN -e "install JSON::Parse"
perl -MCPAN -e "install local::lib"
perl -MCPAN -Mlocal::lib -e "install JSON::Parse"
```

### 2. Install R

```ruby
sudo su
# here enter your password

# install R
wget http://www.stats.bris.ac.uk/R/src/base/R-4/R-4.3.0.tar.gz
tar xvfz R-4.3.0.tar.gz
cd ~/R-4.3.0
./configure
make
make check
make install
R # start R
```

### 3. Install pandoc

```ruby
sudo su
# here enter your password

# install pandoc
wget https://github.com/jgm/pandoc/releases/download/3.1/pandoc-3.1-linux-amd64.tar.gz
tar xvzf pandoc-3.1-linux-amd64.tar.gz --strip-components 1 -C /usr/local/

# use pandoc to render R markdown
R
rmarkdown::pandoc_available()
Sys.setenv(RSTUDIO_PANDOC="/usr/local/bin")
rmarkdown::render(YOUR_RMD_FILE, bookdown::html_document2(number_sections=F, theme="readable", hightlight="default"))
```


## @ Deployment

Assume you place `my_openri` under your `home` directory

```ruby
cd ~/my_openri
systemctl restart apache2.service
morbo -l 'http://*:3080/' script/my_openri
```

## @ Contact

> For any bug reports, please drop [email](mailto:fh12355@rjh.com.cn).


