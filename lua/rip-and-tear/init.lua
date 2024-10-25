local M = {}

local mp3_process = nil
local inactivity_timer = nil

-- Default configuration
M.config = {
  mp3_file = '/path/to/your/file.mp3', -- Replace with your MP3 file path
  player_command = 'mpg123',           -- 'mpg123', 'afplay', or 'cvlc'
  delay = 1000,                        -- Time in milliseconds before stopping playback after inactivity
}

-- Function to start playing the MP3
function M.start_mp3()
  if mp3_process == nil then
    local cmd = nil
    local args = nil

    if M.config.player_command == 'mpg123' then
      cmd = 'mpg123'
      args = {'--loop', '-1', M.config.mp3_file}
    elseif M.config.player_command == 'afplay' then
      cmd = 'afplay'
      args = {M.config.mp3_file}
    elseif M.config.player_command == 'cvlc' then
      cmd = 'cvlc'
      args = {'--loop', M.config.mp3_file}
    else
      vim.api.nvim_err_writeln('Unsupported player command: ' .. M.config.player_command)
      return
    end

    mp3_process = vim.fn.jobstart({cmd, unpack(args)}, {detach = true})
  end
end

-- Function to stop playing the MP3
function M.stop_mp3()
  if mp3_process ~= nil then
    vim.fn.jobstop(mp3_process)
    mp3_process = nil
  end
end

-- Function to handle keypress events
function M.on_key(char)
	print(char)
  M.start_mp3()

  if inactivity_timer == nil then
    inactivity_timer = vim.loop.new_timer()
  else
    inactivity_timer:stop()
  end

  inactivity_timer:start(M.config.delay, 0, vim.schedule_wrap(function()
    M.stop_mp3()
    inactivity_timer:stop()
  end))
end

-- Setup function to initialize the plugin
function M.setup(user_config)
  if user_config ~= nil then
    for k, v in pairs(user_config) do
      M.config[k] = v
    end
  end

  if vim.fn.filereadable(M.config.mp3_file) == 0 then
    vim.api.nvim_err_writeln('MP3 file not found: ' .. M.config.mp3_file)
    return
  end

  if M.ns_id == nil then
    M.ns_id = vim.api.nvim_create_namespace('rip-and-tear')
  end


  vim.on_key(M.on_key, M.ns_id)
end

return M
