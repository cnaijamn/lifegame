lifegame
========

Conway's Game of Life.

* [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life)
* [ライフゲーム](https://ja.wikipedia.org/wiki/%E3%83%A9%E3%82%A4%E3%83%95%E3%82%B2%E3%83%BC%E3%83%A0)
* [cl-charms](https://github.com/HiTECNOLOGYs/cl-charms)

Installation
------------

    $ cd $QUICKLISP/local-projects
    $ git clone https://github.com/cnaijamn/lifegame.git
    $ sbcl
    * (ql:register-local-projects)

Example
-------

    (ql:quickload :lifegame)
    (lifegame:run)
