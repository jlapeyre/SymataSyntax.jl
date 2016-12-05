using PyCall

import Symata.SymataIO: symata_to_mma_fullform_string

const mathics = PyCall.PyNULL()
const symatapy = PyCall.PyNULL()

type MathicsREPL
    TerminalShell
    shell
    evaluation
    definitions
end

pynull() = PyCall.PyNULL()
MathicsREPL() = MathicsREPL(pynull(),pynull(),pynull(),pynull())

const symata_mma_repl = MathicsREPL()
const mathics_repl = MathicsREPL()

const symatapydir = joinpath(dirname(@__FILE__), "..", "pysrc")






function set_TerminalShell(toplevel, shell, repl::MathicsREPL)
    copy!(repl.TerminalShell, toplevel[shell])
    nothing
end

set_symataTerminalShell() = set_TerminalShell(symatapy, :SymataTerminalShell, symata_mma_repl)
set_mathicsTerminalShell() = set_TerminalShell(mathics[:main], :TerminalShell, mathics_repl)

function populateMathicsREPL(repl::MathicsREPL)
    copy!(repl.definitions,  mathics[:core][:definitions][:Definitions](add_builtin=true))
    copy!(repl.shell,  repl.TerminalShell(repl.definitions, "Linux", true, true))
    copy!(repl.evaluation,  mathics[:core][:evaluation][:Evaluation](repl.definitions, output=mathics[:main][:TerminalOutput](repl.shell)))
    nothing
end

function make_mmasyntax_repl()
    set_symataTerminalShell()
    populateMathicsREPL(symata_mma_repl)
end

function make_mathics_repl()
    set_mathicsTerminalShell()
    populateMathicsREPL(mathics_repl)
end

function import_mathics()
    copy!(mathics, PyCall.pyimport_conda("mathics", "mathics"))
end

function import_symatapy()
    push!(pyimport("sys")["path"], symatapydir)
    copy!(symatapy, pyimport("symatapy"))
end

function init_mathics()
    pyimport("mathics.main")
    pyimport("mathics.core")
    pyimport("mathics.core.definitions")
    pyimport("mathics.core.evaluation")
    pyimport("mathics.core.parser")
    import_mathics()
    import_symatapy()
    make_mmasyntax_repl()
    make_mathics_repl()
    nothing
end

#     copy!(symatadefinitions, mathics[:core][:definitions][:Definitions](add_builtin=true))
#     copy!(mathicsdefinitions, mathics[:core][:definitions][:Definitions](add_builtin=true))
#     copy!(symatashell, symataTerminalShell(symatadefinitions, "Linux", true, true))
#     copy!(mathicsshell, mathicsTerminalShell(mathicsdefinitions, "Linux", true, true))
#     copy!(mathicsevaluation, mathics[:core][:evaluation][:Evaluation](mathicsdefinitions, output=mathics[:main][:TerminalOutput](mathicsshell)))
#     copy!(symataevaluation, mathics[:core][:evaluation][:Evaluation](symatadefinitions, output=mathics[:main][:TerminalOutput](symatashell)))
# end

    # copy!(symataTerminalShell, symatapy[:SymataTerminalShell])
    # copy!(mathicsTerminalShell, mathics[:main][:TerminalShell])
# const mathicsevaluation = PyCall.PyNULL()
# const symatashell = PyCall.PyNULL()
# const mathicsshell = PyCall.PyNULL()
# const symatadefinitions = PyCall.PyNULL()
# const mathicsdefinitions = PyCall.PyNULL()


mathicstype(ex::PyObject) = pytypeof(ex)[:__name__]

## For the moment we strip all context information from symbols.
function mathics_to_symata_symbol(s::String)
    rg = r"\`([^\`]+)$"
    ma = match(rg, s)
    return ma !== nothing ? Symbol(ma.captures[1]) : Symbol(s)
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

parseline(repl) = repl.evaluation[:parse_feeder](repl.shell)

## This type is used in Symata to control evaluation

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
    repl = symata_mma_repl
    while true
        ex =
            try
                repl.shell[:set_inputno](get_line_number())
                expr = parseline(repl)
                mathics_to_symata(expr)
            catch e
                isa(e, PyCall.PyError) && pystring(e.val) == "EOFError()" && break
                warn("parse error ",e)
            finally
                repl.shell[:reset_lineno]()
            end
        ex == exitexpr && break
        res = Symata.symataevaluate(ex, evalopts)  ## use the Symata evaluation sequence
        if (res !== nothing) && (res != Null)
            resmathics = repl.evaluation[:parse](Symata.SymataIO.symata_to_mma_fullform_string(res))
            restring = repl.evaluation[:format_output](resmathics)
            println(restring)
        end
        println()
    end
end

"""
    mathics_REPL()

enter the mathics REPL. This is independent of Symata.
Enter `ctrl-d` to exit this REPL.
"""
function mathics_REPL()
    symatapy[:mathics_shell](mathics_repl.shell)
end
