module SymataSyntax

using Symata
using PyCall
using Conda

import Symata: AbstractEvaluateOptions,
    simple, isinteractive, do_we_print_outstring, get_line_number, Null, isymata_mode, isymata_mma_mode

export mathics_REPL, mmasyntax_REPL, mathics_read_evaluate_single_line, symata_expr_to_mma_string

include("version.jl")
include("mathics.jl")

function __init__()
    init_mathics()
    if isymata_mode()  ## Enter Mma syntax mode by default if we are in Jupyter
        isymata_mma_mode(true)
    end
end
        
end # module SymataSyntax
