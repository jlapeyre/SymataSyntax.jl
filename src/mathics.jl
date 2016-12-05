using PyCall

import Symata.SymataIO: symata_to_mma_fullform_string

pynull() = PyCall.PyNULL()

#### Setup REPLs

const mathics = pynull()
const symatapy = pynull()

type MathicsREPL
    TerminalShell
    shell
    evaluation
    definitions
end

MathicsREPL() = MathicsREPL(pynull(),pynull(),pynull(),pynull())

const symata_mma_repl = MathicsREPL()
const mathics_repl = MathicsREPL()

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

import_mathics() = copy!(mathics, PyCall.pyimport_conda("mathics", "mathics"))

const symatapydir = joinpath(dirname(@__FILE__), "..", "pysrc")
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


#### Running REPLs and translating


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
    h == "Symbol" && return mathics_to_symata_symbol(ex[:name])
    haskey(ex, :value) && return ex[:value]
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

"""
    mathics_read_evaluate_single_line(s::String)

parses the mathics expression `s`, evaluates it with the mathics evaluation sequence and
returns the result as a string.
"""
function mathics_read_evaluate_single_line(instr)
    symatapy[:read_and_evaluate](mathics_repl.evaluation,instr)
end

# For example:
# julia> mathics_read_evaluate_single_line("MathMLForm[Table[i, {i,3}]]")
# "<math><mrow><mo>{</mo> <mrow><mn>1</mn> <mo>,</mo> <mn>2</mn> <mo>,</mo> <mn>3</mn></mrow> <mo>}</mo></mrow></math>"

# This formats the expressionw without evaluating it.
# mathics_read_evaluate_single_line("MathMLForm[HoldForm[{1, 2, 3} ]]")


# function read_file(fname)
#     feeder
# end

    # if args.FILE is not None:
    #     feeder = FileLineFeeder(args.FILE)
    #     try:
    #         while not feeder.empty():
    #             evaluation = Evaluation(
    #                 shell.definitions, output=TerminalOutput(shell), catch_interrupt=False)
    #             query = evaluation.parse_feeder(feeder)
    #             if query is None:
    #                 continue
    #             evaluation.evaluate(query, timeout=settings.TIMEOUT)
    #     except (KeyboardInterrupt):
    #         print('\nKeyboardInterrupt')

    #     if args.persist:
    #         definitions.set_line_no(0)
    #     else:
    #         return

