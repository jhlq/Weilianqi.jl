module Weilianqi
export newgame,printpoints,harvest,zoom, save, load, loadsequence!
using Gtk, Graphics

include("qi.jl")

dir=joinpath(homedir(),"weilianqi","saves")
if !ispath(dir)
	mkpath(dir)
end

end # module
