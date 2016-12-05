# SymataSyntax

Mathematica syntax for Symata

<!-- [![Build Status](https://travis-ci.org/jlapeyre/SymataSyntax.jl.svg?branch=master)](https://travis-ci.org/jlapeyre/SymataSyntax.jl) -->

<!-- [![Coverage Status](https://coveralls.io/repos/jlapeyre/SymataSyntax.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/jlapeyre/SymataSyntax.jl?branch=master) -->

<!-- [![codecov.io](http://codecov.io/github/jlapeyre/SymataSyntax.jl/coverage.svg?branch=master)](http://codecov.io/github/jlapeyre/SymataSyntax.jl?branch=master) -->

This package provides Mathematica syntax for [`Symata`](https://github.com/jlapeyre/Symata.jl). This package is unrelated to and independent of
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

### Mathematica-syntax mode

Enter Mathematica-syntax mode with the Symata command `MmaSyntax()`. Return to the standard Symata-syntax mode by typing `ctrl-d`.
The Symata command `MmaSyntax()` will try to load `SymataSyntax.jl`.

```
symata 1> Table(i^2, [i, 1, 10])
Out(1) = [1,4,9,16,25,36,49,64,81,100]

symata 2> MmaSyntax()
In[2]:= ex = Table[x^i, {i,1,5}]
Out[2]= {x, x ^ 2, x ^ 3, x ^ 4, x ^ 5}

In[3]:=     # type ctrl-d to exit MmaSyntax mode
symata 3> ex
Out(3) = [x,x^2,x^3,x^4,x^5]
```

### Mathics mode

Enter the mathics REPL with the command `Mathics()`. Return to Symata by typing `ctrl-d`.
At present, the Symata and mathics processes cannot communicate.


## Symata, sympy, mpmath, and mathics

`SymataSyntax` and `Symata` rely on the following excellent software projects (in addition to Julia!).

[Sympy](http://www.sympy.org/en/index.html) is an active python project that implements a very large number of algebraic-manipulation algorithms
and other general-purpose symbolic mathematics functions.

[mpmath](http://mpmath.org/) is a python library for arbitrary precision arithmetic. It implements a very large number of mathematical functions.

[mathics](http://www.mathics.org) is reimplementation of the Mathematica language in python. This is a volunteer, open-source project that
is completely unrelated to Wolfram Mathematica software. Neither mathics nor Symata are supported in any way by the Wolfram company. mathics
has implemented a very large part of the core of the language as well as many peripheral functions and packages. It reproduces the behavior very
well and is very well documented. At present, mathics is more complete than
Symata. However, mathics is rather slow in many cases, and is very slow in many cases. (The developers are working to improve performance).
Symata is faster than mathics in all examples I have tried, and in some cases is much faster (by factors of perhaps of 5 to 1000). In general, the larger
the expression, the larger the difference in performance.

Symata is fast enough for practical applications. I will release a notebook used for research once the corresponding manuscript is submitted.
There are many optimizations that can be made to Symata with varying amounts of effort. However, pieces of Symata are regularly redesigned,
so optimizing is not a good use of resources at this point.

<!--  LocalWords:  SymataSyntax Mathematica Symata codecov io WRI jl
 -->
<!--  LocalWords:  mathics julia Conda sympy conda dir ROOTENV ctrl
 -->
<!--  LocalWords:  symata mpmath reimplementation
 -->
