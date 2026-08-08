HOME = os.getenv("HOME")

function is_file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then
      io.close(f)
      return true
   else
      return false
   end
end

function create_if_not_exists(path)
   if not is_file_exists(path) then
      os.execute("mkdir -p \"$(dirname \"" .. path .. "\")\"")
      os.execute("echo '-- This file will not be overwritten across dots-hyprland updates.\n-- The file name is for the sake of organization and does not matter\n-- See the corresponding files in ~/.config/hypr/hyprland for examples' > \"" .. path .. "\"")
      return true
   end
   return false
end

function workspace_in_group(i)
	-- Number-key bank stays 1..workspaceGroupSize (Super+1..0 / Super+Alt+1..0)
	local n = workspaceGroupSize or 10
	local idx = ((i - 1) % n) + 1
	return idx
end

-- Relative infinite: no wrap. +1 can open empty higher workspaces; -1 stops at 1.
function cycle_workspace(delta)
	local curr = hl.get_active_workspace().id
	local nextWs = curr + delta
	if nextWs < 1 then
		return
	end
	hl.dispatch(hl.dsp.focus({ workspace = nextWs }))
end

-- Move active window to previous/next workspace (infinite, no wrap) and follow
function cycle_move_window(delta)
	local curr = hl.get_active_workspace().id
	local nextWs = curr + delta
	if nextWs < 1 then
		return
	end
	hl.dispatch(hl.dsp.window.move({ workspace = nextWs, follow = true }))
end
