local M = {}

function M.run_search(all_files, q)
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

return M
