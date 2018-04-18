#module Hexiqi


#storage[:connectivity]=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]

#g=makegrid(2)
#@assert length(g)==43


function surrounded(layer::Integer)
	checked=[(0,0,2)]
	points=Dict()
	for (loc,col) in storage[:map]
		if col==0
			if !in(loc,checked)
				push!(checked,loc)
				locs=[loc]
				check=adjacent(loc)
				while !empty(check)
					ncheck=Array{Tuple,1}()
					for ch in check
						col=storage[:map][ch]
						if col==0

						end
					end
				end
			end
		end
	end
end

function score()
	claims=Dict()
	for player in 1:storage[:np]
		checked=Tuple[]
		for hexp in storage[:map]
			hex,p=hexp
			if p==player
				if in(hex,keys(claims)) 
					if claims[hex][p]<1
						claims[hex][p]=1.0
					end
				else
					a=zeros(storage[:np])
					a[p]=1.0
					claims[hex]=a
				end
				for ahex in adjacent(hex)
					if !in(ahex,checked) && in(ahex,storage[:grid])
						if in(ahex,keys(claims)) 
							if claims[ahex][p]<0.5
								claims[ahex][p]=0.5
							end
						else
							a=zeros(storage[:np])
							a[p]=0.5
							claims[ahex]=a
						end
					end
				end
				push!(checked,hex)
			end
		end
	end
	scores=zeros(storage[:np])
	for hexa in claims
		hex,a=hexa
		m=maximum(a)
		inds=findin(a,m)
		l=length(inds)
		for p in inds
			scores[p]+=1/l #add complementary harvesting, two 0.5 claims don't conflict since one can't harvest all
		end #subtract 0.001 per unit
	end
	maxpoints=length(storage[:map])
	return scores,maxpoints
end



#end
