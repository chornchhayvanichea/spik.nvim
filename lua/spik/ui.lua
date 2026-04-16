local M = {}
local search = require("spik.search")

function M.create(all_files)
	local width = vim.o.columns
	local height = vim.o.lines

	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height - 2,
		row = 0,
		col = 0,
		style = "minimal",
		border = "none",
	})

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].modifiable = true
	vim.bo[buf].omnifunc = ""
	vim.bo[buf].completefunc = ""
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

	local ok, cmp = pcall(require, "cmp")
	if ok then
		cmp.setup.buffer({ enabled = false })
	end

	local ns = vim.api.nvim_create_namespace("spik")
	local selected = 1
	local current_results = {}

	local function highlight_selected()
		vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
		if #current_results > 0 then
			-- results start at line index 1 (line 0 is input)
			vim.api.nvim_buf_add_highlight(buf, ns, "CursorLine", selected, 0, -1)
		end
	end

	local refreshing = false
	local function refresh()
		if refreshing then
			return
		end
		refreshing = true

		local q = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] or ""
		current_results = search.run_search(all_files, q)
		selected = 1

		vim.api.nvim_buf_set_lines(buf, 1, -1, false, current_results)
		highlight_selected()

		refreshing = false
	end

	local function close()
		vim.cmd("stopinsert")
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end

	vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
		buffer = buf,
		callback = refresh,
	})

	for _, key in ipairs({ "<C-c>", "<Esc>" }) do
		vim.keymap.set({ "i", "n" }, key, close, { buffer = buf, nowait = true })
	end

	vim.keymap.set({ "i", "n" }, "<C-n>", function()
		if selected < #current_results then
			selected = selected + 1
			highlight_selected()
		end
	end, { buffer = buf, nowait = true })

	vim.keymap.set({ "i", "n" }, "<C-p>", function()
		if selected > 1 then
			selected = selected - 1
			highlight_selected()
		end
	end, { buffer = buf, nowait = true })

	vim.keymap.set({ "i", "n" }, "<CR>", function()
		local file = current_results[selected]
		close()
		if file and file ~= "" then
			vim.cmd("edit " .. vim.fn.fnameescape(file))
		end
	end, { buffer = buf, nowait = true })

	refresh()
	vim.cmd("startinsert!")
end

return M
