require "test_helper"

class TimerTickJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @room = rooms(:one)
    @room.update!(timer_status: "playing", timer_remaining: 100, timer_duration: 600)
  end

  # ── Basic tick ──────────────────────────────────────────────────
  test "decrements timer_remaining by 1" do
    TimerTickJob.perform_now(@room.id)
    @room.reload
    assert_equal 99, @room.timer_remaining
  end

  test "enqueues another tick if timer is still playing and remaining > 0" do
    assert_enqueued_with(job: TimerTickJob) do
      TimerTickJob.perform_now(@room.id)
    end
  end

  # ── Auto-stop at zero ──────────────────────────────────────────
  test "stops timer when remaining reaches zero" do
    @room.update!(timer_remaining: 1)
    TimerTickJob.perform_now(@room.id)
    @room.reload
    assert_equal 0, @room.timer_remaining
    assert_equal "stopped", @room.timer_status
  end

  test "does not enqueue another tick when timer reaches zero" do
    @room.update!(timer_remaining: 1)
    assert_no_enqueued_jobs(only: TimerTickJob) do
      TimerTickJob.perform_now(@room.id)
    end
  end

  # ── Guard clauses ───────────────────────────────────────────────
  test "does nothing if room does not exist" do
    assert_nothing_raised do
      TimerTickJob.perform_now(-1)
    end
  end

  test "does nothing if timer is paused" do
    @room.update!(timer_status: "paused")
    original = @room.timer_remaining

    TimerTickJob.perform_now(@room.id)
    @room.reload
    assert_equal original, @room.timer_remaining
  end

  test "does nothing if timer is stopped" do
    @room.update!(timer_status: "stopped")
    original = @room.timer_remaining

    TimerTickJob.perform_now(@room.id)
    @room.reload
    assert_equal original, @room.timer_remaining
  end

  # ── Edge cases ──────────────────────────────────────────────────
  test "handles concurrent pause between ticks" do
    @room.update!(timer_status: "paused", timer_remaining: 50)

    assert_no_enqueued_jobs(only: TimerTickJob) do
      TimerTickJob.perform_now(@room.id)
    end
    @room.reload
    assert_equal 50, @room.timer_remaining
  end
end
