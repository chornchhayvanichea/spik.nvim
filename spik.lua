local M = {}

local function run_search(all_files, q)
	if q == "" then
		return all_files
	end
	local results = {}
	for _, file in ipairs(all_files) do
		if file:lower():find(q:lower(), 1, true) then
			table.insert(results, file)
		end
	end
	return results
end

function M.simple_picker()
	local all_files = vim.fn.systemlist("fd --type f")

	local width = vim.o.columns
	local height = vim.o.lines

	local result_buf = vim.api.nvim_create_buf(false, true)
	local result_win = vim.api.nvim_open_win(result_buf, false, {
		relative = "editor",
		width = width,
		height = height - 3,
		row = 0,
		col = 0,
		style = "minimal",
		border = "none",
	})

	local input_buf = vim.api.nvim_create_buf(false, true)
	local input_win = vim.api.nvim_open_win(input_buf, true, {
		relative = "editor",
		width = width,
		height = 1,
		row = height - 3,
		col = 0,
		style = "minimal",
		border = "none",
	})

	vim.bo[input_buf].modifiable = true
	vim.bo[input_buf].buftype = "nofile"
	vim.wo[result_win].cursorline = true

	local function refresh()
		local line = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
		local results = run_search(all_files, line)

		vim.bo[result_buf].modifiable = true
		vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, results)
		vim.bo[result_buf].modifiable = false

		if vim.api.nvim_buf_line_count(result_buf) > 0 then
			vim.api.nvim_win_set_cursor(result_win, { 1, 0 })
		end
	end

	local function close()
		vim.cmd("stopinsert")
		if vim.api.nvim_win_is_valid(input_win) then
			vim.api.nvim_win_close(input_win, true)
		end

		if vim.api.nvim_win_is_valid(result_win) then
			vim.api.nvim_win_close(result_win, true)
		end
	end

	vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
		buffer = input_buf,
		callback = refresh,
	})

	for _, key in ipairs({ "<C-c>", "<Esc>" }) do
		vim.keymap.set({ "i", "n" }, key, close, { buffer = input_buf, nowait = true })
	end

	vim.keymap.set({ "i", "n" }, "<C-n>", function()
		if not vim.api.nvim_win_is_valid(result_win) then
			return
		end

		local row = vim.api.nvim_win_get_cursor(result_win)[1]
		local total = vim.api.nvim_buf_line_count(result_buf)

		if row < total then
			vim.api.nvim_win_set_cursor(result_win, { row + 1, 0 })
		end
	end, { buffer = input_buf, nowait = true })

	vim.keymap.set({ "i", "n" }, "<C-p>", function()
		if not vim.api.nvim_win_is_valid(result_win) then
			return
		end

		local row = vim.api.nvim_win_get_cursor(result_win)[1]
		if row > 1 then
			vim.api.nvim_win_set_cursor(result_win, { row - 1, 0 })
		end
	end, { buffer = input_buf, nowait = true })

	vim.keymap.set({ "i", "n" }, "<CR>", function()
		if not vim.api.nvim_win_is_valid(result_win) then
			return
		end

		local row = vim.api.nvim_win_get_cursor(result_win)[1]
		local line = vim.api.nvim_buf_get_lines(result_buf, row - 1, row, false)[1]

		close()
		vim.cmd("stopinsert")

		if line and line ~= "" then
			vim.cmd("edit " .. vim.fn.fnameescape(line))
		end
	end, { buffer = input_buf, nowait = true })

	refresh()
	vim.cmd("startinsert!")
end

vim.api.nvim_create_user_command("Spik", M.simple_picker, {})
vim.keymap.set("n", "<leader>f", ":Spik<CR>")
return M
