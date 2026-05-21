-- filters/pagebreaks-by-version.lua
-- Insert a LaTeX pagebreak before each top-level "Version ..." header (except the first).
local seen_first = false

function Header(el)
  if FORMAT:match("latex") and el.level == 1 then
    local txt = pandoc.utils.stringify(el.content)
    if txt:match("^Version%s+[A-Z]%s*$") or txt:match("^Version%s+[A-Z]%b()%s*$") then
      if seen_first then
        return { pandoc.RawBlock("latex", "\\clearpage"), el }
      else
        seen_first = true
        return el
      end
    end
  end
  return el
end