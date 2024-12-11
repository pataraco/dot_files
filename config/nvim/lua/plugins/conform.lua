-- LazyVim uses conform.nvim for formatting.
-- https://www.lazyvim.org/plugins/formatting

-- Configuring conform.nvim:
-- opts.format: extra options passed to require("conform").format(options)
-- opts.formatters: options will be merged with builtin formatters, or you can specify a new formatter.
-- opts.formatters[NAME].prepend_args: extra arguments passed to the formatter command. If you want to fully override the args, just use args instead of prepend_args.
-- opts.formatters_by_ft: specify which formatters to use for each filetype.
return {
	"stevearc/conform.nvim",
	opts = {
		-- filetype = {
		--   sh = {
		--     indent = {
		--       case_statements = true,
		--       enabled = true,
		--       width = 2,
		--     },
		--   },
		--   bash = {
		--     indent = {
		--       case_statements = true,
		--       enabled = true,
		--       width = 2,
		--     },
		--   },
		-- },
		-- formatters_by_ft = {
		--   sh = { "shfmt" },
		--   bash = { "shfmt" },
		-- },
		formatters = {
			shfmt = {
				args = { "-i", "2", "-ci", "-sr" },
			},
		},
	},
}

