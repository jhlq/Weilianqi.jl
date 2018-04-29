module Weilianqi
export newgame, save, loadgame, expandboard!, checkharvest, center, setcolorset, getgroup, newunit, units, sync!, string2game
using Gtk, Graphics

dir=joinpath(homedir(),"weilianqi","saves")
if !ispath(dir)
	mkpath(dir)
end

include("qi.jl")

end # module
