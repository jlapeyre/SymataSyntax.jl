module SymataSyntax

using Symata
using Conda

import Symata: AbstractEvaluateOptions, prompt, simple, isinteractive, do_we_print_outstring, get_line_number, Null
export mathics_REPL, mmasyntax_REPL, mathics_read_evaluate_single_line

include("mathics.jl")

function __init__()
    init_mathics()
end
        
end # module SymataSyntax
