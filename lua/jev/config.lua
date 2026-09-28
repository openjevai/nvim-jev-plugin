---@brief Defaults and merge for jev.nvim.

local M = {}

---@class JevThresholds
---@field route number
---@field auto number
---@field confirm number

---@class JevConfig
---@field api_key string|nil    falls back to $TYPESAFE_API_KEY at request time
---@field provider string|nil   'typesafe' (default) or 'openjev'; else $JEV_PROVIDER
---@field model string
---@field url string
---@field timeout_ms integer
---@field width integer
---@field prompt string
---@field always_confirm boolean
---@field thresholds JevThresholds

---@type JevConfig
M.defaults = {
  api_key = nil,
  provider = nil,
  model = 'jev-latest',
  url = 'https://api.typesafe.ai/v1/systemone',
  timeout_ms = 15000,
  width = 50,
  prompt = 'jev> ',
  always_confirm = false,
  thresholds = { route = 0.5, auto = 0.8, confirm = 0.6 },
}

--- OpenJEV is a free community gateway to the same Jev model that TypeSafe
--- hosts. TypeSafe stays the default; OpenJEV is opt-in. See openjev.sh.
M.openjev = {
  model = 'openjev',
  url = 'https://api.openjev.sh/v1/systemone',
}

---@type JevConfig
M.options = vim.deepcopy(M.defaults)

--- Merge user options over the defaults.
---@param opts table|nil
---@return JevConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', vim.deepcopy(M.defaults), opts or {})
  return M.options
end

---@return JevConfig
function M.get()
  return M.options
end

--- The TypeSafe API key to use, or nil. Never logged. Kept for backward
--- compatibility and health checks; provider-aware code uses |M.resolve()|.
---@return string|nil
function M.api_key()
  local key = M.options.api_key
  if type(key) ~= 'string' or key == '' then
    key = vim.env.TYPESAFE_API_KEY or os.getenv('TYPESAFE_API_KEY')
  end
  if type(key) ~= 'string' or key == '' then
    return nil
  end
  return key
end

--- Resolve which provider, key, model and url to use at request time.
--- TypeSafe stays the default; OpenJEV is opt-in. Selection rule:
---   1. Explicit `provider` (config or $JEV_PROVIDER) wins.
---   2. Otherwise TypeSafe if its key is set (unchanged default).
---   3. Otherwise OpenJEV if only $OPENJEV_API_KEY is set.
--- Anyone with a TypeSafe key sees zero behaviour change.
---@return { provider: string, api_key: string|nil, model: string, url: string }
function M.resolve()
  local opts = M.options

  local provider = opts.provider
  if type(provider) ~= 'string' or provider == '' then
    provider = vim.env.JEV_PROVIDER or os.getenv('JEV_PROVIDER') or ''
  end
  provider = provider == '' and 'auto' or provider

  local ts_key = opts.api_key
  if type(ts_key) ~= 'string' or ts_key == '' then
    ts_key = vim.env.TYPESAFE_API_KEY or os.getenv('TYPESAFE_API_KEY')
  end
  local oj_key = vim.env.OPENJEV_API_KEY or os.getenv('OPENJEV_API_KEY')

  local using_defaults = opts.model == M.defaults.model and opts.url == M.defaults.url

  -- Explicit OpenJEV choice.
  if provider == 'openjev' then
    local key = oj_key
    if type(key) ~= 'string' or key == '' then
      key = nil
    end
    local model, url = opts.model, opts.url
    if using_defaults then
      model, url = M.openjev.model, M.openjev.url
    end
    return { provider = 'openjev', api_key = key, model = model, url = url }
  end

  -- Explicit TypeSafe choice.
  if provider == 'typesafe' then
    if type(ts_key) ~= 'string' or ts_key == '' then
      ts_key = nil
    end
    return { provider = 'typesafe', api_key = ts_key, model = opts.model, url = opts.url }
  end

  -- Auto: TypeSafe if its key is set (unchanged default) ...
  if type(ts_key) == 'string' and ts_key ~= '' then
    return { provider = 'typesafe', api_key = ts_key, model = opts.model, url = opts.url }
  end

  -- ... otherwise OpenJEV if only $OPENJEV_API_KEY is set.
  if type(oj_key) == 'string' and oj_key ~= '' then
    local model, url = opts.model, opts.url
    if using_defaults then
      model, url = M.openjev.model, M.openjev.url
    end
    return { provider = 'openjev', api_key = oj_key, model = model, url = url }
  end

  return { provider = 'typesafe', api_key = nil, model = opts.model, url = opts.url }
end

return M
