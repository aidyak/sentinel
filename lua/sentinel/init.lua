local M = {}

local watchers = {}

local function start_watching(buf)
	local filepath = vim.api.nvim_buf_get_name(buf)
	if filepath == "" or watchers[buf] then
		return
	end

	local stat = vim.uv.fs_stat(filepath)
	if not stat or stat.type ~= "file" then
		return
	end

	local handle = vim.uv.new_fs_event()
	if not handle then
		return
	end

	local debounce_timer = nil
	handle:start(filepath, {}, function(err, filename, events)
		if err then
			return
		end

		if debounce_timer then
			debounce_timer:stop()
			debounce_timer:close()
		end

		debounce_timer = vim.uv.new_timer()
		debounce_timer:start(100, 0, function()
			debounce_timer:close()
			debounce_timer = nil
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modified then
					vim.cmd("checktime " .. buf)
				end
			end)
		end)
	end)

	watchers[buf] = handle
end

local function stop_watching(buf)
	local handle = watchers[buf]
	if handle then
		handle:stop()
		handle:close()
		watchers[buf] = nil
	end
end

function M.setup()
	local group = vim.api.nvim_create_augroup("Sentinel", { clear = true })

	vim.o.autoread = true

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		desc = "Start watching file for changes",
		callback = function(args)
			local ok, err = pcall(start_watching, args.buf)
			if not ok then
				vim.notify("Sentinel watch error: " .. tostring(err), vim.log.levels.ERROR)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
		group = group,
		desc = "Stop watching file",
		callback = function(args)
			pcall(stop_watching, args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		desc = "Check for unsaved buffers and cleanup watchers",
		callback = function()
			local ok, err = pcall(function()
				for buf, _ in pairs(watchers) do
					stop_watching(buf)
				end

				for _, buf in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
						local name = vim.api.nvim_buf_get_name(buf)
						if name ~= "" then
							print("Unsaved: " .. name)
						end
					end
				end
			end)
			if not ok then
				vim.notify("Sentinel error: " .. tostring(err), vim.log.levels.ERROR)
			end
		end,
	})

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
			pcall(start_watching, buf)
		end
	end
end

return M
