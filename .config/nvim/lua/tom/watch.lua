vim.api.nvim_create_user_command('Watch', function()
  vim.o.autoread = true
  vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
    buffer = 0, -- Only applies to the current buffer
    callback = function()
      if vim.fn.mode() ~= 'c' then
        vim.cmd("checktime")
      end
    end,
  })
  print("Live reload enabled for this buffer.")
end, {})
