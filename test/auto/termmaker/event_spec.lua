local event = require("termmaker.event")
local spy = require("luassert.spy")

describe("Source", function()
    local src

    before_each(function()
        src = event.Source()
    end)

    describe("#register", function()
        it("allows to register observers with the source", function()
            local some_observer = function(...)
                return true
            end
            local another_observer = function(...)
                return true
            end

            src:register("some_event", some_observer)
            src:register("some_event", another_observer)

            assert.is.equal(some_observer, src._observers.some_event[1])
            assert.is.equal(another_observer, src._observers.some_event[2])
        end)
    end)

    describe("#notify_all", function()
        it("notifies all registered observers of an event", function()
            local some_observer = spy.new(function(event_name, ...)
                return true
            end)

            src:register("some_event", some_observer)
            src:notify_all("some_event", 1, 2, 3)
            src:notify_all("some_event", 5, 6, 7)

            assert.spy(some_observer).was.called_with("some_event", 1, 2, 3)
            assert.spy(some_observer).was.called_with("some_event", 5, 6, 7)
        end)

        it("removes an observer if it returns false", function()
            local observe_once = spy.new(function(event_name, ...)
                return false
            end)

            src:register("some_event", observe_once)
            src:notify_all("some_event", 1, 2, 3)
            src:notify_all("some_event", 5, 6, 7)

            assert.spy(observe_once).was_not.called_with("some_event", 5, 6, 7)
        end)

        it("removes an observer if it returns nothing at all", function()
            local some_observer = spy.new(function(event_name, ...) end)

            src:register("some_event", some_observer)
            src:notify_all("some_event", 1, 2, 3)
            src:notify_all("some_event", 5, 6, 7)

            assert.spy(some_observer).was.called_with("some_event", 1, 2, 3)
            assert.spy(some_observer).was_not.called_with("some_event", 5, 6, 7)
        end)
    end)
end)
