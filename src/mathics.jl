using PyCall

import Symata.SymataIO: symata_to_mma_fullform_string

const mathics = PyCall.PyNULL()
const mathicscore = PyCall.PyNULL()
const mathicsparser = PyCall.PyNULL()
const mathicsTerminalShell = PyCall.PyNULL()
const mathicsevaluation = PyCall.PyNULL()
const mathicsResult = PyCall.PyNULL()
const mathicsshell = PyCall.PyNULL()
const mathicsdefinitions = PyCall.PyNULL()

function import_mathics()
    copy!(mathics, PyCall.pyimport_conda("mathics", "mathics"))
end

function init_mathics()
    import_mathics()
    pyimport("mathics.main")
    pyimport("mathics.core")
    pyimport("mathics.core.definitions")
    pyimport("mathics.core.evaluation")
    pyimport("mathics.core.parser")
    copy!(mathicsTerminalShell, mathics[:main][:SymataTerminalShell])
    make_mathics_REPL()
    nothing
end

function make_mathics_REPL()
    copy!(mathicscore, mathics[:core])
    copy!(mathicsparser, mathics[:core][:parser])
    copy!(mathicsdefinitions, mathics[:core][:definitions][:Definitions](add_builtin=true))
    copy!(mathicsshell, mathicsTerminalShell(mathicsdefinitions, "Linux", true, true))
    copy!(mathicsevaluation, mathics[:core][:evaluation][:Evaluation](mathicsdefinitions, output=mathics[:main][:TerminalOutput](mathicsshell)))
    copy!(mathicsResult, mathics[:core][:evaluation][:Result])
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

function mathicsparseline()
    mathicsevaluation[:parse_feeder](mathicsshell)
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

#input_prompt() = "In[" * string(get_line_number()) * "] := "

"""
    mathics_REPL()

enter the Symata REPL in which input and output follow Mathematica syntax.
Enter `ctrl-d` to exit this mode.
"""
function mathics_REPL()
    exitexpr = mxpr(:ExitMathics)
    evalopts = EvaluateMmaSyntax()
    while true
        ex =
            try
                #                print(input_prompt())  # we do this in python
                mathicsshell[:set_lineno](get_line_number())
                expr = mathicsparseline()
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
        resmathics = mathicsevaluation[:parse](Symata.SymataIO.symata_to_mma_fullform_string(res))
        restring = mathicsevaluation[:format_output](resmathics)
        println(restring)
        println()
    end
end
