module SymataSyntax

using Symata
using Conda

import Symata: AbstractEvaluateOptions, prompt, simple, isinteractive, do_we_print_outstring, get_line_number, Null
export mathics_REPL, mmasyntax_REPL, mathics_read_evaluate_single_line, symata_expr_to_mma_string

include("version.jl")
include("mathics.jl")

function __init__()
    init_mathics()
    if Symata.isymata_mode()  ## Enter Mma syntax mode by default if we are in Jupyter
        Symata.isymata_mma_mode(true)
    end
end
        
end # module SymataSyntax
