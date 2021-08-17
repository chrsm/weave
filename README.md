weave
======

`weave` is a wrapper around LOVE2D's [`love.thread`][1], written in [Yuescript][2].

You can build this repo from source with `make build` or download a [release][3].


API
===

`weave` has two concepts: the Manager and the Thread.

`weave.Manager` handles creation, error checking and sending messages for
threads.

`weave.Thread` handles the "event loop" of receiving messages for threads from
the manager.

```
weave.Manager
	weave.Manager
		ctor

	:update(dt)
		Should be called every `love.update`.
		This checks for errors from the thread and removes threads if
		they have signaled they will be exiting.

		Note that errors will be overwritten, if you wish to check for
		them, you should do it after calling Manager:update.

		In other words, call Manager:update before all other code in
		`love.update`.

	:createThread(name, src)
		src can be a filename, LOVE FileData, or raw lua code.

		Creates a new thread by name - if it doesn't exist.
		Raises an error if it does.

		Starts the thread immediately.
	
	:getError(name)
		Returns the most recent error for a thread.
	
	:has(name)
		Returns true if the Manager has already tracked a thread by
		this name.
	
	:kill(name)
		Forcibly terminates a thread regardless of its status.

		Raises an error if it does not exist.

	:send(name, recv love.thread.Channel|nil, ... any)
		Sends a message to a running thread.

		If `recv` is specified, the Thread will return the result
		of its handler call on the recv channel.

		Raises an error if the thread does not exist.

weave.Thread
	weave.Thread(name)
		ctor

	:setHandler(fn)
		Sets the handler for this thread.

		Handlers receive a message from the Manager, and contain
		any arguments passed to it.

		If results should be able to be passed back to the caller,
		the result should be returned from it.

	:destroy()
		Notifies the Manager of intent-to-exit, and stops at the end
		of the next run loop.

		Clears all current messages in the channel.

	:read()
		Waits for a message on the channel and executes @handler on it.

		Raises an error if the message is falsy from ch:demand.

	:run()
		Starts the Thread, continually running until exit is set to
		true.
	
```


Example
=======

While use of threads is always usecase-specific, here's a very trivial example.

We'll use a single file for this case. In practice, it's cleaner to write your
worker separately from where it is managed.

```lua
local weave = require("weave")
local manager = weave.Manager()
local recv = love.thread.newChannel()

local source = [[
local weave = require("weave")

local thr = weave.Thread("add_ten")

thr:setHandler(function(n1, n2)
  if type(n1) ~= "number" or type(n2) ~= "number" then
    return { err: "n1 or n2 not a number" }
  end

  return { n1+10, n2+10 }
end)

thr:run()
]]

function love.load()
  manager:createThread("add_ten", source)
end

function love.update(dt)
  manager:update(dt)

  err = manager:getError("add_ten")
  if err != nil then
    print("error encountered in thread: " .. err)
  end
end

function love.draw()
  -- not drawing anything, just logging to console
  local r = recv:pop()
  if r then
    print("received results: " .. tostring(r[1]) .. ", " .. tostring(r[2]))
  end
end

function love.keypressed(key)
  if key == "1" then
    manager:send("add_ten", nil, "error pls", "pls error")
  elseif key == "2" then
    manager:send("add_ten", recv, 10, 20)
  elseif key == "3" then
    love.event.quit()
  end
end

```

[1]: https://love2d.org/wiki/Thread
[2]: https://github.com/pigpigyyy/Yuescript
[3]: https://github.com/chrsm/weave
