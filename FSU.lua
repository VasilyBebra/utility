local HttpService = game:GetService("HttpService")

local cfg = {}
cfg.__index = cfg

local jsonEncode = HttpService.JSONEncode
local jsonDecode = HttpService.JSONDecode
local writefile = writefile
local readfile = readfile
local isfile = isfile
local delfile = delfile
local type = type
local typeof = typeof
local next = next

local Serializers = {
 Color3 = function(v) 
  return {__type="Color3", r=v.R, g=v.G, b=v.B} 
 end,
 Vector3 = function(v) 
  return {__type="Vector3", x=v.X, y=v.Y, z=v.Z} 
 end,
 Vector2 = function(v) 
  return {__type="Vector2", x=v.X, y=v.Y} 
 end,
 UDim2 = function(v) 
  return {__type="UDim2", xs=v.X.Scale, xo=v.X.Offset, ys=v.Y.Scale, yo=v.Y.Offset} 
 end,
 CFrame = function(v) 
  local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
  return {
   __type="CFrame", 
   args={x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22}
  } 
 end,
 EnumItem = function(v) 
  return {__type="Enum", k=tostring(v.EnumType), n=v.Name} 
 end
}

local Deserializers = {
 Color3 = function(t) return Color3.new(t.r, t.g, t.b) end,
 Vector3 = function(t) return Vector3.new(t.x, t.y, t.z) end,
 Vector2 = function(t) return Vector2.new(t.x, t.y) end,
 UDim2   = function(t) return UDim2.new(t.xs, t.xo, t.ys, t.yo) end,
 CFrame  = function(t) return CFrame.new(unpack(t.args)) end,
 Enum    = function(t)
  local parts = string.split(t.k, ".")
  local enumName = parts[2] or parts[1]
  local enumLib = Enum[enumName]
  return enumLib and enumLib[t.n]
 end
}

local function DeepSerialize(val)
 local t = typeof(val)
 if t == "table" then
  local newT = {}
  for k, v in next, val do
   newT[k] = DeepSerialize(v)
  end
  return newT
 elseif Serializers[t] then
  return Serializers[t](val)
 end
 return val
end

local function DeepDeserialize(val)
 if type(val) == "table" then
  if val.__type and Deserializers[val.__type] then
   return Deserializers[val.__type](val)
  end
  local newT = {}
  for k, v in next, val do
   newT[k] = DeepDeserialize(v)
  end
  return newT
 end
 return val
end

function cfg.new(fileName, initName)
 return setmetatable({
  file = fileName .. ".json",
  init = (initName or fileName) .. "_init.json"
 }, cfg)
end

function cfg:Save(data)
 writefile(self.file, jsonEncode(HttpService, DeepSerialize(data)))
end

function cfg:Load()
 if not isfile(self.file) then return {} end
 
 local content = readfile(self.file)
 if content == "" then return {} end

 local success, decoded = pcall(jsonDecode, HttpService, content)
 if not success or type(decoded) ~= "table" then return {} end

 return DeepDeserialize(decoded)
end

function cfg:Edit(key, value)
 local currentData = self:Load()
 currentData[key] = value
 self:Save(currentData)
end

function cfg:ConfigExists()
 return isfile(self.file)
end

function cfg:Delete()
 if isfile(self.file) then delfile(self.file) end
end

function cfg:GetInit()
 if not isfile(self.init) then return {} end
 local s, r = pcall(jsonDecode, HttpService, readfile(self.init))
 return s and r or {}
end

function cfg:EditInit(key, value)
 local data = self:GetInit()
 data[key] = value
 writefile(self.init, jsonEncode(HttpService, data))
end

return cfg
