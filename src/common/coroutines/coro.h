#pragma once

#include <boost/asio/awaitable.hpp>
#include <common/telemetry/trace/trace_asio.h>

namespace uh::cluster {

template <typename T> using coro = boost::asio::traced_awaitable<T>;

inline thread_local opentelemetry::context::Context THREAD_LOCAL_CONTEXT;

}
