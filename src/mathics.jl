using PyCall

import Symata.SymataIO: symata_to_mma_fullform_string

const mathics = PyCall.PyNULL()
const symataTerminalShell = PyCall.PyNULL()
const mathicsTerminalShell = PyCall.PyNULL()
const symataevaluation = PyCall.PyNULL()
const mathicsevaluation = PyCall.PyNULL()
const symatashell = PyCall.PyNULL()
const mathicsshell = PyCall.PyNULL()
const symatadefinitions = PyCall.PyNULL()
const mathicsdefinitions = PyCall.PyNULL()
const symatapy = PyCall.PyNULL()

function import_mathics()
    copy!(mathics, PyCall.pyimport_conda("mathics", "mathics"))
end

function init_mathics()
    symatapydir = joinpath(dirname(@__FILE__), "..", "pysrc")
    push!(pyimport("sys")["path"], symatapydir)
    import_mathics()
    pyimport("mathics.main")
    pyimport("mathics.core")
    pyimport("mathics.core.definitions")
    pyimport("mathics.core.evaluation")
    pyimport("mathics.core.parser")
    copy!(symatapy, pyimport("symatapy"))
    copy!(symataTerminalShell, symatapy[:SymataTerminalShell])
    copy!(mathicsTerminalShell, mathics[:main][:TerminalShell])
    make_mmasyntax_REPL()
    nothing
end

function make_mmasyntax_REPL()
    copy!(symatadefinitions, mathics[:core][:definitions][:Definitions](add_builtin=true))
    copy!(mathicsdefinitions, mathics[:core][:definitions][:Definitions](add_builtin=true))
    copy!(symatashell, symataTerminalShell(symatadefinitions, "Linux", true, true))
    copy!(mathicsshell, mathicsTerminalShell(mathicsdefinitions, "Linux", true, true))
    copy!(mathicsevaluation, mathics[:core][:evaluation][:Evaluation](mathicsdefinitions, output=mathics[:main][:TerminalOutput](mathicsshell)))
    copy!(symataevaluation, mathics[:core][:evaluation][:Evaluation](symatadefinitions, output=mathics[:main][:TerminalOutput](symatashell)))
end

mathicstype(ex::PyObject) = pytypeof(ex)[:__name__]

function mathics_to_symata_symbol(s::String)
    rg = r"\`([^\`]+)$"
    ma = match(rg, s)
    if ma !== nothing
        return Symbol(ma.captures[1])
    else
        return Symbol(s)
    end
end

function mathics_to_symata(ex::PyObject)
    h = mathicstype(ex)
    if h == "Expression"
        s = ex[:head][:name]
        return mxpr(mathics_to_symata_symbol(s), map(mathics_to_symata, ex[:leaves]))
    end
    if h == "Symbol"
        return mathics_to_symata_symbol(ex[:name])
    end
    if haskey(ex, :value)
        return ex[:value]
    end
    warn("Unable to translate $ex")
end

## Null, or pass through, or ... ?
mathics_to_symata(x) = Symata.Null

function symataparseline()
    symataevaluation[:parse_feeder](symatashell)
end

type EvaluateMmaSyntax <: AbstractEvaluateOptions
end

function prompt(opt::EvaluateMmaSyntax)
    if (! simple(opt) ) && isinteractive() && do_we_print_outstring
        print("Out[" * string(get_line_number()) * "]= ")
    end
    nothing
end

simple(opt::EvaluateMmaSyntax) = false

"""
    mmasyntax_REPL()

enter the Symata REPL in which input and output follow Mathematica syntax.
Enter `ctrl-d` to exit this mode.
"""
function mmasyntax_REPL()
    exitexpr = mxpr(:ExitMathics)
    evalopts = EvaluateMmaSyntax()
    while true
        ex =
            try
                #                print(input_prompt())  # we do this in python
                symatashell[:set_lineno](get_line_number())
                expr = symataparseline()
                mathics_to_symata(expr)
            catch e
                isa(e, PyCall.PyError) && pystring(e.val) == "EOFError()" && break
                warn("parse error ",e)
            end
        if ex == exitexpr
            break
        end
        res = Symata.symataevaluate(ex, evalopts)
        if (res === nothing) || (res == Null)
            println()
            continue
        end
        resmathics = symataevaluation[:parse](Symata.SymataIO.symata_to_mma_fullform_string(res))
        restring = symataevaluation[:format_output](resmathics)
        println(restring)
        println()
    end
end

"""
    mathics_REPL()

enter the mathics REPL. This is independent of Symata.
Enter `ctrl-d` to exit this REPL.
"""
function mathics_REPL()
    symatapy[:mathics_shell](mathicsshell)
end
