type Unit
	color
	ir::Integer #influence radius
	pl::Array{Int,1} #permitted layers
	passover::Bool
	passoverself::Bool
	inclusive::Bool
	loc
	groundlevel::Bool
	live!::Function
	baselife::Number
	harvest!::Function
	name::String
end
type Board
	shells::Integer #layers of locations to add to the initial ones
	initlocs #initial locations
	grid
	c #GtkCanvas
	sizemod::Number #zoom
	size::Number
	offsetx::Number #pan
	offsety::Number
	bgcolor #background
	gridcolor
end
type Game
	map
	unitparams #to be placed
	color 
	colors
	colind::Integer #index
	colmax::Integer #return to first color after max
	colock::Bool #place a single color
	delete::Bool #delete units
	sequence::Array{Any} #Tuple{Tuple{Int64,Int64,Int64},Any},1} #placed units and performed harvests
	board::Board
	printscore::Bool
	points
	season::Integer #number of harvests
	win #GtkWindow
	window #initial aspect ratio
	lifemap
end
