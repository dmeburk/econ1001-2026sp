-- pagebreaks-by-part.lua
--
-- Pandoc Lua filter: insert TeX page breaks for the "by part" document.
--
-- Expected structure (from your transposer):
--   # Problem 22
--   ## 22(a)
--   ### Version A
--   ...
--   ### Version B
--   ...
--   ## 22(b)
--   ...
--   # Problem 23
--   ...
--
-- Rules:
-- 1) New page before each new Problem (# level 1), except the first Problem.
-- 2) New page before each subpart (## level 2), except the first subpart
--    within each Problem.
-- 3) No page breaks between versions (### level 3).

local saw_problem = false
local first_subpart_in_problem = true

local function pagebreak()
  return pandoc.RawBlock("tex", "\\newpage\n")
end

function Header(h)
  -- Level 1: "# Problem X"
  if h.level == 1 then
    local out = {}
    if saw_problem then
      table.insert(out, pagebreak())
    end
    saw_problem = true
    first_subpart_in_problem = true
    table.insert(out, h)
    return out
  end

  -- Level 2: "## 22(a)" etc.
  if h.level == 2 then
    local out = {}
    if not first_subpart_in_problem then
      table.insert(out, pagebreak())
    end
    first_subpart_in_problem = false
    table.insert(out, h)
    return out
  end

  -- Other headers unchanged
  return h
end