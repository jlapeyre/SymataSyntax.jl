## Does not work
## VERSION >= v"0.4.0-dev+6521" && __precompile__    

module SymataSyntax

using Symata
using Conda

import Symata: AbstractEvaluateOptions, prompt, simple, isinteractive, do_we_print_outstring, get_line_number, Null
export mathics_REPL

syminfo(msg) = "SymataSyntax: " * msg

find_conda_fail(dir) = error(syminfo("required directory (folder) \"$dir\" not found."))
find_mathics_fail(dir) = error(syminfo("mathics installation directory (folder) \"$dir\" not found."))

function _mathics_dir()
    conda_lib_dir = Conda.lib_dir(Conda.ROOTENV)
    conda_site_packages_dir = joinpath(conda_lib_dir, "python2.7", "site-packages")
    conda_mathics_dir = joinpath(conda_site_packages_dir, "mathics")
    isdir(conda_lib_dir) || return find_conda_fail(conda_lib_dir)
    isdir(conda_site_packages_dir) || return find_conda_fail(conda_site_packages_dir)
    isdir(conda_mathics_dir) || return find_mathics_fail(conda_mathics_dir)
    conda_mathics_dir
end

const main_symata_py = joinpath(dirname(@__FILE__), "..", "deps", "main.symata.py")

function read_file(path)
    stream = open(path,"r")
    contents = readstring(stream)
    close(stream)
    contents
end

const main_symata_py_source = read_file(main_symata_py)

function _copy_modified_main()
    assert(isfile(main_symata_py))
    mathics_dir = _mathics_dir()
    installed_mathics_main = joinpath(mathics_dir, "main.py")
    isfile(installed_mathics_main) || error(syminfo("required file \"$installed_mathics_main\" not found."))
    installed_mathics_py_source = read_file(installed_mathics_main)
    if installed_mathics_py_source == main_symata_py_source
        info(syminfo("modified main.py alread installed"))
        return
    end
    origbackup = joinpath(mathics_dir, "main.orig.py")
    if ! isfile(origbackup)
        info(syminfo("No backup of original mathics main.py found. Backing up the assumed original"))
        cp(installed_mathics_main, origbackup)
        isfile(origbackup) || error(syminfo("Unable to backup original mathics main.py to $origbackup"))
    end
    newbackup = joinpath(mathics_dir, "main.back.py")
    cp(installed_mathics_main, newbackup, remove_destination=true)
    isfile(newbackup) || error(syminfo("Unable to backup mathics main.py to $newbackup"))
    info(syminfo("installing modified main.py"))
    cp(main_symata_py, installed_mathics_main, remove_destination=true)
    nothing
end

include("mathics.jl")

function __init__()
    _copy_modified_main()
    init_mathics()
end
        
end # module SymataSyntax
