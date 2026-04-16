local spik = require("spik")
vim.api.nvim_create_user_command("Spik", spik.simple_picker, {})
vim.keymap.set("n", "<leader>f", ":Spik<CR>")
