local repo_root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(repo_root .. '/plugins/file-complete.nvim')

package.preload.cmp = function()
  return {
    lsp = {
      CompletionItemKind = { File = 17 },
      MarkupKind = { PlainText = 'plaintext' },
    },
  }
end

local uv = vim.uv or vim.loop
local home = vim.fn.expand '~'
local razor = home .. '/coding/razor'
local prompts = home .. '/prompts'

if not home:find('file%-complete%-test%-home', 1, false) then
  error('refusing to run regression test outside an isolated HOME: ' .. home)
end

vim.fn.delete(home, 'rf')
vim.fn.mkdir(home, 'p')

local function write_file(path)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
  vim.fn.writefile({ 'test' }, path)
end

local function assert_true(value, message)
  if not value then
    error(message, 2)
  end
end

local function labels(items)
  local result = {}
  for _, item in ipairs(items or {}) do
    result[#result + 1] = item.label
  end
  return result
end

local function includes(items, label)
  for _, item in ipairs(items or {}) do
    if item.label == label then
      return true
    end
  end
  return false
end

local function excludes(items, label)
  return not includes(items, label)
end

write_file(prompts .. '/0.md')
write_file(prompts .. '/cli.md')
write_file(prompts .. '/docker-wp-cli.md')
write_file(prompts .. '/lfi.md')
write_file(prompts .. '/poc.md')
write_file(prompts .. '/rpg.md')
write_file(prompts .. '/xss.md')
write_file(prompts .. '/csrf.md')

write_file(razor .. '/razor-init/Cargo.toml')
write_file(razor .. '/razor-init/src/main.rs')
write_file(razor .. '/razor-init/plugin-list/list.txt')
write_file(razor .. '/list-all-wordpress-plugins/static/index.html')
write_file(razor .. '/jules/wp-cli.phar')
write_file(razor .. '/razor-jules/src/client.rs')

assert_true(uv.chdir(razor), 'failed to chdir into fixture razor directory')

local config = require 'file_complete.config'
config.setup {
  include = {
    '~/prompts',
    '~/coding/razor',
  },
  exclude = {
    '**/.git/**',
    '**/node_modules/**',
    '**/dist/**',
    '**/build/**',
    '**/target/**',
    '**/_core/**',
    '**/themes/**',
    '~/coding/razor/dataset/**',
  },
  filetypes = { 'markdown', 'text' },
  extensions = { 'md', 'txt', 'toml', 'rs', 'json', 'html', 'phar' },
  max_items = 7,
  fff_search_limit = 128,
  fallback_scan_limit = 20000,
  fallback_cache_ttl_ms = 0,
}

require('file_complete.scanner').clear_cache()

local source = require('file_complete.source').new()

local function complete(text)
  local result
  source:complete({ context = { cursor_before_line = text } }, function(response)
    result = response or { items = {} }
  end)
  return result.items or {}
end

local triggers = {}
for _, char in ipairs(source:get_trigger_characters()) do
  triggers[char] = true
end

assert_true(triggers['@'], 'missing @ trigger')
assert_true(triggers['/'], 'missing / trigger')
assert_true(triggers['.'], 'missing . trigger')
assert_true(triggers['-'], 'missing - trigger')
assert_true(triggers.c, 'missing filename letter trigger')

local cli_items = complete '@cli'
assert_true(cli_items[1], '@cli returned no completion items')
assert_true(cli_items[1].label == '~/prompts/cli.md', '@cli should rank ~/prompts/cli.md first, got: ' .. table.concat(labels(cli_items), ', '))
assert_true(cli_items[1].word == '@cli.md', '@cli should filter with @cli.md')
assert_true(excludes(cli_items, 'list-all-wordpress-plugins/static/index.html'), '@cli should not include weak fuzzy index.html match')

local prompts_items = complete '@prompts/'
assert_true(includes(prompts_items, '~/prompts/cli.md'), '@prompts/ should include ~/prompts/cli.md')
assert_true(prompts_items[1] and vim.startswith(prompts_items[1].word, '@prompts/'), '@prompts/ should filter with the prompts/ alias')

local prompts_cli_items = complete '@prompts/cli'
assert_true(prompts_cli_items[1], '@prompts/cli returned no completion items')
assert_true(prompts_cli_items[1].label == '~/prompts/cli.md', '@prompts/cli should rank ~/prompts/cli.md first')
assert_true(prompts_cli_items[1].word == '@prompts/cli.md', '@prompts/cli should filter with @prompts/cli.md')

local razor_init_items = complete '@razor-init'
assert_true(#razor_init_items > 0, '@razor-init returned no completion items')
assert_true(includes(razor_init_items, 'razor-init/Cargo.toml'), '@razor-init should include files inside the razor-init directory')
assert_true(razor_init_items[1] and vim.startswith(razor_init_items[1].word, '@razor-init'), '@razor-init should filter with @razor-init')

local home_razor_init_items = complete '@~/razor-init'
assert_true(#home_razor_init_items > 0, '@~/razor-init returned no completion items')
assert_true(includes(home_razor_init_items, 'razor-init/Cargo.toml'), '@~/razor-init should include files inside the razor-init directory')
assert_true(home_razor_init_items[1] and vim.startswith(home_razor_init_items[1].word, '@~/razor-init'), '@~/razor-init should filter with @~/razor-init')

vim.fn.delete(home, 'rf')

print 'file_complete_regression: ok'
