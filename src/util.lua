function copy(tab)
  return {unpack(tab)}
end

function countKeys(t)
  local n = 0
  for _ in pairs(t) do
    n = n + 1
  end
  return n
end

-- https://love2d.org/forums/viewtopic.php?p=208676&sid=3b643938f0769ccacdc44af3ea34f09c#p208676
function round(n) return n >= 0 and n - n % -1 or n - n % 1 end

QUANTS = {
  1,
  1 / 2,
  1 / 3,
  1 / 4,
  1 / 6,
  1 / 8,
  1 / 12,
  1 / 16,
  1 / 24,
  1 / 48,
}

function getQuantIndex(beat)
  for i, quant in ipairs(QUANTS) do
    if math.abs(beat - round(beat / quant) * quant) < 0.01 then
      return i
    end
  end
  return #QUANTS
end

function getDivision(quantIdx)
  return 4 / QUANTS[quantIdx]
end

function quantize(beat, quantI)
  local quant = QUANTS[quantI]
  return round(beat / quant) * quant
end

---@param str string
---@param len number
---@param char string?
function lpad(str, len, char)
  char = char or ' '
  return string.rep(char, len - #str) .. str
end

---@param t number
function formatTime(t)
  return lpad(tostring(math.floor(t / 60)), 2, '0') .. ':' .. lpad(tostring(math.floor(t)), 2, '0')
end

---@param o any
function pretty(o, depth, seen)
  depth = depth or 0
  if depth > 4 then
    return '...'
  end
  seen = seen and copy(seen) or {}
  --print(depth, countKeys(seen))
  if type(o) == 'table' then
    if seen[o] then return '(circular)' end
    seen[o] = true
    local keys = countKeys(o)
    local onlyNumbers = true
    for i = 1, keys do
      if rawget(o, i) == nil then
        onlyNumbers = false
        break
      end
    end

    local str = ''
    local linebreaks = false
    local nPos = 0

    if onlyNumbers then
      for i, v in ipairs(o) do
        local s = pretty(v, depth + 1, seen)
        if string.find(s, '\n') or (#str - nPos + #s + depth * 2) > 40 then
          linebreaks = true
          str = str .. '\n'
          str = str .. string.rep('  ', depth)
          nPos = #str
        end
        str = str .. s .. ', '
      end
    else
      for k, v in pairs(o) do
        local ks = (type(k) == 'string' and string.find(k, '^[a-zA-Z0-9_]+$')) and k or ('[' .. pretty(k, depth + 1, seen) .. ']')
        local vs = pretty(v, depth + 1, seen)
        local s = ks .. ' = ' .. vs
        local nPos = (string.find(str, '\n') or 0)
        if string.find(s, '\n') or (#str - nPos + #s + depth * 2) > 40 then
          linebreaks = true
          str = str .. '\n'
          str = str .. string.rep('  ', depth)
          nPos = #str
        end

        str = str .. s .. ', '
      end
    end

    str = string.sub(str, 1, #str - 2)

    if linebreaks then
      if string.sub(str, 1, 1) ~= '\n' then
        str = '\n' .. string.rep('  ', depth) .. str
      end
      str = str .. '\n' .. string.rep('  ', depth - 1) .. '}'
    else
      str = str .. ' }'
    end

    return '{ ' .. str
  elseif type(o) == 'string' then
    return string.format('%q', o)
    --if string.find(o, '\n') then
    --  return '[[' .. string.gsub(o, '\\', '\\\\') .. ']]'
    --else
    --  return '"' .. string.gsub(string.gsub(o, '\\', '\\\\'), '"', '\\"') .. '"'
    --end
  elseif type(o) == 'nil' then
    return 'nil'
  else
    return tostring(o)
  end
end

-- returns true if every value in tab1 matches tab2, and not necessarily the other way round
function looseComp(tab1, tab2)
  for k, v1 in pairs(tab1) do
    local v2 = tab2[k]
    if type(v1) ~= type(v2) then return false end
    if type(v1) == 'table' then
      if not looseComp(v1, v2) then return false end
    else
      if v1 ~= v2 then return false end
    end
  end
  return true
end