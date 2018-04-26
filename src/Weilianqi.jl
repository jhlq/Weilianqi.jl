module Weilianqi
export newgame, printpoints, allunitsharvest!, save, loadgame, loadsequence!, expandboard!, checkharvest, center, setcolorset
using Gtk, Graphics

dir=joinpath(homedir(),"weilianqi","saves")
if !ispath(dir)
	mkpath(dir)
end

include("qi.jl")

end # module
