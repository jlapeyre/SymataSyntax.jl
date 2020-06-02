__precompile__(false)

module SymataSyntax

using Symata
using PyCall
#using Conda

import Symata: AbstractEvaluateOptions,
    simple, isinteractive, do_we_print_Out_label, get_line_number, Null, isymata_mma_mode
# isymata_mode

export mathics_REPL, mmasyntax_REPL, mathics_read_evaluate_single_line, symata_expr_to_mma_string

include("version.jl")
include("mathics.jl")

function __init__()
    init_mathics()
    # FIXME: See note in Symata/src/kernelstate.jl
#    if isymata_mode()  ## Enter Mma syntax mode by default if we are in Jupyter
#        isymata_mma_mode(true)
    #    end
    # Following is a test to see if I can find a way around a segfault.
    # It does not solve the problem
    # Calling the following causes a segfault
    py"""
    import mathics
    def get_definitions():
        return mathics.core.definitions.Definitions(add_builtin=True)

    """
end

end # module SymataSyntax
