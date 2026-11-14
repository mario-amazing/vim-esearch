-- nvim-tree.lua integration (https://github.com/nvim-tree/nvim-tree.lua).
-- Public api only: api.tree.get_node_under_cursor(), api.tree.get_nodes(),
-- api.marks.list().
local M = {}

local function api()
  return require('nvim-tree.api')
end

-- Absolute path of the node under the cursor. The root line and an empty
-- tree resolve to the tree root.
function M.path_under_cursor()
  local tree = api().tree
  local node = tree.get_node_under_cursor() or tree.get_nodes()
  return node and node.absolute_path or vim.fn.getcwd()
end

-- Absolute paths of the nodes marked with api.marks.toggle(), empty when
-- nothing is marked. marks.list() iterates a hash, sort to keep the search
-- arguments stable between runs.
function M.marked_paths()
  local paths = {}
  for _, node in ipairs(api().marks.list()) do
    paths[#paths + 1] = node.absolute_path
  end
  table.sort(paths)
  return paths
end

return M
