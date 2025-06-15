local Telescopable = Class(function(self, inst)
    self.inst = inst
    self.canspell = true
    self.ontelescopefn = nil
end)

function Telescopable:look_through_telescope(pt, caster)
    if self.ontelescopefn ~= nil then
        self.ontelescopefn(self.inst, pt, caster)
    end
    return true
end

return Telescopable
