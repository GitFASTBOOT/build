# Roboleaf configuration files interpreter

Reads and executes Roboleaf product configuration files.

## Usage

`rbcrun` *options* *VAR=value*... *file*

### Options

`-d` *dir*\
Root directory for load("//path",...)

`-c` *text*\
Read script from *text*

`--perf` *file*\
Gather performance statistics and save it to *file*. Use \
`       go tool prof -top`*file*\
to show top CPU users

## Extensions

The runner allows Starlark scripts to use the following features that Bazel's Starlark interpreter does not support:

### Propset Data Type

`propset` is similar to `struct` or `module` (see `starklarkstruct` package in starlark-go)
but allows to set the attribute values for arbitrary attribute names. Thus, with

```
   ps = propset()
```

we can set its arbitrary attributes

```
   ps.x = 1
   ps.y = [1,2]
```

can then reference known attributes

```
   print(ps.x)
```

Just like for a struct or module, propset's currently available attributes can be enumerated with `dir()`, attribute's
presence can be checked with `hasattr()`, and dynamic attribute's value can be retrieved with `getattr()`.

At the same time, a propset can be manipulated as a dictionary, that is, `ps["x"]` is equivalent to `ps.x`.

### Queue

The only loop construct in Starlark is the iteration over an iterable data type. Unfortunately, the built-in iterable
data types cannot be modified when they are iterated over. This makes it very difficult to traverse a tree level by
level which we need to provide the functionality equivalent to what calling
`inherit-product` macro provides in the makefiles. The runner provides an iterable data type called `queue` which can be
updated while iterated over.

It has two methods, `enqueue()` and `dequeue()` with obvious meaning, and allows to write the following code:

```python
def foo():
    q = queue()
    q.push(1)
    for item in q:
        q.dequeue()  # This removes 'item'
        if item == 1:
            q.enqueue(2)

```

the loop body will be executed twice, because during the first iteration `2` will be added to the `q`.

### Load statement URI

Starlark does not define the format of the load statement's first argument. The Roboleaf configuration interpreter
supports the format that Bazel uses (`":file"` or `"//path:file"`). In addition, it allows the URI to end
with `"|symbol"` which defines a single variable
`symbol` with `None` value if a module does not exist. Thus,

```
load(":mymodule.rbc|init", mymodule_init="init")
```

will load the module `mymodule.rbc` and export a symbol `init` in it as `mymodule_init` if
`mymodule.rbc` exists. If `mymodule.rbc` is missing, `mymodule_init` will be set to `None`

### Predefined Symbols

#### rblf_env

A propset containing environment variables. E.g., `rblf_env.USER` is the username when running on Unix.

#### rblf_cli

A propset containing the variable set by the interpreter's command line. That is, running

```
rbcrun FOO=bar myfile.rbc
```

will have the value of `rblf_cli.FOO` be `"bar"`

### Predefined Functions

#### rblf_file_exists(*file*)

Returns `True`  if *file* exists

#### rblf_wildcard(*glob*, *top* = None)

Expands *glob*. If *top* is supplied, expands "*top*/*glob*", then removes "*top*/" prefix from the matching file names.

#### rblf_regex(*pattern*, *text*)

Returns *True* if *text matches *pattern*.

##### loadGenerated

`loadGenerated("cmd", ["arg1", ...])` runs command which generates Starlark script on stdout, which is then executed.