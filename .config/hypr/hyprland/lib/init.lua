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
	-- Primary bank is always 1..workspaceGroupSize (loop, not infinite groups)
	local n = workspaceGroupSize or 10
	local idx = ((i - 1) % n) + 1
	return idx
end

-- Wrap workspace index into 1..workspaceGroupSize
function workspace_wrap(id)
	local n = workspaceGroupSize or 10
	-- Lua modulo of negative: normalize into [0, n)
	local z = (id - 1) % n
	if z < 0 then
		z = z + n
	end
	return z + 1
end

-- Relative cycle: delta +1 / -1 loops 10→1 and 1→10
function cycle_workspace(delta)
	local curr = hl.get_active_workspace().id
	local nextWs = workspace_wrap(curr + delta)
	hl.dispatch(hl.dsp.focus({ workspace = nextWs }))
end

-- Move active window to previous/next workspace (wrap) and follow focus with it
function cycle_move_window(delta)
	local curr = hl.get_active_workspace().id
	local nextWs = workspace_wrap(curr + delta)
	hl.dispatch(hl.dsp.window.move({ workspace = nextWs, follow = true }))
end
