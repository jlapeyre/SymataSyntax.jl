# SymataSyntax

Mathematica syntax for Symata

[![Build Status](https://travis-ci.org/jlapeyre/SymataSyntax.jl.svg?branch=master)](https://travis-ci.org/jlapeyre/SymataSyntax.jl)

[![Coverage Status](https://coveralls.io/repos/jlapeyre/SymataSyntax.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/jlapeyre/SymataSyntax.jl?branch=master)

[![codecov.io](http://codecov.io/github/jlapeyre/SymataSyntax.jl/coverage.svg?branch=master)](http://codecov.io/github/jlapeyre/SymataSyntax.jl?branch=master)

This package provides Mathemtatica syntax for [`Symata`](https://github.com/jlapeyre/Symata.jl). This package is unrelated to and independent of
Mathematica and Wolfram language software from WRI. `SymataSyntax` uses the python package [mathics](http://www.mathics.org) for parsing and
formatting.

## Requirements

`SymataSyntax` can be installed like this

```julia
julia> Pkg.clone("https://github.com/jlapeyre/SymataSyntax.jl")
```

`SymataSyntax` requires a development version of `Symata.jl`. You can install and switch to the development version like this

```julia
julia> Pkg.add("Symata")
julia> Pkg.checkout("Symata")
```

See the [`Symata` page](https://github.com/jlapeyre/Symata.jl) for more details.

`SymataSyntax`  requires the python package `mathics`. 
At the moment, mathics cannot be installed automatically via `Conda.jl`. mathics can be installed using `pip`.
The recommended way to install `Symata` is using `Conda.jl`, which installs `python` and `sympy` in your collection of Julia packages in the `Conda` directory.
The program `pip` will also be installed (at least on Linux). The location of the python binaries, `python`, `conda`, `pip`, etc can be found as follows

```julia
julia> Using Conda
julia> Conda.bin_dir(Conda.ROOTENV)
"/home/someuser/.julia/v0.6/Conda/deps/usr/bin"
```

In this case, `mathics` can by installed from a shell like this

```
/home/someuser/.julia/v0.6/Conda/deps/usr/bin/pip install mathics
```

## Using SymataSyntax

Enter Mathematica-syntax mode with the Symata command `Mathics()`. Return to the standard Symata-syntax mode by typing `ctrl-d`.

```
symata 1> Table(i^2, [i, 1, 10])
Out(1) = [1,4,9,16,25,36,49,64,81,100]

symata 2> Mathics()
In[2]:= ex = Table[x^i, {i,1,5}]
Out[2]= {x, x ^ 2, x ^ 3, x ^ 4, x ^ 5}

In[3]:=     # type ctrl-d to exit Mathics mode
symata 3> ex
Out(3) = [x,x^2,x^3,x^4,x^5]
```
