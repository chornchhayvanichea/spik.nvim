local M = {}
local ui = require("spik.ui")

function M.simple_picker()
	local all_files = vim.fn.systemlist(
		"fd --type f --exclude plugin --exclude plugins"
	)
	ui.create(all_files)
end

return M
