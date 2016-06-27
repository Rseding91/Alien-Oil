for k,force in pairs(game.forces) do
  local technologies = force.technologies
  
  if technologies["alien-technology"].researched then
    force.recipes["alien-compass"].enabled = true
  end
end