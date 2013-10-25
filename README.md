# Excowboy

Elixir Mix task to generate a [cowboy](http://github.com/extend/cowboy) project skeleton.

To use it ...

```
git clone https://github.com/joshrotenberg/excowboy.git
cd excowboy/
mix do archive, local.install
mix excowboy.new my_project
cd my_project
mix deps.get
mix compile
mix run --no-halt
```

.. and point your browser at http://localhost:8080