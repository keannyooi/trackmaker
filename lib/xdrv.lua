local M = {}

local SEGMENT_INCR = 1 -- beats

local function gcd(m, n)
  local iters = 0
  while n ~= 0 do
    iters = iters + 1
    if iters > 9999 then
      print('gcd infloop ', m, n)
      return m
    end
    local q = m
    m = n
    n = q % n
  end
  return m
end

local function lcm(m, n)
  return ( m ~= 0 and n ~= 0 ) and m * n / gcd( m, n ) or 0
end

local QUANTS = {
  1,
  1 / 2,
  1 / 3,
  1 / 4,
  1 / 5,
  1 / 6,
  1 / 8,
  1 / 12,
  1 / 16,
  1 / 24,
  1 / 48,
}

local function getQuantIndex(beat)
  for i, quant in ipairs(QUANTS) do
    if math.abs(beat - round(beat / quant) * quant) < 0.01 then
      return i
    end
  end
  return #QUANTS
end

local function getDivision(beat)
  return 1 / QUANTS[getQuantIndex(beat)]
end

---@enum XDRVDifficulty
M.XDRVDifficulty = {
  Beginner = 0,
  Normal = 1,
  Hyper = 2,
  Extreme = 3,
}

---@class XDRVMetadata @ https://github.com/Dylannichols702/SCXEditor/blob/d3339f664c739a3d7d9120c8411192bbb3a1779a/SCXEditor/SCXEditor/Models/XDRV/XDRV.cs#L465
---@field musicTitle string @ MUSIC_TITLE
---@field alternateTitle string @ ALTERNATE_TITLE
---@field musicArtist string @ MUSIC_ARTIST
---@field musicAudio string @ MUSIC_AUDIO
---@field jacketImage string @ JACKET_IMAGE
---@field jacketIllustrator string @ JACKET_ILLUSTRATOR
---@field chartAuthor string @ CHART_AUTHOR
---@field chartUnlock string @ CHART_UNLOCK
---@field stageBackground string @ STAGE_BACKGROUND
---@field modfilePath string @ MODFILE_PATH
---@field chartLevel number @ CHART_LEVEL
---@field chartDisplayBPM number @ CHART_DISPLAY_BPM
---@field chartBoss boolean @ CHART_BOSS
---@field disableLeaderboardUploading boolean @ DISABLE_LEADERBOARD_UPLOADING
---@field rpcHidden boolean @ RPC_HIDDEN
---@field isFlashTrack boolean @ FLASH_TRACK
---@field isKeyboardOnly boolean @ KEYBOARD_ONLY
---@field isOriginal boolean @ ORIGINAL
---@field musicPreviewStart number @ MUSIC_PREVIEW_START
---@field musicPreviewLength number @ MUSIC_PREVIEW_LENGTH
---@field musicVolume number @ MUSIC_VOLUME
---@field musicOffset number @ MUSIC_OFFSET
---@field chartBPM number @ CHART_BPM
---@field chartTags { [1]: number, [2]: number, [3]: number, [4]: number } @ CHART_TAGS
---@field chartDifficulty XDRVDifficulty @ CHART_DIFFICULTY

local function parseString(s)
  if type(s) ~= 'string' then return '' end
  return s
end

local function parseFloat(s)
  return tonumber(s) or -1
end

function round(n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end
local function parseInt(s)
  return round(parseFloat(s))
end

local function parseBool(s)
  return s == 'TRUE'
end

local function parseDifficulty(s)
  if s == 'BEGINNER' then return M.XDRVDifficulty.Beginner end
  if s == 'NORMAL'   then return M.XDRVDifficulty.Normal   end
  if s == 'HYPER'    then return M.XDRVDifficulty.Hyper    end
  if s == 'EXTREME'  then return M.XDRVDifficulty.Extreme  end

  return M.XDRVDifficulty.Beginner
end

local function formatString(s)
  return s
end
local function formatFloat(n)
  return tostring(n)
end
local function formatInt(n)
  return tostring(round(n))
end
local function formatBool(b)
  return b and 'TRUE' or 'FALSE'
end
local function formatDifficulty(d)
  if d == M.XDRVDifficulty.Beginner then return 'BEGINNER' end
  if d == M.XDRVDifficulty.Normal   then return 'NORMAL'   end
  if d == M.XDRVDifficulty.Hyper    then return 'HYPER'    end
  if d == M.XDRVDifficulty.Extreme  then return 'EXTREME'  end
  return 'BEGINNER'
end
M.formatDifficulty = formatDifficulty
function M.formatDifficultyShort(d)
  if d == M.XDRVDifficulty.Beginner then return 'BG' end
  if d == M.XDRVDifficulty.Normal   then return 'NM' end
  if d == M.XDRVDifficulty.Hyper    then return 'HY' end
  if d == M.XDRVDifficulty.Extreme  then return 'EX' end
  return 'BG'
end

---@enum XDRVLane
M.XDRVLane = {
  Left = 1,
  Right = 2,
}

---@enum XDRVDriftDirection
M.XDRVDriftDirection = {
  Left = 1,
  Right = 2,
  Neutral = 3,
}

---@alias XDRVNoteColumn 1 | 2 | 3 | 4 | 5 | 6

---@alias XDRVNote { beat: number, note: { column: XDRVNoteColumn, length: number? } }
---@alias XDRVHoldStart { beat: number, holdStart: { column: XDRVNoteColumn } }
---@alias XDRVHoldEnd { beat: number, holdEnd: { column: XDRVNoteColumn } }
---@alias XDRVGearShift { beat: number, gearShift: { lane: XDRVLane, length: number } }
---@alias XDRVGearShiftStart { beat: number, gearShiftStart: { lane: XDRVLane } }
---@alias XDRVGearShiftEnd { beat: number, gearShiftEnd: { lane: XDRVLane } }
---@alias XDRVDrift { beat: number, drift: { direction: XDRVDriftDirection } }
---@alias XDRVBPMChange { beat: number, bpm: number }
---@alias XDRVWarp { beat: number, warp: number }
---@alias XDRVStop { beat: number, stop: number }
---@alias XDRVStopSeconds { beat: number, stopSeconds: number }
---@alias XDRVScroll { beat: number, scroll: number }
---@alias XDRVTimeSignature { beat: number, timeSignature: { [1]: number, [2]: number } }
---@alias XDRVComboTicks { beat: number, comboTicks: number }
---@alias XDRVLabel { beat: number, label: string }
---@alias XDRVFake { beat: number, fake: number }
---@alias XDRVSceneEvent { beat: number, event: { name: string, args: string[] } }
---@alias XDRVCheckpoint { beat: number, checkpoint: string }
---@alias XDRVEvent XDRVNote | XDRVHoldStart | XDRVHoldEnd | XDRVGearShift | XDRVGearShiftStart | XDRVGearShiftEnd | XDRVDrift | XDRVBPMChange | XDRVWarp | XDRVStop | XDRVStopSeconds | XDRVScroll | XDRVTimeSignature | XDRVComboTicks | XDRVLabel | XDRVFake | XDRVSceneEvent | XDRVCheckpoint

---@return XDRVEvent?
local function parseTimingSegment(beat, s)
  s = string.sub(s, 2) -- remove leading #
  local eq = string.find(s, '=')
  if not eq then return nil end
  local key = string.sub(s, 1, eq - 1)
  local value = string.sub(s, eq + 1)

  local args = {}
  for arg in string.gmatch(value, '([^,]+)') do
    table.insert(args, arg)
  end

  if key == 'BPM' then
    return {
      beat = beat,
      bpm = tonumber(args[1]),
    }
  elseif key == 'WARP' then
    return {
      beat = beat,
      warp = tonumber(args[1]),
    }
  elseif key == 'STOP' then
    return {
      beat = beat,
      stop = tonumber(args[1]),
    }
  elseif key == 'STOP_SECONDS' then
    return {
      beat = beat,
      stopSeconds = tonumber(args[1]),
    }
  elseif key == 'SCROLL' then
    return {
      beat = beat,
      scroll = tonumber(args[1]),
    }
  elseif key == 'TIME_SIGNATURE' then
    return {
      beat = beat,
      timeSignature = { tonumber(args[1]), tonumber(args[2]) },
    }
  elseif key == 'COMBO_TICKS' then
    return {
      beat = beat,
      comboTicks = tonumber(args[1]),
    }
  elseif key == 'COMBO' then
    -- unused
  elseif key == 'LABEL' then
    return {
      beat = beat,
      label = args[1],
    }
  elseif key == 'FAKE' then
    return {
      beat = beat,
      fake = tonumber(args[1]),
    }
  elseif key == 'EVENT' then
    local name = args[1]

    local eventArgs = {}
    for i = 2, #args do
      table.insert(eventArgs, args[i])
    end

    return {
      beat = beat,
      event = { name = name, args = eventArgs }
    }
  elseif key == 'CHECKPOINT' then
    return {
      beat = beat,
      checkpoint = args[1],
    }
  end

  return nil
end

---@param events XDRVEvent[]
---@return XDRVEvent[]
function M.addHoldEnds(events)
  local newEvents = {}
  for _, event in ipairs(events) do
    if event.note and event.note.length then
      table.insert(newEvents, { beat = event.beat, holdStart = { column = event.note.column } })
      table.insert(newEvents, { beat = event.beat + event.note.length, holdEnd = { column = event.note.column } })
    elseif event.gearShift then
      table.insert(newEvents, { beat = event.beat, gearShiftStart = { lane = event.gearShift.lane } })
      table.insert(newEvents, { beat = event.beat + event.gearShift.length, gearShiftEnd = { lane = event.gearShift.lane } })
    else
      table.insert(newEvents, event)
    end
  end
  return newEvents
end
---@param events XDRVEvent[]
---@return XDRVEvent[]
function M.collapseHoldEnds(events)
  local indices = {}
  local insertIndices = {}

  local newEvents = {}

  for i, event in ipairs(events) do
    if event.holdStart then
      local column = event.holdStart.column
      indices[column] = i
      insertIndices[column] = #newEvents + 1
    elseif event.gearShiftStart then
      local column = -event.gearShiftStart.lane
      indices[column] = i
      insertIndices[column] = #newEvents + 1
    elseif event.holdEnd then
      local column = event.holdEnd.column
      local start = indices[column]
      local insert = insertIndices[column]
      if start then
        table.insert(newEvents, insert, {
          beat = events[start].beat,
          note = {
            column = column,
            length = event.beat - events[start].beat
          }
        })
        for k, v in pairs(insertIndices) do
          insertIndices[k] = v + 1
        end
      end
    elseif event.gearShiftEnd then
      local lane = event.gearShiftEnd.lane
      local column = -lane
      local start = indices[column]
      local insert = insertIndices[column]
      if start then
        table.insert(newEvents, insert, {
          beat = events[start].beat,
          gearShift = {
            lane = lane,
            length = event.beat - events[start].beat
          }
        })
        for k, v in pairs(insertIndices) do
          insertIndices[k] = v + 1
        end
      end
    else
      table.insert(newEvents, event)
    end
  end

  return newEvents
end

---@param event XDRVEvent
local function noteEventToType(event)
  if not event then return '0' end
  if event.note then return '1' end
  if event.holdStart then return '2' end
  if event.holdEnd then return '4' end
  return '0'
end
---@param c table<number, XDRVEvent>
local function formatNotesCol(c)
  return
    noteEventToType(c[1]) ..
    noteEventToType(c[2]) ..
    noteEventToType(c[3]) .. '-' ..
    noteEventToType(c[4]) ..
    noteEventToType(c[5]) ..
    noteEventToType(c[6])
end
---@param event XDRVEvent
local function gearEventToType(event)
  if not event then return '0' end
  if event.gearShiftStart then return '1' end
  if event.gearShiftEnd then return '2' end
  return '0'
end
---@param g table<XDRVLane, XDRVEvent>
local function formatGears(g)
  return gearEventToType(g[M.XDRVLane.Left]) .. gearEventToType(g[M.XDRVLane.Right])
end
---@param s XDRVDriftDirection
local function formatDrift(s)
  if s == M.XDRVDriftDirection.Left then
    return '1'
  end
  if s == M.XDRVDriftDirection.Right then
    return '2'
  end
  if s == M.XDRVDriftDirection.Neutral then
    return '3'
  end
  return '0'
end
local function noteEvent(beat, s, c)
  if s == '1' then
    return { beat = beat, note = { column = c } }
  end
  if s == '2' then
    return { beat = beat, holdStart = { column = c } }
  end
  if s == '4' then
    return { beat = beat, holdEnd = { column = c } }
  end
  return nil
end
local function gearShiftEvent(beat, s, lane)
  if s == '1' then
    return { beat = beat, gearShiftStart = { lane = lane } }
  end
  if s == '2' then
    return { beat = beat, gearShiftEnd = { lane = lane } }
  end
  return nil
end
local function driftEvent(beat, s)
  if s == '1' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Left }}
  end
  if s == '2' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Right }}
  end
  if s == '3' then
    return { beat = beat, drift = { direction = M.XDRVDriftDirection.Neutral }}
  end
  return nil
end

---@param events XDRVEvent[]
local function serializeChart(events)
  events = M.addHoldEnds(events)

  -- a lot of code assumes this table is sorted
  -- preferably we shouldn't sort it to do so, but making `addHoldEnds` work
  -- with properly sorted tables is a TODO
  table.sort(events, function(a, b) return a.beat < b.beat end)

  local segments = {}

  local b = 0
  local eventIdx = 1
  local iter = 0
  while true do
    iter = iter + 1
    if iter > 99999 then
      print('Preventing infinite loop!!! backup and run before everything explodes')
      break
    end
    if eventIdx > #events then break end

    ---@type XDRVEvent[]
    local segment = {}
    local add = 0
    for i = eventIdx, #events do
      local event = events[i]
      if event.beat >= (b + SEGMENT_INCR) then
        break
      end
      add = add + 1
      if event.beat >= b then
        table.insert(segment, event)
      end
    end
    eventIdx = eventIdx + add

    local rowsN = 1
    for _, event in ipairs(segment) do
      if event.beat > b then
        rowsN = lcm(rowsN, getDivision(event.beat))
      end
    end
    --print('-> ', #segment, rowsN)

    local segmentStr = {}

    --print(#segment .. ' in segment')

    for row = 1, rowsN do
      local offset = (row - 1) / rowsN

      local cols = {}
      local gears = {}
      local drift = nil

      for i, event in ipairs(segment) do
        if math.abs(event.beat - (b + offset)) < 0.001 then
          if event.note or event.holdStart or event.holdEnd then
            local note = event.note or event.holdStart or event.holdEnd
            cols[note.column] = event
          elseif event.gearShiftStart or event.gearShiftEnd then
            local gear = event.gearShiftStart or event.gearShiftEnd
            gears[gear.lane] = event
          elseif event.drift then
            drift = event.drift.direction
          elseif event.bpm then
            table.insert(segmentStr, '#BPM=' .. event.bpm)
          elseif event.warp then
            table.insert(segmentStr, '#WARP=' .. event.warp)
          elseif event.stop then
            table.insert(segmentStr, '#STOP=' .. event.stop)
          elseif event.stopSeconds then
            table.insert(segmentStr, '#STOP_SECONDS=' .. event.stopSeconds)
          elseif event.scroll then
            table.insert(segmentStr, '#SCROLL=' .. event.scroll)
          elseif event.timeSignature then
            table.insert(segmentStr, '#TIME_SIGNATURE=' .. event.timeSignature[1] .. ',' .. event.timeSignature[2])
          elseif event.comboTicks then
            table.insert(segmentStr, '#COMBO_TICKS=' .. event.comboTicks)
          elseif event.label then
            table.insert(segmentStr, '#LABEL=' .. event.label)
          elseif event.fake then
            table.insert(segmentStr, '#FAKE=' .. event.fake)
          elseif event.event then
            table.insert(segmentStr, '#EVENT=' .. event.event.name .. ',' .. table.concat(event.event.args, ','))
          elseif event.checkpoint then
            table.insert(segmentStr, '#CHECKPOINT=' .. event.checkpoint)
          end
        end
      end

      -- todo: drifts
      table.insert(segmentStr, formatNotesCol(cols) .. '|' .. formatGears(gears) .. '|' .. formatDrift(drift))
    end

    --print(table.concat(segmentStr, '\n'))

    table.insert(segments, table.concat(segmentStr, '\n'))

    b = b + SEGMENT_INCR
  end

  return '--\n' .. table.concat(segments, '\n--\n') .. '\n--'
end

local function serializeMetadata(m)
  local data = {
    MUSIC_TITLE = formatString(m.musicTitle),
    ALTERNATE_TITLE = formatString(m.alternateTitle),
    MUSIC_ARTIST = formatString(m.musicArtist),
    MUSIC_AUDIO = formatString(m.musicAudio),
    JACKET_IMAGE = formatString(m.jacketImage),
    JACKET_ILLUSTRATOR = formatString(m.jacketIllustrator),
    CHART_AUTHOR = formatString(m.chartAuthor),
    CHART_UNLOCK = formatString(m.chartUnlock),
    STAGE_BACKGROUND = formatString(m.stageBackground),
    MODFILE_PATH = formatString(m.modfilePath),
    CHART_LEVEL = formatInt(m.chartLevel),
    CHART_DISPLAY_BPM = formatInt(m.chartDisplayBPM),
    CHART_BOSS = formatBool(m.chartBoss),
    DISABLE_LEADERBOARD_UPLOADING = formatBool(m.disableLeaderboardUploading),
    RPC_HIDDEN = formatBool(m.rpcHidden),
    FLASH_TRACK = formatBool(m.isFlashTrack),
    KEYBOARD_ONLY = formatBool(m.isKeyboardOnly),
    ORIGINAL = formatBool(m.isOriginal),
    MUSIC_PREVIEW_START = formatFloat(m.musicPreviewStart),
    MUSIC_PREVIEW_LENGTH = formatFloat(m.musicPreviewLength),
    MUSIC_VOLUME = formatFloat(m.musicVolume),
    MUSIC_OFFSET = formatFloat(m.musicOffset),
    CHART_BPM = formatFloat(m.chartBPM),
    CHART_TAGS = '0,0,0,0', -- TODO
    CHART_DIFFICULTY = formatDifficulty(m.chartDifficulty),
  }

  local lines = {}
  for k, v in pairs(data) do
    table.insert(lines, k .. '=' .. v)
  end

  return table.concat(lines, '\n')
end

function M.serialize(chart)
  return serializeMetadata(chart.metadata) .. '\n' .. serializeChart(chart.chart)
end

---@return XDRVEvent[]
local function deserializeChart(str)
  local events = {}

  local parsePos = 1

  local b = 0

  while true do
    local pos, off = string.find(str, '\r?\n--\r?\n', parsePos)

    if not pos then pos = #str + 3 end

    local segment = string.sub(str, parsePos, pos - 3)

    local rows = {}
    local buffer = {}

    for line in string.gmatch(segment, '[^\r\n]+') do
      local isEvent = string.sub(line, 1, 1) == '#'
      if string.len(line) ~= 0 and line ~= '--' and string.sub(line, 1, 2) ~= '//' then
        table.insert(buffer, line)
        if not isEvent then
          table.insert(rows, buffer)
          buffer = {}
        end
      end
    end

    for rowI, row in ipairs(rows) do
      local div = (rowI - 1) / #rows
      local b = b + div
      for n = 1, #row - 1 do
        local seg = row[n]
        local parsed = parseTimingSegment(b, seg)
        if parsed then
          table.insert(events, parsed)
        end
      end
      local noterow = row[#row]
      local c1, c2, c3, c4, c5, c6, l, r, d = string.match(noterow, '(%d)(%d)(%d)%-(%d)(%d)(%d)|(%d)(%d)|(%d)')
      if c1 then
        for column, s in ipairs({c1, c2, c3, c4, c5, c6}) do
          local ev = noteEvent(b, s, column)
          if ev then table.insert(events, ev) end
        end
        for lane, gear in ipairs({l, r}) do
          local ev = gearShiftEvent(b, gear, lane)
          if ev then table.insert(events, ev) end
        end
        local ev = driftEvent(b, d)
        if ev then table.insert(events, ev) end
      end
    end

    if off then
      parsePos = off + 1
      b = b + SEGMENT_INCR
    else
      break
    end
  end

  return M.collapseHoldEnds(events)
end

---@param m table<string, string>
---@return XDRVMetadata
local function makeMetdata(m)
  return {
    musicTitle = parseString(m.MUSIC_TITLE),
    alternateTitle = parseString(m.ALTERNATE_TITLE),
    musicArtist = parseString(m.MUSIC_ARTIST),
    musicAudio = parseString(m.MUSIC_AUDIO),
    jacketImage = parseString(m.JACKET_IMAGE),
    jacketIllustrator = parseString(m.JACKET_ILLUSTRATOR),
    chartAuthor = parseString(m.CHART_AUTHOR),
    chartUnlock = parseString(m.CHART_UNLOCK),
    stageBackground = parseString(m.STAGE_BACKGROUND),
    modfilePath = parseString(m.MODFILE_PATH),
    chartLevel = parseInt(m.CHART_LEVEL),
    chartDisplayBPM = parseInt(m.CHART_DISPLAY_BPM),
    chartBoss = parseBool(m.CHART_BOSS),
    disableLeaderboardUploading = parseBool(m.DISABLE_LEADERBOARD_UPLOADING),
    rpcHidden = parseBool(m.RPC_HIDDEN),
    isFlashTrack = parseBool(m.FLASH_TRACK),
    isKeyboardOnly = parseBool(m.KEYBOARD_ONLY),
    isOriginal = parseBool(m.ORIGINAL),
    musicPreviewStart = parseFloat(m.MUSIC_PREVIEW_START),
    musicPreviewLength = parseFloat(m.MUSIC_PREVIEW_LENGTH),
    musicVolume = parseFloat(m.MUSIC_VOLUME),
    musicOffset = parseFloat(m.MUSIC_OFFSET),
    chartBPM = parseFloat(m.CHART_BPM),
    chartTags = { 0, 0, 0, 0 }, -- TODO
    chartDifficulty = parseDifficulty(m.CHART_DIFFICULTY),
  }
end

local function deserializeMetadata(str)
  local metadata = {}

  for line in string.gmatch(str, '[^\r\n]+') do
    if string.len(line) ~= 0 and string.sub(line, 1, 2) ~= '//' then
      local eq = string.find(line, '=')
      if eq then
        local key = string.sub(line, 1, eq - 1)
        local value = string.sub(line, eq + 1)

        metadata[key] = value
      end
    end
  end

  return makeMetdata(metadata)
end

---@alias XDRVChart { metadata: XDRVMetadata, chart: XDRVEvent[] }

---@return XDRVChart
function M.deserialize(str)
  local chartStart = string.find(str, '\r?\n--\r?\n')
  if not chartStart then
    return {
      metadata = deserializeMetadata(str)
    }
  end

  local meta = string.sub(str, 1, chartStart - 1)
  local chart = string.sub(str, chartStart + 1)

  return {
    metadata = deserializeMetadata(meta),
    chart = deserializeChart(chart)
  }
end

return M